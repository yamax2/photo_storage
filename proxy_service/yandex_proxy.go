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
        "sync"
        _ "github.com/lib/pq"
)

type TokenInfo struct {
        mx sync.RWMutex
        connectionStr string
        Tokens map[string]string
}

func (env *TokenInfo) Reload() {
        env.mx.Lock()
        defer env.mx.Unlock()

        for id := range env.Tokens {
                delete(env.Tokens, id)
        }

        db, err := sql.Open("postgres", env.connectionStr)
        if err != nil {
                panic(err)
        }
        defer db.Close()

        rows, err := db.Query("SELECT id, access_token FROM yandex_tokens")
        if err != nil {
                panic(err)
        }
        defer rows.Close()

        for rows.Next() {
                var id, token string

                err := rows.Scan(&id, &token)
                if err != nil {
                        panic(err)
                }

                env.Tokens[id] = token
                fmt.Println(id, "loaded")
        }
}

func newTokenInfo(connectionStr string) *TokenInfo {
        return &TokenInfo{
                connectionStr: connectionStr,
                Tokens: make(map[string]string),
        }
}

func (env *TokenInfo) Get(id string) (string) {
        env.mx.RLock()
        defer env.mx.RUnlock()

        val, _ := env.Tokens[id]
        return val
}

// --------------------------------------------------------------------------

type ProxyHandler struct {
        tokens *TokenInfo
        p *httputil.ReverseProxy
        previews bool
}

func (ph *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        fn := r.URL.Query().Get("fn")
        if len(fn) != 0 {
                w.Header().Add("Content-Disposition", "inline; filename=\"" + fn + "\"")
        }

        id := r.URL.Query().Get("id")
        token := ph.tokens.Get(id)

        if len(token) == 0 {
                http.Error(w, "token not found", http.StatusBadRequest)
                return
        }

        r.URL.Path = strings.Replace(r.URL.Path, "/proxy", "", -1)

        if ph.previews {
                r.URL.Path = strings.Replace(r.URL.Path, "/previews", "", -1)
                r.URL.RawQuery = "preview&" + r.URL.Query().Encode()
        } else {
                w.Header().Add("Access-Control-Allow-Origin", "*")
        }

        r.Header.Add("Authorization", "OAuth " + token)
        ph.p.ServeHTTP(w, r)
}

// --------------------------------------------------------------------------

type ReloadHandler struct {
    tokens *TokenInfo
}

func (handler *ReloadHandler) ServeHTTP(w http.ResponseWriter, _r *http.Request) {
        go handler.tokens.Reload()

        w.WriteHeader(http.StatusAccepted)
        w.Write([]byte("OK"))
}

// --------------------------------------------------------------------------

func main() {
        dbHost := flag.String("db_host", "localhost", "db host")
        dbUser := flag.String("user", "postgres", "db user")
        dbName := flag.String("db", "photos", "database")

        listenAddr := flag.String("listen", "127.0.0.1", "listen_addr")
        flag.Parse()

        connectionStr := fmt.Sprintf("host=%s user=%s dbname=%s sslmode=disable", *dbHost, *dbUser, *dbName)
        log.Println(connectionStr)

        tokens := newTokenInfo(connectionStr)
        tokens.Reload()

        remote, err := url.Parse("https://webdav.yandex.ru")
        if err != nil {
                panic(err)
        }

        proxy := httputil.NewSingleHostReverseProxy(remote)
        http.Handle("/proxy/reload", &ReloadHandler{tokens})
        http.Handle("/proxy/", &ProxyHandler{tokens, proxy, false})
        http.Handle("/proxy/previews/", &ProxyHandler{tokens, proxy, true})

        err = http.ListenAndServe(fmt.Sprintf("%s:9000", *listenAddr), nil)
        if err != nil {
                panic(err)
        }
}
