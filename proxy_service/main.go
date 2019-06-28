package main

import (
	"time"
	"io"
	"log"
	"net/http"
	"strings"
)

func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			if k != "Server" {
				dst.Add(k, v)
			}
		}
	}
}

type proxy struct {
}

func (p *proxy) ServeHTTP(wr http.ResponseWriter, r *http.Request) {
	client := &http.Client{}

	uri := r.RequestURI
	if strings.Index(uri, "/yandex") == 0 {
	    uri = strings.Replace(uri, "/yandex", "", 1)
	}
	req, err := http.NewRequest("GET", "https://webdav.yandex.ru" + uri, nil)
	req.Header.Add("Authorization", "OAuth ...")

	resp, err := client.Do(req)
	if err != nil {
		http.Error(wr, "Server Error", http.StatusInternalServerError)
		log.Fatal("ServeHTTP:", err)
	}

	defer resp.Body.Close()

	fn := r.URL.Query().Get("fn")
	if len(fn) != 0 {
		resp.Header.Add("Content-Disposition", "inline; filename=\"" + fn + "\"")
	}

	copyHeader(wr.Header(), resp.Header)
	wr.WriteHeader(resp.StatusCode)
	io.Copy(wr, resp.Body)
}

func main() {
	handler := &proxy{}
	log.Println("Starting server on :9000")

	srv := &http.Server{
	    Addr: ":9000",
	    Handler: handler,
	    ReadTimeout:  5 * time.Second,
	    WriteTimeout: 5 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}
