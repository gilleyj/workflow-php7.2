#!/bin/sh

file="/etc/nginx/conf.d/default.conf.${APP_ENV:-prod}"

if [ -f ${file} ]; then
	cp ${file} /etc/nginx/conf.d/default.conf
else
	cp /etc/nginx/conf.d/default.conf.prod /etc/nginx/conf.d/default.conf
fi

echo copying ${file}....

/usr/local/sbin/php-fpm --daemonize &
/usr/sbin/nginx -g "daemon off;"

