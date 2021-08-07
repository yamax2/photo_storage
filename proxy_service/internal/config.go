package internal

import "github.com/kelseyhightower/envconfig"

type Config struct {
	ApiHost	 string	`envconfig:"PHOTOSTORAGE_PROXY_API_HOST" default:"localhost:3000"`
	Listen   string `envconfig:"PHOTOSTORAGE_PROXY_LISTEN" default:":9000"`
	LogLevel string	`envconfig:"PHOTOSTORAGE_PROXY_LOG_LEVEL" default:"info"`
}

var config *Config

func GetConfig() *Config {
	return config
}

func LoadConfig() error {
	config = &Config{}

	return envconfig.Process("photostorage-proxy", config)
}
