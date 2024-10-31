FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalamos paquetes esenciales incluyendo MySQL
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    unzip \
    mysql-server \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update \
    && apt-get install -y \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instalamos Swoole
RUN pecl install swoole \
    && echo "extension=swoole.so" > /etc/php/8.2/cli/conf.d/swoole.ini

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configuramos MySQL
RUN service mysql start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS cumplimiento_db;" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '1524';" && \
    mysql -e "GRANT ALL PRIVILEGES ON cumplimiento_db.* TO 'root'@'%';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;" && \
    sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

WORKDIR /app

COPY . .

# Instalamos dependencias de Composer
RUN composer install --no-dev --optimize-autoloader

# Configuramos el archivo .env
COPY .env.example .env
RUN sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=1524/' .env

RUN php artisan key:generate

# Instalamos Octane
RUN composer require laravel/octane --no-interaction \
    && php artisan octane:install --server=swoole

# Configuramos permisos
RUN chmod -R 775 storage bootstrap/cache

# Script de inicio para asegurar que MySQL esté funcionando
RUN echo '#!/bin/bash\n\
service mysql start\n\
while ! mysqladmin ping -h"localhost" --silent; do\n\
    sleep 1\n\
done\n\
php artisan migrate --force\n\
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000\n\
' > /app/start.sh && chmod +x /app/start.sh

EXPOSE 5000

CMD ["/app/start.sh"]