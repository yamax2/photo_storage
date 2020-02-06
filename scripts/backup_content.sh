#!/bin/sh

# backup script for content (NAS)

exec 2>err.log

PHOTO_HOST='http://www.photostorage.localhost'
SECRET='very_secret'

TG_CHAT_ID='-...'
TG_BOT_ID='...:...'
TG_CURL_PROXY='socks5h://user:passs@host:port'

fn="$(date +"%Y_%m_%d")"

tg_notify()
{
  curl -fLsk "https://api.telegram.org/bot$TG_BOT_ID/sendMessage" -d "{\"chat_id\": $TG_CHAT_ID, \"text\": \"$1\"}" \
      -H 'Content-Type: application/json; charset=utf-8' -x "$TG_CURL_PROXY" > /dev/null
}

api_request()
{
  AUTH='admin:'

  attempt=0
  while true; do
    response=$(curl -fLsk -u "$AUTH" "$PHOTO_HOST$1")

    if [ $? -ne 0 ]; then
      tg_notify "⛔ fail to get api url $1"
      break
    fi

    if [ -n "$response" ]; then
      echo "$response"
      break
    fi

    attempt=$((attempt+1))
    if [ $attempt -ge 5 ]; then
      tg_notify "⛔ fail to get api url $1"
      break
    fi

    sleep 5
  done
}

tg_notify '📂 backup started'

api_request '/api/v1/admin/yandex/tokens' | \
  jq  -r '.[] | [.id,.login,.type] | @csv' | while read -r line; do
  id=$(echo "$line" | cut -d',' -f1)

  if [ -f proccessed ] && grep -q "\b$id\b" proccessed
  then
    continue
  fi

  login=$(echo "$line" | cut -d',' -f2 | sed -e 's/^"//' -e 's/"$//')
  resource=$(echo "$line" | cut -d',' -f3 | sed -e 's/^"//' -e 's/"$//')

  key=$(echo -n $SECRET | sha256sum | awk '{ print $1 }')
  iv=$(echo -n $login | md5sum | awk '{ print $1 }')
  info=$(api_request "/api/v1/admin/yandex/tokens/$id?resource=$resource" | jq -r '.info' | \
    openssl aes-256-cbc -a -d -K "$key" -iv "$iv")

  if [ -z "$info" ]; then
    continue
  fi

  filename="$id-$resource-$fn.zip"
  url=$(echo "$info" | awk '{ print $1 }')
  token=$(echo "$info" | awk '{ print $2  }')

  if curl -fLsk -o "$filename" -H "Authorization: OAuth $token" "$url" ; then
    tg_notify "✅ $filename has been downloaded"

    # "find -not" is not supported
    files_to_remove=$(find . -type f -name "$id-$resource*.zip" | grep -v "$fn")
    if [ -n "$files_to_remove" ]; then
      rm -f $files_to_remove && \
        tg_notify "ℹ️ $(echo "$files_to_remove" | sed -e 's/^\.\///g' | tr '\n' ' ')has been deleted"
    fi
  else
    tg_notify "⛔ fail to download $resource for $id"
  fi
done

tg_notify '📁 backup finished'
