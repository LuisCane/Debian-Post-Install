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
            [Yy]* ) Proceeding;
            RootCheck;
            return 0;;
            [Nn]* ) GoodBye;;
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

#Check for Root and inform user that the script has parts that require root and parts for non-root users.
RootCheck() {
    if IsRoot; then
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
            [Yy]* ) Proceeding;
            return 0;;
            [Nn]* ) GoodBye;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
}

#Check if apt package is installed.
CheckForPackage() {
   REQUIRED_PKG=$1
   PKG_OK=$(dpkg-query -W $REQUIRED_PKG)
   if [ "" = "$PKG_OK" ]; then
     return 0
   else 
     return 1
   fi
}

UpdateSoftware() {
    if IsRoot; then
      printf '\nUpdating Software.\nNote: To Update Flatpak software, run this script without root or sudo.\n'
      UpdateApt;
      UpdateSnap;
    elif CheckForPackage flatpak;
      UpdateFlatpak;
    else   
      printf '\nSkipping Updates'
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
#Update Snap packages
UpdateSnap() {
    if CheckForPackage snapd; then
        while true; do
        read -p $'Would you like to update the Snap Packages? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) snap update;
            check_exit_status 
            break;;
            [Nn]* ) break;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
    else
    printf "Snapd is not installed, skipping snap updates."
}

#Update Flatpak packages
UpdateFlatpak() {
    if CheckForPackage flatpak; then
        while true; do
        read -p $'Would you like to update the Flatpak Packages? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;
            flatpak update;
            check_exit_status 
            break;;
            [Nn]* ) break;;
            * ) echo 'Please answer yes or no.';;
        esac
    done
    else
    printf "Snapd is not installed, skipping snap updates."
}

#AddUsers
AddUsers() {
    if IsRoot; then 
        printf "addusers\n"
    fi
}

#Install specified Package
InstallPKG() {
    if CheckForPackage $1; then
        printf '\nWould you like to install %s? [y/n]' "$1"
        read -r yn
        case $yn in
            [Yy]* ) printf '\nInstalling %s\n' "$1"
                    apt install -y $1
                    check_exit_status;
                    return 0;;
            [Nn]* ) printf '\nSkipping %s\n' "$1"
                    return 0;;
                * ) printf '\nPlease enter yes or no.\n'
                    ;;
        esac
    else
        printf '\nSkipping %s\n' "$1"
    fi
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

#Print Proceeding
Proceeding() {
    printf "\nProceeding\n"
}

#Print Goodbye and exit the script
GoodBye() {
    printf "\nGoodbye.\n";
    exit
}

Greeting

#if RootCheck; then
#    Proceeding
#else
#    GoodBye
#fi

#UpdateSoftware
#InstallSudo
#InstallVIM
#InstallPKG sudo
#InstallPKG vim
#InstallPKG cowsay
#AddUsers

GoodBye