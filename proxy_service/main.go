package main

import(
        "fmt"
        "log"
        "flag"
        "net/url"
        "net/http"
        "net/http/httputil"
        "database/sql"
        "strings"
        "crypto/aes"
        "crypto/cipher"
        "crypto/md5"
        "encoding/base64"
        "encoding/hex"
        "encoding/json"
        "bytes"
        "time"
        _ "github.com/lib/pq"
)

type Env struct {
        Tokens map[string]string;
}

func LoadTokens(connection_str string) *Env {
        db, err := sql.Open("postgres", connection_str)
        if err != nil {
                panic(err)
        }
        defer db.Close()

        rows, err := db.Query("SELECT id, access_token FROM yandex_tokens")
        if err != nil {
                panic(err)
        }
        defer rows.Close()

        env := &Env{make(map[string]string)}
        for rows.Next() {
                var id, token string

                err := rows.Scan(&id, &token)
                if err != nil {
                        panic(err)
                }

                env.Tokens[id] = token
        }

        return env
}

func main() {
        db_host := flag.String("db_host", "localhost", "db host")
        db_user := flag.String("user", "postgres", "db user")
        db_name := flag.String("db", "photos", "database")

        no_session := flag.Bool("no_session", false, "disable auth session usage")
        session_secret := flag.String("secret", "secret", "secret for session cookie")
        session_iv := flag.String("iv", "389ed464a551f644", "iv for session cookie")

        listen_addr := flag.String("listen", "127.0.0.1", "listen_addr")
        flag.Parse()

        connection_str := fmt.Sprintf("host=%s user=%s dbname=%s sslmode=disable", *db_host, *db_user, *db_name)
        log.Println(connection_str)
        env := LoadTokens(connection_str)

        remote, err := url.Parse("https://webdav.yandex.ru")
        if err != nil {
                panic(err)
        }

        proxy := httputil.NewSingleHostReverseProxy(remote)
        md5_secret := md5.Sum([]byte(*session_secret))
        secret := []byte(hex.EncodeToString(md5_secret[:]))
        iv := []byte(*session_iv)[:]

        http.Handle("/", &ProxyHandler{env, proxy, *no_session, false, secret, iv})
        http.Handle("/originals/", &ProxyHandler{env, proxy, *no_session, true, secret, iv})

        err = http.ListenAndServe(fmt.Sprintf("%s:9000", *listen_addr), nil)
        if err != nil {
                panic(err)
        }
}

type ProxyHandler struct {
        *Env
        p *httputil.ReverseProxy
        no_session bool
        originals  bool
        secret     []byte
        iv         []byte
}

type SessionInfo struct {
        Till int64 `json:"till"`
}

func (ph *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        if !ph.no_session {
            session, err := r.Cookie("proxy_session")

            if err != nil {
                http.Error(w, "not authorized", http.StatusUnauthorized)
                return
            }

            if  !ph.ValidateSession(session.Value) {
                http.Error(w, "forbidden", http.StatusForbidden)
                return
            }
        }

        fn := r.URL.Query().Get("fn")
        if len(fn) != 0 {
            w.Header().Add("Content-Disposition", "inline; filename=\"" + fn + "\"")
        }

        id := r.URL.Query().Get("id")
        token := ph.Env.Tokens[id]

        if len(token) == 0 {
            http.Error(w, "token not found", http.StatusBadRequest)
            return
        }

        if ph.originals {
            r.URL.Path = strings.Replace(r.URL.Path, "/originals", "", -1)
        }

        r.Header.Add("Authorization", "OAuth " + token)
        ph.p.ServeHTTP(w, r)
}

func  (ph *ProxyHandler) ValidateSession(session string) bool {
        raw, err := url.QueryUnescape(session)
        if err != nil {
            return false
        }

        decoded, err := base64.StdEncoding.DecodeString(raw)
        if err != nil {
            return false
        }

        md5sign := decoded[:16]
        decoded = decoded[16:]

        block, err := aes.NewCipher(ph.secret)
        if (err != nil || len(decoded)%aes.BlockSize != 0) {
            return false
        }

        mode := cipher.NewCBCDecrypter(block, ph.iv)
        mode.CryptBlocks(decoded, decoded)

        trash_bytes := int(decoded[len(decoded) -1])
        decoded = decoded[:len(decoded) - trash_bytes]

        expected_md5 := md5.Sum(decoded)
        if (bytes.Compare(md5sign, expected_md5[:]) != 0) {
            return false
        }

        var info SessionInfo
        err = json.Unmarshal(decoded[:len(decoded) - 8], &info)

        if err != nil {
            return false
        }

        till := time.Unix(info.Till, 0)

        return till.After(time.Now().UTC())
}
