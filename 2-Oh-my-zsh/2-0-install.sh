#!/bin/bash

if [[ ${INSTALL_OH_MY_ZSH} != 'true' ]]; then
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


echo ">>>>>>>>>>>>>>>>>>>>>>>INSTALL OH MY ZSH<<<<<<<<<<<<<<<<<<<<<<<<"
spin '----> Installing' &
pid=$!
# Install oh my zsh
echo ${PASSWORD} | sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" > /dev/null 2>&1
kill ${pid}
printf "\n\n"

# install themes and exts
spin '----> Installing zsh theme and plugins' &
pid=$!
git clone https://github.com/bhilburn/powerlevel9k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel9k > /dev/null 2>&1
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions > /dev/null 2>&1
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting > /dev/null 2>&1
kill ${pid}
printf "\n\n"

# install fonts
spin '----> Installing nerd fonts' &
pid=$!
git clone https://github.com/ryanoasis/nerd-fonts.git --depth=1
cd nerd-fonts && ./install.sh
rm -rf nerd-fonts
kill ${pid}
printf "\n\n"

if [[ ${LIVE_PATH} != '' ]]; then
	if [[ -f "${LIVE_PATH}/2-Oh-my-zsh/.zshrc" ]]; then
		cp -f "${LIVE_PATH}/2-Oh-my-zsh/.zshrc" ~/
	fi
else
	path="$( cd "$( dirname "$0" )" && pwd )"
	if [[ -f "${path}/.zshrc" ]]; then
		cp -f "${path}/.zshrc" ~/
	fi
fi
echo ">>>>>>>>>>>>>>>>>>>>>>>OH MY ZSH - Done!<<<<<<<<<<<<<<<<<<<<<<<<"