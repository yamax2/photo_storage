# PhotoStorage

Приложение для организации фотоархива на облачных серверах, поддерживается только yandex disk.

Позволяет использовать yandex disk-аккаунты как webdav-ноды.

Пример docker-compose на локальном домене photos.localhost:8080 см. `docker/photostorage`

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

* add ci
* eng docs and locale + нормальные доки.
* move to webpack
* выложить сюда ansible playbooks боевого деплоя.
* ресайз карты (фронт)
* итоги для треков рубрики
* перечитать координаты из фото
* удалить фото, трек
* поворот для фото со старого Nikon
* статистика в admin dashboard

* заменить гем gpx на тулзу на golang для получения итогов
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
* webapp: `dip rails s` and open photostorage.localhost in your browser
* sidekiq: `dip compose up -d sidekiq`
* tests:
```bash
RAILS_ENV=test dip provision
dip rspec
```
* rubocop: `dip rubocop`
