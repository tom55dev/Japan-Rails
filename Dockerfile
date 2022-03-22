# syntax=docker/dockerfile:1.0.0-experimental

ARG RUBY_VERSION=2.7.2

FROM ruby:$RUBY_VERSION-alpine AS builder

ARG BUNDLER_VERSION=2.2.3
ARG RAILS_ENV=production
ARG NODE_ENV=production

ENV BUNDLE_APP_CONFIG="/app/.bundle" \
  LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  RUBYOPT='-W:no-deprecated -W:no-experimental'

RUN apk --no-cache add bash build-base mariadb-dev nodejs tzdata && \
  rm -rf /var/cache/apk/*

RUN gem update --system && gem install bundler:$BUNDLER_VERSION

RUN mkdir -p /app
RUN mkdir -p /app/tmp/pids

WORKDIR /app

COPY Gemfile Gemfile.lock /app/
RUN --mount=type=ssh bundle install --without="development test" --path=vendor/bundle \
  && rm -rf vendor/bundle/ruby/*/cache/*.gem \
  && find vendor/bundle/ruby/*/gems/ -name "*.c" -delete \
  && find vendor/bundle/ruby/*/gems/ -name "*.o" -delete

COPY . /app
COPY config/database.docker.yml /app/config/database.yml

RUN bundle exec rails assets:precompile

RUN rm -rf node_modules tmp/cache vendor/assets spec

# App container
FROM ruby:$RUBY_VERSION-alpine

ENV BUNDLE_APP_CONFIG="/app/.bundle" \
  LANG=C.UTF-8

RUN apk --no-cache add bash mariadb-dev nodejs tzdata file && \
  rm -rf /var/cache/apk/*

ARG RAILS_ENV=production

COPY --from=builder /app /app
COPY lib/irbrc.rb /root/.irbrc

WORKDIR /app
