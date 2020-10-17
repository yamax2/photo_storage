# demo

Проверялось на Ubuntu >= 18.04

Потребуется создать аккаунт на яндексе

## Заполнение файла `.env`

Настройки для почтовых уведомлений (сверка)
```ruby
cp .env.example .env
PHOTOSTORAGE_SMTP_USER=...     # пользователь почты яндекса
PHOTOSTORAGE_SMTP_PASSWORD=... # пароль для почты
PHOTOSTORAGE_SMTP_DOMAIN=...   # заполняется в случае почты на домене
```

Регистрация приложения на https://oauth.yandex.ru/, получаем id и secret приложения
права следующие:
```
Яндекс.Диск REST API
Доступ к информации о Диске

API Яндекс.Паспорта
Доступ к логину, имени и фамилии, полу
Доступ к адресу электронной почты

Яндекс.Диск WebDAV API
Доступ к Яндекс.Диску для приложений
``` 

Прочие настройки:
```ruby
TZ=Asia/Yekaterinburg # тайм-зона по умолчанию
PHOTOSTORAGE_ADMIN_EMAILS=max@tretyakov-ma.ru,maximtr@yandex.ru  # почты для служебных уведомления через запятую
PHOTOSTORAGE_ADDITIONAL_TIMEZONES # добавочные тайм-зоны для фотографий
```

## Запуск приложения
```bash
docker-compose -d up
```

открываем в браузере http://photos.localhost:8080

## Работа с приложением
Вход в админку [http://photos.localhost:8080/admin](http://photos.localhost:8080/admin)

Добавляем ноды (яндекс-аккаунты) на странице [http://photos.localhost:8080/admin/yandex/tokens](http://photos.localhost:8080/admin/yandex/tokens)

Создаём рубрики на странице рубрик [http://photos.localhost:8080/admin/rubrics](http://photos.localhost:8080/admin/rubrics)

Загружаем фото на главной странице админки [http://photos.localhost:8080/admin](http://photos.localhost:8080/admin)
