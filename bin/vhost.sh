#!/usr/bin/env bash
set -e

RED='\033[0;31m'
NC='\033[0m'
WEBSERVICE_NGINX=1
WEBSERVICE_APACHE=2
MAGENTO_MULTI_STORE=1
MAGENTO_MULTI_WEBSITE=2
TRUE_VALUE=1
FALSE_VALUE=0

# Get web service
printf "
Select web service
    %s - Nginx (default)
    %s - Apache
Enter:" "${WEBSERVICE_NGINX}" "${WEBSERVICE_APACHE}"
read -r webService
until [[ ${webService} -eq ${WEBSERVICE_NGINX} || ${webService} -eq ${WEBSERVICE_APACHE} || ${webService} == '' ]]; do
    printf "
    %sValue invalid!
    %s
    Select web service:
        %s - Nginx (default)
        %s - Apache
    Enter:" "${RED}" "${NC}" "${WEBSERVICE_NGINX}" "${WEBSERVICE_APACHE}"
    read -r webService
done
if [[ "${webService}" == '' ]]; then
    webService=${WEBSERVICE_NGINX}
fi

if [[ ${webService} -eq ${WEBSERVICE_NGINX} ]]; then
    webserviceName='nginx'
else
    webserviceName='apache2'
fi

SSL_FOLDER=/etc/${webserviceName}/ssl
SSL_CRT=/etc/${webserviceName}/ssl/${webserviceName}.crt
SSL_KEY=/etc/${webserviceName}/ssl/${webserviceName}.key

WEBSERVICE_INCLUDE_FOLDER=/etc/${webserviceName}/include
WEBSERVICE_SITE_AVAILABLE=/etc/${webserviceName}/sites-available

MAGENTO_FILE_CONFIG=/etc/${webserviceName}/include/magento.conf
MAGENTO_MULTI_FILE_CONFIG=/etc/${webserviceName}/include/magento_multi.conf

# Check password
printf "Enter password for %s: " "${USER}"
IFS= read -rs password
sudo -k
until sudo -lS &>/dev/null <<EOF; do
${password}
EOF

    printf "
    %sPassword is incorrect!
    %s
    Enter password for %s: " "${RED}" "${NC}" "${USER}"
    IFS= read -rs password
done

# Get server name
printf "\nEnter server name: "
read -r serverName
until [[ ${serverName} != '' ]]; do ## Server name not empty
    printf "
    %sThe server name doesn't empty
    %s
    Enter server name: " "${RED}" "${NC}"
    read -r serverName
done
until [[ ! -f "${WEBSERVICE_SITE_AVAILABLE}/${serverName}.conf" ]]; do ## Server name doesn't exists
    printf "
    %sThe server name already exists
    %s" "${RED}" "${NC}"
    printf 'Enter server name: '
    read -r serverName
done

# Vhost path
VHOST_FILE_NAME="${WEBSERVICE_SITE_AVAILABLE}/${serverName}.conf"

fullServerName="www.${serverName} ${serverName}"

# Add vhost in file hosts
printf "
127.0.0.1   %s" "${serverName}
" | sudo tee -a /etc/hosts >/dev/null

