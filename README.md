# PhotoStorage

Приложение для организации фотоархива на облачных серверах, поддерживается только yandex disk.

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

Окружение, файл `.env`
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

## Как работать с приложением?

* Регаемся на https://oauth.yandex.ru/, выбираем права:
```
Яндекс.Диск REST API
Доступ к информации о Диске

API Яндекс.Паспорта
Доступ к логину, имени и фамилии, полу
Доступ к адресу электронной почты

Яндекс.Диск WebDAV API
Доступ к Яндекс.Диску для приложений
```
* полученные ID и Пароль вставляем в переменные `PHOTOSTORAGE_YANDEX_API_KEY` и `PHOTOSTORAGE_YANDEX_API_SECRET`
* вход в админку `/admin`
* создать рубрику и токены яндекса.
* загружаем фото и треки на главной странице админки

Боевая версия отлично работает на самом дешевом VDS: 2 core, 1GB RAM, 10GB hdd.

## TODO

* выпилить поддомен proxy (переделать на простые роуты) убрать расширения nginx и кастомный образ.
* add ci
* eng docs and locale + нормальные доки.
* выложить сюда ansible playbooks боевого деплоя.
* ресайз карты (фронт)
* итоги для треков рубрики
* перечитать координаты из фото
* удалить фото, трек
* поворот для фото со старого Nikon

* заменить гем gpx на тулзу на golang для получения итогов
* кэш для треков
* склеивание треков

* вынести yandex в другое измерение - тип токена (?)
* бот-загрузчик
* цепочка действий в корзине

* гео-индекс в редисе (?)
* информирование о новых фото (?)

## local development with docker

* install [dip](https://github.com/bibendi/dip)
* add `export DOCKER_TLD=localhost` to `.bashrc`
* `dip ssh up && dip dns up --domain localhost && dip nginx up --domain localhost`
* `dip provision`
* webapp: `dip rails s` and open www.photostorage.localhost in your browser
* sidekiq: `dip compose up -d sidekiq`, proxy: `dip compose up -d proxy`
* tests:
```bash
RAILS_ENV=test dip provision
dip rspec
```
* rubocop: `dip rubocop`
