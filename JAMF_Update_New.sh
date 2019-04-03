#!/bin/sh

# Purpose: To simplify the DEP enrollment process for Macs.
# Author: David Findley
# Date: December 20, 2017 [Updated 04-03-2019]
# Version: 1.4
# Change Log: 
			#1.3 - Removed local requirement. Cleaned up code.
			#1.4 - Updated mount command to mount -t

# Verifying that user is running the scrip with elevated permissions.
if [ "$USER" != "root" ]; then
echo "************************************"
	echo "You are attempting to execute this process as user $USER"
	echo "Please execute the script with elevated permissions."
	exit 1
fi

clear

#Now we need to authenticate with domain credentials.
echo "We need to authenticate with your tech account domain credentials to proceed: "
read -p 'Please enter your network username:' domainusername
read -s -p 'Please enter your AD password: ' domainpass
clear

#Install of the Location-Specific Quick Add package
function jamf_install()
{
	# We need to check that JAMF is installed. If it is, then it will force a check in.
	echo "\nChecking that JAMF is installed."
	if [ ! -f /usr/local/bin/jamf ]; then
			echo "\nJAMF is not installed. Attempting to install."
			mkdir /Volumes/MacInstalls
			echo "\nMounting remote network location."
			mount -t smbfs //$domainusername:$domainpass@servername/MacInstalls /Volumes/MacInstalls
			/usr/sbin/installer -pkg /Volumes/MacInstalls/Jamf/QuickAdd.pkg -target "/"
			echo "\nJAMF has been installed."
			umount /Volumes/MacInstalls
	else
		echo "\nJAMF is installed. Checking in with the JSS server."
		/usr/local/bin/jamf recon
		/usr/local/bin/jamf policy
	fi

}

## Used to force the machine to check in with JSS
function recon()
{
	echo "\nChecking in with JSS"
	jamf recon
}

# Force policy retrieval - like gpupdate, but for Macs.
function policy()
{
  echo "\nForcing policy retrieval for machine"
	jamf policy
}

function do_all()
{
	jamf_install
	recon
	policy
	clear
}

# Have this as a hidden feature to remove the JAMF software
function remove_jamf()
{
	jamf removeFramework
	clear
}

function read_options()
{
	local choice
	read -p "Choose and option: " number
	case $number in
		1) do_all ;;
		2) jamf_install ;;
		3) recon ;;
		4) policy ;;
		5) exit 0 ;;
		6) remove_jamf ;; # Was a "hidden" menu option to remove the JAMF Framework.
	esac
}

function menu()
{
	echo "*********************************************"
	echo "1) Install JAMF QuickAdd and update policies "
	echo "2) Install JAMF QuickAdd Package Only "
	echo "3) Run Recon Tool for JAMF "
	echo "4) Update JAMF Policies "
	echo "5) Exit "

}

while true
	do
	menu
	read_options
done
