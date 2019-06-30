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

overWriteFile() {
    CURR_LOCATE=$1 &&
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
    cd $NOW/fw &&
    composer require vlucas/phpdotenv &&
    cd $NOW &&
    moveFiles &&
    removeVendorFile &&
    cd $NOW && overWriteFile $NOW
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

installRedis() {
    cd ~ &&
    wget http://download.redis.io/redis-stable.tar.gz &&
    tar xvzf redis-stable.tar.gz &&
    cd redis-stable &&
    make distclean &&
    make &&
    sudo make install &&


    SCRIPT=$(readlink -f $0)
    SCRIPTPATH=$(dirname $SCRIPT)

    REDIS_PORT=6379
    REDIS_CONFIG_FILE="/etc/redis/$REDIS_PORT.conf"
    REDIS_LOG_FILE="/var/log/redis_$REDIS_PORT.log"
    REDIS_DATA_DIR="/var/lib/redis/$REDIS_PORT"
    REDIS_EXECUTABLE=`command -v redis-server`
    CLI_EXEC=`dirname $REDIS_EXECUTABLE`"/redis-cli"
    mkdir -p `dirname "$REDIS_CONFIG_FILE"`
    mkdir -p `dirname "$REDIS_LOG_FILE"`
    mkdir -p "$REDIS_DATA_DIR"


    TMP_FILE="/tmp/${REDIS_PORT}.conf"
    DEFAULT_CONFIG="${SCRIPTPATH}/../redis.conf"
    INIT_TPL_FILE="${SCRIPTPATH}/redis_init_script.tpl"
    INIT_SCRIPT_DEST="/etc/init.d/redis_${REDIS_PORT}"
    PIDFILE="/var/run/redis_${REDIS_PORT}.pid"
    
read -r SED_EXPR <<-EOF
s#^port .\+#port ${REDIS_PORT}#; \
s#^logfile .\+#logfile ${REDIS_LOG_FILE}#; \
s#^dir .\+#dir ${REDIS_DATA_DIR}#; \
s#^pidfile .\+#pidfile ${PIDFILE}#; \
s#^daemonize no#daemonize yes#;
EOF
sed "$SED_EXPR" $DEFAULT_CONFIG >> $TMP_FILE
cp $TMP_FILE $REDIS_CONFIG_FILE
rm -f $TMP_FILE

    REDIS_INIT_HEADER=\
    "#!/bin/sh\n
    #Configurations injected by install_server below....\n\n
    EXEC=$REDIS_EXECUTABLE\n
    CLIEXEC=$CLI_EXEC\n
    PIDFILE=\"$PIDFILE\"\n
    CONF=\"$REDIS_CONFIG_FILE\"\n\n
    REDISPORT=\"$REDIS_PORT\"\n\n
    ###############\n\n"

    REDIS_CHKCONFIG_INFO=\
    "# REDHAT chkconfig header\n\n
    # chkconfig: - 58 74\n
    # description: redis_${REDIS_PORT} is the redis daemon.\n
    ### BEGIN INIT INFO\n
    # Provides: redis_6379\n
    # Required-Start: \$network \$local_fs \$remote_fs\n
    # Required-Stop: \$network \$local_fs \$remote_fs\n
    # Default-Start: 2 3 4 5\n
    # Default-Stop: 0 1 6\n
    # Should-Start: \$syslog \$named\n
    # Should-Stop: \$syslog \$named\n
    # Short-Description: start and stop redis_${REDIS_PORT}\n
    # Description: Redis daemon\n
    ### END INIT INFO\n\n"

    if command -v chkconfig >/dev/null; then
        echo "$REDIS_INIT_HEADER" "$REDIS_CHKCONFIG_INFO" > $TMP_FILE && cat $INIT_TPL_FILE >> $TMP_FILE || die "Could not write init script to $TMP_FILE"
    else
        echo "$REDIS_INIT_HEADER" > $TMP_FILE && cat $INIT_TPL_FILE >> $TMP_FILE || die "Could not write init script to $TMP_FILE"
    fi

cat > ${TMP_FILE} <<EOT
#!/bin/sh
#Configurations injected by install_server below....

EXEC=$REDIS_EXECUTABLE
CLIEXEC=$CLI_EXEC
PIDFILE=$PIDFILE
CONF="$REDIS_CONFIG_FILE"
REDISPORT="$REDIS_PORT"
###############
# SysV Init Information
# chkconfig: - 58 74
# description: redis_${REDIS_PORT} is the redis daemon.
### BEGIN INIT INFO
# Provides: redis_${REDIS_PORT}
# Required-Start: \$network \$local_fs \$remote_fs
# Required-Stop: \$network \$local_fs \$remote_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Should-Start: \$syslog \$named
# Should-Stop: \$syslog \$named
# Short-Description: start and stop redis_${REDIS_PORT}
# Description: Redis daemon
### END INIT INFO

EOT
    cat ${INIT_TPL_FILE} >> ${TMP_FILE}

    cp $TMP_FILE $INIT_SCRIPT_DEST && chmod +x $INIT_SCRIPT_DEST


    if command -v chkconfig >/dev/null 2>&1; then
        chkconfig --add redis_${REDIS_PORT}
        chkconfig --level 345 redis_${REDIS_PORT} on
    elif command -v update-rc.d >/dev/null 2>&1; then
        update-rc.d redis_${REDIS_PORT} defaults


    /etc/init.d/redis_$REDIS_PORT start

    cd ~ &&
    rm -rf redis-stable redis-stable.tar.gz &&
    cd $1
    if ! packageExists php-redis; then
        installPackage php-redis
    fi &&



    service php7.3-fpm restart
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

    ##################################
    ######## install CI, REDIS #######
    ##################################
    export COMPOSER_ALLOW_SUPERUSER=1 &&
    cd $NGINX_ROOT_PATH &&
    rm ./*.html &&
    php --ini &&
    installCodeigniter &&
    installRedis $NGINX_ROOT_PATH
    
    
    ##################################
    ########## install pma ###########
    ##################################
    
    # if ! packageExists phpmyadmin; then
    #     installPackage install phpmyadmin
    # fi &&
    
fi