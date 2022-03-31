FROM composer as composer
FROM php:8.0-cli

ENV APP_DIR /srv/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libzip-dev zip git \
    && docker-php-ext-install zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR $APP_DIR
COPY . .
