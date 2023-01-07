#!/bin/bash

# This is a general-purpose function to ask Yes/No questions in Bash, either
# with or without a default answer. It keeps repeating the question until it
# gets a valid answer.
ask() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
  # https://djm.me/ask
  local prompt default reply

  while true; do

    if [[ "${2:-}" == "Y" ]]; then
      prompt="Y/n"
      default=Y
    elif [[ "${2:-}" == "N" ]]; then
      prompt="y/N"
      default=N
    else
      prompt="y/n"
      default=
    fi

    # Ask the question (not using "read -p" as it uses stderr not stdout)
    printf '%s ' $1 $prompt

    read reply

    # Default?
    if [[ -z "$reply" ]]; then
      reply=${default}
    fi

    # Check if the reply is valid
    case "$reply" in
    Y* | y*) return 0 ;;
    N* | n*) return 1 ;;
    esac

  done
}

Greeting () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf '\nHello!\nWelcome to my post install script for debian\n and debian based distributions.\n\nDISCLAIMER\nIt is not recommended that you run scripts that you find on the internet without knowing exactly what they do.\n\n
This script contains functions that require root privilages.\n'
    sleep 1s
    if ask "Do you wish to proceed?" N; then
        Proceeding
        ScriptDirCheck
        RootCheck
    else
        GoodBye
    fi
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
        sleep 1s
    else 
        printf "\nThis script is not being run as root.\n\nParts that require root privileges will be skipped.\n"
    fi
    if ask "Proceed?" Y; then
        Proceeding
    else
        GoodBye
    fi
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
        UpdateApt
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
    if ask "Would you like to update the apt repositories?" Y; then
        $PKGMGR update;
        check_exit_status
    else
        printf '\nSkipping repository updates.'
    fi
    if ask "Would you like to install the apt software updates?" Y; then
        if $PKGMGR=nala; then
            $PKGMGR upgrade -y;
            check_exit_status
            $PKGMGR autoremove -y;
            check_exit_status
            $PKGMGR clean -y;
            check_exit_status
        else
            $PKGMGR dist-upgrade --allow-downgrades -y;
            check_exit_status
            $PKGMGR autoremove -y;
            check_exit_status
            $PKGMGR autoclean -y;
            check_exit_status
        fi
    else
        printf '\nSkipping package upgrades.'
    fi
}

#Update Snap packages
UpdateSnap() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if CheckForPackage snapd; then
        if ask "" Y; then
            snap refresh
            check_exit_status
        else
            printf '\nSkipping Snap Update.'
        fi
    else
        printf "Snapd is not installed, skipping snap updates."
    fi
}

#Update Flatpak packages
UpdateFlatpak() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if CheckForPackage flatpak; then
        if ask "Would you like to update the Flatpak Packages?" Y; then
            flatpak update
            check_exit_status
        else
            printf '\nSkipping Flatpak Update'
        fi
    else
        printf "Flatpak is not installed, skipping Flatpak updates."
    fi
}

#CreateUsers
CreateUsers() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ask "\nWould you like to add users?" N; then
        AddUsers
        while true; do
            if ask "\nWould you like to add another user?" N; then
                AddUsers
                continue
            else
                printf '\nSkipping adding users.'
                break
            fi
        done
    else
        printf '\nSkipping adding users.'
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
    if [ CheckForPackage sudo ] && [ ask "\nWould you like to add this user to the sudo group?" N ]; then
        usermod -aG sudo $definedusername
    else
        printf '\nSkipping making user sudo.'
    fi
}
    
#SetupZSH
SetupZSH() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if ! CheckForPackage zsh; then
            if ask "Would you like to setup ZSH?" Y; then
                $PKGMGR install -y zsh zsh-syntax-highlighting zsh-autosuggestions
                check_exit_status
                DefinedSHELL=/bin/zsh
                usermod --shell $DefinedSHELL root
                CopyZshrcFile
            else
                printf '\nSkipping ZSH Setup.'
            fi
        fi
    fi
    if ask "\nWould you like to set ZSH as your shell?" Y; then
        DefinedSHELL=/bin/zsh
        chsh -s $DefinedSHELL
        CopyZshrcFile
    else
        printf '\nSkipping zsh Setup.'
    fi
}

