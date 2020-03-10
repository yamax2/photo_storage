# PhotoStorage

Приложение для организации фотоархива на облачных серверах, в настоящее время поддерживается только yandex disk.

Позволяет использовать yandex disk-аккаунты как webdav-ноды.

Пример docker-compose на локальном домене photos.localhost:8080, проверялось на Ubuntu >= 18.04:
```yaml
version: '3.3'

services:
  web:
    image: yamax2/photostorage_web
    env_file: .env
    stdin_open: true
    tty: true
    depends_on:
      - db
      - redis
    volumes:
      - static-files:/photostorage/public
      - upload:/photostorage/tmp/files

  sidekiq:
    image: yamax2/photostorage_web
    env_file: .env
    depends_on:
      - db
      - redis
      - web
    command: bundle exec sidekiq -C config/sidekiq.yml
    volumes:
      - upload:/photostorage/tmp/files
    external_links:
      - nginx

  db:
    image: postgres:${POSTGRES_VERSION:-12.2}-alpine
    environment:
      - POSTGRES_DB=${POSTGRES_DB:-photos}
      - POSTGRES_HOST_AUTH_METHOD=trust
    volumes:
      - pg-data:/var/lib/postgresql/data
      - ./docker/configs/dumps/pg:/docker-entrypoint-initdb.d:ro

  redis:
    image: redis:${REDIS_VERSION:-5}-alpine
    volumes:
      - redis-data:/data

  proxy:
    image: yamax2/photostorage_proxy
    depends_on:
      - db
      - web

  nginx:
    image: yamax2/photostorage_nginx
    depends_on:
      - web
      - proxy
    volumes:
      - static-files:/home/photos/public
      - cache:/var/cache/nginx
    env_file: .env
    environment:
      - RAILS_HOST=web
      - PROXY_HOST=proxy
    ports:
      - "8080:8080"
    networks:
      default:
        aliases:
          - photos.localhost
          - www.photos.localhost
          - proxy.photos.localhost

volumes:
  pg-data:
    driver: local

  redis-data:
    driver: local

  static-files:
    driver: local

  cache:
    driver: local

  upload:
    driver: local
```

Окружение
```bash
PHOTOSTORAGE_SMTP_DOMAIN=...
PHOTOSTORAGE_SMTP_USER=...
PHOTOSTORAGE_SMTP_PASSWORD=...

PHOTOSTORAGE_YANDEX_API_KEY=...
PHOTOSTORAGE_YANDEX_API_SECRET=...

TZ=Asia/Yekaterinburg

PHOTOSTORAGE_ADMIN_EMAILS=max@tretyakov-ma.ru,max@mytm.tk
# PHOTOSTORAGE_ADDITIONAL_TIMEZONES=Europe/Moscow,Europe/Samara
HOST=photos.localhost:8080
# PROTOCOL=http
PROXY_SUBDOMAIN=proxy

# openssl rand -hex 64
SECRET_KEY_BASE=...

PHOTOSTORAGE_PROXY_SECRET=very_secret
# openssl rand -hex 8
PHOTOSTORAGE_PROXY_SECRET_IV=...
```

### credentials

download master.key and run
```bash
dip rails credentials:edit
```

secrets:
```
yandex:
  api_key: ...
  api_secret: ...

email:
  login: auto@mytm.tk
  password: ...
  domain: mytm.tk

proxy:
  secret: ...
  iv: <16 bytes>

backup_secret: ...
secret_key_base: ...
```
