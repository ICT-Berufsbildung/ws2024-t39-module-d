#!/bin/bash
set -euxo pipefail
IFS=$'\n\t'


# Configure hostname and hosts
echo 'helpdesk' >/etc/hostname

cat >/etc/hosts <<'EOF'
127.0.0.1 localhost helpdesk
::1       localhost ip6-localhost ip6-loopback helpdesk
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
    php-posix php-tokenizer php-xmlwriter php-xmlreader php-phar php-soap libapache2-mod-php php-gmp php-apcu php-redis php-imagick php-xdebug \
    python3-requests

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

cp /tmp/Agents.php /var/www/html/uvdesk/vendor/uvdesk/api-bundle/API/
cp /tmp/SavedRepliesSearch.php /var/www/html/uvdesk/vendor/uvdesk/core-framework/UIComponents/Dashboard/Search/SavedReplies.php
cp /tmp/SavedRepliesHomepage.php /var/www/html/uvdesk/vendor/uvdesk/core-framework/UIComponents/Dashboard/Homepage/Items/SavedReplies.php
cp /tmp/SavedRepliesPanel.php /var/www/html/uvdesk/vendor/uvdesk/core-framework/UIComponents/Dashboard/Panel/Items/Productivity/SavedReplies.php
cp /tmp/SavedReplies.php /var/www/html/uvdesk/vendor/uvdesk/core-framework/Controller/SavedReplies.php
cp /tmp/ticket.html.twig /var/www/html/uvdesk/vendor/uvdesk/core-framework/Resources/views/ticket.html.twig

chown -R www-data:www-data /var/www/html/uvdesk
chmod -R 775 /var/www/html/uvdesk
cat >/etc/apache2/sites-available/uvdesk-ssl.conf <<'EOF'
<VirtualHost *:443>
    ServerName helpdesk.wsc2024.local
    DocumentRoot /var/www/html/uvdesk/public

	SSLEngine on
	SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
	SSLCertificateKeyFile   /etc/ssl/private/ssl-cert-snakeoil.key

    RewriteEngine On
    RewriteRule ^/$ /en/member/login [R=302,L]

    <Directory /var/www/html/uvdesk>
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch .php$>
        # 2.4.10+ can proxy to unix socket
        SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
        SSLOptions +StdEnvVars
    </FilesMatch>

    ErrorLog /var/log/apache2/uvdesk-error.log
    CustomLog /var/log/apache2/uvdesk-access.log combined
</VirtualHost>
EOF

cat >/etc/apache2/sites-available/uvdesk.conf <<'EOF'
<VirtualHost *:80>
    ServerName helpdesk.wsc2024.local
    DocumentRoot /var/www/html/uvdesk/public
    # Redirect to SSL
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]
</VirtualHost>
EOF

cat >/var/www/html/uvdesk/.env <<'EOF'
APP_NAME=Helpdesk
APP_ENV=dev
APP_VERSION=1.0.8
APP_KEY=This1sW0rldSkill2024
APP_SECRET=This1sW0rldSkill2024
APP_DEBUG=false
APP_URL=https://helpdesk.wsc2024.local
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
a2ensite uvdesk-ssl
a2dissite 000-default
a2enmod ssl
a2enmod rewrite
systemctl restart apache2

cd /var/www/html/uvdesk
# Create DB schema
php bin/console doctrine:migrations:version --add --all --no-interaction
php bin/console doctrine:migrations:diff --quiet
php bin/console doctrine:migrations:status --quiet
php bin/console doctrine:migrations:migrate --no-interaction --quiet
# Load initial data
php bin/console doctrine:fixtures:load --append
# Create super admin user
php bin/console uvdesk_wizard:defaults:create-user ROLE_SUPER_ADMIN admin admin@wsc2024.local AllTooWell13@ --no-interaction

sed -i 's/APP_ENV=dev/APP_ENV=prod/g' /var/www/html/uvdesk/.env

cat >/etc/systemd/system/fake-smtp.service <<'EOF'
[Unit]
Description=Fake SMTP server
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m smtpd -n -c DebuggingServer 127.0.0.1:25
Restart=always
StandardOutput=null

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable fake-smtp.service
systemctl start fake-smtp.service

chown -R www-data:www-data /var/www/html/uvdesk
chmod -R 775 /var/www/html/uvdesk

mysql -u root uvdesk -e "UPDATE uv_website SET theme_color = '#003764'"
mysql -u root uvdesk < /tmp/saved_reply.sql

# Add users and tickets
python3 /tmp/uvdesk-import.py /tmp/users.csv /tmp/tickets.csv

mysql -u root uvdesk -e "SELECT id FROM uv_support_group" --skip-column-names | while read id; do
    mysql -u root uvdesk -e "INSERT INTO uv_saved_replies_groups VALUES ($id, 1)"
done