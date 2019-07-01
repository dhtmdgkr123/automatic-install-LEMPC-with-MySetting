server Setting Script base on bash and ubuntu16.04 LTS
=

Feature
=
+ Automatic install Nginx <br />
+ Automatic install MariaDb <br />
+ Automatic install php 7.3, Codeigniter, dotenv using Composer<br />
+ Automatic install PhpMyAdmin<br />
+ Automatic install ssh server with root acces setting<br />
+ Automatic install vsftpd with root access and umask 022<br />

Usage
=
`
$curl -S https://raw.githubusercontent.com/dhtmdgkr123/automatic-install-LEMPC-with-MySetting/master/serverSettingHelper.sh | sudo bash
`
### Warning! after finish to setting your server will be reboot and this script download package!! please use only develper server!

<h2>Change Log</h2>

>><h4>Version 1.0.0.0</h5>

>>1. Install Nginx<br />
>>1. Install MariaDb<br />
>>1. Install php7 php Curl, php fpm<br />
>>1. Install PhpMyAdmin<br />
>>1. Install ssh server<br />
>>1. Install vsftpd<br />

>><h4>Version 1.0.0.1</h4>
>>1. fix SyntaxBug<br />

>><h4>Version 1.0.0.2</h4>
>>1. fix SyntaxBug<br />

>><h4>Version 1.0.0.3</h4>
>>1. fix pathError<br />

>><h4>Version 1.0.1.0</h4>
>>1. use packageExists all of package with out php<br />

>><h4>Version 1.0.1.1</h4>
>>1. fix phpmyadmin 404 error bug<br />

>><h4>Version 1.0.1.2</h4>
>>1. add stable Code<br />

>><h4>Version 1.0.1.3</h4>
>>1. remove Codeigniterfolder variable and edit unzip pacakge error<br />

>><h4>Version 1.0.1.4</h4>
>>1. fix SyntaxBug<br />

>><h4>Version 1.0.1.5</h4>
>>1. edit /etc/nginx/sites-available/default and edit some logic<br />

>><h4>Version 1.1.0</h4>
>>1. Upgrade php 7.3<br />
>>2. Install Coposer<br />
>>3. Install Codeigniter<br />
>>4. Install Dotenv<br />


License
-
GPL-3.0 Copyright (c) osh12201@gmail.com


<h2>Contact : osh12201@gmail.com</h2>   
