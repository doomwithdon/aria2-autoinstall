# aria2-autoinstall

sudo su

sudo apt-get install ddclient

sudo apt-get install rclone

rclone config

Create rclone gdrive with remote name "gdrv"

wget -O /root/.aria2/aria2_moveto_rclonedrv.sh https://raw.githubusercontent.com/doomwithdon/aria2-autoinstall/master/aria2_moveto_rclonedrv.sh

chmod +x /root/.aria2/aria2_moveto_rclonedrv.sh

wget -N --no-check-certificate https://raw.githubusercontent.com/doomwithdon/aria2-autoinstall/master/aria2.sh && chmod +x aria2.sh && bash aria2.sh


