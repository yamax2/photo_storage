#!/bin/sh

set -e

echo 'building jq for armv7...'

wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-1.5.tar.gz
tar xfvz jq-1.5.tar.gz
cd jq-1.5
autoreconf -i
./configure --build x86_64-pc-linux-gnu --host=arm-none-linux-gnueabi --target=arm-none-linux-gnueabi LDFLAGS="-static" CC=arm-linux-gnueabihf-gcc  --disable-maintainer-mode
make

cp -f jq ../ready
echo 'finished'
