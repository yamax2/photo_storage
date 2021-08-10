package routes

import (
	"fmt"
	"strconv"
	"context"

	"io/ioutil"
	"net/url"
	"net/http"
	"net/http/httputil"

	s "strings"

	. "proxy_service/internal"

	"github.com/h2non/bimg"
)

const yandexNodeBackend = "https://webdav.yandex.ru"

type ProxyHandlers struct {
	proxy *httputil.ReverseProxy
}

func NewProxyHandlers() (*ProxyHandlers, error) {
	remote, err := url.Parse(yandexNodeBackend)

	if err != nil {
		return nil, err
	}

	handler := &ProxyHandlers{}
	handler.proxy = httputil.NewSingleHostReverseProxy(remote)

	return handler, nil
}

func (h *ProxyHandlers) PingHandler(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("PONG"))
}

func (h *ProxyHandlers) YandexOriginalsHandler(w http.ResponseWriter, r *http.Request) {
	fn := r.URL.Query().Get("fn")

	if len(fn) != 0 {
		w.Header().Add("Content-Disposition", fmt.Sprintf("inline; filename=\"%s\"", fn))
	}

	node, err := getNode(r.URL.Query().Get("id"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if node == nil {
		http.Error(w, "Node not found", http.StatusNotFound)
		return
	}

	r.URL.Path = s.Replace(r.URL.Path, "/proxy/yandex", "", -1)
	w.Header().Add("Access-Control-Allow-Origin", "*")

	for k := range r.Header {
		delete(r.Header, k)
	}

	r.Header.Add("Authorization", fmt.Sprintf("OAuth %s", node.Secret))
	h.proxy.ServeHTTP(w, r)
}

func (h *ProxyHandlers) YandexPreviewsHandler(w http.ResponseWriter, r *http.Request) {
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

	imageURL := yandexNodeBackend + s.Replace(r.URL.Path, "/proxy/yandex/previews", "", -1)

	// FIXME: temporary code
	client := &http.Client{}
	req, _ := http.NewRequest("GET", imageURL, nil)
	req.Header.Set("Authorization", fmt.Sprintf("OAuth %s", node.Secret))
	resp, _ := client.Do(req)

	defer resp.Body.Close()

	buf, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	options := bimg.Options{
		Width:	size,
		Type:	bimg.WEBP,
	}

	if img, err := bimg.NewImage(buf).Process(options); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	} else {
		w.Header().Add("Content-Type", "image/webp")
		w.Write(img)
	}
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

