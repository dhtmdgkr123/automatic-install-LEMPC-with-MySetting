#!/bin/bash
function packageExists() {
    return dpkg -l "$1" &> /dev/null
}
clear &&
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
else
    cd ~ && mkdir CodeIgniter
    echo "update and upgrade Server!" &&
    apt-get -y update &&
    apt-get -y upgrade &&
    apt-get -y dist-upgrade &&
    apt-get -y autoremove && clear && echo "finish update server install ssh" && sleep 1
    if ! packageExists openssh-server; then
        apt-get -y install openssh-server &&
        sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config &&
        service ssh restart
    fi && clear && echo "Success install ssh and Setting and will be setting and install ftp" && sleep 1 &&
    if ! packageExists vsftpd; then
        apt-get -y install vsftpd && cp /etc/vsftpd.conf /etc/vsftpd.conf.bak &&
        sed -i 's/#local_umask=022/local_umask=022/g' /etc/vsftpd.conf &&
        sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd.conf &&
        sed -i 's/#chroot_list_enable=YES/chroot_list_enable=YES/g' /etc/vsftpd.conf &&
        sed -i 's/#chroot_list_file=\/etc\/vsftpd.chroot_list/chroot_list_file=\/etc\/vsftpd.chroot_list/g' /etc/vsftpd.conf &&
        sed -i 's/#local_umask=022/local_umask=022/g' /etc/vsftpd.conf &&
        sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf &&
        sed -i 's/pam_service_name=vsftpd/pam_service_name=ftp/g' /etc/vsftpd.conf &&
        echo "root" > /etc/vsftpd.chroot_list && service vsftpd restart
    fi && clear && echo "finish install and setting vsftpd and will be install nginx and setting" && sleep 1 &&
    if !packageExists nginx; then
        DIRECTORY="/var/www/html" &&
        apt-get -y install nginx &&
        if [ ! -d "$DIRECTORY" ]; then
            mkdir -p $DIRECTORY
        fi;
    fi && cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak &&
    echo "server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;

        server_name server_domain_or_IP;

    	if (!-e \$request_filename) {
            rewrite ^/(.*)$ /index.php?/\$1 last;
            break;
        }

        location / {
            try_files \$uri \$uri/ =404;
        }

        location /phpmyadmin {
               root /usr/share/;
               index index.php index.html index.htm;
               location ~ ^/phpmyadmin/(.+\.php)$ {
                       try_files \$uri =404;
                       root /usr/share/;
                       fastcgi_pass unix:/run/php/php7.0-fpm.sock;
                       fastcgi_index index.php;
                       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                       include /etc/nginx/fastcgi_params;
                }
                location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
                    root /usr/share/;
                }
        }
        location /phpMyAdmin {
               rewrite ^/* /phpmyadmin last;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }
" > /etc/nginx/sites-available/default &&
    apt-get -y install mariadb-server mariadb-client && clear && echo "finish install db server" && sleep 1 &&
    apt-get -y update && apt-get -y install php php-fpm php-curl &&
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.0/fpm/php.ini && service php7.0-fpm restart &&
    mv index.nginx-debian.html index.php && echo "<?php phpinfo();?>" > index.php &&
    apt-get -y install phpmyadmin unzip && wget https://github.com/bcit-ci/CodeIgniter/archive/3.1.9.zip &&
    unzip 3.1.9.zip &&
    cp -r CodeIgniter-3.1.9/* /var/www/html &&
    rm -rf CodeIgniter-3.1.9 3.1.9.zip
fi && reboot
