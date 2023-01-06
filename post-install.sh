#!/bin/bash
Greeting () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
            [Yy]* ) Proceeding
            ScriptDirCheck
            RootCheck
            break
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if [[ $EUID = 0 ]]; then
      return 0
      else
      return 1
    fi
}

#Check for Root and inform user that the script has parts that require root and parts for non-root users.
RootCheck() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
            [Yy]* ) Proceeding
            break
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    REQUIRED_PKG=$1
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    #echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "install ok installed" = "$PKG_OK" ]; then
      return 0
    else
      return 1
    fi
}
#Check if Eddy is installed.
CheckForEddy() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf "Checking for com.github.donadigo.eddy: DPKG\n"
    DPKG_OK=$(dpkg-query -W --showformat='${Status}\n' com.github.donadigo.eddy|grep "install ok installed")
    printf "Checking for com.github.donadigo.eddy: USR\n"
    if [ "install ok installed" = "/usr/bin/com.github.donadigo.eddy" ] || [[ -f "/usr/bin/com.github.donadigo.eddy" ]]; then
      return 0
    else
      return 1
    fi
}

#Setup Nala as alternative package manager to Apt
SetupNala() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
        fi
    else
        PKGMGR=nala
    fi
    nala fetch
}

UpdateSoftware() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    while true; do
        read -p $'Would you like to update the apt repositories? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) $PKGMGR update;
            check_exit_status 
            break
            ;;
            [Nn]* ) printf '\nSkipping repository updates.'
            break
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
            sleep 1s
            $PKGMGR -y dist-upgrade --allow-downgrades;
            check_exit_status
            $PKGMGR -y autoremove;
            check_exit_status
            $PKGMGR -y autoclean;
            check_exit_status
            break
            ;;
            [Nn]* ) printf '\nSkipping package upgrades.'
            break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
}

#Update Apt Packages and repos with Nala
UpdateNala() {
printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    while true; do
        read -p $'Would you like to update the apt repositories? [Y/n]' yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) $PKGMGR update;
            check_exit_status 
            break
            ;;
            [Nn]* ) printf '\nSkipping repository updates.'
            break
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
            sleep 1s
            $PKGMGR upgrade
            check_exit_status
            $PKGMGR autopurge
            check_exit_status
            $PKGMGR clean
            check_exit_status
            break
            ;;
            [Nn]* ) printf '\nSkipping package upgrades.'
            break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
}


#Update Snap packages
UpdateSnap() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if CheckForPackage snapd; then
        while true; do
            read -p $'Would you like to update the Snap Packages? [Y/n]' yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) snap refresh
                check_exit_status
                break
                ;;
                [Nn]* ) printf '\nSkipping Snap Update.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
    printf "Snapd is not installed, skipping snap updates."
    fi
}

#Update Flatpak packages
UpdateFlatpak() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if CheckForPackage flatpak; then
        while true; do
            read -p $'Would you like to update the Flatpak Packages? [Y/n]' yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) flatpak update
                check_exit_status
                break
                ;;
                [Nn]* ) printf '\nSkipping Flatpak Update'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
    printf "Flatpak is not installed, skipping Flatpak updates."
    fi
}

#CreateUsers
CreateUsers() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then 
        while true; do
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
                            break
                            ;;
                            [Nn]* ) printf '\nSkipping adding users.'
                            break
                            ;;
                            * ) AnswerYN
                            ;;
                        esac
                    done
                ;;
                [Nn]* ) printf '\nSkipping adding users.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    fi
}

#AddUsers
AddUsers() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    definedusername=''
    printf '\nEnter username: '
    read definedusername
    useradd -m -s $DefinedSHELL $definedusername 
    passwd $definedusername
    MakeUserSudo
}