##
# Create ssl crt file
##
createSslCrt() {
    if [[ -f "${SSL_CRT}" ]]; then
        return
    fi

    content=$(
        cat <<EOF
-----BEGIN CERTIFICATE-----
MIIDXTCCAkWgAwIBAgIJANHQr6utM246MA0GCSqGSIb3DQEBCwUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTkwMTA0MTQzNjI0WhcNMjAwMTA0MTQzNjI0WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAwKa7+9PfUeen0y5jdOm2kGttVumcLoWyI10o34HU47ae3wz3S+0lDEPP
elaB5jl9zqSkTxXun0rXC9Obw7zZYJjQXZFmRfaMp461LDH44iIOyFA0VneedGFo
pTCYhdSWvApP/pmwKpIfs9dKsxEFyyftQcoYBe4CQ2JD8uxDAXCb52QHsoYv5HKU
32T6jDdiXqOjRinWdQQQCDge0y9PMrnh9zckvkNIPR3d+m2EmjoDTVhBZGLkZkD3
6b/zmxIego0dC6nivAAilbtXiAqgKb2Q5ECpyh5I1O+tc638gZQR7EMaCGdMbVMh
IczsdXneTPSmQkaJlEvm/5+TqRMR8wIDAQABo1AwTjAdBgNVHQ4EFgQUv4GrErfO
ttk7o3e+DBYy5KYeoA4wHwYDVR0jBBgwFoAUv4GrErfOttk7o3e+DBYy5KYeoA4w
DAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAY0PrqnyH+fi/ioYU073S
fbHaNQp6lyOkLd7YQEWnek8Z49xgiE9+KHnBqIv7klSbo93neOoOD4k/ha7vD5LO
10OeOJI+uRLD5UaatEHyZKPK79edZvUABAKmrVYeWqU5EaKodw/U7oFYbVuGzf1i
5VzXNmXNE3Z3+CwOcQe6HarDUgdnMB/h1uC/t7GkJReHzrdxYUphoHs8uUSDokyp
Ljkjhisx61EXCcZgLWatZ7KDd9CEoqeqz/CufZm3pJn+K5dMh5J2y1gzkZEyxvc7
oOBfL+U3243NCmwGu8viVG+ug13CZrbai5tXvNJsclgITpl4SIl+MkndTEihWkCG
8w==
-----END CERTIFICATE-----

EOF
    ) >/dev/null
    echo "${content}" | sudo tee -a "${SSL_CRT}"
}

##
# Create ssl key file
##
createSslKey() {
    if [[ -f "${SSL_KEY}" ]]; then
        return
    fi

    content=$(
        cat <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDAprv7099R56fT
LmN06baQa21W6ZwuhbIjXSjfgdTjtp7fDPdL7SUMQ896VoHmOX3OpKRPFe6fStcL
05vDvNlgmNBdkWZF9oynjrUsMfjiIg7IUDRWd550YWilMJiF1Ja8Ck/+mbAqkh+z
10qzEQXLJ+1ByhgF7gJDYkPy7EMBcJvnZAeyhi/kcpTfZPqMN2Jeo6NGKdZ1BBAI
OB7TL08yueH3NyS+Q0g9Hd36bYSaOgNNWEFkYuRmQPfpv/ObEh6CjR0LqeK8ACKV
u1eICqApvZDkQKnKHkjU761zrfyBlBHsQxoIZ0xtUyEhzOx1ed5M9KZCRomUS+b/
n5OpExHzAgMBAAECggEAbor90MlJGjFHvkie7wXwKLxLuBRB9vvmNJ6PBnj0FFnE
nY5OFDYWDQyX78XVsaoJg1o7odme265Q6MtaVJ13ShNFdHsq6ThIixi64oomGnOa
cdx7u6XVuUfviOHyktBiUbHFJv0+9Z51LHd7uHYrEeBuJlL1J+njSJEJFkn1RMw+
+kCsmbnkrY7YIA38nq2Qw6Id+fkq3O+vi7MOTx6IyNtxSN2nu2EYfaWaqyDGOvD1
UVO1xJcUml5OVm9bznfbmVzSDQnp5M6z83rk/XPdvbBz4UZhwT05GmMmOZ1VwwGs
CalOKOlb/LPiAhB77fTSG2RgHgOKOHvYlUAopOMGqQKBgQDgIumT8NZUYun39JKN
wVlIUz9oDBzYDTwLJUhL8/BKW6feXEKFwvzuCiz5FjgYEnKSAU/St+5hk3qkWr6x
g9V1oDry8FdglA9ZdgWRMIj8GrhwFLT/DcQ5rC0XJ6usWilTxXzlWC+ubanHQuLF
eGymCd7lDGb2q934vr2dquKbzwKBgQDcCfkFKhCJS1WxuNU9HUCArnD4liSfw+6g
6EiTDLAgv6aRlSYppvh5ZmYnKJMPZAK4r7krtIesUccsK+wa9HyFeejsQrYaqXHD
oP6NOv9EX75Iyyxd+A39G6yWagwUVwv8x3cmernzEOtw9meDr0UHMP5vahcKZtNl
x92ZE1s8nQKBgHFbFtjcb/ljwULHLauFwtriR2oe3iOipeBZLbREHh3tNvwtmvM9
h1/4Q4CCbUI3ajxPb4h5v5UX2mnu/wyWSUnhDI87YGWW3CB5oR0p983Q0cDVqChq
VPh6DJ/uT1OukcItWho/vHWyPrBpMnl+iyx6R4F+AUD18SBRj2KDP3JfAoGAdSK5
9g3Wj8AS9nE20znnRJmYej0zcfmT5wTA3cc7W7OqsIV9s163l6jzaJUo9GCBMmAZ
azLHpuxB4znejtroDwY/AMbiun7JmSLzX6uwiG2PlqDSFZQfnkZFMi1yEMHmF8L3
ovxiUQsIyzHhGTEMxi9Gw3jumxLyJpSnWv366+ECgYALIyjfihulif/zR0Dm7yMr
TyWh3PChrwVox9cCnqVpL0Muo57jJ3NZLrGygZiW3146Wy7+fm0ktxN276GhOfAJ
EK2xByTRVl8PCn2u0pPIpMTtt1EEEN3vh97+hTJzW4DYalv28J4AWFxkBUOknwdX
a7zYvL5GT8wIJc23Y95svA==
-----END PRIVATE KEY-----

EOF
    ) >/dev/null
    echo "${content}" | sudo tee -a "${SSL_KEY}"
}

