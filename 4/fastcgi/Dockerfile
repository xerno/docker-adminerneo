FROM php:8.2-fpm-alpine

RUN echo "upload_max_filesize = 256M" > /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
 && echo "post_max_size = 256M" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
 && echo "memory_limit = 2G" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
 && echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
 && echo "max_input_vars = 10000" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini

RUN	addgroup -S adminer \
&&	adduser -S -G adminer adminer \
&&	mkdir -p /var/www/html \
&&	mkdir /var/www/html/plugins-enabled \
&&	chown -R adminer:adminer /var/www/html

RUN	set -x \
&&	apk add --no-cache --virtual .build-deps \
	postgresql-dev \
	sqlite-dev \
	unixodbc-dev \
	freetds-dev \
&&	docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
&&	docker-php-ext-install \
	mysqli \
	pdo_pgsql \
	pdo_sqlite \
	pdo_odbc \
	pdo_dblib \
&&	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
&&	apk add --virtual .phpexts-rundeps $runDeps \
&&	apk del --no-network .build-deps

COPY	*.php /var/www/html/

ENV	ADMINER_VERSION=4.14
ENV	ADMINER_DOWNLOAD_SHA256=a97f99d5d73a6fe79ebd46a8a003f20dd5bbea2a35395480274fac10d2281744
ENV	ADMINER_COMMIT=2993ee4ea714819e342ca999edf9e351c05bca37

RUN	set -x \
&&	apk add --no-cache --virtual .build-deps git \
&&	curl -fsSL "https://github.com/adminerneo/adminerneo/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php" -o adminer.php \
&&	echo "$ADMINER_DOWNLOAD_SHA256  adminer.php" |sha256sum -c - \
&&	git clone --recurse-submodules=designs --depth 1 --shallow-submodules --branch "v$ADMINER_VERSION" https://github.com/adminerneo/adminerneo.git /tmp/adminer \
&&	commit="$(git -C /tmp/adminer/ rev-parse HEAD)" \
&&	[ "$commit" = "$ADMINER_COMMIT" ] \
&&	cp -r /tmp/adminer/designs/ /tmp/adminer/plugins/ . \
&&	rm -rf /tmp/adminer/ \
&&	apk del --no-network  .build-deps

COPY	entrypoint.sh /usr/local/bin/
ENTRYPOINT	[ "entrypoint.sh", "docker-php-entrypoint" ]

USER	adminer
CMD	[ "php-fpm" ]
