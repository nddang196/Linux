#!/bin/bash
set -e

## Env
INSTALL_BASE=0
INSTALL_DOCKER=0
INSTALL_OH_MY_ZSH=0
INSTALL_PHP_STORM=0
INSTALL_INTELIJ_IDEA=0
INSTALL_DATA_GRIP=0
INSTALL_KDE=0
USERNAME=${USER}
GIT_USER=
GIT_EMAIL=


LIVE_PATH="$( cd "$( dirname "$0" )" && pwd )"
spin()
{
    i=1
    while [[ 1 ]]
    do
        sleep 1
        printf "\r$1 : %d" ${i}
        i=$(( ${i} + 1 ))
        wait
    done
}

RED='\033[0;31m'
NC='\033[0m'

until sudo -lS &> /dev/null << EOF
${password}
EOF
do
    printf "\nEnter password for $USER: "
	  IFS= read -rs password
done

printf "\n\n"

if [[ ${INSTALL_BASE} -eq 1 ]];then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL BASE PACKAGE<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing git: ' &
    pid=$!
    echo "PID = ${pid}"
    echo y | sudo pacman -Syu >> ~/arch-install.log 2>&1
    echo y | sudo pacman -S git >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing vim: ' &
    pid=$!
    echo "PID = ${pid}"
    echo y | sudo pacman -S vim >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing curl: ' &
    pid=$!
    echo "PID = ${pid}"

    echo y | sudo pacman -S curl >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing zsh: ' &
    pid=$!
    echo "PID = ${pid}"
    echo y | sudo pacman -S zsh >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing yajl: ' &
    pid=$!
    echo "PID = ${pid}"

    echo y | sudo pacman -S yajl >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing p7zip: ' &
    pid=$!
    echo "PID = ${pid}"

    echo y | sudo pacman -S p7zip >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing libreoffice-fresh: ' &
    pid=$!
    echo "PID = ${pid}"

    echo y | sudo pacman -S libreoffice-fresh >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing unrar: ' &
    pid=$!
    echo "PID = ${pid}"

    echo y | sudo pacman -S unrar >> ~/arch-install.log 2>&1
    kill ${pid}


    spin 'Installing screenfetch: ' &
    pid=$!
    echo "PID = ${pid}"

    sudo curl -L https://git.io/vaHfR -o /usr/local/bin/screenfetch
    sudo chmod +x /usr/local/bin/screenfetch
    kill ${pid}
    printf "\n\n"


    spin 'Installing Yaourt : ' &
    pid=$!
    echo "PID = ${pid}"

    git clone https://aur.archlinux.org/package-query.git >> ~/arch-install.log 2>&1
    git clone https://aur.archlinux.org/yaourt.git >> ~/arch-install.log 2>&1
    cd package-query && echo y | makepkg -si >> ~/arch-install.log 2>&1
    cd yaourt && echo y | makepkg -si >> ~/arch-install.log 2>&1
    rm -r package-query >> ~/arch-install.log 2>&1
    rm -r yaourt >> ~/arch-install.log 2>&1

    echo 'Install base package done!'
    printf "\n\n"

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>GIT CONFIG<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Updating : ' &
    pid=$!
    echo "PID = ${pid}"

    if [[ ${GIT_USER} != '' ]]; then
        git config --global user.name "$GIT_USER" >> ~/arch-install.log 2>&1
    fi
    if [[ ${GIT_EMAIL} != '' ]]; then
        git config --global user.email "$GIT_EMAIL" >> ~/arch-install.log 2>&1
    fi
    git config --global core.filemode false  >> ~/arch-install.log 2>&1

    kill ${pid}
    git config --list
    echo 'Git update config done!'
    printf "\n\n"
fi


