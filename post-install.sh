#!/bin/bash
Greeting () {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
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
            ScriptDirCheck;
            RootCheck;
            return 0
            ;;
            [Nn]* ) GoodBye
            ;;
            * ) AnswerYN
            ;;
        esac
    done
}

#Check if User is Root.
IsRoot() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if [[ $EUID = 0 ]]; then
      return 0
      else
      return 1
    fi
}

#Check for Root and inform user that the script has parts that require root and parts for non-root users.
RootCheck() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
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
            * ) AnswerYN
            ;;
        esac
    done
}

#Make sure script is being run from within the script's directory.
ScriptDirCheck() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    DirCheckFile=./.dircheckfile
    if [[ -f "$DirCheckFile" ]]; then
        return 0
    else
        printf '\nThis script is being run from outside its intended directory. Please run this script from its main directory.'
        GoodBye
        exit
    fi
}

#Check if apt package is installed.
CheckForPackage() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
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
    sleep 1s
    echo "deb http://deb.volian.org/volian/ scar main" | tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list;
    wget -qO - https://deb.volian.org/volian/scar.key | tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg > /dev/null;
    apt update;
    apt install nala;
    if [ $? -eq 100 ]; then
        apt install nala-legacy
        if [ $? -eq 100 ]; then
            printf '\nNala might not be supported on your specific distribution.'
        else
            PKGMGR=nala
            echo 'export LC_ALL=C.UTF-8' >> /etc/profile
            export LC_ALL=C.UTF-8
            echo 'export LANG=C.UTF-8'
            export LANG=C.UTF-8
        fi
    else
        PKGMGR=nala
        echo 'export LC_ALL=C.UTF-8' >> /etc/profile
        export LC_ALL=C.UTF-8
        echo 'export LANG=C.UTF-8'
        export LANG=C.UTF-8
    fi
    nala fetch
}

UpdateSoftware() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if IsRoot; then
        printf '\nUpdating Software.\nNote: To Update Flatpak software, run this script without root or sudo.\n'
        if [[ $PKGMGR == nala ]]; then
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
    sleep 1s
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
            * ) AnswerYN
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
            * ) AnswerYN
            ;;
        esac
    done
}

#Update Apt Packages and repos with Nala
UpdateNala() {
printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
sleep 1s
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
            * ) AnswerYN
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
            * ) AnswerYN
            ;;
        esac
    done
}


#Update Snap packages
UpdateSnap() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if CheckForPackage snapd; then
        read -p $'Would you like to update the Snap Packages? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) snap refresh
            check_exit_status
            ;;
            [Nn]* ) printf '\nSkipping Snap Update.'
            ;;
            * ) AnswerYN
            ;;
        esac
    else
    printf "Snapd is not installed, skipping snap updates."
    fi
}

#Update Flatpak packages
UpdateFlatpak() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if CheckForPackage flatpak; then
        read -p $'Would you like to update the Flatpak Packages? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) flatpak update
            check_exit_status
            ;;
            [Nn]* ) printf '\nSkipping Flatpak Update'
            ;;
            * ) AnswerYN
            ;;
        esac
    else
    printf "Flatpak is not installed, skipping Flatpak updates."
    fi
}

#CreateUsers
CreateUsers() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
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
                    * ) AnswerYN
                    ;;
                esac
                done
            ;;
            [Nn]* ) 
            ;;
            * ) AnswerYN
            ;;
        esac
    fi
}

#AddUsers
AddUsers() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
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
    sleep 1s
    if CheckForPackage sudo; then
        printf '\nWould you like to add this user to the sudo group? [y/N]'
        read -r yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) usermod -aG sudo $definedusername
            ;;
            [Nn]* ) printf '\nSkipping making user sudo.'
            ;;
            * ) AnswerYN
            ;;
        esac
    else
    printf '\nSudo is not installed, would you like to install it? [y/N]'
        read -r yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) InstallPKG Sudo
                printf '\nWould you like to add this user to the sudo group? [y/N]'
                read -r yn
                yn=${yn:-N}
                case $yn in
                   [Yy]* ) usermod -aG sudo $definedusername
                   ;;
                   [Nn]* ) printf '\nSkipping making user sudo.'
                   ;;
                   * ) AnswerYN
                   ;;
                esac
            ;;
            [Nn]* ) printf '\nSkipping making user sudo.'
            ;;
            * ) AnswerYN
            ;;
        esac
    fi
}

