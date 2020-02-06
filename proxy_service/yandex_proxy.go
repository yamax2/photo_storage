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
        _ "github.com/lib/pq"
)

type Env struct {
        Tokens map[string]string
}

func LoadTokens(connectionStr string) *Env {
        db, err := sql.Open("postgres", connectionStr)
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
        dbHost := flag.String("db_host", "localhost", "db host")
        dbUser := flag.String("user", "postgres", "db user")
        dbName := flag.String("db", "photos", "database")

        listenAddr := flag.String("listen", "127.0.0.1", "listen_addr")
        flag.Parse()

        connectionStr := fmt.Sprintf("host=%s user=%s dbname=%s sslmode=disable", *dbHost, *dbUser, *dbName)
        log.Println(connectionStr)
        env := LoadTokens(connectionStr)

        remote, err := url.Parse("https://webdav.yandex.ru")
        if err != nil {
                panic(err)
        }

        proxy := httputil.NewSingleHostReverseProxy(remote)
        http.Handle("/", &ProxyHandler{env, proxy, false})
        http.Handle("/originals/", &ProxyHandler{env, proxy, true})

        err = http.ListenAndServe(fmt.Sprintf("%s:9000", *listenAddr), nil)
        if err != nil {
                panic(err)
        }
}

type ProxyHandler struct {
        *Env
        p *httputil.ReverseProxy
        originals  bool
}

func (ph *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
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
            w.Header().Add("Access-Control-Allow-Origin", "*")
        }

        r.Header.Add("Authorization", "OAuth " + token)
        ph.p.ServeHTTP(w, r)
}
