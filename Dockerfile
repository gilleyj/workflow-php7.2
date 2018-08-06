FROM php:7.2-fpm-alpine3.7

ENV TIMEZONE=UTC \
	ENV=/etc/profile \
	APP_ENV=development

RUN apk --update add dumb-init ca-certificates nginx supervisor bash \
		tzdata unzip zip openssl && \
	apk add --virtual .build_package git curl build-base autoconf dpkg-dev \
		file libmagic re2c && \
	apk add --virtual .deps_run bzip2 libjpeg-turbo libpng libmcrypt freetype \
		icu libcurl && \
	apk add --virtual .build_deps bzip2-dev libjpeg-turbo-dev libpng-dev \
		libmcrypt-dev freetype-dev icu-dev curl-dev

# setup timezone
# update ca certs
# prep bash environmnet
# pepare nginx/php run and app directories
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
	echo "${TIMEZONE}" > /etc/timezone && \
	update-ca-certificates && \
	mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh && \
	echo alias dir=\'ls -alh --color\' >> /etc/profile && \
	echo 'source ~/.profile' >> /etc/profile && \
	echo 'cat /etc/os-release' >> ~/.profile && \
	rm -rf /etc/nginx/conf.d/default.conf && \
	mkdir -p /app /run/nginx /run/php /var/lib/nginx/logs && \
	chown -R nginx:www-data /run/nginx /var/lib/nginx/logs && \
	chown -R www-data:www-data /var/tmp/nginx /run/php /app && \
	chmod -R g+rws /app

# install php modules
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
	docker-php-ext-install intl curl gd exif pdo_mysql bcmath zip&& \
	pecl install -o -f xdebug mcrypt && \
	docker-php-ext-enable xdebug mcrypt

RUN curl --silent --show-error https://getcomposer.org/installer | php && \
	mv /var/www/html/composer.phar /usr/local/bin/composer

# Clean up
RUN apk del .build_package .build_deps && \
	{ find /usr/local/lib -type f -print0 | xargs -0r strip --strip-all -p 2>/dev/null || true; } && \
	rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*

# copy our config files over to the container
COPY ./container_configs/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY ./container_configs/nginx.conf /etc/nginx/nginx.conf
COPY ./container_configs/default.conf.prod /etc/nginx/conf.d/default.conf.prod
COPY ./container_configs/default.conf.dev /etc/nginx/conf.d/default.conf.dev
COPY ./container_configs/cmd.sh /cmd.sh
COPY ./container_configs/index.php /app/index.php

# Report on PHP build
RUN chmod a+x /cmd.sh && \
	php -v && \
	php -m

WORKDIR /app

# expose our service port
EXPOSE 80

# start with our PID 1 controller
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# what we use to start the container
CMD ["/cmd.sh"]
