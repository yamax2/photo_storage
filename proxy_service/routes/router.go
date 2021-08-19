package routes

import (
	"fmt"
	"strconv"
	"context"

	"net/url"
	"net/http"
	"net/http/httputil"

	s "strings"
	. "proxy_service/internal"
	//_ "net/http/pprof"
)

const yandexNodeBackend = "https://webdav.yandex.ru"

var proxy *httputil.ReverseProxy

func InitHandlers() error {
	if remote, err := url.Parse(yandexNodeBackend); err != nil {
		return err
	} else {
		proxy = httputil.NewSingleHostReverseProxy(remote)
	}

	return nil
}

func PingHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("PONG"))
}

func YandexOriginalsHandler(w http.ResponseWriter, r *http.Request) {
	fn := r.URL.Query().Get("fn")

	if len(fn) != 0 {
		w.Header().Add("Content-Disposition", fmt.Sprintf("inline; filename=\"%s\"", fn))
	}

	r.URL.Path = s.Replace(r.URL.Path, "/proxy/yandex", "", -1)
	w.Header().Add("Access-Control-Allow-Origin", "*")

	yandexProxyHandler(w, r)
}

func YandexPreviewsHandler(w http.ResponseWriter, r *http.Request) {
	r.URL.Path = s.Replace(r.URL.Path, "/proxy/yandex/previews", "", -1)
	r.URL.RawQuery = "preview&" + r.URL.Query().Encode()

	yandexProxyHandler(w, r)
}

func YandexResizeHandler(w http.ResponseWriter, r *http.Request) {
	node, err := getNode(r.URL.Query().Get("id"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if node == nil {
		http.Error(w, "Node not found", http.StatusNotFound)
		return
	}

	var size int
	size, err = strconv.Atoi(r.URL.Query().Get("size"))

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	imageURL := yandexNodeBackend + s.Replace(r.URL.Path, "/proxy/yandex/resize", "", -1)
	if img, err := DownloadAndResize(imageURL, node, size); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	} else {
		w.Header().Add("Content-Type", "image/webp")
		w.Write(img)
	}
}

func yandexProxyHandler(w http.ResponseWriter, r *http.Request) {
	node, err := getNode(r.URL.Query().Get("id"))

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if node == nil {
		http.Error(w, "Node not found", http.StatusNotFound)
		return
	}

	for k := range r.Header {
		delete(r.Header, k)
	}

	r.Header.Add("Authorization", fmt.Sprintf("OAuth %s", node.Secret))
	proxy.ServeHTTP(w, r)
}

func getNode(id string) (*Node, error) {
	parsedId, err := strconv.ParseInt(id, 10, 64)
	if err != nil {
		return nil, err
	}

	node := GetNode(parsedId)
	if node == nil {
		node, err = LoadNode(context.Background(), parsedId)

		if err != nil {
			return nil, err
		}
	}

	return node, nil
}
