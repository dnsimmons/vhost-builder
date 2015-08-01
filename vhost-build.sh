#!/bin/bash

if [ -f /etc/redhat-release ]; then
	echo "Redhat based system located"
	DISTRO="Redhat"
	if [ -f /etc/httpd/vhost.d/$1.conf ]; then
		echo "Virtual Host already exists" 
		exit
	fi
fi
if [ -f /etc/debian_version ]; then
	echo "Debian based System located"
	DISTRO="Debian"
	if [ ! -f /etc/apache2/sites-enabled/$1 ]; then
		if [ -f /etc/apache2/sites-available/$1 ]; then
			echo "Virtual Host already exists"
		fi	
	else
		echo "Virtual Host already exists"
		exit
	fi
fi

DATA="<VirtualHost *:80>
        ServerName $1
        ServerAlias www.$1
        #### This is where you put your files for that domain: /var/www/vhosts/$1
        DocumentRoot /var/www/vhosts/$1

	#RewriteEngine On
	#RewriteCond %{HTTP_HOST} ^$1
	#RewriteRule ^(.*)$ http://www.$1$1 [R=301,L]

        <Directory /var/www/vhosts/$1>
                Options -Indexes +FollowSymLinks -MultiViews
                AllowOverride All
		Order deny,allow
		Allow from all
        </Directory>"
if [[ "$DISTRO" == "Debian" ]]; then
	DATA=$DATA"
        CustomLog /var/log/apache2/$1-access.log combined
        ErrorLog /var/log/apache2/$1-error.log"
elif [[ "$DISTRO" == "Redhat" ]]; then
	DATA=$DATA"
        CustomLog /var/log/httpd/$1-access.log combined
        ErrorLog /var/log/httpd/$1-error.log"
fi
DATA=$DATA"
        # New Relic PHP override
        <IfModule php5_module>
               php_value newrelic.appname "$1"
        </IfModule>
        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn
</VirtualHost>


##
# To install the SSL certificate, please place the certificates in the following files:
# >> SSLCertificateFile    /etc/pki/tls/certs/$1.crt
# >> SSLCertificateKeyFile    /etc/pki/tls/private/$1.key
# >> SSLCACertificateFile    /etc/pki/tls/certs/$1.ca.crt
#
# After these files have been created, and ONLY AFTER, then run this and restart Apache:
#
# To remove these comments and use the virtual host, use the following:
# VI   -  :39,$ s/^#//g
# RedHat Bash -  sed -i '39,$ s/^#//g' /etc/httpd/vhost.d/$1.conf && service httpd reload
# Debian Bash -  sed -i '39,$ s/^#//g' /etc/apache2/sites-available/$1 && service apache2 reload
##

#<VirtualHost _default_:443>
#        ServerName $1
#        ServerAlias www.$1
#        DocumentRoot /var/www/vhosts/$1
#        <Directory /var/www/vhosts/$1>
#                Options -Indexes +FollowSymLinks -MultiViews
#                AllowOverride All
#        </Directory>
#"
if [[ "$DISTRO" == "Debian" ]]; then
        DATA=$DATA"
#        CustomLog /var/log/apache2/$1-ssl-access.log combined
#        ErrorLog /var/log/apache2/$1-ssl-error.log"
elif [[ "$DISTRO" == "Redhat" ]]; then
        DATA=$DATA"
#        CustomLog /var/log/httpd/$1-ssl-access.log combined
#        ErrorLog /var/log/httpd/$1-ssl-error.log"
fi
DATA=$DATA"
#
#        # Possible values include: debug, info, notice, warn, error, crit,
#        # alert, emerg.
#        LogLevel warn
#
#        SSLEngine on"
if [[ "$DISTRO" == "Debian" ]]; then
        DATA=$DATA"
#        SSLCertificateFile    /etc/ssl/certs/2014-$1.crt
#        SSLCertificateKeyFile /etc/ssl/private/2014-$1.key
#        SSLCACertificateFile /etc/ssl/certs/2014-$1.ca.crt
#"
elif [[ "$DISTRO" == "Redhat" ]]; then
        DATA=$DATA"
#        SSLCertificateFile    /etc/pki/tls/certs/2014-$1.crt
#        SSLCertificateKeyFile /etc/pki/tls/private/2014-$1.key
#        SSLCACertificateFile /etc/pki/tls/certs/2014-$1.ca.crt
#"
fi
DATA=$DATA"
#        <IfModule php5_module>
#                php_value newrelic.appname "$1"
#        </IfModule>
#        <FilesMatch \\\"\.(cgi|shtml|phtml|php)\$\\\">
#                SSLOptions +StdEnvVars
#        </FilesMatch>
#
#        BrowserMatch \\\"MSIE [2-6]\\\" \\
#                nokeepalive ssl-unclean-shutdown \\
#                downgrade-1.0 force-response-1.0
#        BrowserMatch \\\"MSIE [17-9]\\\" ssl-unclean-shutdown
#</VirtualHost>"


if [[ "$DISTRO" == "Redhat" ]]; then
	# Check for vhost directory in /etc/httpd
	if [ ! -d /etc/httpd/vhost.d  ]; then
		mkdir /etc/httpd/vhost.d &&
		echo "Include vhost.d/*.conf" >> /etc/httpd/conf/httpd.conf
	fi
	if [ -f /etc/httpd/vhost.d/$1.conf ]; then
		echo "This virtual host already exists on this system."
		echo "Please remove the virtual host configuration file."
		exit 1
	fi
	echo "$DATA" > /etc/httpd/vhost.d/$1.conf && 
	mkdir -p /var/www/vhosts/$1 
	#chown apache:apache /var/www/vhosts/$1 && 
	#chmod 2775 /var/www/vhosts/$1

elif [[ "$DISTRO" == "Debian" ]]; then
        if [ -f /etc/apache2/sites-available/$1 ]; then
                echo "This virtual host already exists on this system."
                echo "Please remove the virtual host configuration file."
                exit 1
        fi
	echo "$DATA" > /etc/apache2/sites-available/$1 && 
	mkdir -p /var/www/vhosts/$1 
	#chown www-data:www-data /var/www/vhosts/$1 && 
	#chmod 2775 /var/www/vhosts/$1 &&
	ln -s /etc/apache2/sites-available/$1 /etc/apache2/sites-enabled/$1
fi

echo "********************"
echo ">> Server Name : $1"
echo ">> Server Alias: www.$1"
echo ">> Document Root: /var/www/vhosts/$1"
echo "********************"
