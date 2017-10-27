!/bin/sh
 
echo
echo "Garmin Mac Deployment Script"
echo "Authors: Kyle Brewer, BJ Smith, David Findley"
#echo "Purpose: Apple laptop deployment "
echo "Date: January 17, 2016 "
echo "Version: 2.2.4"
echo
 
# Version 1.2 - Fixed some issues with spacing and responses are recognized as lower and uppercase.
# Version 2.0 - Removed the menu option for installing Adobe CC products. Also introduced the any case answer.
# Version 2.2 - Added the option to install Office updates only. Office installers updated to 15.17.0. 15.17.1 for Word and Outlook
#               due to crashing.
# Version 2.2.1 - Added January security updates. Bringing the versions to 15.18.0
# Version 2.2.3 - Cleaned up code. Simplified Office update functions. Rearranged menu to make it more functional. 
# Version 2.2.3 - Disable Office 2016 for Mac first run prompt

# We need to execute as root to get some of this done.
# If the executing user is not root, the script will exit with code 1.
if [ "$USER" != "root" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "You are attempting to execute this process as user $USER"
    echo "Please execute the script with elevated permissions."
    exit 1
fi
### Standard parameters
 
# Truncated hardware serial. Collect last 7 characters of serial to match Dell service tag standard.
 truncserial=`ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print substr($(NF-1),1+length($(NF-1))-7)}'`
 
# Regional hostname prefix.
 regionprefix="OLA-"
 
# Combine $regionprefix and $truncserial for a standard hostname.
localhostname=$regionprefix$truncserial-MAC
 
# Fully qualified DNS name of Active Directory domain.
domain="enter domain name"
 
# Distinguished name of intended container for this computer.
ou="Enter default OU path"
 
# Name of network time server. Used to synchronize clocks.
networktimeserver="time server"
 
### Advanced options
 
# 'enable' or 'disable' automatic multi-domain authentication.
alldomains="enable"
 
# 'enable' or 'disable' force home directory to local disk.
localhome="enable"
 
# 'afp' or 'smb' change how home is mounted from server.
protocol="smb"
 
# 'enable' or 'disable' mobile account support for offline logon.
mobile="enable"
 
# 'enable' or 'disable' warn the user that a mobile account will be created.
mobileconfirm="disable"
 
# 'enable' or 'disable' use AD SMBHome attribute to determine the home directory.
useuncpath="disable"
 
# Configure local shell. e.g., /bin/bash or "none".
user_shell="/bin/bash"
 
# Use the specified server for all directory lookups and authentication.
# (e.g. "-nopreferred" or "-preferred ad.server.edu")
#preferred="-nopreferred"
preferred="preferred domain"
 
# Comma-separated AD groups and users to be admins ("" or "DOMAIN\groupname").
admingroups="default admin groups to be used"
 
### End of configuration
 
function function_menu()
{
echo "*******************************************"
echo "Menu:"
echo
echo "1. Join a Mac to the domain "
echo "2. Disconnect a Mac from the domain "
echo "3. Reinstall OS X Yosemite "
echo "4. Add User Only "
echo "5. Install Office 2016 for Mac "
echo "6. Install Office 2016 for Mac Security Updates "
echo "7. System Summary "
echo "8. Exit "
}
 
function read_options()
{
    local choice
    read -p "Make a selection: " number
    case $number in
        1) ad_bind ;;
        2) forceunbind ;;
        3) install_osx ;;
        4) admin_only ;;
        5) office_install ;;
        6) office_2016_update ;;
        7) summary ;;
        8) exit 0 ;;
    esac
}
function basic_settings()
{
### Basic configuration
 
echo "Prompting for basic details"
 
# Prompt for local hostname - written just after configuration.
#localhostname=`/usr/sbin/scutil --get LocalHostName`
#read -p "What is this computer's name? " localhostname
 
# Prompt for end-user local admin.
echo "Enter the AD usernames of the people who will be local admins"
read -p "You MUST separate the usernames with spaces: " localadmins
 
# Authenticate with privileged AD credentials (probably YOURS!).
echo "Prompting for *YOUR* AD credentials."
 
# Here we'll ask for a privileged AD username.
read -p "Enter *YOUR* AD username: " domainadmin
 
# And here we'll ask for the password of that privileged AD username.
read -s -p "Enter *YOUR* AD password: " password
echo ""
}
function ad_bind()
{
# Running prompt for basic account settings.
    basic_settings
# Set network time server to prevent errors during binding attempts.
    # We should test for the existence of /etc/ntp.conf before we define the network time server.
    if [ -f /etc/ntp.conf ]; then
        echo "Setting network time server."
        sudo systemsetup setnetworktimeserver $networktimeserver
    else
        echo "Creating /etc/ntp.conf"
        sudo touch /etc/ntp.conf
        echo "Setting network time server."
        sudo systemsetup setnetworktimeserver $networktimeserver
    fi
 
    # Activate the AD plugin by updating DirectoryService preferences.
    echo "Updating DirectoryServices preferences to activate AD plugin."
    sudo defaults write /Library/Preferences/DirectoryService/DirectoryService "Active Directory" "Active"
 
    # Now we wait a few seconds to account for disk write delays and let OS X notice the new configuration.
    echo "Taking a nap for 5 seconds to let Directory Services to catch up."
    sleep 5
 
    # Set HostName, LocalHostName, ComputerName, using value assigned in $localhostname.
    echo "Setting HostName, LocalHostName, and ComputerName as $localhostname."
    scutil --set HostName $localhostname
    scutil --set LocalHostName $localhostname
    scutil --set ComputerName $localhostname
 
    # Bind to AD with hostname defined above.
    echo "Binding computer to $domain as $localhostname."
    sudo dsconfigad -f -a $localhostname -domain $domain -u $domainadmin -p "$password" -ou "$ou"
 
    # Define local admin groups, to be listed in Directory Utility.
    # If no groups are defined in $admingroups, -nogroups option is used.
    if [ "$admingroups" = "" ]; then
        sudo dsconfigad -nogroups
    else
        echo "Configuring AD Groups with local admin privileges."
        sudo dsconfigad -groups "$admingroups"
    fi
 
    echo "Configuring mobile settings."
    sudo dsconfigad -alldomains $alldomains -localhome $localhome -protocol $protocol -mobile $mobile -mobileconfirm $mobileconfirm -useuncpath $useuncpath -shell $user_shell -preferred $preferred
 
    echo "Adding users as admins. "
    users
    summary
}
function users()
{
    # Iterate through each username in @localadmins array to provision each user.
    for username in ${localadmins[@]}
    do
        # Create mobile account for user(s) specified in @localadmins.
        # Domain groups inherited as expected, i.e., members of SPECIFIC GROUP are admins.
        # Note: this will pass two odd messages to the CLI, this is a known bug in ManagedClient.
        echo "Creating mobile account for user $username."
        echo "Expect two odd messages here. They do not indicate an error."
        sudo /System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n "$username"
 
        # Add username(s) specified in @localadmins to local admin group - does not add to Directory Utility listing.
        echo "Adding user $username to local admin group."
        sudo dscl . -append /Groups/admin GroupMembership "$username"
    done
}
function admin_only()
{
    basic_settings
    users
}
 
