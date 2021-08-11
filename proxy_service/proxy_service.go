package main

import (
    "os"
    "os/signal"
    "context"
    "net/http"
    "time"
    "fmt"
    "syscall"

    log "github.com/sirupsen/logrus"
    . "proxy_service/internal"
    r "proxy_service/routes"
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

    if err := r.InitHandlers(); err != nil {
        log.Fatalf("Error: %s", err)
    } else {
        http.HandleFunc("/proxy/ping", r.PingHandler)
        http.HandleFunc("/proxy/yandex/", r.YandexOriginalsHandler)
        http.HandleFunc("/proxy/yandex/previews/", r.YandexPreviewsHandler)
        http.HandleFunc("/proxy/yandex/resize/", r.YandexResizeHandler)
    }

    srv := &http.Server{
       Addr:    cfg.Listen,
       Handler: logRequest(http.DefaultServeMux),
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

type loggingResponseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (lrw *loggingResponseWriter) WriteHeader(code int) {
    lrw.statusCode = code
    lrw.ResponseWriter.WriteHeader(code)
}

func logRequest(handler http.Handler) http.Handler {
    return http.HandlerFunc(
        func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            url := r.URL.String()

            lrw := &loggingResponseWriter{w, http.StatusOK}
            handler.ServeHTTP(lrw, r)

            log.WithFields(log.Fields{
                "method": r.Method,
                "url": url,
                "duration": fmt.Sprintf("%.2f", time.Since(start).Seconds()),
                "code": lrw.statusCode,
            }).Info(http.StatusText(lrw.statusCode))
        },
    )
}