#SetupZSH
SetupZSH() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if IsRoot; then
        printf "\nWould you like to setup to install ZSH? [y/N]" 
        read -r yn
        yn=${yn:-N}
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
            * ) AnswerYN
            ;;
        esac
    fi
}

#CopyZshrcFile
CopyZshrcFile() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if IsRoot; then
        printf "\nWould you like to copy the zshrc file included with this script to your home directory? [Y/n]" 
        yn=${yn:-Y}
        read -r yn
        case $yn in
            [Yy]* ) rcfile=./rcfiles/zshrc
                    if [[ -f "$rcfile" ]]; then
                    cp ./rcfiles/zshrc /root/.zshrc
                    cp ./rcfiles/zshrc /etc/skel/.zshrc
                    cp ./rcfiles/zshrc /home/$USER/.zshrc
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
    sleep 1s
    if IsRoot; then
        if ! CheckForPackage $1; then
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
            printf '\nSkipping %s, already installed.\n' "$1"
        fi
    fi
}
#Install specified Package
InstallSnapd() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if IsRoot; then
        if ! CheckForPackage snapd; then
            printf '\nWould you like to install %s? [y/n]' "snapd"
            read -r yn
            case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "snapd"
                        InstallPKG snapd
                        snap install core
                        check_exit_status
                        ;;
                [Nn]* ) printf '\nSkipping %s\n' "snapd"
                        ;;
                    * ) printf '\nPlease enter yes or no.\n'
                        ;;
            esac
        else
            printf '\nSkipping %s, already installed.\n' "snapd"
        fi  
    fi
}
#Install flatpak
InstallFlatpak() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if IsRoot; then
        if ! CheckForPackage flatpak; then
            printf '\nWould you like to install %s? [y/n]' "flatpak"
            read -r yn
            case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "flatpak"
                        InstallPKG flatpak
                        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                        check_exit_status
                        ;;
                [Nn]* ) printf '\nSkipping %s\n' "flatpak"
                        ;;
                    * ) printf '\nPlease enter yes or no.\n'
                        ;;
            esac
        else
            printf '\nSkipping %s, already installed.\n' "flatpak"
        fi
    fi
}

#Install Selected desktop Apt packages
InstallAptDeskSW() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    file='./apps/apt-desktop-apps'
    while read -r line <&3; do
    printf 'Would you like to install %s [Y-yes Default / N-no / E-exit]? ' "$line"
    read -r yne
    yne=${yne:-Y}
    case $yne in
        [Yy]*) InstallPKG "$line"
               check_exit_status
        ;;
        [Nn]*) printf '\nSkipping %s\n' "$line"
        ;;
        [Ee]*) break
        ;;
        *) AnswerYN 
        ;;
    esac
  done 3< "$file"
}

#Install Selected server Apt packages
InstallAptServSW() {
printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
sleep 1s
file='./apps/apt-server-apps'
    while read -r line <&3; do
    printf 'Would you like to install %s [Y-yes Default / N-no / E-exit]? ' "$line"
    read -r yne
    yne=${yne:-Y}
    case $yne in
        [Yy]*) InstallPKG "$line"
               check_exit_status
        ;;
        [Nn]*) printf '\nSkipping %s\n' "$line"
        ;;
        [Ee]*) break
        ;;
        *) AnswerYN 
        ;;
    esac
  done 3< "$file"
}

