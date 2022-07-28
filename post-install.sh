#!/bin/bash
Greeting () {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
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
            return 0
            ;;
            [Nn]* ) GoodBye
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
}

#Check if User is Root.
IsRoot() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if [[ $EUID = 0 ]]; then
      return 0
      else
      return 1
    fi
}

#Check for Root and inform user that the script has parts that require root and parts for non-root users.
RootCheck() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
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
            return 0
            ;;
            [Nn]* ) GoodBye
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
}

#Check if apt package is installed.
CheckForPackage() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    REQUIRED_PKG=$1
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "install ok installed" = "$PKG_OK" ]; then
      return 0
    else
      return 1
    fi
}

#Setup Nala as alternative package manager to Apt
SetupNala() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf "\nNala is a front-end for apt with a variety of features such as parallel downloads, clear display of what is happening, and the ability to fetch faster mirrors."
        sleep 1s
        printf "\nWould you like to install Nala? [y/N]"
        read -p yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) echo "deb http://deb.volian.org/volian/ scar main" | tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list;
                    wget -qO - https://deb.volian.org/volian/scar.key | tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null;
                    apt update;
                    apt install nala;
                    if [ $? -eq 100 ]; then
                        apt install nala-legacy
                        if [ $? -eq 100 ]; then
                            printf '\nNala might not be supported on your specific distribution.'
                        else
                            PKGMGR=nala
                            export LC_ALL=C.UTF-8
                            export LANG=C.UTF-8
                        fi
                    else
                        PKGMGR=nala
                        export LC_ALL=C.UTF-8
                        export LANG=C.UTF-8
                    fi
                    nala fetch
            ;;
            [Nn]* ) 
            ;;
            * ) printf '\nPlease answer yes or no.'
        esac

    fi
}

UpdateSoftware() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf '\nUpdating Software.\nNote: To Update Flatpak software, run this script without root or sudo.\n'
        if [[ '$PKGMGR' == 'nala' ]]; then
            UpdateNala;
        else
            UpdateApt;
        fi
        UpdateSnap;
    elif CheckForPackage flatpak; then
      UpdateFlatpak;
    else   
      printf '\nSkipping Updates'
    fi
}


#Update and upgrade apt packages repos
UpdateApt () {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    while true; do
        read -p $'Would you like to update the apt repositories? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) $PKGMGR update;
            check_exit_status 
            break
            ;;
            [Nn]* ) break
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
    while true; do
        read -p $'Would you like to install the apt software updates? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) printf '\nInstalling apt package updates.\n'
            sleep1s
            $PKGMGR -y dist-upgrade --allow-downgrades;
            check_exit_status
            $PKGMGR -y autoremove;
            check_exit_status
            $PKGMGR -y autoclean;
            check_exit_status
            break
            ;;
            [Nn]* ) break
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
}

#Update Apt Packages and repos with Nala
UpdateNala() {
printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    while true; do
        read -p $'Would you like to update the apt repositories? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) $PKGMGR update;
            check_exit_status 
            break
            ;;
            [Nn]* ) break
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
    while true; do
        read -p $'Would you like to install the apt software updates? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) printf '\nInstalling apt package updates.\n'
            sleep1s
            $PKGMGR upgrade;
            check_exit_status
            $PKGMGR autoremove;
            check_exit_status
            $PKGMGR autopurge;
            check_exit_status
            $PKGMGR clean;
            check_exit_status
            break
            ;;
            [Nn]* ) break
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
}


#Update Snap packages
UpdateSnap() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if CheckForPackage snapd; then
        while true; do
        read -p $'Would you like to update the Snap Packages? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) snap refresh;
            check_exit_status 
            break
            ;;
            [Nn]* ) break
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    done
    else
    printf "Snapd is not installed, skipping snap updates."
    fi
}

#Update Flatpak packages
UpdateFlatpak() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if CheckForPackage flatpak; then
        while true; do
        read -p $'Would you like to update the Flatpak Packages? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) flatpak update;
            check_exit_status 
            break
            ;;
            [Nn]* ) break
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
        done
    else
    printf "Flatpak is not installed, skipping Flatpak updates."
    fi
}

#CreateUsers
CreateUsers() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then 
        printf '\nWould you like to add users? [y/N]'
        read -r yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) AddUsers
                while true; do
                printf '\nWould you like to add another user? [y/N]'
                read -r yn
                yn=${yn:-N}
                case $yn in
                    [Yy]* ) AddUsers
                    ;;
                    [Nn]* ) break
                    ;;
                    * ) printf '\nPlease answer yes or no.'
                    ;;
                esac
                done
            ;;
            [Nn]* ) 
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    fi
}

