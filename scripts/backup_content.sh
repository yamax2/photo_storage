#!/bin/sh

# backup script for content (NAS)

exec 2>err.log

PHOTO_HOST='http://photostorage.localhost'
SECRET='very_secret'

TG_CHAT_ID='-...'
TG_BOT_ID='...:...'
#TG_CURL_PROXY='socks5h://user:passs@host:port'
TG_CURL_PROXY=
CURL_PROXY=

fn="$(date +"%Y_%m_%d_%H_%M_%S")"

tg_notify()
{
  curl -Lsk "https://api.telegram.org/bot$TG_BOT_ID/sendMessage" -d "{\"chat_id\": $TG_CHAT_ID, \"text\": \"$1\"}" \
      -H 'Content-Type: application/json; charset=utf-8' -x "$TG_CURL_PROXY" > /dev/null
}

api_request()
{
  AUTH='admin:'

  attempt=0
  while true; do
    response=$(curl -Lsk -u "$AUTH" -x "$CURL_PROXY" "$PHOTO_HOST$1")

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

zip_info()
{
  count=$(unzip -Z "$1" | sed -e '1,2d' | sed '$ d' | awk '{print $4}' | grep -v '^0$' | wc -l)
  size=$(unzip -Zt "$1" | tail -n 1 | awk '{print $3}')

  echo "$size:$count"
}

tg_notify '📂 backup started'

api_request '/api/v1/admin/yandex/tokens' | \
  jq  -r '.[] | [.id,.login,.type,.folder_index] | @csv' | while read -r line; do
  id=$(echo "$line" | cut -d',' -f1)

  login=$(echo "$line" | cut -d',' -f2 | sed -e 's/^"//' -e 's/"$//')
  resource=$(echo "$line" | cut -d',' -f3 | sed -e 's/^"//' -e 's/"$//')
  folder_index=$(echo "$line" | cut -d',' -f4 | sed -e 's/^"//' -e 's/"$//')

  key=$(echo -n $SECRET | sha256sum | awk '{ print $1 }')
  iv=$(echo -n $login | md5sum | awk '{ print $1 }')

  token_data=$(api_request "/api/v1/admin/yandex/tokens/$id?resource=$resource&folder_index=$folder_index")
  info=$(echo "$token_data" | jq -r '.info' | openssl aes-256-cbc -a -d -K "$key" -iv "$iv")

  if [ -z "$info" ]; then
    continue
  fi

  filename="$id-$resource-$folder_index-$fn.zip"
  url=$(echo "$info" | awk '{ print $1 }')
  token=$(echo "$info" | awk '{ print $2  }')

  if curl -Lsk -x "$CURL_PROXY" -o "$filename" -H "Authorization: OAuth $token" "$url" ; then
    tg_notify "✅ $filename has been downloaded"

    actual_data=$(zip_info "$filename")

    files_size=$(echo "$token_data" | jq -r '.size')
    files_count=$(echo $token_data | jq -r '.count')
    files_data="$files_size:$files_count"

    if [ "$actual_data" = "$files_data" ]; then
      tg_notify "✅ $filename validation passed $files_data"
    else
      tg_notify "⛔ $filename validation fails: downloaded $actual_data instead of $files_data"

      continue
    fi

    if [ "$resource" = "photo" ] && [ "$folder_index" = 0 ]; then
      api_request "/api/v1/admin/yandex/tokens/$id/touch"
    fi

    # "find -not" is not supported
    files_to_remove=$(find . -type f -name "$id-$resource-$folder_index-*.zip" | grep -v "$fn")
    if [ -n "$files_to_remove" ]; then
      rm -f $files_to_remove && \
        tg_notify "ℹ️ $(echo "$files_to_remove" | sed -e 's/^\.\///g' | tr '\n' ' ')has been deleted"
    fi
  else
    tg_notify "⛔ fail to download $resource for $id ($folder_index)"
  fi
done

tg_notify '📁 backup finished'
