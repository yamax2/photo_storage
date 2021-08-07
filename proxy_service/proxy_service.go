package main

import (
    "os"
    "os/signal"
    "context"
    "net/http"
    "time"
    "syscall"

    log "github.com/sirupsen/logrus"
    . "proxy_service/internal"
)

func init() {
    log.SetFormatter(&log.JSONFormatter{})
    log.SetOutput(os.Stdout)

    if err := LoadConfig(); err != nil {
        log.Fatalf("cannot load config: %s", err)
    }
}

func main() {
    cfg := GetConfig()

    log.Info("Starting proxy service...")
    log.Infof("Api host: %s", cfg.ApiHost)
    log.Infof("Listen: %s", cfg.Listen)

    if level, err := log.ParseLevel(cfg.LogLevel); err != nil {
        log.Fatalf("Cannot parse log level: %s", err)
    } else {
        log.Infof("Log level: %s", cfg.LogLevel)
        log.SetLevel(level)
    }

    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    srv := &http.Server{
        Addr:    cfg.Listen,
        Handler: nil,
    }

    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("listen: %s", err)
        }
    }()

    <-ctx.Done()
    stop()

    log.Println("Shutting down gracefully, press Ctrl+C again to force")

    ctx, stop = context.WithTimeout(context.Background(), 5 * time.Second)
    defer stop()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown: ", err)
    }

    log.Info("Stopping...")
}
