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

Greeting