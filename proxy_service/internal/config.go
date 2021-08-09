package internal

import (
	"crypto/sha256"

	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	ApiHost	 string	`envconfig:"PHOTOSTORAGE_PROXY_API_HOST" default:"localhost:3000"`
	Listen   string `envconfig:"PHOTOSTORAGE_PROXY_LISTEN" default:":9000"`
	LogLevel string	`envconfig:"PHOTOSTORAGE_PROXY_LOG_LEVEL" default:"info"`
	Secret   string `envconfig:"PHOTOSTORAGE_PROXY_SECRET" default:"very_secret"`

	secretSHA256 string
}

var config *Config

func GetConfig() *Config {
	return config
}

func LoadConfig() error {
	config = &Config{}

	if err := envconfig.Process("photostorage-proxy", config); err != nil {
		return err
	}

	config.parseSecret()

	return nil
}

func (cfg *Config) parseSecret() {
	key := sha256.Sum256([]byte(config.Secret))
	config.secretSHA256 = string(key[:])
}
