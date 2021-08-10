package internal

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetConfig(t *testing.T) {
	t.Run("returns nil on start", func(t *testing.T) {
		assert.Nil(t, GetConfig())
	})

	t.Run("returns not nil after load", func(t *testing.T) {
		LoadConfig()
		assert.NotNil(t, GetConfig())
	})

	t.Cleanup(func() {
		config = nil
	})
}

func TestLoadConfig(t *testing.T) {
	origApiHost := os.Getenv("PHOTOSTORAGE_PROXY_API_HOST")
	origListen := os.Getenv("PHOTOSTORAGE_PROXY_LISTEN")

	t.Run("returns default values", func(t *testing.T) {
		LoadConfig()
		cfg := GetConfig()

		assert.Equal(t, cfg.ApiHost, "http://photostorage.localhost")
		assert.Equal(t, cfg.Listen, ":9000")
		assert.Equal(t, cfg.LogLevel, "info")
		assert.Equal(t, cfg.Secret, "very_secret")
	})

	t.Run("loads the env values", func(t *testing.T) {
		// FIXME: rework with t.Setenv in 1.17
		os.Setenv("PHOTOSTORAGE_PROXY_API_HOST", "test.localhost")
		os.Setenv("PHOTOSTORAGE_PROXY_LISTEN", "localhost:8080")

		LoadConfig()
		cfg := GetConfig()

		assert.Equal(t, cfg.ApiHost, "test.localhost")
		assert.Equal(t, cfg.Listen, "localhost:8080")
	})

	t.Cleanup(func() {
		config = nil

		os.Setenv("PHOTOSTORAGE_PROXY_API_HOST", origApiHost)
		os.Setenv("PHOTOSTORAGE_PROXY_LISTEN", origListen)
	})
}
