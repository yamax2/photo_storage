package internal

import (
	"testing"
	"context"
	"time"
	"net/http"
	"net/http/httptest"

	"github.com/stretchr/testify/assert"
)

func TestGetNode(t *testing.T) {
	t.Run("returns nil for non-existent node", func(t *testing.T) {
		assert.Nil(t, GetNode(1))
	})

	t.Run("returns nil for expired", func(t *testing.T) {
		nodes[1] = Node{
			Type: "yandex",
			Name: "test",
			Secret: "secret",
			LoadedAt: time.Now().Add(-4 * time.Hour),
		}

		assert.Nil(t, GetNode(1))
	})

	t.Run("returns value when not expired", func(t *testing.T) {
		nodes[1] = Node{
			Type: "yandex",
			Name: "test",
			Secret: "secret",
			LoadedAt: time.Now().Add(-59 * time.Minute),
		}

		assert.Equal(t, GetNode(1).Name, "test")
	})

	t.Cleanup(func() {
		nodes = make(map[int64]Node)
	})
}

func TestLoadNode(t *testing.T) {
	var nodeApiStub *httptest.Server

	LoadConfig()

	t.Run("when first time load", func(t *testing.T) {
		nodeApiStub = defaultStub()
		config.ApiHost = nodeApiStub.URL

		node, err := LoadNode(context.Background(), 1)

		assert.Nil(t, err)

		assert.Equal(t, node.Name, "nodedev.photostorage")
		assert.Equal(t, node.Type, "yandex")
		assert.Equal(t, node.Secret, "SAMPLE_TOKEN")
		assert.Equal(t, node.IsExpired(), false)
	})

	t.Run("when wrong encrypted data", func(t *testing.T) {
		nodes = make(map[int64]Node)

		nodeApiStub = httptest.NewServer(
			http.HandlerFunc(
				func(w http.ResponseWriter, r *http.Request) {
					w.Write([]byte(`{"id": 1, "name": "nodedev.photostorage", "type": "yandex", "secret": "c29tZSB0ZXh0"}`))
				},
			),
		)
		config.ApiHost = nodeApiStub.URL

		_, err := LoadNode(context.Background(), 1)

		assert.NotNil(t, err)
		assert.Equal(t, err.Error(), "encoded secret is not a multiple of the block size")
	})

	t.Run("when expired node exists", func(t *testing.T) {
		nodeApiStub = defaultStub()
		config.ApiHost = nodeApiStub.URL

		nodes[1] = Node{
			Name: "zozo",
			Type: "zozo",
			Secret: "secret",
			LoadedAt: time.Now().Add(-5 * time.Hour),
		}

		assert.Nil(t, GetNode(1))

		node, err := LoadNode(context.Background(), 1)

		assert.Nil(t, err)
		assert.Equal(t, node.Name, "nodedev.photostorage")
		assert.Equal(t, node.IsExpired(), false)

		assert.NotNil(t, GetNode(1))
	})

	t.Run("when timeout", func(t *testing.T) {
		nodes = make(map[int64]Node)
		httpClient = http.Client{
			Timeout: time.Duration(5 * time.Millisecond),
		}

		nodeApiStub = httptest.NewServer(
			http.HandlerFunc(
				func(w http.ResponseWriter, r *http.Request) {
					time.Sleep(5 * time.Second)
				},
			),
		)

		config.ApiHost = nodeApiStub.URL
		node, err := LoadNode(context.Background(), 1)

		assert.NotNil(t, err)
		assert.Nil(t, node)

		t.Cleanup(func() {
			httpClient = http.Client{
				Timeout: time.Duration(1 * time.Second),
			}
		})
	})

	t.Run("when invalid response", func(t *testing.T) {
		nodes = make(map[int64]Node)
		nodeApiStub = httptest.NewServer(
			http.HandlerFunc(
				func(w http.ResponseWriter, r *http.Request) {
					w.Write([]byte(`{"id": 1, "name": "test"}`))
				},
			),
		)

		config.ApiHost = nodeApiStub.URL
		node, err := LoadNode(context.Background(), 1)

		assert.Equal(t, err.Error(), "Node is not valid: 1")
		assert.Nil(t, node)
	})

	t.Run("when api response is 500", func(t *testing.T) {
		nodes = make(map[int64]Node)
		nodeApiStub = httptest.NewServer(
			http.HandlerFunc(
				func(w http.ResponseWriter, r *http.Request) {
					w.WriteHeader(http.StatusInternalServerError)
				},
			),
		)

		config.ApiHost = nodeApiStub.URL
		node, err := LoadNode(context.Background(), 1)

		assert.Equal(t, err.Error(), "Api response is Internal Server Error")
		assert.Nil(t, node)
	})

	t.Cleanup(func() {
		nodes = make(map[int64]Node)
		config = nil
	})
}

func TestNode_Valid(t *testing.T) {
	tests := []struct {
		name   string
		node   Node
		want   bool
	}{
		{
			"Valid with name, type and secret",
			Node{
				Type: "test",
				Name: "test",
				Secret: "test",
			},
			true,
		},
		{
			"Invalid with all empty attrs",
			Node{},
			false,
		},
		{
			"Invalid without name",
			Node{
				Type: "test",
				Secret: "secret",
			},
			false,
		},
		{
			"Invalid without secret",
			Node{
				Type: "test",
				Name: "name",
			},
			false,
		},
		{
			"Invalid without type",
			Node{
				Secret: "test",
				Name: "name",
			},
			false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.node.Valid(), tt.want)
		})
	}
}

func defaultStub() *httptest.Server {
	return httptest.NewServer(
		http.HandlerFunc(
			func(w http.ResponseWriter, r *http.Request) {
				w.Write([]byte(`{"id": 1, "name": "nodedev.photostorage", "type": "yandex", "secret": "Nm2H6lQKpuGl8h0FpQXAOw=="}`))
			},
		),
	)
}