if [[ ${INSTALL_OH_MY_ZSH} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL OH MY ZSH<<<<<<<<<<<<<<<<<<<<<<<<"
    spin '----> Installing' &
    pid=$!
    echo "PID = ${pid}"
    # Install oh my zsh
    echo ${password} | sh -c \
      "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" \
      >> ~/arch-install.log 2>&1
    kill ${pid}
    printf "\n\n"

    # install themes and exts
    spin '----> Installing zsh theme and plugins' &
    pid=$!
echo "PID = ${pid}"    
    git clone https://github.com/bhilburn/powerlevel9k.git \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel9k >> ~/arch-install.log 2>&1
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >> ~/arch-install.log 2>&1
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting >> ~/arch-install.log 2>&1
    cp -f "${LIVE_PATH}/.zshrc" ~/
    kill ${pid}
    printf "\n\n"
    echo ">>>>>>>>>>>>>>>>>>>>>>>OH MY ZSH - Done!<<<<<<<<<<<<<<<<<<<<<<<<"
fi



if [[ ${INSTALL_PHP_STORM} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL PHPStorm<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing PHPStorm' &
    pid=$!
    echo "PID = ${pid}"

    arr=($(curl https://data.services.jetbrains.com/products/releases\?code\=PS\&latest\=true | \
      grep -oP "https:\/\/download\.jetbrains\.com\/webide\/PhpStorm-\d*\.\d*(\.\d*)*\.tar\.gz"))

    url=${arr[0]}
    if [[ ${url} != '' ]]; then
        wget -O phpstorm.tar.gz ${url} >> ~/arch-install.log 2>&1
        mkdir -p phpstorm
        tar -zxvf phpstorm.tar.gz -C phpstorm >> ~/arch-install.log 2>&1
        sudo mv phpstorm /opt/ >> ~/arch-install.log 2>&1
        rm phpstorm.tar.gz >> ~/arch-install.log 2>&1
    fi

    kill ${pid}
    echo 'Install PHPStorm done!'
    printf "\n\n"
fi


if [[ ${INSTALL_DATA_GRIP} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL DataGrip<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing DataGrip' &
    pid=$!
    echo "PID = ${pid}"

    arr=($(curl https://data.services.jetbrains.com/products/releases\?code\=DG\&latest\=true | \
      grep -oP "https:\/\/download\.jetbrains\.com\/datagrip\/datagrip-\d*\.\d*(\.\d*)*\.tar\.gz"))

    url=${arr[0]}
    if [[ ${url} != '' ]]; then
        wget -O datagrip.tar.gz ${url} >> ~/arch-install.log 2>&1
        mkdir -p datagrip
        tar -zxvf datagrip.tar.gz -C datagrip >> ~/arch-install.log 2>&1
        sudo mv datagrip /opt/ >> ~/arch-install.log 2>&1
        rm datagrip.tar.gz >> ~/arch-install.log 2>&1
    fi

    kill ${pid}
    echo 'Install DataGrip done!'
    printf "\n\n"
fi


if [[ ${INSTALL_INTELIJ_IDEA} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL Intelij Idea<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing Intelij Idea' &
    pid=$!
    echo "PID = ${pid}"

    arr=($(curl https://data.services.jetbrains.com/products/releases\?code\=IIU%2CIIC\&latest\=true\&type\=release | \
      grep -oP "https:\/\/download\.jetbrains\.com\/idea\/ideaIU-\d*\.\d*(\.\d*)*\.tar\.gz"))

    url=${arr[0]}
    if [[ ${url} != '' ]]; then
        wget -O idea.tar.gz ${url} >> ~/arch-install.log 2>&1
        mkdir -p idea
        tar -zxvf idea.tar.gz -C idea >> ~/arch-install.log 2>&1
        sudo mv idea /opt/ >> ~/arch-install.log 2>&1
        rm idea.tar.gz >> ~/arch-install.log 2>&1
    fi

    kill ${pid}
    echo 'Install  Intelij Idea done!'
    printf "\n\n"
fi

if [[ ${INSTALL_DOCKER} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL Docker<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing Docker' &
    pid=$!
    echo "PID = ${pid}"
    
    echo y | sudo pacman -S docker >> ~/arch-install.log 2>&1
    sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose >> ~/arch-install.log 2>&1
    sudo chmod +x /usr/local/bin/docker-compose >> ~/arch-install.log 2>&1
    sudo usermod -aG docker ${USER} >> ~/arch-install.log 2>&1
    sudo systemctl enable docker >> ~/arch-install.log 2>&1
    sudo systemctl start docker >> ~/arch-install.log 2>&1
    printf "
        # Docker alias
        alias redis=\"docker-compose exec redis\"
        alias mgt=\"docker-compose exec -u www php m2\"
        alias magento=\"docker-compose exec -u www php bin/magento\"
        alias artisan=\"docker-compose exec -u www php php artisan\"
        alias php=\"docker-compose exec -u www php php\"
        alias composer=\"docker-compose exec -u www php composer\"
    " >> ~/.zshrc 2>&1
    kill ${pid}
    echo ">>>>>>>>>>>>>>>>>>>>>>>DOCKER - Done!<<<<<<<<<<<<<<<<<<<<<<<<"
fi

if [[ ${INSTALL_KDE} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL KDE<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing KDE' &
    pid=$!
    echo "PID = ${pid}"

    printf "\ny" | sudo pacman -S plasma \
      sddm \
      ark \
      konsole \
      yakuake \
      sweeper \
      dolphin \
      dolphin-plugins \
      kdeplasma-addons \
      networkmanager openconnect networkmanager-openconnect \
      speedcrunch \
      kdeconnect \
      kfind \
      kwalletmanager \
      kinfocenter \
      filelight \
      gwenview \
      kipi-plugins \
      gimp \
      vlc \
      redshift \
      ntfs-3g >> ~/arch-install.log 2>&1
    sudo systemctl enable sddm >> ~/arch-install.log 2>&1
    sudo systemctl enable NetworkManager >> ~/arch-install.log 2>&1

    kill ${pid}
    echo ">>>>>>>>>>>>>>>>>>>>>>>>KDE - Done!<<<<<<<<<<<<<<<<<<<<<<<<<"
fi

printf "\n\n"
echo "Arch Linux install package done! <<<<<<<<<<<<<<<<<< VooThanhArch"