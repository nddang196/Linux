#!/bin/bash

if [[ ${INSTALL_BASE} != 'true' ]]; then
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
        printf "\r$1 : %d" ${i}
        i=$(( ${i} + 1 ))
        wait
    done
}

echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL BASE PACKAGE<<<<<<<<<<<<<<<<<<<<<<<<"
spin 'Installing git, vim, curl, zsh' &
pid=$!

sudo ${syntax} git vim curl zsh > /dev/null 2>&1
case ${DISTRO} in
    arch)
        echo y | sudo pacman -S git vim curl zsh > /dev/null 2>&1
        ;;
    ubuntu)
        sudo apt-get install -ygit vim curl zsh > /dev/null 2>&1
        ;;
    centos)
        sudo yum install -y git vim curl zsh > /dev/null 2>&1
        ;;
    fedora)
        sudo dnf -y install git vim curl zsh > /dev/null 2>&1
        ;;
esac

sudo curl -L https://git.io/vaHfR -o /usr/local/bin/screenfetch
sudo chmod +x /usr/local/bin/screenfetch

kill ${pid}
echo 'Install base package done!'
printf "\n\n"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>GIT CONFIG<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
spin 'Updating : ' &
pid=$!

if [[ ${GIT_USER} != '' ]]; then
	git config --global user.name "$GIT_USER" > /dev/null 2>&1
fi
if [[ ${GIT_EMAIL} != '' ]]; then
	git config --global user.email "$GIT_EMAIL" > /dev/null 2>&1
fi 
git config --global core.filemode false  > /dev/null 2>&1

kill ${pid}
git config --list
echo 'Git update config done!'
printf "\n\n"