#Add Defined User to Sudo group
MakeUserSudo() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if CheckForPackage sudo; then
        while true; do
            printf '\nWould you like to add this user to the sudo group? [y/N]'
            read -r yn
            yn=${yn:-N}
            case $yn in
                [Yy]* ) usermod -aG sudo $definedusername
                break
                ;;
                [Nn]* ) printf '\nSkipping making user sudo.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
    while true; do
        printf '\nSudo is not installed, would you like to install it? [y/N]'
        read -r yn
        yn=${yn:-N}
        case $yn in
            [Yy]* ) 
            while true; do
                InstallPKG Sudo
                printf '\nWould you like to add this user to the sudo group? [y/N]'
                read -r yn
                yn=${yn:-N}
                case $yn in
                    [Yy]* ) usermod -aG sudo $definedusername
                    break
                    ;;
                    [Nn]* ) printf '\nSkipping making user sudo.'
                    break
                    ;;
                    * ) AnswerYN
                    ;;
                esac
            done
            break
            ;;
            [Nn]* ) printf '\nSkipping making user sudo.'
            break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
    fi
}

#SetupZSH
SetupZSH() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        while true; do
            printf "\nWould you like to setup ZSH? [y/N]" 
            read -r yn
            yn=${yn:-N}
                case $yn in
                [Yy]* ) $PKGMGR install -y zsh zsh-syntax-highlighting zsh-autosuggestions
                check_exit_status
                DefinedSHELL=/bin/zsh
                usermod --shell $DefinedSHELL root
                CopyZshrcFile
                break
                ;;
                [Nn]* ) printf '\nSkipping ZSH Setup.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
        if CheckForPackage zsh; then
            while true; do
                printf "\nWould you like to set ZSH as your shell? [y/N]" 
                read -r yn
                yn=${yn:-Y}
                case $yn in
                    [Yy]* ) DefinedSHELL=/bin/zsh
                    chsh -s $DefinedSHELL
                    CopyZshrcFile
                    break
                    ;;
                    [Nn]* ) printf '\nSkipping zsh Setup.'
                    break
                    ;;
                    * ) AnswerYN
                    ;;
                esac
            done
        fi
    fi
}

#CopyZshrcFile
CopyZshrcFile() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        while true; do
            printf "\nWould you like to copy the zshrc file included with this script to your home directory? [Y/n]" 
            yn=${yn:-Y}
            read -r yn
            case $yn in
                [Yy]* ) rcfile=./rcfiles/zshrc
                if [[ -f "$rcfile" ]]; then
                    cp ./rcfiles/zshrc /root/.zshrc
                    cp ./rcfiles/zshrc /etc/skel/.zshrc
                else
                        printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."                
                fi
                break
                ;;
                [Nn]* ) printf "\nSkipping zshrc file."
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
        if CheckForPackage zsh; then
            while true; do
                printf "\nWould you like to copy the zshrc file included with this script to your home directory? [Y/n]" 
                yn=${yn:-Y}
                read -r yn
                case $yn in
                    [Yy]* ) rcfile=./rcfiles/zshrc
                    if [[ -f "$rcfile" ]]; then
                        cp ./rcfiles/zshrc /home/$USER/.zshrc
                    else
                        printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."                
                    fi
                    break
                    ;;
                    [Nn]* ) printf "\nSkipping zshrc file."
                    break
                    ;;
                    * ) AnswerYN
                    ;;
                esac
            done
        fi
    fi
}

#Generate SSH Key with comment
SSHKeyGen () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    while true; do
        if IsRoot; then
            printf '\nNOTE: You are running this script as Root, or with Sudo. The SSH Key generated will be for the root user.'
        fi
        printf '\nWould you like to generate an SSH key? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) printf '\nPlease enter a type [RSA/dsa]: '
            read -r keytype
            keytype=${keytype:-RSA}
            printf '\nPlease enter a modulus [4096]: '
            read -r modulus
            modulus=${modulus:-4096}
            printf '\nEnter a comment to help identify this key [%s @ %s]: ' "$USER" "$HOSTNAME"
            read -r keycomment;
            keycomment=${keycomment:-$USER @ $HOSTNAME}
            printf '\nEnter an output file [%s/.ssh/%s\_rsa]: ' "$HOME" "$USER"
            read -r outfile;
            outfile=${outfile:-$HOME/.ssh/$USER\_rsa}
            ssh-keygen -t $keytype -b $modulus -C "$keycomment" -f $outfile;
            break
            ;;
        [Nn]* ) printf '\nSSH Key Not generated\n'
        break
        ;;
        * ) AnswerYN
        ;;
        esac
    done
}

