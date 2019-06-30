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
    WD=$(pwd) &&
    cd ../vendor/codeigniter/framework &&
    rm -rf ./application/ ./composer.json ./user_guide ./index.php
}

successAndIntalledMessage() {
    clear && echo "success to install $1 will be install $2" && sleep 1 && clear
}
installComposer() {
    curl -sS https://getcomposer.org/installer -o composer-setup.php &&
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php
}
installCodeigniter() {
    composer create-project kenjis/codeigniter-composer-installer fw &&
    cd $(pwd)/fw &&
    composer require vlucas/phpdotenv &&
    cd ../ &&
    moveFiles &&
    removeVendorFile &&
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
            location /phpmyadmin {
                root /usr/share/;
                index index.php index.html index.htm;
                location ~ ^/phpmyadmin/(.+\.php)$ {
                        try_files \$uri =404;
                        root /usr/share/;
                        fastcgi_pass unix:/run/php/php7.3-fpm.sock;
                        fastcgi_index index.php;
                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                        include /etc/nginx/fastcgi_params;
                    }
                    location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
                        try_files \$uri =404;
                    }
            }
            location /phpMyAdmin {  
                rewrite ^/* /phpmyadmin last;
            }
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

        # if [ ! -d "$NGINX_ROOT_PATH" ]; then
        #     mkdir -p $NGINX_ROOT_PATH
        # fi;

    fi && nginxConfigSetting && 
    

    ##################################
    ########## install php ###########
    ##################################

    if ! packageExists php; then
        installPackage php7.3 && installPackage php7.3-fpm
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
    export COMPOSER_ALLOW_SUPERUSER=1 && cd $NGINX_ROOT_PATH && rm ./*.html && php --ini && installCodeigniter
    
    
    ##################################
    ########## install pma ###########
    ##################################
    
    
    # if ! packageExists phpmyadmin; then
    #     installPackage install phpmyadmin
    # fi &&
    
    
#     cd ~ &&
#     if ! packageExists unzip; then
#         apt-get -y install unzip && 
#         wget https://github.com/bcit-ci/CodeIgniter/archive/3.1.9.zip && unzip 3.1.9.zip
#     fi && echo "update and upgrade Server!" &&
#     apt-get -y update && clear && echo "finish update repository and will be upgrade server" && sleep 1 &&
#     apt-get -y upgrade && clear && echo "finish upgrade packages and will be dist upgrade" && sleep 1 &&
#     apt-get -y dist-upgrade && clear && echo "finish dist upgrade and wiil be install remove "
#     apt-get -y autoremove && clear && echo "finish update server and will be install ssh" && sleep 1
#     if ! packageExists openssh-server; then
#         apt-get -y install openssh-server && cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak &&
#         sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config &&
#         service ssh restart
#     fi && clear && echo "Success install ssh and Setting and will be setting and install ftp" && sleep 1 &&
#     if ! packageExists vsftpd; then
#         apt-get -y install vsftpd && cp /etc/vsftpd.conf /etc/vsftpd.conf.bak &&
#         sed -i 's/#local_umask=022/local_umask=022/g' /etc/vsftpd.conf &&
#         sed -i 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd.conf &&
#         sed -i 's/#chroot_list_enable=YES/chroot_list_enable=YES/g' /etc/vsftpd.conf &&
#         sed -i 's/#chroot_list_file=\/etc\/vsftpd.chroot_list/chroot_list_file=\/etc\/vsftpd.chroot_list/g' /etc/vsftpd.conf &&
#         sed -i 's/#local_umask=022/local_umask=022/g' /etc/vsftpd.conf &&
#         sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf &&
#         sed -i 's/pam_service_name=vsftpd/pam_service_name=ftp/g' /etc/vsftpd.conf &&
#         echo "root" > /etc/vsftpd.chroot_list && service vsftpd restart
#     fi && clear && echo "finish install and setting vsftpd and will be install nginx and setting" && sleep 1 &&
#     if ! packageExists nginx; then
#         DIRECTORY="/var/www/html" &&
#         apt-get -y install nginx &&
#         if [ ! -d "$DIRECTORY" ]; then
#             mkdir -p $DIRECTORY
#         fi;
#     fi && 
#     if ! packageExists mariadb-server; then
#         apt-get -y install mariadb-server mariadb-client && clear && echo "finish install db server and install php!"
#     fi && sleep 1 &&
#     apt-get -y update && apt-get -y install php php-fpm php-curl && cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.bak
#     sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php/7.0/fpm/php.ini &&
#     if [ ! -e $DIRECTORY/phpmyadmin ]; then
#         ln -s /usr/share/phpmyadmin $DIRECTORY
#     fi && service php7.0-fpm restart &&
#     mv $DIRECTORY/index.nginx-debian.html index.php && cp -r ~/CodeIgniter-3.1.9/* /var/www/html && rm -r 3.1.9.zip CodeIgniter-3.1.9 &&
#     cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak &&
#     echo "server {
#         listen 80 default_server;
#         listen [::]:80 default_server;
#         root /var/www/html;
#         index index.php index.html index.htm index.nginx-debian.html;
#         server_name server_domain_or_IP;
#         location /phpmyadmin {
#                root /usr/share/;
#                index index.php index.html index.htm;
#                location ~ ^/phpmyadmin/(.+\.php)$ {
#                        try_files \$uri =404;
#                        root /usr/share/;
#                        fastcgi_pass unix:/run/php/php7.3-fpm.sock;
#                        fastcgi_index index.php;
#                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
#                        include /etc/nginx/fastcgi_params;
#                 }
#                 location ~* ^/phpmyadmin/(.+\.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt))$ {
#                     try_files \$uri =404;
#                 }
#         }
#         location /phpMyAdmin {
#                rewrite ^/* /phpmyadmin last;
#         }
#        if (!-e \$request_filename) {
#             rewrite ^/(.*)$ /index.php?/\$1 last;
#             break;
#         }
#         location / {
#             try_files \$uri \$uri/ =404;
#         }

#         location ~ \.php$ {
#             include snippets/fastcgi-php.conf;
#             fastcgi_pass unix:/run/php/php7.3-fpm.sock;
#         }
#         location ~ /\.ht {
#             deny all;
#         }
#     }
# " > /etc/nginx/sites-available/default &&
# apt-get -y install phpmyadmin

# fi && reboot
fi