#Install Selected Flatpak apps
    InstallFlatpakSW() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    file='./apps/flatpak-apps'
    while read -r line <&3; do
    printf 'Would you like to install %s [Y-yes (Default) / N-no / E-exit]? ' "$line"
    read -r yne
    yne=${yne:-Y}
    case $yne in
        [Yy]*) flatpak install -y "$line"
               check_exit_status
        ;;
        [Nn]*) printf '\nSkipping %s\n' "$line"
        ;;
        [Ee]*) break
        ;;
        *) AnswerYN 
        ;;
    esac
  done 3< "$file"
}

#Install Selected Snap packages
InstallSnapSW() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    file='./apps/snap-apps'
    while read -r line <&3; do
    printf 'Would you like to install %s [Y-yes (Default) / N-no / E-exit]? ' "$line"
    read -r yne
    yne=${yne:-Y}
    case $yne in
        [Yy]*) snap install -y "$line"
               check_exit_status
        ;;
        [Nn]*) printf '\nSkipping %s\n' "$line"
        ;;
        [Ee]*) break
        ;;
        *) AnswerYN 
        ;;
    esac
  done 3< "$file"
}

#Install Firestorm Second Life Viewer
InstallFirestorm() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf '\nPlease ensure that the download link in ./apps/firestorm is the latest version. Press any key to continue.'
    read -rsn1
    file='./apps/firestorm'
    read -r url < "$file"
    wget $url
    tar -xvf Phoenix_Firestorm-Release_x86_64*.tar.xz
    chmod +x Phoenix_Firestorm*/install.sh
    ./Phoenix_Firestorm*/install.sh
    rm -r ./Phoenix_Firestorm*
}

