package internal

import "flag"

type Config struct {
	ApiHost	string
	Listen  string
}

var config *Config

func GetConfig() *Config {
	return config
}

func LoadConfig() {
	config = &Config{}

	apiHost := flag.String("api", "localhost:3000", "api host")
	listen := flag.String("listen", "::9000", "listen addr")

	flag.Parse()

	config.ApiHost = *apiHost
	config.Listen = *listen
}
