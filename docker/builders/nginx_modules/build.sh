#!/bin/sh

NGINX_VERSION=1.17.9

set -e
rm -rf docker-nginx-with-modules
git clone git@github.com:tsuru/docker-nginx-with-modules.git
mkdir -p modules
sed -i -e 's/^USER.*$//g' docker-nginx-with-modules/Dockerfile

docker build -t photostorage-nginx-modules \
  --build-arg nginx_version=$NGINX_VERSION \
  --build-arg modules=https://github.com/simplresty/ngx_devel_kit.git,https://github.com/openresty/encrypted-session-nginx-module.git,https://github.com/openresty/set-misc-nginx-module.git \
  ./docker-nginx-with-modules

docker run -it -v "$PWD/modules":/etc/nginx/copied_modules photostorage-nginx-modules bash -c 'cp modules/* copied_modules/'

rm -rf docker-nginx-with-modules
echo "finished for $NGINX_VERSION"