#Copy bashrc and vimrc to home folder
CPbashrc () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf '\nNOTE: You are running this script as root. The bashrc file here will be copied to the /root and /etc/skel/ directories.\n'
    fi
    while true; do
        printf '\nWould you like to copy the bashrc file included with this script to your home folder? [Y/n]' 
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) if IsRoot; then
                cp ./rcfiles/bashrc ~/.bashrc
                cp ./rcfiles/bashrc /etc/skel/.bashrc
            else
                cp ./rcfiles/bashrc ~/.bashrc
            fi
            break
            ;;
            [Nn]* ) printf '\nSkipping bashrc file.\n'
            break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
}
CPvimrc ()  {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf '\nNOTE: You are running this script as root. The vimrc file here will be copied to the /root and /etc/skel/ directories.\n'
    fi
    while true; do
    printf '\nWould you like to copy the vimrc file included with this script to your home folder? [Y/n]' 
    read -r yn
    yn=${yn:-Y}
    case $yn in
        [Yy]* ) if IsRoot; then
            cp ./rcfiles/vimrc ~/.vimrc
            cp ./rcfiles/vimrc /etc/skel/.vimrc
        else
            cp ./rcfiles/vimrc ~/.vimrc
        fi
        break
        ;;
        [Nn]* ) printf '\nSkipping vimrc file.\n'
        break
        ;;
        * ) AnswerYN
        ;;
        esac
    done
}

#Install specified Package
InstallPKG() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    $PKGMGR install -y $1
    check_exit_status;
}
#Remove specified Package
RemovePKG() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    $PKGMGR remove -y $1
    check_exit_status;
}
#Install specified Package
InstallSnapd() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if ! CheckForPackage snapd; then
            while true; do
                printf '\nWould you like to install %s? [y/n]' "snapd"
                read -r yn
                case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "snapd"
                InstallPKG snapd
                snap install core
                if CheckForPackage gnome-software; then
                    InstallPKG gnome-software-plugin-snap
                fi
                check_exit_status
                break
                ;;
                [Nn]* ) printf '\nSkipping %s\n' "snapd"
                break
                ;;
                * ) AnswerYN
                ;;
                esac
            done
        else
            printf '\nSkipping %s, already installed.\n' "snapd"
        fi  
    fi
}
#Install flatpak
InstallFlatpak() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if ! CheckForPackage flatpak; then
            while true; do
                printf '\nWould you like to install %s? [y/n]' "flatpak"
                read -r yn
                case $yn in
                [Yy]* ) printf '\nInstalling %s\n' "flatpak"
                InstallPKG flatpak
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
                if CheckForPackage gnome-software; then
                    InstallPKG gnome-software-plugin-flatpak
                fi
                check_exit_status
                break
                ;;
                [Nn]* ) printf '\nSkipping %s\n' "flatpak"
                break
                ;;
                * ) AnswerYN
                ;;
                esac
            done
        else
            printf '\nSkipping %s, already installed.\n' "flatpak"
        fi
    fi
}

InstallEddy() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    $PKGMGR install -y wget valac libgranite-dev libpackagekit-glib2-dev libunity-dev meson ninja-build libzeitgeist-2.0-dev gettext
    check_exit_status 
    WORKINGDIR=$(pwd)
    wget https://github.com/donadigo/eddy/archive/refs/tags/1.3.2.tar.gz
    tar -xzf 1.3.2.tar.gz eddy
    meson build ./eddy && cd build ./eddy
    meson configure ./eddy -Dprefix=/usr
    ninja ./eddy
    ninja install ./eddy
}

#Install Selected desktop Apt packages
InstallAptDeskSW() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        file='./apps/apt-desktop-apps'
        while read -r line <&3; do
            if ! CheckForPackage $1; then
                while true; do
                    printf 'Would you like to install %s [Y-yes Default / N-no / E-exit]? ' "$line"
                    read -r yne
                    yne=${yne:-Y}
                    case $yne in
                        [Yy]*) $PKGMGR install -y "$line"
                        ;;
                        [Nn]*) printf '\nSkipping %s\n' "$line"
                        ;;
                        [Ee]*) break
                        ;;
                        *) AnswerYN 
                        ;;
                    esac
                done
            else
                printf '\nSkipping %s, already installed.\n' "$1"
            fi    
        done 3< "$file"
    fi
}

