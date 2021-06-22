# PhotoStorage

Store your photos and tracks on multiple free cloud file storage accounts.

Only [Yandex disk](https://disk.yandex.ru/client/disk) is now supported.

See the docker-compose example on local domain `photos.localhost:8080` in `docker/photostorage` dir (Ubuntu >= 18.04 tested only).

## How to use the app (wip)

Register a new app on this page https://oauth.yandex.ru/ and choose the following permissions:
```
Яндекс.Диск REST API
Доступ к информации о Диске

API Яндекс.Паспорта
Доступ к логину, имени и фамилии, полу
Доступ к адресу электронной почты

Яндекс.Диск WebDAV API
Доступ к Яндекс.Диску для приложений
```

Then open admin page `/admin`

You can use the app with the cheapest VDS: 2 core, 1GB RAM (2GB is recommended), 10GB hdd.

## Local development with docker

For ubuntu >= 18.04. For another os see the dip readme.

* install [dip](https://github.com/bibendi/dip)
* add `export DOCKER_TLD=localhost` to `.bashrc`
* `dip ssh up && dip dns up --domain localhost && dip nginx up --domain localhost`
* `dip provision`
* Start web app: `dip rails s` and open `photostorage.localhost` in your browser
* Start sidekiq: `dip compose up -d sidekiq`
* Run tests:
```bash
RAILS_ENV=test dip provision
dip rspec
```
* Run rubocop: `dip rubocop` (test env)
