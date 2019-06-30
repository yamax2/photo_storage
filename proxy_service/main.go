package main

import(
        // "log"
        "net/url"
        "net/http"
        "net/http/httputil"
        "database/sql"
        _ "github.com/lib/pq"
)

func main() {
        db, err := sql.Open("postgres", "host=db user=postgres dbname=photos sslmode=disable")
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

        remote, err := url.Parse("https://webdav.yandex.ru")
        if err != nil {
                panic(err)
        }

        proxy := httputil.NewSingleHostReverseProxy(remote)
        http.Handle("/", &ProxyHandler{env, proxy})
        err = http.ListenAndServe(":9000", nil)
        if err != nil {
                panic(err)
        }
}

type Env struct {
        Tokens map[string]string;
}

type ProxyHandler struct {
        *Env
        p *httputil.ReverseProxy
}

func (ph *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        // log.Println(r.URL)

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

        r.Header.Add("Authorization", "OAuth " + token)
        ph.p.ServeHTTP(w, r)
}
