ARG DOCKER_RUBY_VERSION
FROM ruby:${DOCKER_RUBY_VERSION}-alpine

RUN apk add --update --no-cache \
    tzdata libexif-dev openssh-client xz-dev libpq nodejs build-base less git postgresql-dev postgresql-client mc
RUN cp /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime && echo 'Asia/Yekaterinburg' > /etc/timezone

RUN gem update --system
RUN gem install 'bundler:2.2.7'
RUN ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts

ENV EDITOR mcedit
ENV BROWSER /bin/cat
ENV BUNDLE_APP_CONFIG /app/.bundle

WORKDIR /app