#Install Selected server Apt packages
InstallAptServSW() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        file='./apps/apt-server-apps'
        while read -r line <&3; do
            if ! CheckForPackage $1; then
                while true; do
                    printf 'Would you like to install %s [Y-yes Default / N-no / E-exit]? ' "$line"
                    read -r yne
                    yne=${yne:-Y}
                    case $yne in
                        [Yy]*) $PKGMGR install -y "$line"
                        ;;
                        [Nn]*) printf '\nSkipping %s\n' "$line"
                        ;;
                        [Ee]*) break
                        ;;
                        *) AnswerYN 
                        ;;
                    esac
                done
            else
                printf '\nSkipping %s, already installed.\n' "$1"
            fi    
        done 3< "$file"
    fi
}

#Remove Unnecessary Apps
removeUnnecessaryApps() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        file='./apps/apt-unnecessary-apps'
        while read -r line <&3; do
            if CheckForPackage $1; then
                while true; do
                    printf 'Would you like to remove %s [Y-yes Default / N-no / E-exit]? ' "$line"
                    read -r yne
                    yne=${yne:-Y}
                    case $yne in
                        [Yy]*) $PKGMGR remove -y "$line"
                        check_exit_status
                        break
                        ;;
                        [Nn]*) printf '\nSkipping %s\n' "$line"
                        break
                        ;;
                        [Ee]*) break
                        ;;
                        *) AnswerYN 
                        ;;
                    esac
                done
            else
                printf '\nSkipping %s, not installed.\n' "$1"
            fi``    
        done 3< "$file"
        $PKGMGR autoremove
    fi
}

#Install Selected Flatpak apps
InstallFlatpakSW() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    file='./apps/flatpak-apps'
    while read -r line <&3; do
        printf 'Would you like to install %s [Y-yes (Default) / N-no / E-exit]? ' "$line"
        read -r yne
        yne=${yne:-Y}
        case $yne in
            [Yy]*) flatpak install -y "$line"
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    file='./apps/snap-apps'
    while read -r line <&3; do
        printf 'Would you like to install %s [Y-yes (Default) / N-no / E-exit]? ' "$line"
        read -r yne
        yne=${yne:-Y}
        case $yne in
            [Yy]*) snap install -y "$line"
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf '\nInstalling Required Packages for yubikey authentication.'
    InstallPKG libpam-yubico
    InstallPKG libpam-u2f
    InstallPKG yubikey-manager
    InstallPKG yubikey-personalization

}
#Set up Yubikey for One Time Password Authentication
CreateYubikeyChalResp() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
                        [Nn]* ) printf '\nSkipping.'
                        break
                        ;;
                        * ) AnswerYN
                        ;;
                    esac
                done
            ;;
            [Nn]* ) printf '\nSkipping.'
            break
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
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

#Install Qemu guest agent and/or Spice-vdagent for QEMU VMs
VMSetup() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ! CheckForPackage spice-vdagent; then
        while true; do
            printf '\nWould you like to install spice-vdagent for an improved desktop VM experience? [Y/n] '
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) InstallPKG spice-vdagent
                check_exit_status
                break
                ;;
                [Nn]* ) printf '\nSkipping installing Spice-vdagent.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    fi
    if ! CheckForPackage qemu-guest-agent; then
        while true; do
            printf '\nWould you like to install qemu-guest-agent for improved VM control and monitoring? [Y/n] '
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) InstallPKG qemu-guest-agent
                check_exit_status
                break
                ;;
                [Nn]* ) printf '\nSkipping installing qemu-guest-agent.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    fi
}

#Install NordVPN
InstallNordVPN() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ! CheckForPackage nordvpn; then
        if IsRoot; then
            while true; do
            printf '\nWould You like to install NordVPN? [y/N]'
            read -r yn
            yn=${yn:-N}
                case $yn in
                    [Yy]* ) sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
                    printf '\nRun this script again as user to finish setting up NordVPN.'
                    break
                    ;;
                    [Nn]* ) printf '\nSkipping installing NordVPN'
                    break
                    ;;
                    * ) AnswerYN
                    ;;
                esac
            done
        fi
    else
        if ! IsRoot; then
            printf '\nAdding %s to nordvpn group.' "$USER"
            sudo usermod -aG nordvpn $USER
            printf '\nReboot the computer to be able to login to NordVPN.'
        fi
    fi
}