#CopyZshrcFile
CopyZshrcFile() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        if ask "\nWould you like to copy the zshrc file included with this script to your home directory?" Y; then
            rcfile=./rcfiles/zshrc
            if [[ -f "$rcfile" ]]; then
                cp ./rcfiles/zshrc /root/.zshrc
                cp ./rcfiles/zshrc /etc/skel/.zshrc
            else
                printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."
            fi
        else
            printf "\nSkipping zshrc file."
        fi
    elif CheckForPackage zsh; then
        if ask "\nWould you like to copy the zshrc file included with this script to your home directory?" Y; then
            rcfile=./rcfiles/zshrc
            if [[ -f "$rcfile" ]]; then
                cp ./rcfiles/zshrc /home/$USER/.zshrc
            else
                printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."                
            fi
        else
            printf "\nSkipping zshrc file."
        fi
    fi
}

#Generate SSH Key with comment
SSHKeyGen () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf '\nPlease enter a type [RSA/dsa]: '
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
}

#Copy bashrc and vimrc to home folder
CPbashrc () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf '\nNOTE: You are running this script as root. The bashrc file here will be copied to the /root and /etc/skel/ directories.\n'
    fi
    if ask "\nWould you like to copy the bashrc file included with this script to your home folder?" Y; then
        if IsRoot; then
            cp ./rcfiles/bashrc ~/.bashrc
            cp ./rcfiles/bashrc /etc/skel/.bashrc
        else
            cp ./rcfiles/bashrc ~/.bashrc
        fi
    else
        printf '\nSkipping bashrc file.\n'
    fi
}

CPvimrc () {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if IsRoot; then
        printf '\nNOTE: You are running this script as root. The vimrc file here will be copied to the /root and /etc/skel/ directories.\n'
    fi
    if ask "Would you like to copy the vimrc file included with this script to your home folder?" Y; then
        if IsRoot; then
            cp ./rcfiles/vimrc ~/.vimrc
            cp ./rcfiles/vimrc /etc/skel/.vimrc
        else
            cp ./rcfiles/vimrc ~/.vimrc
        fi
    else
        printf '\nSkipping vimrc file.\n'
    fi
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
    if ! CheckForPackage snapd; then
        if ask "Would you like to install snapd?" N; then
            InstallPKG snapd
            snap install core
            if CheckForPackage gnome-software; then
                InstallPKG gnome-software-plugin-snap
            fi
            check_exit_status
        else
            printf '\nSkipping %s\n' "snapd"
        fi
    else
        printf '\nSkipping %s, already installed.\n' "snapd"
    fi
}
#Install flatpak
InstallFlatpak() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ! CheckForPackage flatpak; then
        if ask "Would you like to install flatpak?" N; then
            printf '\nInstalling %s\n' "flatpak"
            InstallPKG flatpak
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            if CheckForPackage gnome-software; then
                InstallPKG gnome-software-plugin-flatpak
            fi
            check_exit_status
        else
            printf '\nSkipping %s\n' "flatpak"
        fi
    else
        printf '\nSkipping %s, already installed.\n' "flatpak"
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
    file='./apps/apt-desktop-apps'
    while read -r line <&3; do
        if ! CheckForPackage $1; then
            if ask "Would you like to install $line?" N; then
                $PKGMGR install -y "$line"
            else
                printf '\nSkipping %s\n' "$line"
            fi
        else
            printf '\nSkipping %s, already installed.\n' "$1"
        fi     
    done 3< "$file"
}

#Install Selected server Apt packages
InstallAptServSW() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    file='./apps/apt-server-apps'
    while read -r line <&3; do
        if ! CheckForPackage $1; then
            if ask "Would you like to install $line?" N; then
                $PKGMGR install -y "$line"
            else
                printf '\nSkipping %s\n' "$line"
            fi
        else
            printf '\nSkipping %s, already installed.\n' "$1"
        fi    
    done 3< "$file"
}

