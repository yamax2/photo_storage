#!/bin/sh

set -e

attempt=0

until psql -h db -U postgres --dbname=photos -c 'SELECT COUNT(*) FROM yandex_tokens'; do
  attempt=$((attempt+1))

  if [ $attempt -ge 20 ]; then
      break
  fi

  echo 'Postgres is unavailable or migrations in process - sleeping'
  sleep 1
done
