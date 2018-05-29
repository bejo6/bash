#!/bin/bash
MYSELF=$0
DOMAIN=$1
CMS=$2
ARGC=$#

function apache_conf
{
FILE="/etc/httpd/vhost/$2.conf"

cat >> "$FILE" <<- EOM
<VirtualHost *:8080>
    ServerAdmin webmaster@$1
    DocumentRoot "/var/www/$2"
    ServerName $1
    $3

    ErrorLog "|/usr/sbin/rotatelogs -l /var/log/httpd/$2_error_log_%Y_%m_%d 10M"
    CustomLog "|/usr/sbin/rotatelogs -l /var/log/httpd/$2_access_log_%Y_%m_%d 10M" common
    <FilesMatch \\.php$>
        SetHandler "proxy:fcgi://127.0.0.1:9000" 
    </FilesMatch>
    
    <Directory "/var/www/$2">
        DirectoryIndex index.php
        Options -Indexes +FollowSymLinks +MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
    </Directory>
    
    AccessFileName .htaccess
    <Files ~ "^\\.ht">
        Order allow,deny
        Deny from all
        Satisfy All
    </Files>
</VirtualHost>

EOM

}
function nginx_conf
{
FILE="/etc/nginx/vhost/web.conf"

cat >> "$FILE" <<- EOM
######################################################
#----------------------------------------------------#
upstream  $1 {
    server    127.0.0.1:8080;
}

server {

    listen 80;

    server_name $1 $2;

    location / {

        # needed to forward user's IP address to rails
        proxy_redirect      off;
        proxy_set_header    Host             \$host;
        proxy_set_header    X-Real-IP        \$remote_addr;
        proxy_set_header    X-Forwarded-For  \$proxy_add_x_forwarded_for;
        proxy_pass http://$1;

        fastcgi_connect_timeout              60;
        fastcgi_send_timeout                180;
        fastcgi_read_timeout                180;
        fastcgi_buffer_size                128k;
        fastcgi_buffers                  4 256k;
        fastcgi_busy_buffers_size          256k;
        fastcgi_temp_file_write_size       256k;
        fastcgi_intercept_errors             on;

        client_max_body_size               200m;
        client_body_buffer_size            256k;

        proxy_connect_timeout                90;
        proxy_send_timeout                   90;
        proxy_read_timeout                   90;

        # limit
        # limit_req zone=one burst=5 nodelay;
    } 
    #end location
    
    location /server_status {
        stub_status on;
    }
} 
#end server
######################################################



EOM

}

function restart_service
{
  systemctl restart php-fpm.service;
  systemctl restart httpd.service;
  systemctl restart nginx.service;
}
function create_dir
{
  DIR="/var/www/$1"
  if [ ! -d "$DIR" ]; then
    mkdir -p "$DIR"
    chown -R "apache.apache" "$DIR"
    chcon -R -t httpd_sys_content_rw_t "$DIR"
  fi
}
function header
{
  printf "#########################################################################\\n"
  printf "Domain and Type CMS Required!!                                           \\n"
  printf "Example : sh %s domain.ltd itunes or ./%s domain.ltd itunes              \\n" "$MYSELF" "$MYSELF"
  printf "#########################################################################\\n"
  exit;
}
if [ "$ARGC" -lt 2 ];
then
  header
fi

if [ "$ARGC" -eq 2 ];
then
  printf "Writing apache config for domain '%s' with CMS '%s'\\n" "$DOMAIN" "$CMS"
  apache_conf "$DOMAIN" "$CMS"
  printf "Writing nginx config for domain '%s' with CMS '%s'\\n" "$DOMAIN" "$CMS"
  nginx_conf "$DOMAIN" "$CMS"
fi


if [ "$ARGC" -eq 3 ];
then
  printf "Writing apache config for domain '%s' with CMS '%s'\\n" "$DOMAIN" "$CMS"
  apache_conf "$DOMAIN" "$CMS" "ServerAlias www.$DOMAIN"
  printf "Writing nginx config for domain '%s' with CMS '%s'\\n" "$DOMAIN" "$CMS"
  nginx_conf "$DOMAIN" "www.$DOMAIN"
fi

create_dir "$CMS"
restart_service
