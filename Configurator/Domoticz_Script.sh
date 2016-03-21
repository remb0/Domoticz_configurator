#!/bin/bash

# Confire your Raspberry Pi for domoticz with the most common things.
# (c) 2015, 2016
# Domoticz Config Script



  
######## VARIABLES #########

tmpLog=/tmp/Domoticz-install.log
instalLogLoc=/home/pi/install.log


domoticzGitUrl="https://github.com/domoticz/domoticz.git"
ConfiguratorFilesDir="/home/pi/domoticz_configurator/"

# Find the rows and columns
rows=$(tput lines)
columns=$(tput cols)

# Divide by two so the dialogs take up half of the screen, which looks nice.
r=$(( rows / 2 ))
c=$(( columns / 2 ))

# Find IP used to route to outside world

IPv4dev=$(ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++)if($i~/dev/)print $(i+1)}')
IPv4addr=$(ip -o -f inet addr show dev $IPv4dev | awk '{print $4}' | awk 'END {print}')
IPv4gw=$(ip route get 8.8.8.8 | awk '{print $3}')

availableInterfaces=$(ip -o link | awk '{print $2}' | grep -v "lo" | cut -d':' -f1)
dhcpcdFile=/etc/dhcpcd.conf
  
  
  


  
  ######## FIRST CHECK ########
# Must be root to install
echo ":::"
if [[ $EUID -eq 0 ]];then
	echo "::: You are root."
else
	echo "::: sudo will be used for the install."
	# Check if it is actually installed
	# If it isn't, exit because the install cannot complete
	if [[ $(dpkg-query -s sudo) ]];then
		export SUDO="sudo"
	else
		echo "::: Please install sudo or run this as root."
		exit 1
	fi
fi


  ######## Start ########

  welcomeDialogs() {
	# Display the welcome dialog
	whiptail --msgbox --backtitle "Welcome" --title "Domoticz Configurator" "This script will help you configuring your Raspberry Pi for Domoticz!" $r $c
	# Support for a part-time dev
#	whiptail --msgbox --backtitle "Please" --title "Free and open source" "The script is free, but powered by help" $r $c
}


verifyFreeDiskSpace() {
	# 25MB is the minimum space needed (20MB install + 5MB one day of logs.)
	requiredFreeBytes=51200
	
	existingFreeBytes=`df -lk / 2>&1 | awk '{print $4}' | head -2 | tail -1`    	
	if ! [[ "$existingFreeBytes" =~ ^([0-9])+$ ]]; then       
		existingFreeBytes=`df -lk /dev 2>&1 | awk '{print $4}' | head -2 | tail -1`		
	fi
	
	if [[ $existingFreeBytes -lt $requiredFreeBytes ]]; then
		whiptail --msgbox --backtitle "Insufficient Disk Space" --title "Insufficient Disk Space" "\nYour system appears to be low on disk space. Domoticz recomends a minimum of $requiredFreeBytes Bytes.\nYou only have $existingFreeBytes Free.\n\nIf this is a new install you may need to expand your disk.\n\nTry running:\n    'sudo raspi-config'\nChoose the 'expand file system option'\n\nAfter rebooting, run this installation again.\n\n\n" $r $c
		echo "$existingFreeBytes is less than $requiredFreeBytes"
		echo "Insufficient free space, exiting..."
		exit 1
	fi
}




clear
RETVAL=$(whiptail --title "Domoticz Menu" --menu "" 12 53 0 \
"1" "Backup of Domoticz folder" \
"2" "Update Domoticz to the latest beta version" \
"3" "Updating and Upgrading Raspbian" \
"4" "Raspberry Pi Software Configuration Tool" \
"5" "Install Extra software" \
"6" "Domoticz configurations" \
"7" "Fix permissions" \
"8" "Reboot System" \
"9" "Shutdown System" \
3>&1 1>&2 2>&3)

# Below you can enter the corresponding commands
# Create backupz folder in pi folder first

case $RETVAL in
1) echo "Backing up Domoticz folder... (please standby...)"
sudo service domoticz.sh stop
sudo tar --verbose --verify --create --file=./backupz/domoticz_bak.tar domoticz/ --exclude=domoticz_linux_armv7l.tgz
echo "Restarting Domoticz... (please standby...)"
sudo service domoticz.sh restart ;;

2) 

##whiptail --title "Example Dialog" --infobox "This is an example of an info box." 8 78
cd ~/domoticz
echo "Updating to latest beta version... (please standby...)"
sudo service domoticz.sh stop
sudo cp domoticz.db ../backupz/domoticz.db
mv domoticz_linux_armv7l.tgz ../backupz/domoticz_linux_armv7l.tgz
wget http://releases.domoticz.com/releases/beta/domoticz_linux_armv7l.tgz
tar xvfz domoticz_linux_armv7l.tgz
echo "Restarting Domoticz... (please standby...)"
sudo service domoticz.sh restart ;;

3) 
sudo apt-get update
sudo apt-get upgrade ;;

## misschien sub menu voor
## sudo rpi-update

4) sudo raspi-config ;;

5)  echo " Extra software" ;; 
##whiptail —yesno "Are you sure?" —yes-button "Yes, I did" —no-button "No, never heard of it"  10 70
##  CHOICEs=$?

##Monit
##MODT
##ramdisk


6) echo " Configure domoticz extras"

##logging
##persistent usb
##scripting:   hue, mindergas


			## Mindergas! upload to mindergas (DUTCH).
			sudo apt-get install flex -y
			wget https://github.com/stedolan/jq/releases/download/jq-1.4/jq-1.4.tar.gz
			tar xfvz jq-1.4.tar.gz
			cd jq-1.4
			./configure
			make
			sudo make install
			rm /home/pi/jq-1.4.tar.gz
			cd home/pi/domoticz/scripts/bash/
			ls
			sh post-mindergas.sh ;;

7) echo "Fix permissions"
			## zet rechten goed (niet nodig gehad, maar goed als naslag):
			cd /home/pi/domoticz/
			sudo sh domoticz.sh stop
			sudo service domoticz stop
			sudo chown -R pi.pi *
			##zet rechten via 777 op scripts (bash script voor backup bijvoorbeeld)
			sudo chmod -R 0777 /tmp
			sudo service domoticz start ;;
8) sudo reboot ;;

9) sudo poweroff ;; 

*) echo "You chose Cancel." ;;
esac



######## SCRIPT ############
# Start the installer
$SUDO mkdir -p /home/pi/domoticz_script/
welcomeDialogs

# Verify there is enough disk space for the install
verifyFreeDiskSpace

# Move the log file 
$SUDO mv $tmpLog $instalLogLoc

displayFinalMessage

echo -n "::: Restarting services..."
# Start services

echo " done."

echo ":::"
echo "::: Installation Complete! You can use the number one Home automation Software"

echo "::: "
echo "::: The install log is located at: " $instalLogLoc


