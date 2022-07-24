#!/bin/bash
Greeting () {
    printf '\nHello!'
    sleep 1s
    printf '\nWelcome to my post install script for debian\n and debian based distributions.'
    sleep 1s
    printf '\n\nDISCLAIMER'
    sleep 1s
    printf '\nIt is not recommended that you run scripts that you find on the internet without knowing exactly what they do.\n\n
This script contains functions that require root privilages.\n'
    sleep 2s
    while true; do
        read -p $'Do you wish to proceed? [y/N]' yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
}

#Check for Root and inform user that the script has parts that require root and parts for non-root users.
RootCheck() {
    if [[ $EUID = 0 ]]; then
        printf "\nThis script is being run as root.\n\nCertain parts of this script should be run as a non-root user or without sudo.\nRun the script again for those parts.\n"
        printf "For example if you install flatpak, the apps should be installed as user.\n"
        sleep 2s
    else 
        printf "\nThis script is not being run as root.\n\nParts that require root privileges will be skipped.\n"
    fi
    while true; do
        read -p $'Proceed? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
}

#Check if User is Root.
IsRoot() {
    if [[ $EUID = 0 ]]; then
      return 0
      else
      return 1
    fi
}

UpdateSoftware() {
    if IsRoot; then
      printf '\nUpdating Software.\nNote: To Update Flatpak software, run this script without root or sudo.\n'
      UpdateApt;
    else
      printf '\nSkipping'
    fi
}


#Update and upgrade apt packages repos
UpdateApt () {
    while true; do
        read -p $'Would you like to update the apt repositories? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) apt update;
            check_exit_status 
            break;;
            [Nn]* ) break;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
    while true; do
        read -p $'Would you like to install the apt software updates? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) printf '\nInstalling apt package updates.\n'
            sleep1s
            apt -y dist-upgrade --allow-downgrades;
            check_exit_status
            apt -y autoremove;
            check_exit_status
            apt -y autoclean;
            check_exit_status
            break;;
            [Nn]* ) break;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
}
#Install Sudo
InstallSudo () {
    printf '\nWould you like to install sudo [y/n]'
    read -r yn
    case $yn in
        [Yy]* ) printf '\nInstalling sudo\n'
                apt install -y sudo
                check_exit_status;
                return 0;;
        [Nn]* ) printf '\nSkipping sudo'
                return 0;;
            * ) printf '\nPlease enter yes or no.\n'
                ;;
    esac
}
#Install VIM
InstallVIM () {
    printf '\nWould you like to install VIM? [y/n]'
    read -r yn
    case $yn in
        [Yy]* ) printf '\nInstalling VIM\n'
                apt install -y vim
                check_exit_status;
                return 0;;
        [Nn]* ) printf '\nSkipping VIM'
                return 0;;
            * ) printf '\nPlease enter yes or no.\n'
                ;;
    esac
}

#check process for errors and prompt user to exit script if errors are detected.
check_exit_status() {
    if [ $? -eq 0 ]
    then
        printf '\nSuccess\n'
    else
        printf '\nError\n'

        read -p $"The last command exited with an error. Exit script? (y/N) " yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) GoodBye;;
            [Nn]* ) break;;
            *) echo 'Please answer yes or no.';;
        esac
    fi
}

Proceeding() {
    printf "\nProceeding\n"
}
GoodBye() {
    printf "\nGoodbye.";
    exit
}

if Greeting; then
    Proceeding 
else
    GoodBye
fi
if RootCheck; then
    Proceeding
else
    GoodBye
fi


RootCheck
UpdateSoftware

GoodBye