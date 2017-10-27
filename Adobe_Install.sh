#!/bin/sh
 
# We need to execute as root to get some of this done.
# If the executing user is not root, the script will exit with code 1.
if [ "$USER" != "root" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "You are attempting to execute this process as user $USER"
    echo "Please execute the script with elevated permissions."
    exit 1
fi
 
echo
echo "Installing Adobe Creative Cloud for Mac"
echo
 
read -p "Which version of Adobe CC 2014 do you need installed? (Standard or Premium) " response
 
if [[ $response == Standard ]]; then
    /usr/sbin/installer -pkg ./"Design Standard OS X_Install.pkg" -target "/" ;
elif [[ $response == Premium ]]; then
    /usr/sbin/installer -pkg ./"Production Premium OS X_Install.pkg" -target "/" ;
fi
 
exit
