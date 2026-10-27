# Reproduit l'hébergement o2switch en local : PHP + Apache, site à la racine, WordPress dans /blog.
FROM wordpress:php8.3-apache
RUN docker-php-ext-install pdo_mysql \
 && a2enmod rewrite headers expires \
 && sed -ri 's!DocumentRoot /var/www/html!DocumentRoot /var/www/site/public!' /etc/apache2/sites-available/000-default.conf \
 && printf '<Directory /var/www/site/public>\n  AllowOverride All\n  Require all granted\n</Directory>\n' > /etc/apache2/conf-enabled/site.conf
# L'entrypoint WordPress copie WordPress dans le dossier courant au premier démarrage.
WORKDIR /var/www/site/public/blog