#AddUsers
AddUsers() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    definedusername=''
    printf '\nEnter username: '
    read definedusername
    useradd -m -s $DefinedSHELL $definedusername 
    passwd $definedusername
    MakeUserSudo
}

#Add Defined User to Sudo group
MakeUserSudo() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if CheckForPackage sudo; then
        printf '\nWould you like to add this user to the sudo group? [y/N]'
        read -r yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) usermod -aG sudo $definedusername
            ;;
            [Nn]* ) 
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    fi
}

#SetupZSH
SetupZSH() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf "\nWould you like to setup to install ZSH? [y/N]" 
        read -r yn
        case $yn in
            [Yy]* ) $PKGMGR install -y zsh zsh-syntax-highlighting zsh-autosuggestions
            check_exit_status
            DefinedSHELL=/bin/zsh
            usermod --shell $DefinedSHELL root
            usermod --shell $DefinedSHELL $USER
            CopyZshrcFile
            ;;
            [Nn]* )
            ;;
            * ) printf '\nPlease answer yes or no.'
            ;;
        esac
    fi
}

#CopyZshrcFile
CopyZshrcFile() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf "\nWould you like to copy the zshrc file included with this script to your home directory?" 
        read -r yn
        case $yn in
            [Yy]* ) rcfile=./rcfiles/zshrc
                    if [[ -f "$rcfile" ]]; then
                    copy ./rcfiles/zshrc /root/.zshrc
                    copy ./rcfiles/zshrc /home/$USER/.zshrc
                else
                    printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."                
                fi
            ;;
            [Nn]* ) printf "\nSkipping zshrc file."
            ;;
            * ) echo "Please answer yes or no"
            ;;
        esac
    fi
}

#Install specified Package
InstallPKG() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if CheckForPackage $1; then
            printf '\nWould you like to install %s? [y/n]' "$1"
            read -r yn
            case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "$1"
                        $PKGMGR install -y $1
                        check_exit_status;
                        return 0
                        ;;
                [Nn]* ) printf '\nSkipping %s\n' "$1"
                        return 0
                        ;;
                    * ) printf '\nPlease enter yes or no.\n'
                        ;;
            esac
        else
            printf '\nSkipping %s\n' "$1"
        fi
    fi
}
#Install specified Package
InstallSnapd() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if CheckForPackage snapd; then
            printf '\nWould you like to install %s? [y/n]' "snapd"
            read -r yn
            case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "snapd"
                        $PKGMGR install -y snapd
                        check_exit_status;
                        return 0
                        ;;
                [Nn]* ) printf '\nSkipping %s\n' "snapd"
                        return 0
                        ;;
                    * ) printf '\nPlease enter yes or no.\n'
                        ;;
            esac
        else
            printf '\nSkipping %s\n' "snapd"
        fi  
    fi
}
#Install flatpak
InstallFlatpak() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if CheckForPackage flatpak; then
            printf '\nWould you like to install %s? [y/n]' "flatpak"
            read -r yn
            case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "flatpak"
                        $PKGMGR install -y flatpak
                        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo;
                        check_exit_status;
                        return 0
                        ;;
                [Nn]* ) printf '\nSkipping %s\n' "flatpak"
                        return 0
                        ;;
                    * ) printf '\nPlease enter yes or no.\n'
                        ;;
            esac
        else
            printf '\nSkipping %s\n' "flatpak"
        fi
    fi
}

#check process for errors and prompt user to exit script if errors are detected.
check_exit_status() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    if [ $? -eq 0 ]; then
        printf '\nSuccess\n'
    else
        printf '\nError\n'

        read -p $"The last command exited with an error. Exit script? (y/N) " yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) GoodBye
            ;;
            [Nn]* ) break
            ;;
            *) printf '\nPlease answer yes or no.'
            ;;
        esac
    fi
}

#Print Proceeding
Proceeding() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    printf "\nProceeding\n"
}

#Print Goodbye and exit the script
GoodBye() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    printf "\nGoodbye.\n";
    exit
}

Greeting
PKGMGR=apt
DefinedSHELL=/bin/bash

SetupNala
UpdateSoftware
SetupZSH
InstallSudo
InstallVIM
InstallFlatpak
InstallSnapd
InstallPKG sudo
InstallPKG vim
InstallPKG cowsay
CreateUsers

GoodBye