##
# Create normal vhost file
##
createNormalVhostFile() {
    if [[ ${webService} -eq ${WEBSERVICE_NGINX} ]]; then
        content=$(
            cat <<EOF
server {
        listen 80;
        !HTTPS_LISTEN!

        root !ROOT_FOLDER!;
        index index.html index.htm index.php;

        server_name !SERVER_NAME!;

        #location / {
        #        try_files \$uri \$uri/ =404;
        #}

        location / {
            try_files \$uri \$uri/ /index.php\$is_args\$args;
        }

        # pass PHP scripts to FastCGI server
        #
        location ~ \\.php\$ {
            try_files \$uri =404;
            fastcgi_split_path_info ^(.+\\.php)(/.+)\$;
            fastcgi_pass backend-server;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_param PATH_INFO \$fastcgi_path_info;
        }

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        location ~ /\\.ht {
               deny all;
        }
}

EOF
        )
    else
        content=$(
            cat <<EOF
<VirtualHost *:!HTTPS_LISTEN!>
    DocumentRoot !ROOT_FOLDER!
    ServerName !SERVER_NAME!
    ServerAlias !SERVER_ALIAS!
    SSLEngine !HTTPS_ON!
    SSLCertificateFile ${SSL_CRT}
    SSLCertificateKeyFile ${SSL_KEY}
    ErrorLog "/var/log/apache2/!SERVER_NAME!-error.log"
    CustomLog "/var/log/apache2/!SERVER_NAME!-access.log" common

    <Directory !ROOT_FOLDER!>
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Order allow, deny
        Allow from all
    </Directory>
</VirtualHost>

EOF
        )
    fi

    echo "${content}" | sudo tee -a "${VHOST_FILE_NAME}" >>/dev/null
}

##
# Create magento vhost file
# @param $1 | Server name
##
createMagentoVhostFile() {
    if [[ ${webService} -eq ${WEBSERVICE_NGINX} ]]; then
        content=$(
            cat <<EOF
server {
    listen 80;
    !HTTPS_LISTEN!

    server_name !SERVER_NAME!;

    ssl_certificate ${SSL_CRT};
    ssl_certificate_key ${SSL_KEY};
    set \$MAGE_ROOT !ROOT_FOLDER!;
    
    include ${MAGENTO_FILE_CONFIG};
}

EOF
        )
    else
        content=$(
            cat <<EOF
<VirtualHost *:!HTTPS_LISTEN!>
    DocumentRoot !ROOT_FOLDER!
    ServerName !SERVER_NAME!
    ServerAlias !SERVER_ALIAS!
    SSLEngine !HTTPS_ON!
    SSLCertificateFile ${SSL_CRT}
    SSLCertificateKeyFile ${SSL_KEY}
    ErrorLog "/var/log/apache2/!SERVER_NAME!-error.log"
    CustomLog "/var/log/apache2/!SERVER_NAME!-access.log" common

    <Directory "!ROOT_FOLDER!">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Order allow, deny
        Allow from all
    </Directory>
</VirtualHost>

EOF
        )
    fi

    echo "${content}" | sudo tee -a "${VHOST_FILE_NAME}" >>/dev/null
}

