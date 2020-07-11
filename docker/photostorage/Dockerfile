ARG DOCKER_RUBY_VERSION=2.6.6
FROM ruby:${DOCKER_RUBY_VERSION}-alpine AS base

RUN apk add --update --no-cache tzdata libexif-dev xz-dev libpq less postgresql-dev nodejs
RUN gem update --system
RUN gem install 'bundler:2.1.4'
RUN mkdir /photostorage

ENV RAILS_ENV production
WORKDIR /photostorage

COPY Gemfile /photostorage/Gemfile
COPY Gemfile.lock /photostorage/Gemfile.lock

COPY app /photostorage/app
COPY bin /photostorage/bin
COPY config /photostorage/config
COPY db /photostorage/db
COPY lib /photostorage/lib
COPY public /photostorage/public
COPY vendor /photostorage/vendor
COPY config.ru /photostorage/config.ru
COPY Rakefile /photostorage/Rakefile

RUN bundle config set deployment 'true'
# production env is only for ubuntu
RUN bundle config set without 'development test production'

FROM base AS builder
RUN apk add --update --no-cache build-base
RUN bundle install
RUN bundle exec rails assets:precompile

FROM base

COPY --from=builder /photostorage/vendor/bundle /photostorage/vendor/bundle
COPY --from=builder /usr/local/bundle/config /usr/local/bundle/config
COPY --from=builder /photostorage/public/assets /photostorage/public/assets
RUN mkdir -p /photostorage/log

ENV RAILS_LOG_TO_STDOUT true

EXPOSE 3000
CMD bundle exec rails db:create && bundle exec rails db:migrate && bundle exec rails s -p 3000 -b 0.0.0.0
