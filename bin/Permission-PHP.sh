#!/bin/bash
set -e

##
# Show count up
# param $1 waiting message
##
spin() {
    i=1
    while [[ 1 ]]; do
        sleep 1
        printf "\r$1: %d" ${i}
        i=$((i + 1))
        wait
    done
}

RED='\033[0;31m'
NC='\033[0m'

until sudo -lS &>/dev/null <<EOF; do
$password
EOF

    printf "Enter password for %s: " "${USER}"
    IFS= read -rs password
done

printf "\nEnter project path root (Enter if current folder): "
read -r projectFolder
if [[ "${projectFolder}" == "" ]]; then
    projectFolder=$(pwd)
    echo "${projectFolder}"
fi

until [[ -d "${projectFolder}" ]]; do
    printf "%s%s is a directory\n%s" "${RED}" "${projectFolder}" "${NC}"
    printf 'Enter project path root: '
    read -r projectFolder
done

printf 'HTTP group (default: www-data): '
read -r HTTPDUSER

spin 'Running' &
pid=$!

sudo chown -R "$(whoami)":"$HTTPDUSER" "${projectFolder}"
if [[ -d "${projectFolder}/var" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/var"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:$(whoami):rwX "${projectFolder}/var"
fi
if [[ -d "${projectFolder}/pub/static" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/pub/static"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/pub/static"
fi
if [[ -d "${projectFolder}/pub/media" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/pub/media"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/pub/media"
fi
if [[ -d "${projectFolder}/app/etc" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/app/etc"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/app/etc"
fi
if [[ -d "${projectFolder}/generated" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/generated"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/generated"
fi
if [[ -d "${projectFolder}/storage" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/storage"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/storage"
fi
if [[ -d "${projectFolder}/bootstrap/cache" ]]; then
    sudo setfacl -R -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/bootstrap/cache"
    sudo setfacl -dR -m u:"$HTTPDUSER":rwX -m u:"$(whoami)":rwX "${projectFolder}/bootstrap/cache"
fi
if [[ -e "${projectFolder}/bin/magento" ]]; then
    sudo chmod u+x "${projectFolder}/bin/magento"
fi
find "${projectFolder}" -type f -exec chmod 664 {} \;
find "${projectFolder}" -type d -exec chmod 775 {} \;
kill ${pid}
printf "\nDone!"
