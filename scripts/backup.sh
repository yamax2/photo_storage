#!/bin/sh

host='http://www.photostorage.localhost'
secret='very_secret'
auth='admin:'
fn="$(date +"%Y_%m_%d")"

curl -L -s -k -u "$auth" "$host/api/v1/admin/yandex/tokens" | jq  -r '.[] | [.id,.login,.type] | @csv' | while read -r line; do
  id=$(echo $line | cut -d',' -f1)
  login=$(echo $line | cut -d',' -f2 | sed 's/^"\|"$//g')
  resource=$(echo $line | cut -d',' -f3 | sed 's/^"\|"$//g')

  info=$(curl -L -s -k -u "$auth" "$host/api/v1/admin/yandex/tokens/$id?resource=$resource" | jq -r '.info' | \
    openssl aes-256-cbc -a -d -K $(echo -n $secret | \
    sha256sum | awk '{ print $1 }') -iv $(echo -n $login | md5sum | awk '{ print $1 }'))

  filename="$id-$resource-$fn.zip"
  url=$(echo $info | awk '{ print $1 }')
  token=$(echo $info | awk '{ print $2  }')

  curl -L -s -k -o "$filename" -H "Authorization: OAuth $token" "$url" && \
    find -type f -name "$id-$resource*.zip" -not -name "*$fn*" -exec rm -f {} \;
done