##
# Create magento multi store or website vhost file
# @param $1 | Main server name
##
createMagentoMultiVhostFile() {
    if [[ ${webService} -eq ${WEBSERVICE_NGINX} ]]; then
        content=$(
            cat <<EOF
map \$http_host \$MAGE_RUN_CODE {
	!MAGE_MULTI_SITES!
}

server {
    listen 80;
    !HTTPS_LISTEN!

    server_name !SERVER_NAME!;

    ssl_certificate ${SSL_CRT};
    ssl_certificate_key ${SSL_KEY};

	set \$MAGE_ROOT !ROOT_FOLDER!;
	set \$MAGE_RUN_TYPE !MAGE_RUN_TYPE!;

	include ${MAGENTO_MULTI_FILE_CONFIG};
}

EOF
        )
    else
        content=$(
            cat <<EOF
<VirtualHost *:!HTTPS_LISTEN!>
    DocumentRoot !ROOT_FOLDER!
    ServerName !SERVER_NAME!
    ServerAlias !SERVER_ALIAS!
    SSLEngine !HTTPS_ON!
    SSLCertificateFile ${SSL_CRT}
    SSLCertificateKeyFile ${SSL_KEY}
    ErrorLog "/var/log/apache2/!SERVER_NAME!-error.log"
    CustomLog "/var/log/apache2/!SERVER_NAME!-access.log" common

    <Directory !ROOT_FOLDER!>
        Options Indexes MultiViews FollowSymLinks
        AllowOverride All
        Order allow, deny
        Allow from all
    </Directory>
</VirtualHost>

EOF
        )
    fi

    echo "${content}" | sudo tee -a "${VHOST_FILE_NAME}" >>/dev/null
}

##
# Create magento multi store or website vhost file
# @param $1 | sub server name
# @param $2 | store code / website code
##
addMagentoSubDomain() {
    if [[ ${webService} -eq ${WEBSERVICE_NGINX} ]]; then
        sed -i "s/!MAGE_MULTI_SITES!/${1}\t${2};\n\t!MAGE_MULTI_SITES!/g" "${VHOST_FILE_NAME}"
    else
        content=$(
            cat <<EOF
<VirtualHost *:!HTTPS_LISTEN!>
    ServerName          ${1}
    DocumentRoot        !ROOT_FOLDER!
    SetEnv MAGE_RUN_CODE ${2}
    SetEnv MAGE_RUN_TYPE !MAGE_RUN_TYPE!
</VirtualHost>

EOF
        )
        echo "${content}" | sudo tee -a "${VHOST_FILE_NAME}" >>/dev/null
    fi
}

