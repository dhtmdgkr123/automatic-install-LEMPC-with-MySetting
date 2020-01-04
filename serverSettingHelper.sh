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
installComposer() {
    curl -sS https://getcomposer.org/installer -o composer-setup.php &&
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php
}
installCodeigniter() {
    cd /var &&
    composer create-project dhtmdgkr123/codeigniter-custom:dev-master www
}

nginxConfigSetting() {
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak &&
    echo "server {
            listen 80 default_server;
            listen [::]:80 default_server;
            root /var/www/public;
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
                fastcgi_pass unix:/run/php/php7.4-fpm.sock;
            }
            location ~ /\.ht {
                deny all;
            }
        }
    " > /etc/nginx/sites-available/default
}

installPhp() {
    installPackage php7.4 &&
    installPackage php7.4-fpm &&
    installPackage php7.4-mysqli &&
    installPackage php7.4-pdo &&
    installPackage php7.4-mbstring &&
    installPackage php7.4-intl
}

installRedis() {
    if ! packageExists redis-server; then
        installPackage redis-server
    fi &&

    if ! packageExists php-redis; then
        installPackage php-redis
    fi &&
    
    service php7.4-fpm restart
}

installPma() {
    cd ~ &&
    wget https://files.phpmyadmin.net/phpMyAdmin/5.0.0/phpMyAdmin-5.0.0-all-languages.zip &&
    unzip phpMyAdmin-5.0.0-all-languages.zip &&
    mv ./phpMyAdmin-5.0.0-all-languages/ /var/www/public/pma &&
    rm -rf ./phpMyAdmin-5.0.0-all-languages.zip
}
clearDpkg() {
    rm /var/lib/apt/lists/lock &&
    rm /var/cache/apt/archives/lock &&
    rm /var/lib/dpkg/lock* &&
    dpkg --configure -a
}
setMySQLRootPassword() {
    while : ; do
        read -s -p "Enter MySQL Root Password: " firstPassword
        printf "\n"
        read -s -p "Retry Enter MySQL Password: " secondPassword
        printf "\n"
        if [[ "$firstPassword" == "$secondPassword" ]]; then
            break;
        else
            echo "Password is not match. Re Enter MySQL Root Password"
        fi;
    done;
    
    mysql -u root -e "UPDATE user SET plugin='mysql_native_password' WHERE User='root'" mysql &&
    mysql -u root -e "FLUSH PRIVILEGES" mysql &&
    mysql -u root -e "SET PASSWORD FOR root@'localhost' = Password('${firstPassword}')" mysql
}

clear && 
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
else
    cd ~ &&
    add-apt-repository ppa:ondrej/php -y 2>&1 
    
    ##################################
    ##### update & upgrade server ####
    ##################################
    
    apt-get -y update &&
    clearDpkg &&
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
        installPackage nginx
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
    php --ini &&
    rm -rf /var/www &&
    installCodeigniter &&
    installRedis &&
    
    ##################################
    ########## install pma ###########
    ##################################
    installPma &&

    ##################################
    ####### Set MySQL Password #######
    ##################################
    setMySQLRootPassword &&

    ##################################
    ######### Apt Auto remove ########
    ##################################
    apt-get -y autoremove
    clear &&
    echo "Finish Initialize Server"
    
fi