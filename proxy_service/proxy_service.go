package main

import (
    "os"
    log "github.com/sirupsen/logrus"

    . "proxy_service/internal"
)

func init() {
    log.SetFormatter(&log.JSONFormatter{})
    log.SetOutput(os.Stdout)
    log.SetLevel(log.InfoLevel)

    LoadConfig()
}

func main() {
    cfg := GetConfig()

    log.Info("Starting proxy service...")
    log.Infof("Api host: %s", cfg.ApiHost)
    log.Infof("Listen: %s", cfg.Listen)

    log.Info("Stopping...")
}