##
# Create file import config for magento
##
createMagentoFileConfig() {
    if [[ -f "${MAGENTO_FILE_CONFIG}" ]]; then
        return
    fi

    content=$(
        cat <<EOF
root \$MAGE_ROOT/pub;

index index.php;
autoindex off;
charset UTF-8;
error_page 404 403 = /errors/404.php;
#add_header "X-UA-Compatible" "IE=Edge";

# PHP entry point for setup application
location ~* ^/setup(\$|/) {
    root \$MAGE_ROOT;
    location ~ ^/setup/index.php {
        fastcgi_pass   backend-server;

        fastcgi_param  PHP_FLAG  "session.auto_start=off \\n suhosin.session.cryptua=off";
        fastcgi_param  PHP_VALUE "memory_limit=2G \\n max_execution_time=18000";
        fastcgi_read_timeout 600s;
        fastcgi_connect_timeout 600s;

        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }

    location ~ ^/setup/(?!pub/). {
        deny all;
    }

    location ~ ^/setup/pub/ {
        add_header X-Frame-Options "SAMEORIGIN";
    }
}

# PHP entry point for update application
location ~* ^/update(\$|/) {
    root \$MAGE_ROOT;

    location ~ ^/update/index.php {
        fastcgi_split_path_info ^(/update/index.php)(/.+)\$;
        fastcgi_pass   backend-server;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        fastcgi_param  PATH_INFO        \$fastcgi_path_info;
        include        fastcgi_params;
    }

    # Deny everything but index.php
    location ~ ^/update/(?!pub/). {
        deny all;
    }

    location ~ ^/update/pub/ {
        add_header X-Frame-Options "SAMEORIGIN";
    }
}

location / {
    try_files \$uri \$uri/ /index.php\$is_args\$args;
}

location /pub/ {
    location ~ ^/pub/media/(downloadable|customer|import|theme_customization/.*\\.xml) {
        deny all;
    }
    alias \$MAGE_ROOT/pub/;
    add_header X-Frame-Options "SAMEORIGIN";
}

location /static/ {
    # Uncomment the following line in production mode
    # expires max;

    # Remove signature of the static files that is used to overcome the browser cache
    location ~ ^/static/version {
        rewrite ^/static/(version\\d*/)?(.*)\$ /static/\$2 last;
    }

    location ~* \\.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)\$ {
        add_header Cache-Control "public";
        add_header X-Frame-Options "SAMEORIGIN";
        expires +1y;

        if (!-f \$request_filename) {
            rewrite ^/static/?(.*)\$ /static.php?resource=\$1 last;
        }
    }
    location ~* \\.(zip|gz|gzip|bz2|csv|xml)\$ {
        add_header Cache-Control "no-store";
        add_header X-Frame-Options "SAMEORIGIN";
        expires    off;

        if (!-f \$request_filename) {
           rewrite ^/static/?(.*)\$ /static.php?resource=\$1 last;
        }
    }
    if (!-f \$request_filename) {
        rewrite ^/static/?(.*)\$ /static.php?resource=\$1 last;
    }
    add_header X-Frame-Options "SAMEORIGIN";
}

location /media/ {
    try_files \$uri \$uri/ /get.php\$is_args\$args;

    location ~ ^/media/theme_customization/.*\\.xml {
        deny all;
    }

    location ~* \\.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)\$ {
        add_header Cache-Control "public";
        add_header X-Frame-Options "SAMEORIGIN";
        expires +1y;
        try_files \$uri \$uri/ /get.php\$is_args\$args;
    }
    location ~* \\.(zip|gz|gzip|bz2|csv|xml)\$ {
        add_header Cache-Control "no-store";
        add_header X-Frame-Options "SAMEORIGIN";
        expires    off;
        try_files \$uri \$uri/ /get.php\$is_args\$args;
    }
    add_header X-Frame-Options "SAMEORIGIN";
}

#location /media/customer/ {
#    deny all;
#}

location /media/downloadable/ {
    deny all;
}

location /media/import/ {
    deny all;
}

# PHP entry point for main application
location ~ (index|get|static|report|404|503|health_check)\\.php\$ {
    try_files \$uri =404;
    fastcgi_pass   backend-server;
    fastcgi_buffers 1024 4k;

    fastcgi_param  PHP_FLAG  "session.auto_start=off \\n suhosin.session.cryptua=off";
    fastcgi_param  PHP_VALUE "memory_limit=2G \\n max_execution_time=18000";
    fastcgi_read_timeout 600s;
    fastcgi_connect_timeout 600s;

    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}

gzip on;
gzip_disable "msie6";

gzip_comp_level 6;
gzip_min_length 1100;
gzip_buffers 16 8k;
gzip_proxied any;
gzip_types
    text/plain
    text/css
    text/js
    text/xml
    text/javascript
    application/javascript
    application/x-javascript
    application/json
    application/xml
    application/xml+rss
    image/svg+xml;
gzip_vary on;

# Banned locations (only reached if the earlier PHP entry point regexes don't match)
location ~* (\\.php\$|\\.htaccess\$|\\.git) {
    deny all;
}

EOF
    )

    echo "${content}" | sudo tee -a "${MAGENTO_FILE_CONFIG}" >>/dev/null
}

