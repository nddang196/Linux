#!/bin/bash

if [[ ${INSTALL_DOCKER} != 'true' ]]; then
    exit 0;
fi

##
# Show count up
# param $1 waitting message
##
spin()
{
    i=1
    while [[ 1 ]]
    do
        sleep 1
        printf "\r$1: %d" ${i}
        i=$(( ${i} + 1 ))
        wait
    done
}

archInstall ()
{
    sudo pacman -S docker
}

ubuntuInstall ()
{
    sudo apt-get install -y apt-transport-https \
                ca-certificates \
                curl \
                gnupg-agent \
                software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
       $(lsb_release -cs) \
       stable"
    sudo apt-get update
    sudo apt-get -y install docker-ce docker-ce-cli containerd.io
}

centosInstall ()
{
    sudo yum install -y yum-utils \
          device-mapper-persistent-data \
          lvm2
    sudo yum-config-manager --add-repo  https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce docker-ce-cli containerd.io
}

fedoraInstall ()
{
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager  --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install docker-ce docker-ce-cli containerd.io
}

echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL DOCKER<<<<<<<<<<<<<<<<<<<<<<<<"
spin '----> Installing' &
pid=$!
case $1 in
     arch)
         archInstall
         ;;
     ubuntu)
         ubuntuInstall
         ;;
     centos)
         centosInstall
         ;;
     fedora)
         fedoraInstall
         ;;
esac

sudo systemctl enable docker
sudo systemctl start docker
kill ${pid}
printf "\n\n"

spin '----> Docker compose is installing' &
pid=$!
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
kill ${pid}
printf "\n\n"

sudo usermod -aG docker ${USERNAME}

printf "
alias redis=\"docker-compose exec redis\"
alias elasticsearch=\"docker-compose exec elasticsearch\"
alias mgt=\"docker-compose exec -u www php mgt\"
alias magento=\"docker-compose exec -u www php bin/magento\"
alias artisan=\"docker-compose exec -u www php php artisan\"
alias php=\"docker-compose exec -u www php php\"
alias composer=\"doco exec -u www php composer\"
" >> ~/.zshrc
echo ">>>>>>>>>>>>>>>>>>>>>>>DOCKER - Done!<<<<<<<<<<<<<<<<<<<<<<<<"
