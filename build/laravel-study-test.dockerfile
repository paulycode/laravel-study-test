FROM php:7.3-fpm-alpine

# install composer
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN php -r " \
    copy('https://getcomposer.org/installer', 'composer-setup.php'); \
    if (hash_file('sha384', 'composer-setup.php') === trim(file_get_contents('https://composer.github.io/installer.sig'))) { \
        echo 'Installer verified'; \
        echo PHP_EOL; \
    } else { \
        echo 'Installer corrupt'; \
        echo PHP_EOL; \
        unlink('composer-setup.php'); \
        exit(1); \
    } \
  " \
 && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
 && php -r "unlink('composer-setup.php');" \
# using aliyun alpine mirror
 && echo "http://mirrors.aliyun.com/alpine/v3.10/main"      >  /etc/apk/repositories \
 && echo "http://mirrors.aliyun.com/alpine/v3.10/community" >> /etc/apk/repositories \
# nginx
 && apk add --no-cache \
    nginx \
    tzdata \
    supervisor \
# php-exts
 && docker-php-ext-install -j "$(nproc)" opcache pdo_mysql \
# timezone
 && /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo 'Asia/Shanghai' > /etc/timezone \
 && echo '[date]'                        >> "$PHP_INI_DIR/conf.d/docker-php-ext-date.ini" \
 && echo 'date.timezone = Asia/Shanghai' >> "$PHP_INI_DIR/conf.d/docker-php-ext-date.ini" \
# php.ini
 && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
# cleanup
 && rm -rf /var/cache/apk/* \
# nginx logs
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# composer install
COPY dist/composer.* /var/www/html/
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
 && cd /var/www/html \
 && composer update --ignore-platform-reqs --prefer-dist \
    --no-interaction \
    --no-autoloader \
    --no-plugins \
    --no-scripts \
    --no-suggest \
 && composer clearcache

# setup nginx, php-fpm, supervisor
COPY build/etc /etc/
COPY dist      /var/www/html

# logs & composer & crontab
RUN cd /var/www/html \
 && composer dump-autoload --optimize \
 && chown -R www-data:www-data /var/www/html/storage \
 && echo "* * * * * cd /var/www/html/ && php artisan schedule:run >> /dev/null 2>&1" >> /var/spool/cron/crontabs/root

# start nginx & php-fpm
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
