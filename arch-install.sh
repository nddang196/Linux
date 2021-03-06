#!/bin/bash
set -e

## Env
source .env

LIVE_PATH="$( cd "$( dirname "$0" )" && pwd )"
spin()
{
    i=1
    while true
    do
        sleep 1
        printf "\r$1 : %d" ${i}
        i=$(( i + 1 ))
        wait
    done
}

until sudo -lS &> /dev/null << EOF
${password}
EOF
do
    printf "\nEnter password for %s: " "${USERNAME}"
	  IFS= read -rs password
done

printf "\n\n"

if [[ ${SETUP_SYSTEM} -eq 1 ]];then
    echo ">>>>>>>>>>>>>>>>>>>>>>>Arch Linux System Setup<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Updating : ' &
    pid=$!
    echo "PID = ${pid}"

    {
        # Set hostname
        echo "${HOST_NAME}" > /etc/hostname
        printf "
        127.0.0.1   localhost
        ::1         localhost
        127.0.1.1   %s
        " "${HOST_NAME}" >> /etc/hosts


        # Set language
        sed -i 's/#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/g' /etc/locale.gen
        locale-gen
        echo LANG=en_US.UTF-8 > /etc/locale.conf


        # Update mirrorlist
        sed -i "1s/^/Server = http:\/\/f\.archlinuxvn\.org\/archlinux\/\$repo\/os\/\$arch\n\n/" /etc/pacman.d/mirrorlist
        sed -i "1s/^/Server = http:\/\/mirror\.bizflycloud\.vn\/archlinux\/\$repo\/os\/\$arch\n/" /etc/pacman.d/mirrorlist
        sed -i '1s/^/# Viet Nam\n/' /etc/pacman.d/mirrorlist
        sed -i ':a;N;$!ba;s/#[multilib]\n#Include = \/etc\/pacman.d\/mirrorlist/[multilib]\nInclude = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf


        # Set network time
        ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
        hwclock --systohc --utc
        timedatectl set-ntp true


        # Boot setup
        mkinitcpio -P
        bootctl --path=/boot install
        cp "${LIVE_PATH}/includes/boot-loader.conf" /boot/loader/loader.conf
        cp "${LIVE_PATH}/includes/arch.conf" /boot/loader/entries/arch.conf
        cp "${LIVE_PATH}/includes/arch-fallback.conf" /boot/loader/entries/arch-fallback.conf
        sed -i "s/%ROOT_LABEL%/${ROOT_LABEL}/g" /boot/loader/entries/arch.conf
        sed -i "s/%ROOT_LABEL%/${ROOT_LABEL}/g" /boot/loader/entries/arch-fallback.conf

        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\n\n"
    echo ">>>>>>>>>>>>>>>>>>>>>>>System Setup - Done!<<<<<<<<<<<<<<<<<<<<<<<<"
fi

if [[ ${INSTALL_BASE} -eq 1 ]];then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL BASE PACKAGE<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing git, vim, curl, zsh, yajl, p7zip, unrar, wget: ' &
    pid=$!
    echo "PID = ${pid}"

    {
        echo y | sudo pacman -Syu \
        git \
        vim \
        curl \
        zsh \
        yajl \
        p7zip \
        unrar \
        wget
        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\n\n"
    spin 'Installing screenfetch: ' &
    pid=$!
    echo "PID = ${pid}"
    {
        sudo curl -L https://git.io/vaHfR -o /usr/local/bin/screenfetch
        sudo chmod +x /usr/local/bin/screenfetch
        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\n\n"
    spin 'Installing Yaourt : ' &
    pid=$!
    echo "PID = ${pid}"

    {
        git clone https://aur.archlinux.org/package-query.git
        git clone https://aur.archlinux.org/yaourt.git
        cd package-query && echo y | makepkg -si
        cd ..
        cd yaourt && echo y | makepkg -si
        cd ..
        rm -rf package-query
        rm -rf yaourt
        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\nInstall base package done!\n\n"


    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>GIT CONFIG<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Updating : ' &
    pid=$!
    echo "PID = ${pid}"

    {
        if [[ ${GIT_USER} != '' ]]; then
            git config --global user.name "$GIT_USER"
        fi
        if [[ ${GIT_EMAIL} != '' ]]; then
            git config --global user.email "$GIT_EMAIL"
        fi
        git config --global core.filemode false

        kill ${pid}
    } >> ~/arch-install.log 2>&1
    printf "\nGit update config done!\n\n"
fi


if [[ ${INSTALL_OH_MY_ZSH} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL OH MY ZSH<<<<<<<<<<<<<<<<<<<<<<<<"
    spin '----> Installing' &
    pid=$!
    echo "PID = ${pid}"

    {
	      rm -rf ~/.oh-my-zsh
        # Install oh my zsh
        echo "${password}" | sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

        # install themes and extensions
	      git clone https://github.com/romkatv/powerlevel10k.git \
          "${ZSH_CUSTOM:-/home/${USERNAME}/.oh-my-zsh/custom}/themes/powerlevel10k"
        git clone https://github.com/zsh-users/zsh-autosuggestions \
          "${ZSH_CUSTOM:-~/home/${USERNAME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
          "${ZSH_CUSTOM:-~/home/${USERNAME}/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

        cp "${LIVE_PATH}/includes/.zshrc" "/home/${USERNAME}/"
        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\nOh my zsh is installed!\n\n"
fi



if [[ ${INSTALL_PHP_STORM} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL PHPStorm<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing PHPStorm' &
    pid=$!
    echo "PID = ${pid}"

    {
        url="https://download.jetbrains.com/product?code=PS&latest&distribution=linux"
        wget -O phpstorm.tar.gz "${url}"
        mkdir -p phpstorm
        tar -zxvf phpstorm.tar.gz -C phpstorm
        sudo mv phpstorm /opt/
        rm phpstorm.tar.gz

        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\nPHPStorm is installed!\n\n"
fi


if [[ ${INSTALL_DATA_GRIP} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL DataGrip<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing DataGrip' &
    pid=$!
    echo "PID = ${pid}"

    {
        url="https://download.jetbrains.com/product?code=DG&latest&distribution=linux"
        wget -O datagrip.tar.gz "${url}"
        mkdir -p datagrip
        tar -zxvf datagrip.tar.gz -C datagrip
        sudo mv datagrip /opt/
        rm datagrip.tar.gz

        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\nDataGrip is installed!\n\n"
fi


if [[ ${INSTALL_INTELIJ_IDEA} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL Intelij Idea<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing Intelij Idea' &
    pid=$!
    echo "PID = ${pid}"

    {
        url="https://download.jetbrains.com/product?code=IIU&latest&distribution=linux"
        wget -O idea.tar.gz "${url}"
        mkdir -p idea
        tar -zxvf idea.tar.gz -C idea
        sudo mv idea /opt/
        rm idea.tar.gz

        kill ${pid}
    } >> ~/arch-install.log 2>&1

    printf "\nIntelij Idea is installed!\n\n"
fi

if [[ ${INSTALL_DOCKER} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL Docker<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing Docker' &
    pid=$!
    echo "PID = ${pid}"
    
    {
        echo y | sudo pacman -S docker
        sudo curl -L "https://github.com/docker/compose/releases/download//1.28.6/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo usermod -aG docker "${USERNAME}"
        sudo systemctl enable docker
        sudo systemctl start docker
        printf "
        # Docker alias
        alias redis=\"docker-compose exec redis\"
        alias mgt=\"docker-compose exec -u www php m2\"
        alias magento=\"docker-compose exec -u www php bin/magento\"
        alias artisan=\"docker-compose exec -u www php php artisan\"
        alias php=\"docker-compose exec -u www php php\"
        alias composer=\"docker-compose exec -u www php composer\"
        " >> ~/.zshrc 2>&1
    } >> ~/arch-install.log 2>&1

    kill ${pid}
    printf "\nDocker is installed!\n\n"
fi

if [[ ${INSTALL_KDE} -eq 1 ]]; then
    echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL KDE<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    spin 'Installing KDE' &
    pid=$!
    echo "PID = ${pid}"

    {
        printf "\ny" | sudo pacman -S \
            plasma \
            sddm \
            ark \
            konsole \
            yakuake \
            sweeper \
            dolphin \
            dolphin-plugins \
            kdeplasma-addons \
            networkmanager \
            openconnect \
            networkmanager-openconnect \
            speedcrunch \
            kdeconnect \
            kfind \
            kwalletmanager \
            kinfocenter \
            filelight \
            gwenview \
            kipi-plugins \
            redshift \
            ntfs-3g
        sudo systemctl enable sddm
        sudo systemctl enable NetworkManager
    } >> ~/arch-install.log 2>&1

    kill ${pid}
    printf "\nKDE is installed!\n\n"
fi

echo "Arch Linux install package done! <<<<<<<<<<<<<<<<<< VooThanhArch"
