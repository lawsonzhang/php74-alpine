FROM php:7.4.11-alpine

RUN apk update; \
    apk add tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone; \
    apk del tzdata;

ENV PHPIZE_DEPS \
    autoconf \
    libc-dev \
    gcc \
    g++ \
    make

RUN set -e; \
    \
    apk add --no-cache --virtual .runtime-deps \
        libjpeg \
        libpng \
        freetype \
        libmemcached-libs \
        libmcrypt \
        git \
        busybox-extras \
        imagemagick-dev \
    ; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        libjpeg-turbo-dev \
        libpng-dev \
        freetype-dev \
        libxml2-dev \
        libzip-dev \
        openssl libssh-dev \
        libmemcached-dev \
        libmcrypt-dev \
    ;\
    docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
        mysqli \
        pdo_mysql \
        zip bcmath \
        opcache \
        pcntl \
        soap \
    && pecl install redis \
    && pecl install imagick \
    && cd /tmp && pecl download swoole \
    && tar -zxvf swoole* && cd swoole* \
    && phpize \
    && ./configure --enable-openssl --enable-http2 \
    && make -j "$(nproc)" && make install \
    && cd ~ && rm -rf /tmp/swoole* \
    && docker-php-ext-enable gd mysqli pdo_mysql zip bcmath opcache pcntl soap imagick redis swoole; \
    apk del .build-deps

RUN mkdir -p /data/logs/php

COPY php.ini /usr/local/etc/php/
