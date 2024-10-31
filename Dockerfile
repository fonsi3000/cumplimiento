# Usa Ubuntu 22.04 como imagen base
FROM ubuntu:22.04

# Evita interacciones durante la instalación de paquetes
ENV DEBIAN_FRONTEND=noninteractive

# Actualiza el sistema e instala paquetes necesarios
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y bash git sudo openssh-client \
    libxml2-dev libonig-dev autoconf gcc g++ make npm \
    libfreetype6-dev libjpeg-turbo8-dev libpng-dev libzip-dev \
    curl unzip nano software-properties-common

# Instala MySQL
RUN apt-get install -y mysql-server

# Agrega el repositorio de PHP 8.2 y lo instala junto con las extensiones requeridas
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y php8.2 php8.2-fpm php8.2-cli php8.2-common \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
    php8.2-intl php8.2-readline php8.2-pcov php8.2-dev

# Instala Swoole desde PECL
RUN pecl install swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini && \
    phpenmod swoole

# Instala Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configura MySQL
RUN service mysql start && \
    mysql -e "CREATE DATABASE cumplimiento_db;" && \
    mysql -e "CREATE USER 'root'@'%' IDENTIFIED BY '1524';" && \
    mysql -e "GRANT ALL PRIVILEGES ON cumplimiento_db.* TO 'root'@'%';" && \
    mysql -e "FLUSH PRIVILEGES;"

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos de la aplicación al contenedor
COPY . .

# Copia el archivo .env.example a .env si no existe
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Configura todas las variables en el archivo .env
RUN sed -i 's/APP_NAME=.*/APP_NAME="Cumplimiento EM"/' .env && \
    sed -i 's/APP_ENV=.*/APP_ENV=local/' .env && \
    sed -i 's/APP_DEBUG=.*/APP_DEBUG=true/' .env && \
    sed -i 's/APP_URL=.*/APP_URL=http:\/\/localhost:5000/' .env && \
    sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=1524/' .env && \
    sed -i 's/BROADCAST_DRIVER=.*/BROADCAST_DRIVER=log/' .env && \
    sed -i 's/CACHE_DRIVER=.*/CACHE_DRIVER=file/' .env && \
    sed -i 's/FILESYSTEM_DISK=.*/FILESYSTEM_DISK=local/' .env && \
    sed -i 's/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/' .env && \
    sed -i 's/SESSION_DRIVER=.*/SESSION_DRIVER=file/' .env && \
    sed -i 's/SESSION_LIFETIME=.*/SESSION_LIFETIME=120/' .env && \
    sed -i 's/MEMCACHED_HOST=.*/MEMCACHED_HOST=127.0.0.1/' .env && \
    sed -i 's/REDIS_HOST=.*/REDIS_HOST=127.0.0.1/' .env && \
    sed -i 's/REDIS_PASSWORD=.*/REDIS_PASSWORD=null/' .env && \
    sed -i 's/REDIS_PORT=.*/REDIS_PORT=6379/' .env && \
    sed -i 's/MAIL_MAILER=.*/MAIL_MAILER=smtp/' .env && \
    sed -i 's/MAIL_HOST=.*/MAIL_HOST=smtp.mailersend.net/' .env && \
    sed -i 's/MAIL_PORT=.*/MAIL_PORT=587/' .env && \
    sed -i 's/MAIL_USERNAME=.*/MAIL_USERNAME=MS_Vb1rjI@trial-3yxj6ljmmmxldo2r.mlsender.net/' .env && \
    sed -i 's/MAIL_PASSWORD=.*/MAIL_PASSWORD=eWnEvTCwlchI0E8M/' .env && \
    sed -i 's/MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=tls/' .env && \
    sed -i 's/MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS="MS_Vb1rjI@trial-3yxj6ljmmmxldo2r.mlsender.net"/' .env && \
    sed -i 's/MAIL_FROM_NAME=.*/MAIL_FROM_NAME="${APP_NAME}"/' .env && \
    sed -i 's/OCTANE_SERVER=.*/OCTANE_SERVER=swoole/' .env

# Instala las dependencias del proyecto
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Configura los permisos correctos para los directorios de almacenamiento y caché
RUN chmod -R 775 storage bootstrap/cache

# Genera la clave de la aplicación si no existe
RUN php artisan key:generate --force

# Instala Laravel Octane
RUN composer require laravel/octane spiral/roadrunner --no-interaction

# Instala Octane con Swoole
RUN php artisan octane:install --server=swoole

# Crea un script de inicio para asegurar que MySQL esté en funcionamiento antes de ejecutar las migraciones
RUN echo '#!/bin/bash\n\
service mysql start\n\
while ! mysqladmin ping -h"localhost" --silent; do\n\
    sleep 1\n\
done\n\
php artisan migrate --force\n\
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000\n\
' > /app/start.sh && chmod +x /app/start.sh

# Comando para iniciar MySQL, ejecutar migraciones y la aplicación
CMD ["/app/start.sh"]

# Expone el puerto 5000 para acceder a la aplicación
EXPOSE 5000