##
# Create file import config for magento multi store or multi website
##
createMagentoFileConfigMulti() {
    if [[ -f "${MAGENTO_MULTI_FILE_CONFIG}" ]]; then
        return
    fi

    content=$(
        cat <<EOF
root \$MAGE_ROOT/pub;

index index.php;
autoindex off;
charset off;

add_header 'X-Content-Type-Options' 'nosniff';
add_header 'X-XSS-Protection' '1; mode=block';

location /setup {
    root \$MAGE_ROOT;
    location ~ ^/setup/index.php {
        fastcgi_pass   backend-server;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        fastcgi_params;
    }

    location ~ ^/setup/(?!pub/). {
        deny all;
    }

    location ~ ^/setup/pub/ {
        add_header X-Frame-Options "SAMEORIGIN";
    }
}

location /update {
    root \$MAGE_ROOT;

    location ~ ^/update/index.php {
        fastcgi_split_path_info ^(/update/index.php)(/.+)\$;
        fastcgi_pass   backend-server;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        fastcgi_param  PATH_INFO        \$fastcgi_path_info;
        include        fastcgi_params;
    }

    # deny everything but index.php
    location ~ ^/update/(?!pub/). {
        deny all;
    }

    location ~ ^/update/pub/ {
        add_header X-Frame-Options "SAMEORIGIN";
    }
}

location / {
    try_files \$uri \$uri/ /index.php?\$args;
}

location /pub {
    location ~ ^/pub/media/(downloadable|customer|import|theme_customization/.*\\.xml) {
        deny all;
    }
    alias \$MAGE_ROOT/pub;
    add_header X-Frame-Options "SAMEORIGIN";
}

location /static/ {
    if (\$MAGE_MODE = "production") {
        expires max;
    }
    location ~* \\.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2|html)\$ {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header Cache-Control "public";
        add_header X-Frame-Options "SAMEORIGIN";
        expires +1y;

        if (!-f \$request_filename) {
            rewrite ^/static/(version\\d*/)?(.*)\$ /static.php?resource=\$2 last;
        }
    }
    location ~* \\.(zip|gz|gzip|bz2|csv|xml)\$ {
        add_header Cache-Control "no-store";
        add_header X-Frame-Options "SAMEORIGIN";
        expires    off;

        if (!-f \$request_filename) {
           rewrite ^/static/(version\\d*/)?(.*)\$ /static.php?resource=\$2 last;
        }
    }
    if (!-f \$request_filename) {
        rewrite ^/static/(version\\d*/)?(.*)\$ /static.php?resource=\$2 last;
    }
    add_header X-Frame-Options "SAMEORIGIN";
}

location /media/ {
    try_files \$uri \$uri/ /get.php?\$args;

    location ~ ^/media/theme_customization/.*\\.xml {
        deny all;
    }

    location ~* \\.(ico|jpg|jpeg|png|gif|svg|js|css|swf|eot|ttf|otf|woff|woff2)\$ {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header Cache-Control "public";
        add_header X-Frame-Options "SAMEORIGIN";
        expires +1y;
        try_files \$uri \$uri/ /get.php?\$args;
    }
    location ~* \\.(zip|gz|gzip|bz2|csv|xml)\$ {
        add_header Cache-Control "no-store";
        add_header X-Frame-Options "SAMEORIGIN";
        expires    off;
        try_files \$uri \$uri/ /get.php?\$args;
    }
    add_header X-Frame-Options "SAMEORIGIN";
}

location /media/customer/ {
    deny all;
}

location /media/downloadable/ {
    deny all;
}

location /media/import/ {
    deny all;
}

location ~ cron\\.php {
    deny all;
}

location ~ (index|get|static|report|404|503|test|console)\\.php\$ {
    try_files \$uri =404;
    fastcgi_pass   backend-server;

    fastcgi_param  PHP_FLAG  "session.auto_start=off \\n suhosin.session.cryptua=off";
    fastcgi_param  PHP_VALUE "memory_limit=2G \\n max_execution_time=18000 \\n session.gc_maxlifetime=36000";
    fastcgi_read_timeout 600s;
    fastcgi_send_timeout 600s;
    fastcgi_connect_timeout 600s;
    fastcgi_param  MAGE_MODE \$MAGE_MODE;
    fastcgi_param  MAGE_RUN_TYPE \$MAGE_RUN_TYPE;
    fastcgi_param  MAGE_RUN_CODE \$MAGE_RUN_CODE;    
    #fastcgi_param  MAGE_PROFILER \$MAGE_PROFILER;

    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
    include        fastcgi_params;
}

EOF
    )

    echo "${content}" | sudo tee -a "${MAGENTO_MULTI_FILE_CONFIG}" >>/dev/null
}

