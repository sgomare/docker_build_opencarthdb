FROM php:7.4.13-apache-buster
COPY src/ /var/www/html/
RUN chmod 777 -R /var/www/html/opencart/

ENV APACHE_DOCUMENT_ROOT /var/www/html/opencart/upload
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN set -ex; \
        docker-php-source extract; \
        { \
                echo '# https://github.com/docker-library/php/issues/103#issuecomment-271413933'; \
                echo 'AC_DEFUN([PHP_ALWAYS_SHARED],[])dnl'; \
                echo; \
                cat /usr/src/php/ext/odbc/config.m4; \
        } > temp.m4; \
        mv temp.m4 /usr/src/php/ext/odbc/config.m4; \
        apt-get update; \
        apt-get install -y --no-install-recommends unixodbc-dev; \
        docker-php-ext-configure odbc --with-unixODBC=shared,/usr; \
        docker-php-ext-install odbc;

RUN apt-get update && apt-get install --no-install-recommends unixodbc unixodbc-dev -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
        libcurl4-openssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install curl \
    && docker-php-ext-install odbc \
    && docker-php-ext-install pdo \
    && docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
    && docker-php-ext-install pdo_odbc \
    && docker-php-source delete \
    && apt-get purge -y --auto-remove
