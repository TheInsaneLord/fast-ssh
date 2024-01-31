#!/bin/bash

# variables
user=$(whoami)
sshpath="/home/$user/.ssh"
keychoice='none'
remoteuser='none'
remoteip='0.0.0.0'
num_columns=3
ignore_files=("hosts.txt" "known_hosts" "known_hosts.old")
files=()
choice=0
existinghost="$sshpath/hosts.txt"

# Functions

listkeys() {
    # Populate the array of files, excluding specified files
    for file in $(ls -1 "$sshpath"); do
        if [[ ! " ${ignore_files[@]} " =~ " $file " ]]; then
            files+=("$file")
        fi
    done
}

sshconnect() {
    disply
    listkeys

    # Get a list of available SSH keys
    echo "Here are SSH keys from < $sshpath >:"
    for ((i=0; i<${#files[@]}; i++)); do
        printf "%-3s %-25s" "$((i+1))." "${files[i]}"
        if (( (i+1) % num_columns == 0 )); then
            echo
        fi
    done

    # Add a newline if the last row is not complete
    if (( ${#files[@]} % num_columns != 0 )); then
        echo
    fi

    # Get the selected key
    read -p "Please enter the number corresponding to the key you want to use: " key_number

    # Debug: Display selected key number
    echo "DEBUG: Selected key number: $key_number"

    # Validate the user input
    if ! [[ "$key_number" =~ ^[1-${#files[@]}]$ ]]; then
        echo "Invalid selection. Please enter a number between 1 and ${#files[@]}."
        exit 1
    fi

    # Get the selected key
    keychoice="${files[key_number-1]}"

    # Debug: Display selected key
    echo "DEBUG: Selected key: $keychoice"

    # Check if existing data for the selected key exists in hosts.txt
    if grep -q "$keychoice" "$existinghost"; then
        existingremote
    else
        newremote
    fi
}

existingremote() {
    # Retrieve host data from hosts.txt using key name
    host_data=$(grep "^$keychoice " "$existinghost")

    # Check if the key name exists in hosts.txt
    if [ -n "$host_data" ]; then
        remoteuser=$(echo "$host_data" | awk '{print $2}')
        remoteip=$(echo "$host_data" | awk '{print $3}')

        # Auto connect to server
        echo "Using selected key $keychoice"
        echo "Using the following IP and user"
        echo "User: $remoteuser IP used: $remoteip"

        # Connect
        ssh -i "$sshpath/$keychoice" "$remoteuser@$remoteip"
    else
        echo "No existing data found for key $keychoice in hosts.txt."
        exit 1
    fi
}


newremote() {
    # Prompt for remote IP and user
    read -p "Enter remote user: " remoteuser
    read -p "Enter remote IP: " remoteip

    # Save to existing host using key name
    echo "$keychoice $remoteuser $remoteip" >> "$existinghost"

    # Auto connect to server
    echo "Using selected key $keychoice"
    echo "Using the following IP and user"
    echo "User: $remoteuser IP used: $remoteip"

    # Connect
    ssh -i "$sshpath/$keychoice" "$remoteuser@$remoteip"
}


createssh(){
    disply
    read -p "What is the remote host name: " keychoice
    read -p "Enter remote user: " remoteuser
    read -p "Enter remote IP: " remoteip

    # create and send key
    echo 'generating key'
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/$keychoice

    echo 'Sending the key to remote host'
    ssh-copy-id -i $sshpath/$keychoice $remoteuser@$remoteip

    # clean up
    rm $sshpath/$keychoice.pub

}

disply(){
    clear
    echo '==============================================='
    echo '    ______        _      _____ _____ _    _    '
    echo '   |  ____|      | |    / ____/ ____| |  | |   '
    echo '   | |__ __ _ ___| |_  | (___| (___ | |__| |   '
    echo '   |  __/ _` / __| __|  \___ \\___ \|  __  |   '
    echo '   | | | (_| \__ \ |_   ____) |___) | |  | |   '
    echo '   |_|  \__,_|___/\__| |_____/_____/|_|  |_|   '
    echo '                                               '
    echo '==============================================='
    echo 'By The Insane Lord (2024)'
    echo ''
}


# script start
disply
echo 'Please select an option:'

# selection menu
echo "Select an option:"
echo "1. Connect to a server"
echo "2. create and auto send ssh key"
echo "3. Exit"
echo ''
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        sshconnect
        ;;
    2)
        createssh
        ;;
    3)
        echo "Exiting script. Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please enter a number between 1 and 3."
        ;;
esac
