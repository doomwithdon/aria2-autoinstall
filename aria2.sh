#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Aria2
#	Version: 1.1.10
#	Author: Toyo
#	Blog: https://doub.io/shell-jc4/
#=================================================
sh_ver="1.1.10"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/root/.aria2"
aria2_conf="/root/.aria2/aria2.conf"
aria2_log="/root/.aria2/aria2.log"
Folder="/usr/local/aria2"
aria2c="/usr/bin/aria2c"
Crontab_file="/usr/bin/crontab"

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[information]${Font_color_suffix}"
Error="${Red_font_prefix}[error]${Font_color_suffix}"
Tip="${Green_font_prefix}[tip]${Font_color_suffix}"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} The current non-ROOT account (or no ROOT permission), cannot continue to operate, please change the ROOT account or use ${Green_background_prefix}sudo su${Font_color_suffix} Command to obtain temporary ROOT permission (you may be prompted to enter the password of the current account after execution)." && exit 1
}
#Check system
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
	bit=`uname -m`
}
check_installed_status(){
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 Not installed, please check !" && exit 1
	[[ ! -e ${aria2_conf} ]] && echo -e "${Error} Aria2 The configuration file does not exist, please check!" && [[ $1 != "un" ]] && exit 1
}
check_crontab_installed_status(){
	if [[ ! -e ${Crontab_file} ]]; then
		echo -e "${Error} Crontab No installation, start installation..."
		if [[ ${release} == "centos" ]]; then
			yum install crond -y
		else
			apt-get install cron -y
		fi
		if [[ ! -e ${Crontab_file} ]]; then
			echo -e "${Error} Crontab Installation failed, please check！" && exit 1
		else
			echo -e "${Info} Crontab Successful installation！"
		fi
	fi
}
check_pid(){
	PID=`ps -ef| grep "aria2c"| grep -v grep| grep -v "aria2.sh"| grep -v "init.d"| grep -v "service"| awk '{print $2}'`
}
check_new_ver(){
	echo -e "${Info} please enter Aria2 version number, the format is as：[ 1.34.0 ]，Get address：[ https://github.com/q3aql/aria2-static-builds/releases ]"
	read -e -p "By default, press Enter to automatically get the latest version number:" aria2_new_ver
	if [[ -z ${aria2_new_ver} ]]; then
		aria2_new_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/q3aql/aria2-static-builds/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g;s/v//g' | sed 's/tag_name: //g')
		if [[ -z ${aria2_new_ver} ]]; then
			echo -e "${Error} Aria2 Failed to obtain the latest version, please obtain the latest version number manually[ https://github.com/q3aql/aria2-static-builds/releases ]"
			read -e -p "Please enter the version number [ Format like 1.34.0 ] :" aria2_new_ver
			[[ -z "${aria2_new_ver}" ]] && echo "cancel..." && exit 1
		else
			echo -e "${Info} detected Aria2 The latest version is [ ${aria2_new_ver} ]"
		fi
	else
		echo -e "${Info} Ready to download Aria2 version is [ ${aria2_new_ver} ]"
	fi
}
check_ver_comparison(){
	aria2_now_ver=$(${aria2c} -v|head -n 1|awk '{print $3}')
	[[ -z ${aria2_now_ver} ]] && echo -e "${Error} Brook Failed to obtain the current version !" && exit 1
	if [[ "${aria2_now_ver}" != "${aria2_new_ver}" ]]; then
		echo -e "${Info} Find Aria2 There is a new version [ ${aria2_new_ver} ](current version：${aria2_now_ver})"
		read -e -p "Whether to update(Will interrupt the current download task, please note) ? [Y/n] :" yn
		[[ -z "${yn}" ]] && yn="y"
		if [[ $yn == [Yy] ]]; then
			check_pid
			[[ ! -z $PID ]] && kill -9 ${PID}
			Download_aria2 "update"
			Start_aria2
		fi
	else
		echo -e "${Info} current Aria2 Already the latest version [ ${aria2_new_ver} ]" && exit 1
	fi
}
Download_aria2(){
	update_dl=$1
	cd "/usr/local"
	#echo -e "${bit}"
	if [[ ${bit} == "x86_64" ]]; then
		bit="64bit"
	elif [[ ${bit} == "i386" || ${bit} == "i686" ]]; then
		bit="32bit"
	else
		bit="arm-rbpi"
	fi
	wget -N --no-check-certificate "https://github.com/q3aql/aria2-static-builds/releases/download/v${aria2_new_ver}/aria2-${aria2_new_ver}-linux-gnu-${bit}-build1.tar.bz2"
	Aria2_Name="aria2-${aria2_new_ver}-linux-gnu-${bit}-build1"
	
	[[ ! -s "${Aria2_Name}.tar.bz2" ]] && echo -e "${Error} Aria2 Failed to download the compressed package !" && exit 1
	tar jxvf "${Aria2_Name}.tar.bz2"
	[[ ! -e "/usr/local/${Aria2_Name}" ]] && echo -e "${Error} Aria2 Unzip failed !" && rm -rf "${Aria2_Name}.tar.bz2" && exit 1
	[[ ${update_dl} = "update" ]] && rm -rf "${Folder}"
	mv "/usr/local/${Aria2_Name}" "${Folder}"
	[[ ! -e "${Folder}" ]] && echo -e "${Error} Aria2 Failed to rename folder !" && rm -rf "${Aria2_Name}.tar.bz2" && rm -rf "/usr/local/${Aria2_Name}" && exit 1
	rm -rf "${Aria2_Name}.tar.bz2"
	cd "${Folder}"
	make install
	[[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 The main program installation failed！" && rm -rf "${Folder}" && exit 1
	chmod +x aria2c
	echo -e "${Info} Aria2 The main program is installed! Start downloading the configuration file..."
}
Download_aria2_conf(){
	mkdir "${file}" && cd "${file}"
	wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/other/Aria2/aria2.conf"
	[[ ! -s "aria2.conf" ]] && echo -e "${Error} Aria2 Configuration file download failed !" && rm -rf "${file}" && exit 1
	wget --no-check-certificate -N "https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/other/Aria2/dht.dat"
	[[ ! -s "dht.dat" ]] && echo -e "${Error} Aria2 DHTFile download failed !" && rm -rf "${file}" && exit 1
	echo '' > aria2.session
	sed -i 's/^rpc-secret=DOUBIToyo/rpc-secret='$(date +%s%N | md5sum | head -c 20)'/g' ${aria2_conf}
}
Service_aria2(){
	if [[ ${release} = "centos" ]]; then
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/service/aria2_centos -O /etc/init.d/aria2; then
			echo -e "${Error} Aria2Service management script download failed !" && exit 1
		fi
		chmod +x /etc/init.d/aria2
		chkconfig --add aria2
		chkconfig aria2 on
	else
		if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/service/aria2_debian -O /etc/init.d/aria2; then
			echo -e "${Error} Aria2 Service management script download failed !" && exit 1
		fi
		chmod +x /etc/init.d/aria2
		update-rc.d -f aria2 defaults
	fi
	echo -e "${Info} Aria2 Service management script download completed !"
}
Installation_dependency(){
	if [[ ${release} = "centos" ]]; then
		yum update
		yum -y groupinstall "Development Tools"
		yum install nano -y
	else
		apt-get update
		apt-get install nano build-essential -y
	fi
}
Install_aria2(){
	check_root
	[[ -e ${aria2c} ]] && echo -e "${Error} Aria2 Installed, please check !" && exit 1
	check_sys
	echo -e "${Info} Start installation/configuration..."
	Installation_dependency
	echo -e "${Info} Start to download/install the main program..."
	check_new_ver
	Download_aria2
	echo -e "${Info} Start to download/install the configuration file..."
	Download_aria2_conf
	echo -e "${Info} Start download/install service script(init)..."
	Service_aria2
	Read_config
	aria2_RPC_port=${aria2_port}
	echo -e "${Info} Start setting up iptables firewall..."
	Set_iptables
	echo -e "${Info} Start adding iptables firewall rules..."
	Add_iptables
	echo -e "${Info} Start saving iptables firewall rules..."
	Save_iptables
	echo -e "${Info} All steps are installed, start to start..."
	Start_aria2
}
Start_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && echo -e "${Error} Aria2 Running, please check !" && exit 1
	/etc/init.d/aria2 start
}
Stop_aria2(){
	check_installed_status
	check_pid
	[[ -z ${PID} ]] && echo -e "${Error} Aria2 Not running, please check !" && exit 1
	/etc/init.d/aria2 stop
}
Restart_aria2(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/aria2 stop
	/etc/init.d/aria2 start
}
Set_aria2(){
	check_installed_status
	echo && echo -e "what are you going to do？
 ${Green_font_prefix}1.${Font_color_suffix}  Change Aria2 RPC password
 ${Green_font_prefix}2.${Font_color_suffix}  Modify Aria2 RPC port
 ${Green_font_prefix}3.${Font_color_suffix}  Modify the download location of Aria2 files
 ${Green_font_prefix}4.${Font_color_suffix}  Modify Aria2 password + port + file download location
 ${Green_font_prefix}5.${Font_color_suffix}  Manually open the configuration file to modify" && echo
	read -e -p "(Default: Cancel):" aria2_modify
	[[ -z "${aria2_modify}" ]] && echo "Cancelled..." && exit 1
	if [[ ${aria2_modify} == "1" ]]; then
		Set_aria2_RPC_passwd
	elif [[ ${aria2_modify} == "2" ]]; then
		Set_aria2_RPC_port
	elif [[ ${aria2_modify} == "3" ]]; then
		Set_aria2_RPC_dir
	elif [[ ${aria2_modify} == "4" ]]; then
		Set_aria2_RPC_passwd_port_dir
	elif [[ ${aria2_modify} == "5" ]]; then
		Set_aria2_vim_conf
	else
		echo -e "${Error} Please enter the correct number(1-5)" && exit 1
	fi
}
Set_aria2_RPC_passwd(){
	read_123=$1
	if [[ ${read_123} != "1" ]]; then
		Read_config
	fi
	if [[ -z "${aria2_passwd}" ]]; then
		aria2_passwd_1="Empty (the configuration is not detected, it may be manually deleted or annotated)"
	else
		aria2_passwd_1=${aria2_passwd}
	fi
	echo -e "Please enter the Aria2 RPC password to be set (the old password is：${Green_font_prefix}${aria2_passwd_1}${Font_color_suffix})"
	read -e -p "(Default password: randomly generated, please do not include the equal sign = and the hash sign #):" aria2_RPC_passwd
	echo
	[[ -z "${aria2_RPC_passwd}" ]] && aria2_RPC_passwd=$(date +%s%N | md5sum | head -c 20)
	if [[ "${aria2_passwd}" != "${aria2_RPC_passwd}" ]]; then
		if [[ -z "${aria2_passwd}" ]]; then
			echo -e "\nrpc-secret=${aria2_RPC_passwd}" >> ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} Password reset complete! The new password is：${Green_font_prefix}${aria2_RPC_passwd}${Font_color_suffix}(Because the old configuration parameters cannot be found, they are automatically added to the bottom of the configuration file)"
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} Password modification failed! The old password is：${Green_font_prefix}${aria2_passwd}${Font_color_suffix}"
			fi
		else
			sed -i 's/^rpc-secret='${aria2_passwd}'/rpc-secret='${aria2_RPC_passwd}'/g' ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} Password reset complete! The new password is：${Green_font_prefix}${aria2_RPC_passwd}${Font_color_suffix}"
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} Password modification failed! The old password is：${Green_font_prefix}${aria2_passwd}${Font_color_suffix}"
			fi
		fi
	else
		echo -e "${Error} The new password is the same as the old password, cancel..."
	fi
}
Set_aria2_RPC_port(){
	read_123=$1
	if [[ ${read_123} != "1" ]]; then
		Read_config
	fi
	if [[ -z "${aria2_port}" ]]; then
		aria2_port_1="Empty (the configuration is not detected, it may be manually deleted or annotated)"
	else
		aria2_port_1=${aria2_port}
	fi
	echo -e "Please enter the Aria2 RPC port to be set (the old port is：${Green_font_prefix}${aria2_port_1}${Font_color_suffix})"
	read -e -p "(Default port: 6800):" aria2_RPC_port
	echo
	[[ -z "${aria2_RPC_port}" ]] && aria2_RPC_port="6800"
	if [[ "${aria2_port}" != "${aria2_RPC_port}" ]]; then
		if [[ -z "${aria2_port}" ]]; then
			echo -e "\nrpc-listen-port=${aria2_RPC_port}" >> ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} The port has been modified successfully! The new port is：${Green_font_prefix}${aria2_RPC_port}${Font_color_suffix}(Because the old configuration parameters cannot be found, they are automatically added to the bottom of the configuration file)"
				Del_iptables
				Add_iptables
				Save_iptables
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} Port modification failed! The old port is：${Green_font_prefix}${aria2_port}${Font_color_suffix}"
			fi
		else
			sed -i 's/^rpc-listen-port='${aria2_port}'/rpc-listen-port='${aria2_RPC_port}'/g' ${aria2_conf}
			if [[ $? -eq 0 ]];then
				echo -e "${Info} The port has been modified successfully! The new password is：${Green_font_prefix}${aria2_RPC_port}${Font_color_suffix}"
				Del_iptables
				Add_iptables
				Save_iptables
				if [[ ${read_123} != "1" ]]; then
					Restart_aria2
				fi
			else 
				echo -e "${Error} Port modification failed! The old password is：${Green_font_prefix}${aria2_port}${Font_color_suffix}"
			fi
		fi
	else
		echo -e "${Error} The new port is the same as the old port, cancel..."
	fi
}
Set_aria2_RPC_dir(){
	read_123=$1
	if [[ ${read_123} != "1" ]]; then
		Read_config
	fi
	if [[ -z "${aria2_dir}" ]]; then
		aria2_dir_1="Empty (the configuration is not detected, it may be manually deleted or annotated)"
	else
		aria2_dir_1=${aria2_dir}
	fi
	echo -e "Please enter the download location of the Aria2 file to be set (the old location is：${Green_font_prefix}${aria2_dir_1}${Font_color_suffix})"
	read -e -p "(Default location: /usr/local/caddy/www/aria2/download):" aria2_RPC_dir
	[[ -z "${aria2_RPC_dir}" ]] && aria2_RPC_dir="/usr/local/caddy/www/aria2/download"
	echo
	if [[ -d "${aria2_RPC_dir}" ]]; then
		if [[ "${aria2_dir}" != "${aria2_RPC_dir}" ]]; then
			if [[ -z "${aria2_dir}" ]]; then
				echo -e "\ndir=${aria2_RPC_dir}" >> ${aria2_conf}
				if [[ $? -eq 0 ]];then
					echo -e "${Info} The location has been modified successfully! The new location is：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}(Because the old configuration parameters cannot be found, they are automatically added to the bottom of the configuration file)"
					if [[ ${read_123} != "1" ]]; then
						Restart_aria2
					fi
				else 
					echo -e "${Error} Location modification failed! Old location is：${Green_font_prefix}${aria2_dir}${Font_color_suffix}"
				fi
			else
				aria2_dir_2=$(echo "${aria2_dir}"|sed 's/\//\\\//g')
				aria2_RPC_dir_2=$(echo "${aria2_RPC_dir}"|sed 's/\//\\\//g')
				sed -i 's/^dir='${aria2_dir_2}'/dir='${aria2_RPC_dir_2}'/g' ${aria2_conf}
				if [[ $? -eq 0 ]];then
					echo -e "${Info} The location has been modified successfully! The new location is：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}"
					if [[ ${read_123} != "1" ]]; then
						Restart_aria2
					fi
				else 
					echo -e "${Error} Location modification failed! Old location is：${Green_font_prefix}${aria2_dir}${Font_color_suffix}"
				fi
			fi
		else
			echo -e "${Error} The new location is the same as the old location, cancel..."
		fi
	else
		echo -e "${Error} The new location folder does not exist, please check! The new location is：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}"
	fi
}
Set_aria2_RPC_passwd_port_dir(){
	Read_config
	Set_aria2_RPC_passwd "1"
	Set_aria2_RPC_port "1"
	Set_aria2_RPC_dir "1"
	Restart_aria2
}
Set_aria2_vim_conf(){
	Read_config
	aria2_port_old=${aria2_port}
	echo -e "${Tip} Notes on Manually Modifying the Configuration File（nano Text editor detailed tutorial：https://doub.io/linux-jc13/）：
${Green_font_prefix}1.${Font_color_suffix} The configuration file contains Chinese comments. If your server system or SSH tool does not support Chinese display, it will be garbled (please edit locally).
${Green_font_prefix}2.${Font_color_suffix} After the configuration file is automatically opened, you can start to edit the file manually.
${Green_font_prefix}3.${Font_color_suffix} If you want to exit and save the file, press ${Green_font_prefix}Ctrl+X key${Font_color_suffix} After entering ${Green_font_prefix}y${Font_color_suffix} After that, click again ${Green_font_prefix}enter${Font_color_suffix} Can。
${Green_font_prefix}4.${Font_color_suffix} If you want to exit without saving the file, press ${Green_font_prefix}Ctrl+X key${Font_color_suffix} After entering ${Green_font_prefix}n${Font_color_suffix} That's it.
${Green_font_prefix}5.${Font_color_suffix} If you want to edit the configuration file locally, then the configuration file location： ${Green_font_prefix}/root/.aria2/aria2.conf${Font_color_suffix} (Note that the directory is hidden) 。" && echo
	read -e -p "If you already understand how to use nano, please press any key to continue, if you want to cancel, please use Ctrl+C 。" var
	nano "${aria2_conf}"
	Read_config
	if [[ ${aria2_port_old} != ${aria2_port} ]]; then
		aria2_RPC_port=${aria2_port}
		aria2_port=${aria2_port_old}
		Del_iptables
		Add_iptables
		Save_iptables
	fi
	Restart_aria2
}
Read_config(){
	status_type=$1
	if [[ ! -e ${aria2_conf} ]]; then
		if [[ ${status_type} != "un" ]]; then
			echo -e "${Error} Aria2 The configuration file does not exist !" && exit 1
		fi
	else
		conf_text=$(cat ${aria2_conf}|grep -v '#')
		aria2_dir=$(echo -e "${conf_text}"|grep "dir="|awk -F "=" '{print $NF}')
		aria2_port=$(echo -e "${conf_text}"|grep "rpc-listen-port="|awk -F "=" '{print $NF}')
		aria2_passwd=$(echo -e "${conf_text}"|grep "rpc-secret="|awk -F "=" '{print $NF}')
	fi
	
}
View_Aria2(){
	check_installed_status
	Read_config
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ip}" ]]; then
				ip="VPS_IP(External IP detection failed)"
			fi
		fi
	fi
	[[ -z "${aria2_dir}" ]] && aria2_dir="Could not find configuration parameter"
	[[ -z "${aria2_port}" ]] && aria2_port="Could not find configuration parameter"
	[[ -z "${aria2_passwd}" ]] && aria2_passwd="Cannot find configuration parameters (or no password)"
	clear
	echo -e "\nAria2 Simple configuration information：\n
 address\t: ${Green_font_prefix}${ip}${Font_color_suffix}
 port\t: ${Green_font_prefix}${aria2_port}${Font_color_suffix}
 password\t: ${Green_font_prefix}${aria2_passwd}${Font_color_suffix}
 Table of Contents\t: ${Green_font_prefix}${aria2_dir}${Font_color_suffix}\n"
}
View_Log(){
	[[ ! -e ${aria2_log} ]] && echo -e "${Error} Aria2 Log file does not exist !" && exit 1
	echo && echo -e "${Tip} press ${Red_font_prefix}Ctrl+C${Font_color_suffix} Stop viewing logs" && echo -e "If you need to view the complete log content, please use ${Red_font_prefix}cat ${aria2_log}${Font_color_suffix} command。" && echo
	tail -f ${aria2_log}
}
Update_bt_tracker(){
	check_installed_status
	check_crontab_installed_status
	crontab_update_status=$(crontab -l|grep "aria2.sh update-bt-tracker")
	if [[ -z "${crontab_update_status}" ]]; then
		echo && echo -e "Current automatic update mode: ${Red_font_prefix}Unopened${Font_color_suffix}" && echo
		echo -e "Sure to turn on ${Green_font_prefix}Aria2 Auto update BT-Tracker server${Font_color_suffix} Function? (Under normal circumstances, the effect of BT download will be enhanced)[Y/n]"
		read -e -p "Note: This function will restart Aria2 regularly! (default: y):" crontab_update_status_ny
		[[ -z "${crontab_update_status_ny}" ]] && crontab_update_status_ny="y"
		if [[ ${crontab_update_status_ny} == [Yy] ]]; then
			crontab_update_start
		else
			echo && echo "	Cancelled..." && echo
		fi
	else
		echo && echo -e "Current automatic update mode: ${Green_font_prefix}Turned on${Font_color_suffix}" && echo
		echo -e "Sure to close ${Red_font_prefix}Aria2 Auto update BT-Tracker server${Font_color_suffix} Function? (Under normal circumstances, the effect of BT download will be enhanced)[y/N]"
		read -e -p "Note: This function will restart Aria2 regularly! (default: n):" crontab_update_status_ny
		[[ -z "${crontab_update_status_ny}" ]] && crontab_update_status_ny="n"
		if [[ ${crontab_update_status_ny} == [Yy] ]]; then
			crontab_update_stop
		else
			echo && echo "	Cancelled..." && echo
		fi
	fi
}
crontab_update_start(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/aria2.sh update-bt-tracker/d" "$file_1/crontab.bak"
	echo -e "\n0 3 * * 1 /bin/bash $file_1/aria2.sh update-bt-tracker" >> "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -f "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "aria2.sh update-bt-tracker")
	if [[ -z ${cron_config} ]]; then
		echo -e "${Error} Aria2 Automatic update of BT-Tracker server failed to start !" && exit 1
	else
		echo -e "${Info} Aria2 Automatically update the BT-Tracker server and start successfully !"
		Update_bt_tracker_cron
	fi
}
crontab_update_stop(){
	crontab -l > "$file_1/crontab.bak"
	sed -i "/aria2.sh update-bt-tracker/d" "$file_1/crontab.bak"
	crontab "$file_1/crontab.bak"
	rm -f "$file_1/crontab.bak"
	cron_config=$(crontab -l | grep "aria2.sh update-bt-tracker")
	if [[ ! -z ${cron_config} ]]; then
		echo -e "${Error} Aria2 Automatic update of BT-Tracker server Stop failure !" && exit 1
	else
		echo -e "${Info} Aria2 Automatically update the BT-Tracker server and stop successfully !"
	fi
}
Update_bt_tracker_cron(){
	check_installed_status
	check_pid
	[[ ! -z ${PID} ]] && /etc/init.d/aria2 stop
	bt_tracker_list=$(wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt |awk NF|sed ":a;N;s/\n/,/g;ta")
	if [ -z "`grep "bt-tracker" ${aria2_conf}`" ]; then
		sed -i '$a bt-tracker='${bt_tracker_list} "${aria2_conf}"
		echo -e "${Info} Added successfully..."
	else
		sed -i "s@bt-tracker.*@bt-tracker=$bt_tracker_list@g" "${aria2_conf}"
		echo -e "${Info} update completed..."
	fi
	/etc/init.d/aria2 start
}
Update_aria2(){
	check_installed_status
	check_new_ver
	check_ver_comparison
}
Uninstall_aria2(){
	check_installed_status "un"
	echo "Sure to uninstall Aria2 ? (y/N)"
	echo
	read -e -p "(default: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		crontab -l > "$file_1/crontab.bak"
		sed -i "/aria2.sh/d" "$file_1/crontab.bak"
		crontab "$file_1/crontab.bak"
		rm -f "$file_1/crontab.bak"
		check_pid
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config "un"
		Del_iptables
		Save_iptables
		cd "${Folder}"
		make uninstall
		cd ..
		rm -rf "${aria2c}"
		rm -rf "${Folder}"
		rm -rf "${file}"
		if [[ ${release} = "centos" ]]; then
			chkconfig --del aria2
		else
			update-rc.d -f aria2 remove
		fi
		rm -rf "/etc/init.d/aria2"
		echo && echo "Aria2 Uninstall complete !" && echo
	else
		echo && echo "Uninstall canceled..." && echo
	fi
}
Add_iptables(){
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${aria2_RPC_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${aria2_RPC_port} -j ACCEPT
}
Del_iptables(){
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${aria2_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${aria2_port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/aria2.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} Can't link to Github !" && exit 0
	if [[ -e "/etc/init.d/aria2" ]]; then
		rm -rf /etc/init.d/aria2
		Service_aria2
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/ToyoDAdoubiBackup/doubi/master/aria2.sh" && chmod +x aria2.sh
	echo -e "The script has been updated to the latest version[ ${sh_new_ver} ] !(Note: Because the update method is to directly overwrite the currently running script, some errors may be prompted below, just ignore it)" && exit 0
}
action=$1
if [[ "${action}" == "update-bt-tracker" ]]; then
	Update_bt_tracker_cron
else
echo && echo -e " Aria2 One-click installation management script ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
  -- Toyo | doub.io/shell-jc4 --
  
 ${Green_font_prefix} 0.${Font_color_suffix} Upgrade script
————————————
 ${Green_font_prefix} 1.${Font_color_suffix} Install Aria2
 ${Green_font_prefix} 2.${Font_color_suffix} Update Aria2
 ${Green_font_prefix} 3.${Font_color_suffix} Uninstall Aria2
————————————
 ${Green_font_prefix} 4.${Font_color_suffix} Start Aria2
 ${Green_font_prefix} 5.${Font_color_suffix} Stop Aria2
 ${Green_font_prefix} 6.${Font_color_suffix} Restart Aria2
————————————
 ${Green_font_prefix} 7.${Font_color_suffix} Modify the configuration file
 ${Green_font_prefix} 8.${Font_color_suffix} View configuration information
 ${Green_font_prefix} 9.${Font_color_suffix} View log information
 ${Green_font_prefix}10.${Font_color_suffix} Configure automatic update of BT-Tracker server
————————————" && echo
if [[ -e ${aria2c} ]]; then
	check_pid
	if [[ ! -z "${PID}" ]]; then
		echo -e " Current state: ${Green_font_prefix}It has been installed${Font_color_suffix} and ${Green_font_prefix}Activated${Font_color_suffix}"
	else
		echo -e " Current state: ${Green_font_prefix}It has been installed${Font_color_suffix} but ${Red_font_prefix}has not started${Font_color_suffix}"
	fi
else
	echo -e " Current state: ${Red_font_prefix}Not Installed${Font_color_suffix}"
fi
echo
read -e -p " Please key in numbers [0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_aria2
	;;
	2)
	Update_aria2
	;;
	3)
	Uninstall_aria2
	;;
	4)
	Start_aria2
	;;
	5)
	Stop_aria2
	;;
	6)
	Restart_aria2
	;;
	7)
	Set_aria2
	;;
	8)
	View_Aria2
	;;
	9)
	View_Log
	;;
	10)
	Update_bt_tracker
	;;
	*)
	echo "Please enter the correct number [0-10]"
	;;
esac
fi