#Install Refind for Dual Boot Systems
DualBootSetup() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ! CheckForPackage refind; then
        printf '\nRefind is a graphical bootloader that shows the icons of the installed operating systems.'
        while true; do
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
        done
    fi
}

#check process for errors and prompt user to exit script if errors are detected.
check_exit_status() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if [ $? -eq 0 ]; then
        printf '\nSuccess\n'
    else
        while true; do
            printf '\nError\nThe last command exited with an error. Exit script? (y/N) '
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) GoodBye
                ;;
                [Nn]* ) Proceeding
                break
                ;;
                *) AnswerYN
                ;;
            esac
        done
    fi
}

#Print Proceeding
Proceeding() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf "\nProceeding\n"
}

#Print Goodbye and exit the script
GoodBye() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf "\nGoodbye.\n"
    exit
}

AnswerYN() {
    printf '\nPlease answer yes or no.\n'
}

#Functions ---> ^ ^ ^ ^ ^ ^ ^ ^ <-----
#Script ------> V V V V V V V V <----- 


#Greet The User and Warn of using scripts that need root privilages.
Greeting
PKGMGR=apt
DefinedSHELL=/bin/bash
if IsRoot; then
    echo 'export LC_ALL=C.UTF-8' >> /etc/profile
    echo 'export LANG=C.UTF-8' >> /etc/profile
fi
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

#Setup Nala
if CheckForPackage nala; then
    PKGMGR=nala
elif CheckForPackage nala-legacy; then
    PKGMGR=nala
else
    if IsRoot; then
        printf "\nNala is a front-end for libapt-pkg with a variety of features such as parallel downloads, clear display of what is happening, and the ability to fetch faster mirrors."
        sleep 1s
        while true; do
            printf "\nWould you like to install Nala? [y/N]"
            read -r yn
            yn=${yn:-N}
            case $yn in
                [Yy]* ) SetupNala
                break
                ;;
                [Nn]* ) printf '\nSkipping Nala Setup.'
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
        PKGMGR=apt
    fi
fi

UpdateSoftware

if IsRoot; then
    if ! CheckForPackage vim; then
        while true; do
            printf '\nWould you like to install VIM? [y/N]'
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) InstallPKG vim
                break
                ;;
                [Nn]* ) printf '\nSkipping VIM setup'
                break
                ;;
                *) AnswerYN
                ;;
            esac
        done
    fi
fi

if IsRoot; then
    if ! CheckForPackage sudo; then
        while true; do
            printf '\nWould you like to install sudo? [y/N]'
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) InstallPKG sudo
                break
                ;;
                [Nn]* ) printf '\nSkipping sudo setup'
                break
                ;;
                *) AnswerYN
                ;;
            esac
        done
    fi
fi

SetupZSH

InstallFlatpak

InstallSnapd

SSHKeyGen

CPbashrc

CPvimrc

InstallNordVPN

CreateUsers

#Setup SpiceVD Agent for QEMU VMs.
if IsRoot; then
    while true; do
        printf '\nIs this system a QEMU based virtual machine? [y/N]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) VMSetup
            break
            ;;
            [Nn]* ) printf '\nSkipping VM setup'
            break
            ;;
            *) AnswerYN
            ;;
        esac
    done
fi

#Setup Refind for Dual Boot systems
if IsRoot; then
    while true; do
    printf '\nIs this system a dual boot system? [y/N]'
    read -r yn
    yn=${yn:-Y}
        case $yn in
            [Yy]* ) DualBootSetup
            break
            ;;
            [Nn]* ) printf '\nSkipping DualBoot setup'
            break
            ;;
            *) AnswerYN
            ;;
        esac
    done
fi

#Setup Yubikey Authentication
if IsRoot; then
    while true; do
        printf '\nWould you like to set up Yubikey authentication? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) InstallYubiSW
            CreateYubikeyOTP
            CreateYubikeyChalResp
            CPYubikeyFiles
            break
            ;;
            [Nn]* ) printf "\nSkipping Yubikey setup\n"
            break
            ;;
            * ) echo 'Please answer yes or no.'
            break
            ;;
        esac
    done
fi

#Install Recommended Apt Software

