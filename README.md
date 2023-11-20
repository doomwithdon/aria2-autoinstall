# aria2-autoinstall

sudo su

sudo apt-get install ddclient

sudo -v ; curl https://rclone.org/install.sh | sudo bash

rclone config

Create rclone gdrive with remote name "gdrv"

wget -N --no-check-certificate https://raw.githubusercontent.com/doomwithdon/aria2-autoinstall/master/aria2.sh && chmod +x aria2.sh && bash aria2.sh

wget -O aria2_moveto_rclonedrv.sh https://github.com/doomwithdon/aria2-autoinstall/blob/main/aria2_moveto_rclonedrv.sh

chmod +x aria2_moveto_rclonedrv.sh

crontab -e
@reboot /etc/init.d/aria2 start
@reboot rclone serve webdav --addr :7654 --user username --pass password gdrv:



