ARG DOCKER_RUBY_VERSION
FROM ruby:${DOCKER_RUBY_VERSION}-alpine AS base

RUN apk add --update --no-cache tzdata libexif-dev xz-dev libpq less postgresql-client nodejs curl jq unzip openssl && \
    gem update --system && \
    mkdir /photostorage

ENV RAILS_ENV production
WORKDIR /photostorage

RUN bundle config set deployment true && \
    bundle config set no-cache true && \
    bundle config set clean true && \
    bundle config set frozen true && \
    bundle config set without 'development test'

FROM base AS builder

COPY Gemfile Gemfile.lock ./
COPY app /photostorage/app
COPY bin /photostorage/bin
COPY config /photostorage/config
COPY db /photostorage/db
COPY lib /photostorage/lib
COPY public /photostorage/public
COPY vendor /photostorage/vendor
COPY config.ru /photostorage/config.ru
COPY Rakefile /photostorage/Rakefile

RUN apk add --update --no-cache build-base postgresql-dev git && \
    bundle install --jobs `grep -c ^processor /proc/cpuinfo` && \
    bundle exec rails assets:precompile

FROM base
COPY --from=builder /photostorage /photostorage
COPY --from=builder /photostorage/vendor/bundle /photostorage/vendor/bundle
COPY --from=builder /usr/local/bundle/config /usr/local/bundle/config
COPY --from=builder /photostorage/public/assets /photostorage/public/assets
RUN mkdir -p /photostorage/log

ENV RAILS_LOG_TO_STDOUT true

EXPOSE 3000
CMD bundle exec rails db:create && bundle exec rails db:migrate && bundle exec rails s -p 3000 -b 0.0.0.0
