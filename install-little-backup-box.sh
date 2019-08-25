#!/usr/bin/env bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

echo "Updating the system..."

sudo apt-get update -qq >/dev/null
sudo apt-get dist-upgrade -y -qq >/dev/null
sudo apt-get update -qq >/dev/null


echo "Installing the required packages..."

sudo apt-get install acl git-core screen rsync exfat-fuse exfat-utils ntfs-3g gphoto2 libimage-exiftool-perl dialog php minidlna samba samba-common-bin -y >/dev/null
curl -s https://syncthing.net/release-key.txt | sudo apt-key add - >/dev/null
echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
echo "Finishing up..."
sudo apt-get update -qq >/dev/null
sudo apt-get install syncthing -y >/dev/null

USER="$1"

if [ -z "$USER" ]; then
    USER="pi"
    fi
sudo mkdir /media/card
sudo mkdir /media/storage
sudo chown -R $USER:users /media/storage
sudo chmod -R 775 /media/storage
sudo setfacl -Rdm g:$USER:rw /media/storage

sudo sed -i 's|'media_dir=/var/lib/minidlna'|'media_dir=/media/storage'|' /etc/minidlna.conf
sudo sh -c "echo 'media_dir=/home/$USER/BACKUP' >> /etc/minidlna.conf"
sudo service minidlna start

echo "Fetching Little Backup Box..."

cd
git clone https://github.com/dmpop/little-backup-box.git

echo -e '\nBAK_DIR="/home/'$USER'/BACKUP" # Home directory path' >> little-backup-box/scripts/config.cfg
mkdir -p /home/$USER/BACKUP
chown $USER:users -R /home/$USER/BACKUP

BACKTITLE="Little Backup Box"

OPTIONS=(1 "Remote control"
         2 "Card backup"
         3 "Camera backup"
	 4 "Internal backup")

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "Backup Mode" \
                --menu "Select the default backup mode:" \
                15 40 4 \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/card-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/camera-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/internal-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "@reboot cd /home/"$USER"/little-backup-box/scripts && sudo php -S 0.0.0.0:8000"; } | crontab
            ;;
        2)
            crontab -l | { cat; echo "@reboot sudo /home/"$USER"/little-backup-box/scripts/card-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/camera-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/internal-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot cd /home/"$USER"/little-backup-box/scripts && sudo php -S 0.0.0.0:8000"; } | crontab
            ;;
        3)
            crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/card-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "@reboot sudo /home/"$USER"/little-backup-box/scripts/camera-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/internal-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot cd /home/"$USER"/little-backup-box/scripts && sudo php -S 0.0.0.0:8000"; } | crontab
            ;;
	4)
            crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/card-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot sudo /home/"$USER"/little-backup-box/scripts/camera-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "@reboot sudo /home/"$USER"/little-backup-box/scripts/internal-backup.sh >> /home/"$USER"/little-backup-box.log 2>&1"; } | crontab
	    crontab -l | { cat; echo "#@reboot cd /home/"$USER"/little-backup-box/scripts && sudo php -S 0.0.0.0:8000"; } | crontab
            ;;
esac

crontab -l | { cat; echo "@reboot sudo /home/"$USER"/little-backup-box/scripts/restart-servers.sh"; } | crontab

echo "Configuring Samba and Syncthing..."