#Remove Unnecessary Apps
removeUnnecessaryApps() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    file='./apps/apt-unnecessary-apps'
    while read -r line <&3; do
        if CheckForPackage $1; then
            if ask "Would you like to remove $line?" N; then
                $PKGMGR remove -y "$line"
            else
                printf '\nSkipping %s\n' "$line"
            fi
        else
            printf '\nSkipping %s, not installed.\n' "$1"
        fi   
    done 3< "$file"
    $PKGMGR autoremove
}

#Install Selected Flatpak apps
InstallFlatpakSW() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    file='./apps/flatpak-apps'
    while read -r line <&3; do
        if ask "Would you like to install $line?" N; then
            flatpak install -y "$line"
        else
            printf '\nSkipping %s\n' "$line"
        fi
    done 3< "$file"
}

#Install Selected Snap packages
InstallSnapSW() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    file='./apps/snap-apps'
    while read -r line <&3; do
        if ask "Would you like to install $line?" N; then
            snap install -y "$line"
        else
            printf '\nSkipping %s\n' "$line"
        fi
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
    if ask "Would you like to program challenge reponse keys on your yubikey?" N; then
        ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible;
        if ask "Would you like to program challenge reponse keys on another yubikey?" N; then
            printf '\nPlease insert your next yubikey and press any key to continue.'
            read -rsn1
            ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible;
        else
            printf "Skipping."
        fi
    else
        printf "Skipping."
    fi
    printf '\nNow creating Yubikey Challenge Response files.\n'
    ykpamcfg -2 -v
    if ask "Would you like to add another yubikey?" N; then
        printf '\nPlease insert your next yubikey and press any key to continue.'
        read -rsn1
        ykpamcfg -2 -v
    else
        printf '\nSkipping.'
    fi
}
#Set up Yubikey for Challange Response Authentication
CreateYubikeyOTP() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf '\nSetting up OTP (One Time Password) Authentication.\n'
    authkeys=$USER
    printf '\nPlease touch your Yubikey.'
    read -r ykey
    ykey12=${ykey:0:12}
    authkeys+=':'
    authkeys+="$ykey12"
    if ask "Would you like to add another Yubikey?" N; then
        printf '\nPlease touch your Yubikey.'
        read -r ykey
        ykey12=${ykey:0:12}
        authkeys+=':'
        authkeys+="$ykey12"
    else
        printf '\nSkipping.\n'
        echo $authkeys | tee >> ./authorized_yubikeys;
    fi
    echo $authkeys | tee >> ./authorized_yubikeys
    printf '\nKeys saved to ./authorized_yubikeys.'
}

#Copy Key files and PAM rules
CPYubikeyFiles() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    printf 'Creating key directories and copying key files to appropriate locations. You may need to manually edit some files.'
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
        if ask "Would you like to install spice-vdagent for an improved desktop VM experience?" N; then
            InstallPKG spice-vdagent
            check_exit_status
        else
            printf '\nSkipping installing Spice-vdagent.'
        fi
    fi
    if ! CheckForPackage qemu-guest-agent; then
        if ask "Would you like to install qemu-guest-agent for improved VM control and monitoring" N; then
            InstallPKG qemu-guest-agent
            check_exit_status
        else
            printf '\nSkipping installing qemu-guest-agent.'
        fi
    fi
}

#Install NordVPN
InstallNordVPN() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ! CheckForPackage nordvpn; then
        if IsRoot; then
            if ask "Would You like to install NordVPN?" N; then
                sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
                printf '\nRun this script again as user to finish setting up NordVPN.\nPress any key to continue.'
                read -rsn1
            else
                '\nSkipping installing NordVPN'
            fi
        fi
    else
        if ! IsRoot; then
            printf '\nAdding %s to nordvpn group.' "$USER"
            sudo usermod -aG nordvpn $USER
            printf '\nReboot the computer to be able to login to NordVPN.\nPress any key to continue.'
            read -rsn1
        fi
    fi
}

#Install Refind for Dual Boot Systems
DualBootSetup() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if ! CheckForPackage refind; then
        printf '\nRefind is a graphical bootloader that shows the icons of the installed operating systems.'
        if ask "Would you like to install refind?" N; then
            InstallPKG refind
        else
            printf '\nSkipping installing refind.'
        fi
    fi
}