#Reinstalls OS X Yosemite
 
function install_osx()
{
    echo "This only applies to OS X Yosemite! "
    read -p "Are you sure you want to reinstall OS X? (Yes/No) " reinstall
    if [ $reinstall = Yes ] || [ $reinstall = yes ]; then
        ~/Documents/Test\ Scripts/Install\ OS\ X\ Yosemite.app/Contents/MacOS/InstallAssistant
    else
    echo "Returning to the main menu. "
    fi
}
 
function office_install()
{
    read -p "Is Office 2016 okay to install? (Yes/No) " response
    if [ $response = yes ] || [ $response = Yes ]; then
        echo "Installing Office 2016 for Mac"
        echo
        echo
        /usr/sbin/installer -pkg ./"Microsoft_Office_2016.pkg" -target "/"
 
        office_2016_update
        
        echo "Disabling the application first run prompting"
        defaults write /Library/Preferences/com.microsoft.Excel kSubUIAppCompletedFirstRunSetup1507 -bool true
        defaults write /Library/Preferences/com.microsoft.onenote.mac kSubUIAppCompletedFirstRunSetup1507 -bool true
        defaults write /Library/Preferences/com.microsoft.Outlook kSubUIAppCompletedFirstRunSetup1507 -bool true
        defaults write /Library/Preferences/com.microsoft.Outlook FirstRunExperienceCompletedO15 -bool true
        defaults write /Library/Preferences/com.microsoft.PowerPoint kSubUIAppCompletedFirstRunSetup1507 -bool true
        defaults write /Library/Preferences/com.microsoft.Word kSubUIAppCompletedFirstRunSetup1507 -bool true
        echo
        echo "Package installation completed."     
 
    elif [ $response = no ] || [ $response = No ]; then
        echo "Office 2016 is the only package this script supports. Please manually install Office 2011. "
    fi
}