pw="raspberry"
(echo $pw; echo $pw ) | sudo smbpasswd -s -a pi
sudo sh -c "echo '### Global Settings ###' > /etc/samba/smb.conf"
sudo sh -c "echo '[global]' >> /etc/samba/smb.conf"
sudo sh -c "echo 'workgroup = WORKGROUP' >> /etc/samba/smb.conf"
sudo sh -c "echo 'wide links = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'unix extensions = no' >> /etc/samba/smb.conf"
sudo sh -c "echo 'dns proxy = no' >> /etc/samba/smb.conf"
sudo sh -c "echo '### Debugging/Accounting ###' >> /etc/samba/smb.conf"
sudo sh -c "echo 'log file = /var/log/samba/log.%m' >> /etc/samba/smb.conf"
sudo sh -c "echo 'max log size = 1000' >> /etc/samba/smb.conf"
sudo sh -c "echo 'syslog = 0' >> /etc/samba/smb.conf"
sudo sh -c "echo 'panic action = /usr/share/samba/panic-action %d' >> /etc/samba/smb.conf"
sudo sh -c "echo '### Authentication ###' >> /etc/samba/smb.conf"
sudo sh -c "echo 'security = user' >> /etc/samba/smb.conf"
sudo sh -c "echo 'map to guest = Bad User' >> /etc/samba/smb.conf"
sudo sh -c "echo 'guest account = pi' >> /etc/samba/smb.conf"
sudo sh -c "echo '### Share Definitions ###' >> /etc/samba/smb.conf"
sudo sh -c "echo '[little-backup-box]' >> /etc/samba/smb.conf"
sudo sh -c "echo 'comment = Little Backup Box /media/storage' >> /etc/samba/smb.conf"
sudo sh -c "echo 'path = /media/storage' >> /etc/samba/smb.conf"
sudo sh -c "echo 'browseable = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'force user = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'force group = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'admin users = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'writeable = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'read only = no' >> /etc/samba/smb.conf"
sudo sh -c "echo 'guest ok = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'create mask = 0777' >> /etc/samba/smb.conf"
sudo sh -c "echo 'directory mask = 0777' >> /etc/samba/smb.conf"

sudo sh -c "echo '[internal-backup]' >> /etc/samba/smb.conf"
sudo sh -c "echo 'comment = Little Backup Box internal backup' >> /etc/samba/smb.conf"
sudo sh -c "echo 'path = /home/$USER/BACKUP' >> /etc/samba/smb.conf"
sudo sh -c "echo 'browseable = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'force user = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'force group = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'admin users = $USER' >> /etc/samba/smb.conf"
sudo sh -c "echo 'writeable = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'read only = no' >> /etc/samba/smb.conf"
sudo sh -c "echo 'guest ok = yes' >> /etc/samba/smb.conf"
sudo sh -c "echo 'create mask = 0777' >> /etc/samba/smb.conf"
sudo sh -c "echo 'directory mask = 0777' >> /etc/samba/smb.conf"

sudo samba restart

sudo systemctl start syncthing@pi.service
sleep 15
sudo sed -i "s/127\.0\.0\.1/0.0.0.0/g" ~/.config/syncthing/config.xml

chmod +x little-backup-box/scripts/*.sh

dialog --title "Enable OLED support" \
       --backtitle "$BACKTITLE" \
       --yesno "Enable support for a 128x32 OLED display?" 7 60

response=$?
case $response in
    0) cd
       sudo apt-get install wiringpi i2c-tools -y >/dev/null
       https://github.com/dmpop/ssd1306_rpi.git
       cd ssd1306_rpi
       cc -o oled oled.c fontx.c -lwiringPi -lpthread -DI2C -DX32
       sudo cp oled /usr/local/bin/
       sudo chown root:root /usr/local/bin/oled
       sudo chmod 755 /usr/local/bin/oled
       crontab -l | { cat; echo "@reboot sudo /home/"$USER"/little-backup-box/scripts/ip.sh"; } | crontab
       dialog --title "Enable I2C" \
       --backtitle "$BACKTITLE" \
       --msgbox "Almost done! Run the following command:\n\nsudo raspi-config\n\nSwitch to the Interfacing Options section and enable I2C. Then reboot the system." 15 30
       ;;
    1) dialog --title "Setup finished" \
	      --backtitle "$BACKTITLE" \
	      --infobox "\nAll done! The system will reboot now." 5 45 ; sleep 3
      sudo reboot
      ;;
   255) dialog --title "Setup finished" \
	      --backtitle "$BACKTITLE" \
	      --infobox "\nAll done! The system will reboot now." 5 45 ; sleep 3
	sudo reboot
	;;
esac