#check process for errors and prompt user to exit script if errors are detected.
check_exit_status() {
    printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
    if [ $? -eq 0 ]; then
        printf '\nSuccess\n'
    else
        printf '\nError\nThe last command exited with an error.'
        if ask "Exit script?" N; then
            GoodBye
        else
            Proceeding
        fi
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
        printf "Nala is a front-end for libapt-pkg with a variety of features such as parallel downloads, clear display of what is happening, and the ability to fetch faster mirrors."
        if ask "Would you like to install Nala?" N; then
            SetupNala
        else
            printf '\nSkipping Nala Setup.'
        fi
    else
        PKGMGR=apt
    fi
fi

UpdateSoftware

if IsRoot; then
    if ! CheckForPackage vim; then
        if ask "Would you like to install VIM?" Y; then
            InstallPKG vim
        else
            printf '\nSkipping VIM install'
        fi
    fi
fi

if IsRoot; then
    if ! CheckForPackage sudo; then 
        if ask "Would you like to install sudo?" Y; then
            InstallPKG sudo
        else
            printf '\nSkipping sudo setup'
        fi
    fi
fi

SetupZSH

if IsRoot; then
    InstallFlatpak
    InstallSnapd
fi

if IsRoot; then
    printf "\nNOTE: You are running this script as Root, or with Sudo. The SSH Key generated will be for the root user."
    if ask "Would you like to generate an SSH key?" N; then
        SSHKeyGen
    else
        printf '\nSSH Key Not generated\n'
    fi
    if ask "Would you like to generate an SSH key?" N; then
        SSHKeyGen
    else
       printf '\nSSH Key Not generated\n'
    fi
fi

CPbashrc

CPvimrc

if IsRoot; then
    InstallNordVPN
    CreateUsers
fi

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
    if ask "Would you like to install apt packages?" N; then
        if ask "Would you like to install desktop apps?" N; then
            InstallAptDeskSW
            if ! CheckForEddy; then
                printf 'Eddy is a graphical .deb package installer built for Elementary OS and Used in PopOS.'
                if ask "Would you like to install Eddy?" N; then
                    InstallEddy
                else
                    printf '\nSkipping Eddy.'
                fi
            else
                printf '\nSkipping Eddy, already installed.\n'
            fi
        else
            printf '\nSkipping Desktop Apps.'
        fi
        if ask "Would you like to install server and CLI apps?" N; then
            InstallAptServSW
        else
            printf '\nSkipping Server and CLI apps.'
        fi
    else
        printf "\nSkipping apt packages\n"
    fi
fi

#Remove Unnescessary Gnome Apps
if IsRoot; then
    printf '\nNOTE: If you are using GNOME, unnecessary apps such as games may be installed.'
    if ask "Would you like to remove unnecessary apps?" N; then
        removeUnnecessaryApps
    else
        printf '\nSkipping unnecessary packages removal.\n'
    fi
fi

#Install Recommended Flatpak Software
if ! IsRoot; then
    if CheckForPackage flatpak; then
        if ask "Would you like to install Flatpak apps?" N; then
            InstallFlatpakSW
        else
            printf "\nSkipping Flatpak apps\n"
        fi
    else
        printf '\nFlatpak is not installed. Skipping flatpak apps.'
    fi
else
    printf '\nYou are running this script as root. To install Flatpak apps, you should run this script again without root or sudo.'
fi

#Install Recommended snap packages
if IsRoot; then
    if CheckForPackage snapd; then
        if ask "Would you like to install Snap apps?" N; then
            InstallSnapSW
        else
            printf "\nSkipping Snap apps\n"
        fi
    else
        printf '\nSnapd is not installed. Skipping Snap apps.'
    fi
fi

#Install Firestorm Viewer for Second Life
if ask "Would you like to install Firestorm Second Life Viewer?" N; then
    if IsRoot; then
        InstallFirestorm
    else
        printf "\nYou are not root, installing firestorm as user will install to your home directory."
        if ask "Proceed?" N; then
            InstallFirestorm
        else
           printf '\nSkipping Firestorm Installation.'
        fi
    fi
else
    printf '\nSkipping Firestorm Installation.'
fi

GoodBye