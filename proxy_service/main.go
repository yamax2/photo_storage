package main

import (
	"time"
	"io"
	"log"
	"net/http"
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

	req, err := http.NewRequest("GET", "https://webdav.yandex.ru" + r.RequestURI, nil)
	req.Header.Add("Authorization", "OAuth ...")

	resp, err := client.Do(req)
	if err != nil {
		http.Error(wr, "Server Error", http.StatusInternalServerError)
		log.Fatal("ServeHTTP:", err)
	}

	defer resp.Body.Close()
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
