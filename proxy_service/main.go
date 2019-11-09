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
        "crypto/sha256"
        "crypto/md5"
        "encoding/base64"
        "encoding/json"
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

        session_secret := flag.String("secret", "secret", "secret for session cookie")
        app_host := flag.String("host", "photostorage.localhost", "app host")

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
        secret := sha256.Sum256([]byte(*session_secret))
        iv := md5.Sum([]byte(*app_host))

        http.Handle("/", &ProxyHandler{env, proxy, false, secret[:], iv[:]})
        http.Handle("/originals/", &ProxyHandler{env, proxy, true, secret[:], iv[:]})

        err = http.ListenAndServe(fmt.Sprintf("%s:9000", *listen_addr), nil)
        if err != nil {
                panic(err)
        }
}

type ProxyHandler struct {
        *Env
        p *httputil.ReverseProxy
        originals bool
        secret    []byte
        iv        []byte
}

type SessionInfo struct {
        Till int64 `json:"till"`
}

func (ph *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        session, err := r.Cookie("proxy_session")
        if err != nil {
            http.Error(w, "not authorized", http.StatusUnauthorized)
            return
        }

        if !ph.ValidateSession(session.Value) {
            http.Error(w, "forbidden", http.StatusForbidden)
            return
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
        decoded, err := base64.RawURLEncoding.DecodeString(session)
        if err != nil {
            return false
        }

        block, err := aes.NewCipher(ph.secret)
        if (err != nil || len(decoded)%aes.BlockSize != 0) {
            return false
        }

        mode := cipher.NewCBCDecrypter(block, ph.iv)
        mode.CryptBlocks(decoded, decoded)

        var info SessionInfo
        err = json.Unmarshal(decoded, &info)

        if err != nil {
            return false
        }

        till := time.Unix(info.Till, 0)

        return till.After(time.Now().UTC())
}
