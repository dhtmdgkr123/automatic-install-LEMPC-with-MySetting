#!/bin/bash
packageExists() {
    return dpkg -l "$1" &> /dev/null
}

yesOrNo() {
    echo "$(whiptail --title "$2" --yesno "$1" 20 78 3>&1 1>&2 2>&3; echo $?)"
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
function isUrl() {
    urlRegex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    [[ $1 =~ $urlRegex ]];
    return
}
function isIp() {
    ipRegex='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
    [[ $1 =~ $ipRegex ]];
    return
}
function validAddress() {
    urlRegex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    ipRegex='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
    [[ $1 =~ $urlRegex || $1 =~ $ipRegex ]];
    return
}

function isEmail() {
    emailRegex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    [[ $1 =~ $emailRegex ]];
    return;
}

installComposer() {
    curl -sS https://getcomposer.org/installer -o composer-setup.php &&
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && rm composer-setup.php
}

installCodeigniter() {
    cd /var &&
    composer create-project --remove-vcs dhtmdgkr123/codeigniter-custom:dev-master www
}

nginxHeaderSetting() {
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak &&
    echo "$(curl https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/master/NginxHeader.conf)" > /etc/nginx/nginx.conf
}

nginxConfigSetting() {
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak &&
    title="Install HTTPS"
    checkSSL="Do You Want to install Https?"
    isUseSSL=$(yesOrNo "$checkSSL" "$title")
    
    if [[ "$isUseSSL" -eq 0 ]]; then
        
        while ! isUrl "$domainName" || [[ -z "$domainName" ]]; do
            domainName=$(whiptail --title "${title}" --inputbox "${inputError}Please enter site domain \nIf You Enter Domain, You must include http:// or https://\nExample: http://www.exam.com" 20 78 3>&1 1>&2 2>&3)
            inputError="Site Domain is Empty or Re enter site domain"
        done;
        inputError=""
        while ! isEmail "$emailAddress" || [[ -z "$emailAddress" ]]; do
            emailAddress=$(whiptail --title "${title}" --inputbox "${inputError}Please enter Your Email Address" 20 78 3>&1 1>&2 2>&3)
            inputError="Email is Empty or Invalid Email"
        done;

        domainName="$(echo $domainName | awk -F[/:] '{print $4}')"
        tmpConfigUrl="https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/master/NoSSLDefault"
        
        echo "$(echo "$(curl ${tmpConfigUrl})" | sed "s/domainName/${domainName}/g")" > /etc/nginx/sites-available/default
        systemctl restart nginx

        configUrl="https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/master/SSLDefault"
        cronMessage="* 4 * * * /usr/bin/certbot renew --renew-hook=\"systemctl restart nginx\""
        installPackage letsencrypt &&
        letsencrypt certonly --webroot --webroot-path=/var/www/public -d "${domainName}" -m "${emailAddress}"
        crontab -l | { cat; echo "${cronMessage}"; } | crontab -
    else
        while ! validAddress "$domainName" || [[ -z "$domainName" ]]; do
            domainName=$(whiptail --title "${title}" --inputbox "${inputError}Please enter site domain or Ip Address \nIf You Enter Domain, You must include http:// or https://\nExample: http://www.exam.com\nExample : 49.0.33.1" 20 78 3>&1 1>&2 2>&3)
            inputError="Site Domain is Empty or Re enter site domain"
        done;
        configUrl="https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/master/NoSSLDefault"    
    fi;
    if isUrl "$domainName"; then
        domainName="$(echo $domainName | awk -F[/:] '{print $4}')"
    fi;

    echo "$(echo "$(curl ${configUrl})" | sed "s/domainName/${domainName}/g")" > /etc/nginx/sites-available/default
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
    password="1"
    passwordRepeat="2"
    title="MariaDB root Password Setting"
    while [[ "$password" != "$passwordRepeat" || -z "$password" ]]; do
        password=$(whiptail --title "${title}" --passwordbox "${passwordInvalidMessage}Please enter MariaDB password" 20 78 3>&1 1>&2 2>&3)
        passwordRepeat=$(whiptail --title "${title}" --passwordbox "Please repeat the MySQL Password" 20 78 3>&1 1>&2 2>&3)
        passwordInvalidMessage="Password is not match. ReEnter MariaDB Root Password"
    done;
    mysql -u root -e "UPDATE user SET plugin='mysql_native_password' WHERE User='root'" mysql &&
    mysql -u root -e "FLUSH PRIVILEGES" mysql &&
    mysql -u root -e "SET PASSWORD FOR root@'localhost' = Password('${password}')" mysql
}

restartInstalledPackage() {
    systemctl restart nginx.service &&
    systemctl restart php7.4-fpm.service &&
    systemctl restart redis.service &&
    systemctl restart mysql.service &&
    systemctl restart vsftpd.service
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
        installPackage nginx &&
        installPackage nginx-extras
    fi && nginxHeaderSetting
    
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
    ##### install Redis & Predis #####
    ##################################
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
    ##### Set Nginx default host #####
    ##################################
    nginxConfigSetting &&

    ##################################
    ### Restart Installed Service ####
    ##################################
    restartInstalledPackage &&

    ##################################
    ####### install Codeigniter ######
    ##################################
    export COMPOSER_ALLOW_SUPERUSER=1 &&
    php --ini &&
    rm -rf /var/www &&
    installCodeigniter &&

    ##################################
    ######### Add Git ignore #########
    ##################################
    echo -e ".env\n/public/pma/*" >> /var/www/.gitignore &&
    clear &&

    ##################################
    ########## Feature Log ###########
    ##################################
    whiptail --textbox /dev/stdin 40 100 <<< "$(curl https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/master/Feature.txt)" --title "Feature Log" &&
    clear &&
    cat << "EOF"
                       _ _     _                 _       _        __ ___  ____             
                      | | |   | |               | |     | |      /_ |__ \|___ \            
                    __| | |__ | |_ _ __ ___   __| | __ _| | ___ __| |  ) | __) |           
                   / _` | '_ \| __| '_ ` _ \ / _` |/ _` | |/ / '__| | / / |__ <            
                  | (_| | | | | |_| | | | | | (_| | (_| |   <| |  | |/ /_ ___) |           
                   \__,_|_| |_|\__|_| |_| |_|\__,_|\__, |_|\_\_|  |_|____|____/            
                                                    __/ |                                  
                                                   |___/
              _      ______ __  __ _____   _____    _____           _        _ _           
             | |    |  ____|  \/  |  __ \ / ____|  |_   _|         | |      | | |          
             | |    | |__  | \  / | |__) | |         | |  _ __  ___| |_ __ _| | | ___ _ __ 
             | |    |  __| | |\/| |  ___/| |         | | | '_ \/ __| __/ _` | | |/ _ \ '__|
             | |____| |____| |  | | |    | |____    _| |_| | | \__ \ || (_| | | |  __/ |   
             |______|______|_|  |_|_|     \_____|  |_____|_| |_|___/\__\__,_|_|_|\___|_|   
             
EOF
fi
