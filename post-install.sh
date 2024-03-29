#!/bin/bash

# This is a general-purpose function to ask Yes/No questions in Bash, either
# with or without a default answer. It keeps repeating the question until it
# gets a valid answer.
ask() {
  #printf '\n--> Function: %s <--\n' "${FUNCNAME[0]}"
  # https://djm.me/ask
  local prompt default reply

  while true; do

    if [[ "${2:-}" == "Y" ]]; then
      prompt="[Y/n]"
      default=Y
    elif [[ "${2:-}" == "N" ]]; then
      prompt="[y/N]"
      default=N
    else
      prompt="[y/n]"
      default=
    fi

    # Ask the question (not using "read -p" as it uses stderr not stdout)
    printf '\n'
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
    printf '\nHello!\nWelcome to my post install script for debian\nand debian based distributions.\n\nDISCLAIMER\nIt is not recommended that you run scripts that you find on the internet without knowing exactly what they do.\n\nThis script contains functions that require root privilages.\n'
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
    if [[ $EUID = 0 ]]; then
      return 0
      else
      return 1
    fi
}

#Check for Root and inform user that the script has parts that require root and parts for non-root users.
RootCheck() {
    if IsRoot; then
        printf "\nThis script is being run as root.\n\nCertain parts of this script should be run as a non-root user or without sudo.
        \nRun the script again for those parts.\
        \nFor example if you install flatpak, the apps should be installed as user.\n"
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
# If CheckForPackage package; then
# package is not installed.
# If ! CheckForPackage package; then
# package is installed.
CheckForPackage() {
    return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}     

UpdateSoftware() {
    if IsRoot; then
        printf '\nUpdating Software.\nNote: To Update Flatpak software, run this script without root or sudo.\n'
        UpdateApt
        UpdateSnap;
    elif ! CheckForPackage flatpak; then
      UpdateFlatpak;
    else   
      printf '\nSkipping Updates.\n'
    fi
}


#Update and upgrade apt packages repos
UpdateApt () {
    if ask "Would you like to update the apt repositories?" Y; then
        $PKGMGR update;
        check_exit_status
    else
        printf '\nSkipping repository updates.\n'
    fi
    if ask "Would you like to install the apt software updates?" Y; then
        if [ $PKGMGR=nala ]; then
            $PKGMGR upgrade -y;
            check_exit_status
            $PKGMGR autoremove -y;
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
        printf '\nSkipping package upgrades.\n'
    fi
}

#Update Snap packages
UpdateSnap() {
    if ! CheckForPackage snapd; then
        if ask "Would you like to update snap packages?" Y; then
            snap refresh
            check_exit_status
        else
            printf '\nSkipping Snap Update.\n'
        fi
    else
        printf "Snapd is not installed, skipping snap updates.\n"
    fi
}

#Update Flatpak packages
UpdateFlatpak() {
    if ! CheckForPackage flatpak; then
        if ask "Would you like to update the Flatpak Packages?" Y; then
            flatpak update
            check_exit_status
        else
            printf '\nSkipping Flatpak Update.\n'
        fi
    else
        printf "Flatpak is not installed, skipping Flatpak updates.\n"
    fi
}

#CreateUsers
CreateUsers() {
    if ask "Would you like to add users?" N; then
        AddUsers
        while true; do
            if ask "Would you like to add another user?" N; then
                AddUsers
                continue
            else
                printf '\nSkipping adding users.\n'
                break
            fi
        done
    else
        printf '\nSkipping adding users.\n'
    fi
}

#AddUsers
AddUsers() {
    definedusername=''
    printf '\nEnter username: '
    read definedusername
    useradd -m -s $DefinedSHELL $definedusername 
    passwd $definedusername
    MakeUserSudo
}

#Add Defined User to Sudo group
MakeUserSudo() {
    if CheckForPackage sudo; then
        if ask "Would you like to add this user to the sudo group?" N ]; then
            usermod -aG sudo $definedusername
        else
            printf '\nSkipping adding user to sudo group.\n'
        fi
    else
        printf '\nSudo not installed, skipping adding user to sudo group.\n'
    fi
}
    
#SetupZSH
SetupZSH() {
    if IsRoot; then
        if CheckForPackage zsh; then
            if ask "Would you like to setup ZSH?" Y; then
                $PKGMGR install -y zsh zsh-syntax-highlighting zsh-autosuggestions
                check_exit_status
                DefinedSHELL=/bin/zsh
                usermod --shell $DefinedSHELL root
                CopyZshrcFile
            else
                printf '\nSkipping ZSH Setup.\n'
            fi
        fi
    fi
    if ask "Would you like to set ZSH as your shell?" Y; then
        DefinedSHELL=/bin/zsh
        chsh -s $DefinedSHELL
        CopyZshrcFile
    else
        printf '\nSkipping zsh Setup.\n'
    fi
}