if IsRoot; then
    printf '\nNOTE: depending on your distribution and sources, apt packeges may not be the latest versions available.\nIf you want the latest version of something, install it from flatpak.'
    while true; do
        printf '\nWould you like to install apt packages? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]* ) while true; do
                printf '\nWould you like to install desktop apps? [Y/n]'
                read -r yn
                yn=${yn:-Y}
                case $yn in
                    [Yy]*) InstallAptDeskSW
                    break
                    ;;
                    [Nn]*) printf '\nSkipping Desktop Apps.'
                    break
                    ;;
                    *) AnswerYN
                    ;;
                esac
            done
            if ! CheckForEddy; then
                while true; do
                    printf 'Eddy is a graphical .deb package installer built for Elementary OS and Used in PopOS.'
                    printf 'Would you like to install Eddy [Y-yes Default / N-no / E-exit]? '
                    read -r yn
                    yn=${yn:-Y}
                    case $yn in
                        [Yy]*) InstallEddy
                        break
                        ;;
                        [Nn]*) printf '\nSkipping Eddy.'
                        break
                        ;;
                        *) AnswerYN
                        ;;
                    esac
                done
            else
                printf '\nSkipping Eddy, already installed.\n'
            fi
            while true; do
                printf '\nWould you like to install server and CLI apps? [Y/n]'
                read -r yn
                yn=${yn:-Y}
                case $yn in
                    [Yy]*) InstallAptServSW
                    break
                    ;;
                    [Nn]*) '\nSkipping Server and CLI apps.'
                    break
                    ;;
                    *) AnswerYN
                    ;;
                esac
            done
            break
            ;;
            [Nn]* ) printf "\nSkipping apt packages\n"
            break
            ;;
            * ) AnswerYN
            ;;
        esac
    done
fi

#Remove Unnescessary Gnome Apps
if IsRoot; then
    printf '\nNOTE: If you are using GNOME, unnecessary apps such as games may be installed.'
    while true; do
        printf '\nWould you like to remove unnecessary apps? [Y/n]'
        read -r yn
        yn=${yn:-Y}
        case $yn in
            [Yy]*) removeUnnecessaryApps
            break
            ;;
            [Nn]*) printf '\nSkipping unnecessary packages removal.\n'
            break
            ;;
            *) AnswerYN
            ;;
        esac
    done
fi

#Install Recommended Flatpak Software
if ! IsRoot; then
    if CheckForPackage flatpak; then
        while true; do
            printf '\nWould you like to install Flatpak apps? [Y/n]'
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) InstallFlatpakSW
                break
                ;;
                [Nn]* ) printf "\nSkipping Flatpak apps\n"
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
        printf '\nFlatpak is not installed. Skipping flatpak apps.'
    fi
else
    printf '\nYou are running this script as root. To install Flatpak apps, you should run this script again without root or sudo.'
fi

#Install Recommended snap packages
if IsRoot; then
    if CheckForPackage snapd; then
        while true; do
            printf '\nWould you like to install Snap packages? [Y/n]'
            read -r yn
            yn=${yn:-Y}
            case $yn in
                [Yy]* ) InstallSnapSW
                break
                ;;
                [Nn]* ) printf "\nSkipping Snap apps\n"
                break
                ;;
                * ) AnswerYN
                ;;
            esac
        done
    else
        printf '\nSnapd is not installed. Skipping Snap Packages.'
    fi
fi

#Install Firestorm Viewer for Second Life
while true; do
    printf '\nWould you like to install Firestorm Second Life Viewer? [y/N]'
    read -r yn
    yn=${yn:-Y}
    case $yn in
        [Yy]* ) if IsRoot; then
        InstallFirestorm
        else
            while true; do
                printf '\nYou are not root, installing firestorm as user will install to your home directory. Proceed? [Y/n]'
                read -r yn
                yn=${yn:-N}
                case $yn in
                    [Yy]* ) InstallFirestorm
                    break
                    ;;
                    [Nn]* ) printf '\nSkipping Firestorm Installation.'
                    break
                    ;;
                    *) AnswerYN
                    ;;
                esac
            done                
        fi
        break
        ;;
        [Nn]* ) printf '\nSkipping Firestorm Installation.'
        break
        ;;
        * ) AnswerYN
        ;;
    esac
done

GoodBye