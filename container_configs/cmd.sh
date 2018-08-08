#!/bin/sh
# ----------------------------------------------------------------------------
# cmd for container
# ----------------------------------------------------------------------------
set -e

HOST_IP=`/bin/grep $HOSTNAME /etc/hosts | /usr/bin/cut -f1`
export HOST_IP=${HOST_IP}
echo
echo "container started with ip: ${HOST_IP}..."
echo
for script in /container-init.d/*.sh; do
	case "$script" in
		*.sh)     echo "... running $script"; . "$script" ;;
		*)        echo "... ignoring $script" ;;
	esac
	echo
done

nginx_conf="/etc/nginx/conf.d/default.conf.${APP_ENV:-prod}"
if [ -f ${nginx_conf} ]; then
	echo copying ${file} to default.conf....
	cp ${nginx_conf} /etc/nginx/conf.d/default.conf
else
	echo ${nginx_conf} not found, copying default.conf.prod to default.conf....
	cp /etc/nginx/conf.d/default.conf.prod /etc/nginx/conf.d/default.conf
fi

echo "starting php-fpm and nginx..."
/usr/local/sbin/php-fpm --daemonize &
/usr/sbin/nginx -g "daemon off;"

