#!/bin/sh

# Purpose: Create macOS bootable USB media
# Date: February 10, 2017
# Author: David Findley
#Updated October 31, 2017 - Added missing Sierra install command. Will update for High Sierra soon.

# Checking for root user privileges

if [ "$USER" != "root" ]; then
echo "************************************"
	echo "You are attempting to execute this process as user $USER"
	echo "Please execute the script with elevated permissions."
	exit 1
fi

# Determining which version of OS X/macOS is needed
function menu()
{
	clear
	echo "CREATE BOOTABLE OSX/MACOS USB DRIVE"
	echo
	echo "Make a selection below: "
	echo "........................"
	echo "1. Create OS X Yosemite Installer"
	echo "2. Create OS X El Capitan Installer"
	echo "3. Create macOS Sierra Installer"
	echo "4. Exit"

}

# Read the input and continue

function input()
{
	local selection
	read -p "Enter your selection: " selection
	case $selection in
		1) yosemite ;;
		2) el_capitan ;;
		3) sierra ;;
		4) exit 0 ;;
	
	esac

}

function yosemite()
{
	echo "Creating OS X Yosemite USB Drive: "
	read -p "Please enter the name of your USB drive: " drive 
	/Applications/Install\ OS\ X\ Yosemite.app/Contents/Resources/createinstallmedia --volume /Volumes/$drive --applicationpath /Applications/Install\ OS\ X\ Yosemite.app
	sleep 2	
}

function el_capitan()
{
	echo "Creating OS X El Capitan USB Drive: "
	read -p "Please enter the name of the USB drive: " drive
	/Applications/Install\ OS\ X\ El\ Capitan.app/Contents/Resources/createinstallmedia --volume /Volumes/$drive --applicationpath /Applications/Install\ OS\ X\ El\ Capitan.app
	sleep 2
}

function sierra()
{
	echo "Creating macOS Sierra Installer: "
	read -p "Please enter the name of the USB drive: " drive
	/Applications/Install\ macOS\ Sierra.app/Contents/Resources/createinstallmedia --volume /Volumes/$drive --applicationpath /Applications/Install\ macOS\ Sierra.app
	sleep 2
}	

while true
do
	menu
	input
done	