#Obviously old versions of Office. 

function office_2016_update()
{
    echo "***Installing Office 2016 updates***"
    echo
    echo "Installing Microsoft Autoupdate Update "
    echo
    /usr/sbin/installer -pkg ./"Microsoft_AutoUpdate_3.4.0_Updater.pkg" -target "/"
    echo
    echo "Installing Microsoft Excel 2016 update"
    echo
    /usr/sbin/installer -pkg ./"Microsoft_Excel_15.18.0_Updater.pkg" -target "/"
    echo
    echo "Installing Microsoft OneNote 2016 update"
    echo
    /usr/sbin/installer -pkg ./"Microsoft_OneNote_15.18.0_Updater.pkg" -target "/"
    echo
    echo "Installing Microsoft Outlook 2016 update"
    echo
    /usr/sbin/installer -pkg ./"Microsoft_Outlook_15.18.0_Updater.pkg" -target "/"
    echo
    echo "Installing Microsoft PowerPoint 2016 update"
    echo
    /usr/sbin/installer -pkg ./"Microsoft_PowerPoint_15.18.0_Updater.pkg" -target "/"
    echo
    echo "Installing Microsoft Word 2016 update"
    echo
    /usr/sbin/installer -pkg ./"Microsoft_Word_15.18.0_Updater.pkg" -target "/"
    echo
}
 
function summary()
{
    # Sanity check. Rather than printing from variables, we'll query the system configuration for these values.
    #This part brought to you by Kyle's amazing knowledge of awk. 
    echo "\n*** SUMMARY ***"
    echo "Hardware serial number:"
    ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}'
 
    echo "\nHostname:"
    scutil --get HostName
 
    # Print AD forest.
    echo "\nActive Directory forest:"
    dsconfigad -show | awk -F\= '/^Active Directory Forest/{gsub(/ /, ""); print $(NF)}'
 
    # Print AD domain, specified in $domain variable.
    echo "\nActive Directory domain:"
    dsconfigad -show | awk -F\= '/^Active Directory Domain/{gsub(/ /, ""); print $(NF)}'
 
    # Print preferred domain controller, specified in $preferred variable.
    echo "\nPreferred domain controller:"
    dsconfigad -show | awk -F\= '/Preferred Domain controller/{gsub(/ /, ""); print $(NF)}'
 
    # Print network time server and ntpd status.
    echo "\nNetwork time server:"
    sudo systemsetup getnetworktimeserver | awk '{print $(NF)}'
    echo "\nNetwork time status:"
    sudo systemsetup getusingnetworktime | awk '{print $(NF)}'
 
    # Print members of local "admin" group.
    echo "\nCurrent members of local \"admin\" group:"
    dscl . -read /Groups/admin GroupMembership | awk -F ' ' '{for (i=2; i<=NF; i++) print $i}'
 
    # Print allowed admin groups, specified in $admingroups variable.
    echo "\nAllowed admin groups:"
    dsconfigad -show | grep "Allowed admin groups" | sed -e $'s/.*= //;s/,/\\\n/g'
}
 
function forceunbind()
{
    # Force unbind from domain.
    echo "\nForce unbinding $HOSTNAME from domain."
    dsconfigad -f -r $HOSTNAME -u $domainadmin -p $password
 
    # Sanity check. If "dsconfigad -show" returns nothing, unbinding was successful.
    if [ "$(dsconfigad -show)" = "" ]; then
        echo "\nForce unbinding successful."
    else
        echo "\nForce unbinding unsuccessful."
    fi
}
 
while true
    do
    function_menu
    read_options
done