#Install Yubikey Packages
InstallYubiSW() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf '\nInstalling Required Packages for yubikey authentication.'
    InstallPKG libpam-yubico
    InstallPKG libpam-u2f
    InstallPKG yubikey-manager
    InstallPKG yubikey-personalization

}
#Set up Yubikey for One Time Password Authentication
CreateYubikeyChalResp() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf '\nSetting up Challenge Response Authentication\n'
    printf '\nPlease Insert your yubikey and press any key to continue.'
    read -rsn1 -p
    printf '\nWARNING IF YOU HAVE ALREADY PROGRAMED CHALLENGE RESPONSE, THIS STEP WILL OVERWRITE YOUR EXISTING KEY WITH A NEW ONE. SKIP THIS STEP IF YOU DO NOT WANT A NEW KEY!\n'
    sleep 1s
    while true; do
        printf '\nWould you like to program challenge reponse keys on your yubikey? [y/N]'
        read -r yn
        yn=${yn:-n}
        case $yn in
            [Yy]* ) ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible ;
                while true; do
                    printf '\nWould you like to program challenge reponse keys on another yubikey? [y/N]'
                    read -r yn
                    yn=${yn:-N}
                    case $yn in
                        [Yy]* ) printf '\nPlease insert your next yubikey and press any key to continue.'
                        read -rsn1
                        ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible;
                        ;;
                        [Nn]* ) break
                        ;;
                        * ) AnswerYN
                        ;;
                    esac
                done
            ;;
            [Nn]* ) break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
    printf '\nNow creating Yubikey Challenge Response files.\n'
    sleep 1s
    while true; do
        ykpamcfg -2 -v
        printf '\nWould you like to add another yubikey? [Y/n]'
        read -r yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) printf '\nPlease insert your next yubikey and press any key to continue.'
                    read -rsn1
                    ykpamcfg -2 -v
            ;;
            [Nn]* ) printf '\nSkipping.'
                    break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
}
#Set up Yubikey for Challange Response Authentication
CreateYubikeyOTP() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf '\nSetting up OTP (One Time Password) Authentication.\n'
    sleep 1s
    authkeys=$USER
    printf '\nPlease touch your Yubikey.'
    read -r ykey
    ykey12=${ykey:0:12}
    authkeys+=':'
    authkeys+="$ykey12"
    while true; do
        printf '\nWould you like to add another Yubikey? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* )printf '\nPlease touch your Yubikey.'
                   read -r ykey
                   ykey12=${ykey:0:12}
                   authkeys+=':'
                   authkeys+="$ykey12"
            ;;
            [Nn]* ) printf '\nSkipping.\n'
                    echo $authkeys | tee >> ./authorized_yubikeys;
                    break
            ;;
            * ) AnswerYN
            ;;
        esac
    echo $authkeys | tee >> ./authorized_yubikeys
    printf '\nKeys saved to ./authorized_yubikeys.'
    done
}
#Copy Key files and PAM rules
CPYubikeyFiles() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf 'Creating key directories and copying key files to appropriate locations. You may need to manually edit some files.'\
    sleep 1s
    mkdir -p /var/yubico
    chown root:root /var/yubico
    chmod 766 /var/yubico
    cp ./authorized_yubikeys /var/yubico/authorized_yubikeys
    for i in ~/.yubico/*; do
        cp $i $(echo $i | sed "s/challenge/$USER/")
        cp ~/.yubico/$USER* /var/yubico/
        chown root:root /var/yubico/*
        chmod 600 /var/yubico/*
    done
    chmod 700 /var/yubico
    cp ./pamfiles/yubikey /etc/pam.d/yubikey
    cp ./pamfiles/yubikey-pin /etc/pam.d/yubikey-pin
    cp ./pamfiles/yubikey-sudo /etc/pam.d/yubikey-sudo
    printf "\nAdd 'include' statements to /etc/pam auth files to specify your security preferences."
    sleep 1s
}

#Install Spice-vdagent for QEMU VMs
VMSetup() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if ! CheckForPackage spice-vdagent; then
        printf '\nWould you like to install spice-vdagent for an improved VM desktop experience? [Y/n] '
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) InstallPKG spice-vdagent
                check_exit_status
            ;;
            [Nn]* ) printf '\nSkipping installing Spice-vdagent.'
            ;;
            * ) AnswerYN
            ;;
        esac
    fi
}

#Install Refind for Dual Boot Systems
DualBootSetup() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    if ! CheckForPackage refind; then
        printf '\nRefind is a graphical bootloader that shows the icons of the installed operating systems.'
        printf '\nWould you like to install refind? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) InstallPKG refind
            ;;
            [Nn]* ) printf '\nSkipping installing refind.'
            ;;
            * ) AnswerYN
            ;;
        esac
    fi
}

#check process for errors and prompt user to exit script if errors are detected.
check_exit_status() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
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
            *) AnswerYN
            ;;
        esac
    fi
}

#Print Proceeding
Proceeding() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf "\nProceeding\n"
}

#Print Goodbye and exit the script
GoodBye() {
    printf '\n--------------------> Function: %s <--------------------\n' "${FUNCNAME[0]}"
    sleep 1s
    printf "\nGoodbye.\n";
    exit
}

AnswerYN() {
    printf '\nPlease answer yes or no.'
}

#Functions ---> ^ ^ ^ ^ ^ ^ ^ ^ <-----
#Script ------> V V V V V V V V <----- 


#Greet The User and Warn of using scripts that need root privilages.
Greeting
PKGMGR=apt
DefinedSHELL=/bin/bash

#Setup Nala
if CheckForPackage nala; then
    PKGMGR=nala
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
elif CheckForPackage nala-legacy; then
    PKGMGR=nala
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
else
    if IsRoot; then
        printf "\nNala is a front-end for libapt-pkg with a variety of features such as parallel downloads, clear display of what is happening, and the ability to fetch faster mirrors."
        sleep 1s
        printf "\nWould you like to install Nala? [y/N]"
        read -p yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) SetupNala
            ;;
            [Nn]* ) 
            ;;
            * ) AnswerYN
            ;;
        esac
    else
        PKGMGR=nala
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
    fi
fi

UpdateSoftware

SetupZSH

InstallPKG vim

InstallFlatpak

InstallSnapd

CreateUsers


InstallPKG sudo

#Setup SpiceVD Agent for QEMU VMs.
if IsRoot; then
    printf '\nIs this system a QEMU based virtual machine? [y/N]'
    read -r yn
    yn=${yn:-Y}
        case $yn in
            [Yy]* ) VMSetup
            ;;
            [Nn]* ) printf '\nSkipping VM setup'
            ;;
            *) AnswerYN
            ;;
        esac
fi

#Setup Refind for Dual Boot systems
if IsRoot; then
    printf '\nIs this system a dual boot system? [y/N]'
    read -r yn
    yn=${yn:-Y}
        case $yn in
            [Yy]* ) DualBootSetup
            ;;
            [Nn]* ) printf '\nSkipping DualBoot setup'
            ;;
            *) AnswerYN
            ;;
        esac
fi

#Setup Yubikey Authentication
if IsRoot; then
    printf '\nWould you like to set up Yubikey authentication? [Y/n]'
    read -r yn
    yn=${yn:-Y}
    case $yn in
        [Yy]* ) InstallYubiSW
                CreateYubikeyOTP
                CreateYubikeyChalResp
                CPYubikeyFiles
                return 0
        ;;
        [Nn]* ) printf "\nSkipping Yubikey setup\n"
        ;;
        * ) echo 'Please answer yes or no.'
        ;;
    esac
fi

#Install Recommended Apt Software
if IsRoot; then
    printf '\nNOTE: depending on your distribution and sources, apt packeges may not be the latest versions available.\nIf you want the latest version of something, install it from flatpak.'
    printf '\nWould you like to install apt packages? [Y/n]'
    read -r yn
    yn=${yn:-Y}
    case $yn in
        [Yy]* ) printf '\nWould you like to install desktop apps? [Y/n]'
                read -r yn
                yn=${yn:-Y}
                case $yn in
                    [Yy]*) InstallAptDeskSW
                    ;;
                    [Nn]*)
                    ;;
                    *) AnswerYN
                    ;;
                esac
                printf '\nWould you like to install server and CLI apps? [Y/n]'
                read -r yn
                yn=${yn:-Y}
                case $yn in
                    [Yy]*) InstallAptServSW
                    ;;
                    [Nn]*)
                    ;;
                    *) AnswerYN
                    ;;
                esac
        ;;
        [Nn]* ) printf "\nSkipping apt packages\n"
        ;;
        * ) AnswerYN
        ;;
    esac
fi

#Install Recommended Flatpak Software
if ! IsRoot; then
    if CheckForPackage flatpak; then
        printf '\nWould you like to install Flatpak apps? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) InstallFlatpakSW
            ;;
            [Nn]* ) printf "\nSkipping Flatpak apps\n"
            ;;
            * ) AnswerYN
            ;;
        esac
    else
        printf '\nFlatpak is not installed. Skipping flatpak apps.'
    fi
else
    printf '\nYou are running this script as root. To install Flatpak apps, you should run this script again without root or sudo.'
fi

#Install Recommended snap packages
if IsRoot; then
    if CheckForPackage snapd; then
        printf '\nWould you like to install Snap packages? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) InstallSnapSW
            ;;
            [Nn]* ) printf "\nSkipping Snap apps\n"
            ;;
            * ) AnswerYN
            ;;
        esac
    else
        printf '\nSnapd is not installed. Skipping Snap Packages.'
    fi
fi

#Install Firestorm Viewer for Second Life
printf '\nWould you like to install Firestorm Second Life Viewer? [y/N]'
read -r yn
yn=${yn:-Y}
case $yn in
    [Yy]* ) if IsRoot; then
                InstallFirestorm
            else
                printf '\nYou are not root, installing firestorm as user will install to your home directory. Proceed? [Y/n]'
                read -r yn
                yn=${yn:-Y}
                case $yn in
                    [Yy]* ) InstallFirestorm
                    ;;
                    [Nn]* ) printf '\nSkipping Firestorm Installation.'
                    ;;
                    *) AnswerYN
                    ;;
                esac                
            fi
    ;;
    [Nn]* ) printf '\nSkipping Firestorm Installation.'
    ;;
    * ) AnswerYN
    ;;
esac

GoodBye