##
# Init ssl required file
##
initSslFile() {
    if [[ ! -d "${SSL_FOLDER}" ]]; then
        sudo mkdir -p "${SSL_FOLDER}"
    fi

    if [[ ! -f "${SSL_CRT}" ]]; then
        createSslCrt
    fi

    if [[ ! -f "${SSL_KEY}" ]]; then
        createSslKey
    fi
}

##
# Init magento equired file
##
initMagentoFile() {
    if [[ ! -d "${WEBSERVICE_INCLUDE_FOLDER}" ]]; then
        sudo mkdir -p "${WEBSERVICE_INCLUDE_FOLDER}"
    fi

    if [[ ! -f "${MAGENTO_FILE_CONFIG}" ]]; then
        createMagentoFileConfig
    fi

    if [[ ! -f "${MAGENTO_MULTI_FILE_CONFIG}" ]]; then
        createMagentoFileConfigMulti
    fi
}

# Get product path
printf "\nEnter project path root: "
read -r projectFolder
until [[ -d "${projectFolder}" ]]; do
    printf "
    %s%s is a directory
    %s
    Enter project path root: " "${RED}" "${projectFolder}" "${NC}"
    read -r projectFolder
done

# Check is using https
printf "
Is using https?
    %s - TRUE
    %s - FALSE (default)
Enter: " :"${TRUE_VALUE}" "${FALSE_VALUE}"
read -r ishttps
until [[ ${ishttps} -eq ${TRUE_VALUE} || ${ishttps} -eq ${FALSE_VALUE} || ${ishttps} == '' ]]; do
    printf "
    %sValue invalid!
    %s
    Is using https?
        %s - TRUE
        %s - FALSE (default)
    Enter: " "${RED}" "${NC}" "${TRUE_VALUE}" "${FALSE_VALUE}"
    read -r ishttps
done
if [[ "${ishttps}" == '' ]]; then
    ishttps=${FALSE_VALUE}
fi

initSslFile >/dev/null

# Check is magento project
printf "
Is magento project?
    %s - TRUE
    %s - FALSE (default)
Enter: " "${TRUE_VALUE}" "${FALSE_VALUE}"
read -r isMagento
until [[ ${isMagento} -eq ${TRUE_VALUE} || ${isMagento} -eq ${FALSE_VALUE} || ${isMagento} == '' ]]; do
    printf "
    %sValue invalid!
    %s
    Is magento project?
        %s - TRUE
        %s - FALSE (default)
    Enter: " "${RED}" "${NC}" "${TRUE_VALUE}" "${FALSE_VALUE}"
    read -r isMagento
done
if [[ "${isMagento}" == '' ]]; then
    isMagento=${FALSE_VALUE}
fi

