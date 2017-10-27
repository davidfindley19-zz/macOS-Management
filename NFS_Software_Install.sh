#!/bin/sh
 
# Purpose: Copy installer from remote, centralized software repo and install.
# Author: David Findley
# Version: 1.0
 
### As with all scripts, it needs to be ran as root. Checking credentials.
 
if [ "$USER" != "root" ]; then
echo "************************************"
    echo "You are attempting to execute this process as user $USER"
    echo "Please execute the script with elevated permissions."
    exit 1
fi
 
# Now we need to authenticate with domain credentials
read -p 'Please enter your network username:' domainusername
read -s -p 'Please enter your AD password: ' domainpass
 
function setup()
{
# Now we need to make a mount point for the NFS share.
 
mkdir /Volumes/name of directory you want mounted to
 
mount_smbfs "//$domainusername:$domainpass@FQDN/Share Name" /Volumes/name of directory you created
 
#This was example software used. Really, any software that needs copied over to be installed can be inserted.

echo "Copying over Skype For Business..."
cp /Volumes/scratch/SCRATCH/Findley/SkypeForBusiness.pkg ~/Desktop
 
echo "Copying over Microsoft Office 2016..."
cp /Volumes/scratch/SCRATCH/Findley/Microsoft_Office.pkg ~/Desktop
 
echo "Installing Skype for Business for Mac:"
/usr/sbin/installer -pkg ~/Desktop/"SkypeForBusiness.pkg" -target "/"
echo
echo
echo "Skype for Business is now installed."
echo
echo "Installing Microsoft Office 2016 for Mac:"
echo
/usr/sbin/installer -pkg ~/Desktop/"Microsoft_Office.pkg" -target "/"
echo
echo "Microsoft Office 2016 for Mac is now installed."
 
#Trying to be responsible, I have it remove the install files for each package. 
#This could be simplified, but for testing I wanted to have it remove each one individually.
echo "Removing install files. "
 
rm ~/Desktop/Microsoft_Office.pkg
rm ~/Desktop/SkypeForBusiness.pkg
 
#The last step, it unmounts the network share you are working from.  
umount /Volumes/name of directory you created
}
