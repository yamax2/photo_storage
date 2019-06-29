package main

import(
        "log"
        "net/url"
        "net/http"
        "net/http/httputil"
)

func main() {
        remote, err := url.Parse("https://webdav.yandex.ru")
        if err != nil {
                panic(err)
        }

        proxy := httputil.NewSingleHostReverseProxy(remote)
        http.Handle("/", &ProxyHandler{proxy})
        err = http.ListenAndServe(":9000", nil)
        if err != nil {
                panic(err)
        }
}

type ProxyHandler struct {
        p *httputil.ReverseProxy
}

func (ph *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
        log.Println(r.URL)

        fn := r.URL.Query().Get("fn")
        if len(fn) != 0 {
            w.Header().Add("Content-Disposition", "inline; filename=\"" + fn + "\"")
        }

        r.Header.Add("Authorization", "OAuth ...")
        ph.p.ServeHTTP(w, r)
}