if [[ ${isMagento} -eq ${TRUE_VALUE} ]]; then
    initMagentoFile >/dev/null
    # Check is magento multi if it is magento project
    printf "
    Is magento multi store or website?
        %s - TRUE
        %s - FALSE (default)
    Enter: " "${TRUE_VALUE}" "${FALSE_VALUE}"
    read -r isMagentoMulti
    until [[ ${isMagentoMulti} -eq ${TRUE_VALUE} || ${isMagentoMulti} -eq ${FALSE_VALUE} || ${isMagentoMulti} == '' ]]; do
        printf "
        %sValue invalid!
        %s
        Is magento multi store or website?
            %s - TRUE
            %s - FALSE (default)
        Enter: " "${RED}" "${NC}" "${TRUE_VALUE}" "${FALSE_VALUE}"
        read -r isMagentoMulti
    done
    if [[ "${isMagentoMulti}" == '' ]]; then
        isMagentoMulti=${FALSE_VALUE}
    fi

    if [[ ${isMagentoMulti} -eq ${TRUE_VALUE} ]]; then
        subdomainContinue=${TRUE_VALUE}
        createMagentoMultiVhostFile "${serverName}" >/dev/null

        # Get magento multi type
        printf "
        Select magento multi type
            %s - Store (default)
            %s - Website
        Enter: " "${MAGENTO_MULTI_STORE}" "${MAGENTO_MULTI_WEBSITE}"
        read -r magentoType
        until [[ ${magentoType} -eq ${MAGENTO_MULTI_STORE} || ${magentoType} -eq ${MAGENTO_MULTI_WEBSITE} || ${magentoType} == '' ]]; do
            printf "
            %sValue invalid!
            %s
            Select magento multi type
                %s - Store (default)
                %s - Website
            Enter: " "${RED}" "${NC}" "${MAGENTO_MULTI_STORE}" "${MAGENTO_MULTI_WEBSITE}"
            read -r magentoType
        done
        if [[ "${magentoType}" == '' ]]; then
            magentoType=${MAGENTO_MULTI_STORE}
        fi

        while [[ ${subdomainContinue} -eq ${TRUE_VALUE} ]]; do
            # Get sub server name
            printf "\nEnter server name for store (website): "
            read -r subserverName
            until [[ ${subserverName} != '' ]]; do
                printf "
                %sSub server name is not empty!
                %s
                Enter server name for store / website: " "${RED}" "${NC}"
                read -r subserverName
            done

            fullServerName="${fullServerName} www.${subserverName} ${subserverName}"

            # Get store / website code
            printf "\nEnter store (website) code: "
            read -r subCode
            until [[ ${subCode} != '' ]]; do
                printf "
                %sCode is not empty!
                %s
                Enter store (website) code: " "${RED}" "${NC}"
                read -r subCode
            done

            addMagentoSubDomain "${subserverName}" "${subCode}"

            # Is continue
            printf "
            Continue to add sub domain?
                %s - TRUE
                %s - FALSE (default)
            Enter: " "${TRUE_VALUE}" "${FALSE_VALUE}"
            read -r subdomainContinue
        done

        sudo sed -i "/!MAGE_MULTI_SITES!/d" "${VHOST_FILE_NAME}"
        sudo sed -i "s/!MAGE_RUN_TYPE!/${magentoType}/g" "${VHOST_FILE_NAME}"
    else
        createMagentoVhostFile "${serverName}"
    fi
else
    createNormalVhostFile "${serverName}"
fi

rootFolder=$(echo "${projectFolder}" | sed "s/\//\\\\\//g")
sudo sed -i "s/!ROOT_FOLDER!/${rootFolder}/g" "${VHOST_FILE_NAME}"
if [[ ${webService} -eq ${WEBSERVICE_NGINX} ]]; then
    sudo sed -i "s/!SERVER_NAME!/${fullServerName}/g" "${VHOST_FILE_NAME}"
    if [[ ${ishttps} -eq ${TRUE_VALUE} ]]; then
        sudo sed -i "s/!HTTPS_LISTEN!/listen 443;/g" "${VHOST_FILE_NAME}"
    else
        sudo sed -i "/!HTTPS_LISTEN!/d" "${VHOST_FILE_NAME}"
    fi

    # Create back-end service
    if [[ ! -f "${WEBSERVICE_SITE_AVAILABLE}/php.conf" ]]; then
        printf "\nEnter php version (5.6 or 7.0 or 7.1 ...): "
        read -r phpversion
        phpserverContent=$(
            cat <<EOF
upstream backend-server {
    server unix:/run/php/php${phpversion}-fpm.sock;
}

EOF
        )
        echo "${phpserverContent}" | sudo tee -a "${WEBSERVICE_SITE_AVAILABLE}/php.conf" >>/dev/null
        sudo ln -sf "${WEBSERVICE_SITE_AVAILABLE}/php.conf" /etc/nginx/sites-enabled/
    fi

    sudo ln -sf "${VHOST_FILE_NAME}" /etc/nginx/sites-enabled/
    sudo service nginx restart
else
    sudo sed -i "s/!SERVER_NAME!/${serverName}/g" "${VHOST_FILE_NAME}"
    sudo sed -i "s/!SERVER_ALIAS!/www.${serverName}/g" "${VHOST_FILE_NAME}"
    if [[ ${ishttps} -eq ${TRUE_VALUE} ]]; then
        sudo sed -i "s/!HTTPS_LISTEN!/443/g" "${VHOST_FILE_NAME}"
        sudo sed -i "s/!HTTPS_ON!/on/g" "${VHOST_FILE_NAME}"
    else
        sudo sed -i "s/!HTTPS_LISTEN!/80/g" "${VHOST_FILE_NAME}"
        sudo sed -i "/!HTTPS_ON!/d" "${VHOST_FILE_NAME}"
    fi

    sudo a2ensite "${serverName}.conf"
    sudo service apache2 restart
fi
