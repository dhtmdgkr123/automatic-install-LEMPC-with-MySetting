#!/bin/bash
packageExists() {
    return dpkg -l "$1" &> /dev/null
}

sshRootSetting() {
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak &&
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config &&
    service ssh restart
}

vsftpdRootSetting() {
    cp /etc/vsftpd.conf /etc/vsftpd.conf.bak &&
    sed -i 's/#local_umask=022/local_umask=022/g' /etc/vsftpd.conf &&
    sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd.conf &&
    sed -i 's/#chroot_list_enable=YES/chroot_list_enable=YES/g' /etc/vsftpd.conf &&
    sed -i 's/#chroot_list_file=\/etc\/vsftpd.chroot_list/chroot_list_file=\/etc\/vsftpd.chroot_list/g' /etc/vsftpd.conf &&
    sed -i 's/#local_umask=022/local_umask=022/g' /etc/vsftpd.conf &&
    sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf &&
    sed -i 's/pam_service_name=vsftpd/pam_service_name=ftp/g' /etc/vsftpd.conf &&
    echo "root" > /etc/vsftpd.chroot_list && service vsftpd restart
}

installPackage() {
    apt-get -y install "$1"
}

checkDir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

moveFiles() {
    mv ./fw/application/ ./fw/bin/ ./fw/vendor/ ./fw/composer.json ./fw/composer.lock ./fw/README.md  ../ &&
    mv ./fw/public/index.php ./fw/public/.htaccess ./ &&
    rm -rf /var/www/html/fw
}


removeVendorFile() {
    cd ../vendor/codeigniter/framework &&
    rm -rf ./application/ ./composer.json ./user_guide ./index.php
}

overWriteFile() {
    curl https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/refector/index.php > ./index.php &&
    curl https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/refector/codeigniter.php > ../vendor/codeigniter/framework/system/core/CodeIgniter.php
}

successAndIntalledMessage() {
    clear && echo "success to install $1 will be install $2" && sleep 1 && clear
}
installComposer() {
    curl -sS https://getcomposer.org/installer -o composer-setup.php &&
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php
}
installCodeigniter() {
    NOW=$(pwd) &&
    composer create-project kenjis/codeigniter-composer-installer fw &&
    cd "$NOW"/fw &&
    composer require vlucas/phpdotenv &&
    cd "$NOW" &&
    moveFiles &&
    removeVendorFile &&
    cd "$NOW" && overWriteFile
    service nginx restart
}

nginxConfigSetting() {
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak &&
    echo "server {
            listen 80 default_server;
            listen [::]:80 default_server;
            root /var/www/html;
            index index.php;
            server_name server_domain_or_IP;
            if (!-e \$request_filename) {
                rewrite ^/(.*)$ /index.php?/\$1 last;
                break;
            }
            location / {
                try_files \$uri \$uri/ =404;
            }
            location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.3-fpm.sock;
            }
            location ~ /\.ht {
                deny all;
            }
        }
    " > /etc/nginx/sites-available/default
}

installPhp() {
    installPackage php7.3 &&
    installPackage php7.3-fpm &&
    installPackage php7.3-mysqli &&
    installPackage php7.3-pdo
}

installRedis() {
    if ! packageExists redis-server; then
        installPackage redis-server
    fi &&

    if ! packageExists php-redis; then
        installPackage php-redis
    fi &&
    
    service php7.3-fpm restart
}

installPma() {
    cd ~ &&
    wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.zip &&
    unzip phpMyAdmin-4.9.0.1-all-languages.zip &&
    mv ./phpMyAdmin-4.9.0.1-all-languages/ /var/www/html/pma &&
    rm -rf ./phpMyAdmin-4.9.0.1-all-languages.zip
}

clear && 
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
else
    cd ~ &&
    NGINX_ROOT_PATH="/var/www/html" &&
    add-apt-repository ppa:ondrej/php -y 2>&1 
    
    ##################################
    ##### update & upgrade server ####
    ##################################
    
    apt-get -y update &&
    apt-get -y upgrade &&
    
    ##################################
    ########## install gcc ###########
    ##################################
    if ! packageExists gcc; then
        installPackage gcc;
    fi &&

    ##################################
    ########## install make ##########
    ##################################
    if ! packageExists make; then
        installPackage make
    fi &&
    
    ##################################
    ########## install zip ###########
    ##################################
    if ! packageExists unzip; then
        installPackage unzip
    fi &&
    
    ##################################
    ######### install unzip ##########
    ##################################
    if ! packageExists zip; then
        installPackage zip
    fi &&
    
    ##################################
    ####### install ssh server #######
    ##################################

    if ! packageExists openssh-server; then
        installPackage openssh-server
    fi && sshRootSetting &&
    
    ##################################
    ####### install ftpServer ########
    ##################################

    if ! packageExists vsftpd; then
        installPackage vsftpd
    fi && vsftpdRootSetting &&
    
    ##################################
    ########## install nginx #########
    ##################################

    if ! packageExists nginx; then
        installPackage nginx &&
        checkDir $NGINX_ROOT_PATH
    fi && nginxConfigSetting && 
    

    ##################################
    ########## install php ###########
    ##################################

    if ! packageExists php; then
        installPhp
    fi &&
    
    ##################################
    ######## install maria-db ########
    ##################################
    if ! packageExists mariadb-server; then
        installPackage mariadb-server mariadb-client
    fi &&
    
    ##################################
    ######## install composer ########
    ##################################
    if ! packageExists composer; then
        installComposer
    fi &&
    
    ##################################
    ######## install CI, REDIS #######
    ##################################
    export COMPOSER_ALLOW_SUPERUSER=1 &&
    cd $NGINX_ROOT_PATH &&
    rm ./*.html &&
    php --ini &&
    installCodeigniter &&
    installRedis &&
    
    ##################################
    ########## install pma ###########
    ##################################
    installPma
    
fi