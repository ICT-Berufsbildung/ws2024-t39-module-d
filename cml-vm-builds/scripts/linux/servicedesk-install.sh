#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'


# Configure hostname and hosts
echo 'servicedesk' >/etc/hostname

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost servicedesk
::1       localhost ip6-localhost ip6-loopback servicedesk
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# Install required packages unattended
export DEBIAN_FRONTEND=noninteractive
apt-get -qqy update

apt-get install -qqy \
  -o DPkg::options::="--force-confdef" \
  -o DPkg::options::="--force-confold" \
    unzip vim apache2 libapache2-mod-fcgid mariadb-server php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml \
    php-bcmath php-imap php-intl php-mailparse php-pear curl php-dom php-iconv php-xsl php-ctype php-pdo php-bz2 php-calendar php-exif php-fileinfo php-mysqli \
    php-posix php-tokenizer php-xmlwriter php-xmlreader php-phar php-soap libapache2-mod-php php-gmp php-apcu php-redis php-imagick php-xdebug

a2enmod actions fcgid alias proxy_fcgi rewrite
systemctl restart apache2

mysql -u root -e 'CREATE DATABASE uvdesk'
mysql -u root -e "CREATE USER 'uvdesk'@'localhost' IDENTIFIED BY 'AllTooWell13'"
mysql -u root -e "GRANT ALL PRIVILEGES ON uvdesk.* TO 'uvdesk'@'localhost'"
mysql -u root -e "FLUSH PRIVILEGES"

# Install UVDesk
curl -sS https://getcomposer.org/installer -o composer-setup.php
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

cd /var/www/html
COMPOSER_ALLOW_SUPERUSER=1 composer create-project --no-interaction --no-dev uvdesk/community-skeleton uvdesk
chown -R www-data:www-data /var/www/html/uvdesk
chmod -R 775 /var/www/html/uvdesk
cat >/etc/apache2/sites-available/uvdesk.conf <<'EOF'
<VirtualHost *:80>
    ServerName help.wsc2024.local
    DocumentRoot /var/www/html/uvdesk/public

    <Directory /var/www/html/uvdesk>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch .php$>
        # 2.4.10+ can proxy to unix socket
        SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
    </FilesMatch>

    ErrorLog /var/log/apache2/uvdesk-error.log
    CustomLog /var/log/apache2/uvdesk-access.log combined
</VirtualHost>
EOF

cat >/var/www/html/uvdesk/.env <<'EOF'
APP_NAME=Servicedesk
APP_ENV=dev
APP_VERSION=1.0.8
APP_KEY=This1sW0rldSkill2024
APP_DEBUG=false
APP_URL=http://help.wsc2024.local
APP_TIMEZONE='Europe/Paris'
LOG_CHANNEL=stack
APP_CURRENCY=USD
DATABASE_URL=mysql://uvdesk:AllTooWell13@127.0.0.1:3306/uvdesk?serverVersion=10.11.6-MariaDB

BROADCAST_DRIVER=log
CACHE_DRIVER=file
SESSION_DRIVER=file
SESSION_LIFETIME=20
QUEUE_DRIVER=sync

MAILER_DSN=null://null
EOF

chown -R www-data:www-data /var/lib/php/sessions
a2ensite uvdesk
a2dissite 000-default
a2enmod rewrite
systemctl restart apache2

su - appadmin -c 'cd /var/www/html/uvdesk && php bin/console doctrine:migrations:migrate --no-interaction --quiet'
su - appadmin -c 'cd /var/www/html/uvdesk && php bin/console doctrine:fixtures:load --append'
su - appadmin -c 'cd /var/www/html/uvdesk && php bin/console uvdesk_wizard:defaults:create-user ROLE_SUPER_ADMIN admin admin@wsc2024.local AllTooWell13 --no-interaction'