#CopyZshrcFile
CopyZshrcFile() {
    if IsRoot; then
        if ask "Would you like to copy the zshrc file included with this script to your home directory?" Y; then
            rcfile=./rcfiles/zshrc
            if [[ -f "$rcfile" ]]; then
                cp ./rcfiles/zshrc /root/.zshrc
                cp ./rcfiles/zshrc /etc/skel/.zshrc
            else
                printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."
            fi
        else
            printf "\nSkipping zshrc file.\n"
        fi
    elif ! CheckForPackage zsh; then
        if ask "Would you like to copy the zshrc file included with this script to your home directory?" Y; then
            rcfile=./rcfiles/zshrc
            if [[ -f "$rcfile" ]]; then
                cp ./rcfiles/zshrc /home/$USER/.zshrc
            else
                printf "\nThe zshrc file is not in the expected path. Please run this script from inside the script directory."                
            fi
        else
            printf "\nSkipping zshrc file.\n"
        fi
    fi
}

#Generate SSH Key with comment
SSHKeyGen () {
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
    if IsRoot; then
        printf '\nNOTE: You are running this script as root.\nThe bashrc file here will be copied to the /root and /etc/skel/ directories.\n'
    fi
    if ask "Would you like to copy the bashrc file included with this script to your home folder?" Y; then
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
    if IsRoot; then
        printf '\nNOTE: You are running this script as root.\nThe vimrc file here will be copied to the /root and /etc/skel/ directories.\n'
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
    $PKGMGR install -y $1
    check_exit_status;
}
#Remove specified Package
RemovePKG() {
    $PKGMGR remove -y $1
    check_exit_status;
}
#Install specified Package
InstallSnapd() {
    if CheckForPackage snapd; then
        if ask "Would you like to install snapd?" N; then
            InstallPKG snapd
            snap install core
            if ! CheckForPackage gnome-software; then
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
    if CheckForPackage flatpak; then
        if ask "Would you like to install flatpak?" N; then
            printf '\nInstalling %s\n' "flatpak"
            InstallPKG flatpak
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
            if ! CheckForPackage gnome-software; then
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

#Install Selected desktop Apt packages
InstallAptDeskSW() {
    file='./apps/apt-desktop-apps'
    while read -r line <&3; do
        if CheckForPackage $line; then
            printf "\n%s is not installed." "$line"
            if ask "Would you like to install $line?" N; then
                $PKGMGR install -y "$line"
            else
                printf '\nSkipping %s\n' "$line"
            fi
        else
            printf '\nSkipping %s, already installed.\n' "$line"
        fi     
    done 3< "$file"
}

#Install Selected server Apt packages
InstallAptServSW() {
    file='./apps/apt-server-apps'
    while read -r line <&3; do
        if CheckForPackage $line; then
            printf "\n%s is not installed." "$line"
            if ask "Would you like to install $line?" N; then
                $PKGMGR install -y "$line"
            else
                printf '\nSkipping %s\n' "$line"
            fi
        else
            printf '\nSkipping %s, already installed.\n' "$line"
        fi    
    done 3< "$file"
}

#Remove Unnecessary Apps
removeUnnecessaryApps() {
    file='./apps/apt-unnecessary-apps'
    while read -r line <&3; do
        if ! CheckForPackage $line; then
            printf "\n%s is installed." "$line"
            if ask "Would you like to remove $line?" Y; then
                $PKGMGR remove -y "$line"
            else
                printf '\nSkipping %s\n' "$line"
            fi
        else
            printf '\nSkipping %s, not installed.\n' "$line"
        fi   
    done 3< "$file"
    $PKGMGR autoremove
}

#Install Selected Flatpak apps
InstallFlatpakSW() {
    file='./apps/flatpak-apps'
    while read -r line <&3; do
        if ask "Would you like to install $line?" N; then
            flatpak install -y "$line"
        else
            printf '\nSkipping %s\n' "$line"
        fi
    done 3< "$file"
}

#Install Discord Deb
InstallDiscord() {
    if ask "Would you like to install Discord(DEB)?" Y; then
        printf '\nDownloading Discord deb package.\n'
        wget "https://discord.com/api/download?platform=linux&format=deb"
        printf '\nInstalling Discord.\n'
        dpkg -i ./discord-*.deb
    else
        printf '\nSkipping Installing Discord (DEB).\n'
    fi
}

#Install Steam Deb
InstallSteam() {
    if ask "Would you like to install Steam(DEB)?" Y; then
        printf '\nDownloading Steam deb package.\n'
        wget "hhttps://cdn.cloudflare.steamstatic.com/client/installer/steam.deb"
        printf '\nInstalling Steam.\n'
        dpkg -i ./steam-latest.deb
    else
        printf '\nSkipping Installing Steam (DEB).\n'
    fi
}

#Install Selected Snap packages
InstallSnapSW() {
    file='./apps/snap-apps'
    while read -r line <&3; do
        if ask "Would you like to install $line?" N; then
            snap install -y "$line"
        else
            printf '\nSkipping %s\n' "$line"
        fi
    done 3< "$file"
}

#Install Yubikey Packages
InstallYubiSW() {
    printf '\nInstalling Required Packages for yubikey authentication.'
    InstallPKG libpam-yubico
    InstallPKG libpam-u2f
    InstallPKG yubikey-manager
    InstallPKG yubikey-personalization

}
#Set up Yubikey for One Time Password Authentication
CreateYubikeyChalResp() {
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
            printf "Skipping.\n"
        fi
    else
        printf "Skipping.\n"
    fi
    printf '\nNow creating Yubikey Challenge Response files.\n'
    ykpamcfg -2 -v
    if ask "Would you like to add another yubikey?" N; then
        printf '\nPlease insert your next yubikey and press any key to continue.'
        read -rsn1
        ykpamcfg -2 -v
    else
        printf '\nSkipping.\n'
    fi
}
#Set up Yubikey for Challange Response Authentication
CreateYubikeyOTP() {
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
    if CheckForPackage spice-vdagent; then
        if ask "Would you like to install spice-vdagent for an improved desktop VM experience?" N; then
            InstallPKG spice-vdagent
            check_exit_status
        else
            printf '\nSkipping installing Spice-vdagent.\n'
        fi
    fi
    if CheckForPackage qemu-guest-agent; then
        if ask "Would you like to install qemu-guest-agent for improved VM control and monitoring" N; then
            InstallPKG qemu-guest-agent
            check_exit_status
        else
            printf '\nSkipping installing qemu-guest-agent.\n'
        fi
    fi
    if ! CheckForPackage spice-vdagent; then
        printf "Sometimes, the VM doesn't resize automatically. If that's the case this part of the script can usually fix that."
        if ask "Would you like to apply the resize VM fix?" N; then
            ResizeVM
        else
            printf "\nSkipping Resize Fix.\n"
        fi
    else
        printf "\nSpice-vdagent not installed, Skipping resize VM fix.\n"
    fi
}

#Setup Automatic VM Resizing credit to DannyDa.
ResizeVM () {
    mkdir -p /usr/local/bin
    mkdir -p /etc/udev/rules.d
    cp ./resize/x-resize /usr/local/bin/x-resize
    cp ./resize/50-x-resize.rules /etc/udev/rules.d/50-x-resize.rules
    chmod +x /usr/local/bin/x-resize
}

#Install NordVPN
InstallNordVPN() {
    if CheckForPackage nordvpn; then
        if IsRoot; then
            if ask "Would You like to install NordVPN?" N; then
                InstallPKG curl
                check_exit_status
                sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
                printf '\nRun this script again as user to finish setting up NordVPN.\nPress any key to continue.\n'
                read -rsn1
            else
                printf '\nSkipping installing NordVPN,\n'
            fi
        fi
    else
        if ! IsRoot; then
            printf '\nAdding %s to nordvpn group.' "$USER"
            sudo usermod -aG nordvpn $USER
            printf '\nReboot the computer to be able to login to NordVPN.\nPress any key to continue.\n'
            read -rsn1
        fi
    fi
}

#Install Refind for Dual Boot Systems
DualBootSetup() {
    if CheckForPackage refind; then
        printf '\nRefind is a graphical bootloader that shows the icons of the installed operating systems.'
        if ask "Would you like to install refind?" N; then
            InstallPKG refind
        else
            printf '\nSkipping installing refind.\n'
        fi
    fi
}

#check process for errors and prompt user to exit script if errors are detected.
check_exit_status() {
    if [ $? -eq 0 ]; then
        printf '\nSuccess\n'
    else
        printf '\nError\nThe last command exited with an error.\n'
        if ask "Exit script?" N; then
            GoodBye
        else
            Proceeding
        fi
    fi
}

#Print Proceeding
Proceeding() {
    printf "\nProceeding\n"
}

#Print Goodbye and exit the script
GoodBye() {
    printf "\nGoodbye.\n"
    exit
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
if IsRoot; then
    if CheckForPackage nala; then
        printf "Nala is a front-end for libapt-pkg with a variety of features such as parallel downloads, clear display of what is happening, and the ability to fetch faster mirrors."
        if ask "Would you like to install Nala?" N; then
            $PKGMGR update
            InstallPKG nala
            PKGMGR=nala
        elif ! CheckForPackage nala; then
            printf '\nNala is installed.\n'
            PKGMGR=nala
            if ask "Would you like to run Nala Fetch (for Ubuntu/Debian) to find the fastest mirrors?" Y; then
                nala fetch
            fi
        else
            printf '\nSkipping Nala Setup.\n'
        fi
    elif ! CheckForPackage nala; then
        PKGMGR=nala
        if ask "Would you like to run Nala Fetch (for Ubuntu/Debian) to find the fastest mirrors?" Y; then
            nala fetch
        fi
    else
        PKGMGR=apt
    fi
fi

UpdateSoftware

if IsRoot; then
    if CheckForPackage vim; then
        if ask "Would you like to install VIM?" Y; then
            InstallPKG vim
        else
            printf '\nSkipping VIM install.\n'
        fi
    fi
fi

if IsRoot; then
    if CheckForPackage sudo; then 
        if ask "Would you like to install sudo?" Y; then
            InstallPKG sudo
        else
            printf '\nSkipping sudo setup.\n'
        fi
    fi
fi

SetupZSH

if IsRoot; then
    InstallFlatpak
    InstallSnapd
fi

if IsRoot; then
    printf "\nNOTE: You are running this script as Root, or with Sudo. The SSH Key generated will be for the root user.\n"
    if ask "Would you like to generate an SSH key?" N; then
        SSHKeyGen
    else
        printf '\nSSH Key Not generated\n'
    fi
else
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
    if ask "Is this system a QEMU based virtual machine?" N; then
        VMSetup
    else
        printf '\nSkipping VM setup.\n'
    fi
fi

#Setup Refind for Dual Boot systems
if IsRoot; then
    if ask "Is this system a dual boot system?" N; then
        DualBootSetup
    else
        printf '\nSkipping DualBoot setup.\n'
    fi
fi

#Setup Yubikey Authentication
if IsRoot; then
    if ask "Would you like to set up Yubikey authentication?" N; then
        InstallYubiSW
        CreateYubikeyOTP
        CreateYubikeyChalResp
        CPYubikeyFiles
    else
        printf "\nSkipping Yubikey setup.\n"
    fi
fi

#Install Recommended Apt Software

if IsRoot; then
    printf '\nNOTE: depending on your distribution and sources, apt packeges may not be the latest versions available.\nIf you want the latest version of something, install it from flatpak.'
    if ask "Would you like to install apt packages?" N; then
        if ask "Would you like to install desktop apps?" N; then
            InstallAptDeskSW
        else
            printf '\nSkipping Desktop Apps.\n'
        fi
        if ask "Would you like to install server and CLI apps?" N; then
            InstallAptServSW
        else
            printf '\nSkipping Server and CLI apps.\n'
        fi
    else
        printf "\nSkipping apt packages\n"
    fi
fi

#Install Discord DEB
if IsRoot; then
    if ! CheckForPackage discord; then
        printf '\nNOTE: Discord can be installed as a deb package which requires root, or as a flatpak. If you wish to install the flatpak version of Discord, skip this step.\n'
        InstallDiscord
    else
        printf '\nSkipping Discord Already Installed.\n'
    fi
fi

#Install Steam DEB
if IsRoot; then
    if ! CheckForPackage steam; then
        printf '\nNOTE: Steam can be installed as a deb package which requires root, or as a flatpak. If you wish to install the flatpak version of Steam, skip this step.\n'
        InstallSteam
    else
        printf '\nSkipping Steam Already Installed.\n'
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
    if ! CheckForPackage flatpak; then
        if ask "Would you like to install Flatpak apps?" N; then
            InstallFlatpakSW
        else
            printf "\nSkipping Flatpak apps\n"
        fi
    else
        printf '\nFlatpak is not installed. Skipping flatpak apps.\n'
    fi
else
    printf '\nYou are running this script as root. To install Flatpak apps, you should run this script again without root or sudo.\n'
    sleep 1s
fi

#Install Recommended snap packages
if IsRoot; then
    if ! CheckForPackage snapd; then
        if ask "Would you like to install Snap apps?" N; then
            InstallSnapSW
        else
            printf "\nSkipping Snap apps\n"
        fi
    else
        printf '\nSnapd is not installed. Skipping Snap apps.\n'
    fi
fi

GoodBye
