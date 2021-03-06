#!/bin/bash
#set -x on

function diy_config(){
	#diy配置区
	#DIY_BANNER
	DIY_BANNER='
  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 A   OPENWRT_ARCH %A
 b   BUG_URL %b
 C   %C
 d   ID %d
 D   NAME %D
 DVC OPENWRT_RELEASE %D %V %C
 DV  PRETTY_NAME %D %V
 h   OPENWRT_DEVICE_REVISION %h
 M   OPENWRT_DEVICE_MANUFACTURER %M
 m   OPENWRT_DEVICE_MANUFACTURER_URL %m
 P   OPENWRT_DEVICE_PRODUCT %P
 R   BUILD_ID %R
 S   OPENWRT_BOARD %S
 s   SUPPORT_URL %s
 t   OPENWRT_TAINTS %t
 u   HOME_URL %u
 v   VERSION_ID %v
 V   VERSION %V
 -----------------------------------------------------'

	#DIY_IP
	DIY_IP=10.0.0.1
	#ttyd自定义登录
	DIY_TTYD='y'
	#nginx 80 端口
	DIY_NGINX='y'
	#bootstrap material openwrt openwrt-2020
	DIY_THEME='bootstrap'

	#DIY_HOSTNAME DIY_TIMEZONE DIY_ZONENAME
	DIY_HOSTNAME='A-OpenWrt'
	DIY_TIMEZONE='CST-8'
	DIY_ZONENAME='Asia/Shanghai'

	#DIY_PASSWORD DIY_USERNAME
	DIY_USERNAME='admin'
	DIY_PASSWORD=''

	#DIY_HIDE
	DIY_HIDE='n'

	#packages
	if [ ! `grep -c csjtl openwrt/feeds.conf.default` -ne '0' ];then
    	echo "src-git-full csjtl https://github.com/csjtl/openwrt-packages-backup.git" >> openwrt/feeds.conf.default
	fi
	#url=('https://github.com/csjtl/openwrt-packages-backup/trunk/autocore'
    #    'https://github.com/csjtl/openwrt-packages-backup/trunk/luci-app-fileassistant'
    #    'https://github.com/csjtl/openwrt-packages-backup/trunk/luci-app-openclash')
}

function start_compile(){
		while :; do
		echo "1.build; 2.rebuild"
		read -p "选择: " CHOOSE
		case $CHOOSE in
			1)	rm -rf openwrt

				if [ ! -d "openwrt" ]; then
				#	ln -sf /mnt/win/GitHub/csjtl-openwrt-script/diy /home/csjtl/project/x86
				#	ln -sf /mnt/win/GitHub/csjtl-openwrt-script/csjtl_build.sh /home/csjtl/project/x86
				#   ln -sf /mnt/win/GitHub/csjtl-openwrt-script/uci-set.sh /home/csjtl/project/x86
				#	ln -sf /mnt/win/GitHub/csjtl-openwrt-script/.config /home/csjtl/project/x86/openwrt

					git clone https://github.com/openwrt/openwrt.git

					mkdir -p /home/csjtl/project/x86/openwrt-x86/dl /home/csjtl/project/x86/openwrt-x86/build_dir /home/csjtl/project/x86/openwrt-x86/staging_dir
					ln -sf /home/csjtl/project/x86/openwrt-x86/build_dir /home/csjtl/project/x86/openwrt
					ln -sf /home/csjtl/project/x86/openwrt-x86/dl /home/csjtl/project/x86/openwrt
					ln -sf /home/csjtl/project/x86/openwrt-x86/staging_dir /home/csjtl/project/x86/openwrt
					ln -sf /home/csjtl/project/x86/openwrt-x86/feeds /home/csjtl/project/x86/openwrt

					diy_config
					cd openwrt
					./scripts/feeds update -a
					diy_config_run
					./scripts/feeds install -a
					cp /mnt/win/GitHub/csjtl-openwrt-script/.config .
					make_config
					make -j$(($(nproc)+1)) download V=s
					make -j1 V=s || make -j$(($(nproc)+1)) V=s
					copy_firmware
					diy_config_recover
					exit
				fi
			break
			;;
			2)
			break
			;;
		esac
	done
	
}

function make_config(){
	every_step='编译'
	cp /mnt/win/GitHub/csjtl-openwrt-script/.config .
	while :; do
		echo "1.menuconfig; 2.defconfig"
		read -p "选择: " CHOOSE
		case $CHOOSE in
			1)	make menuconfig
			break
			;;
			2)	make defconfig
			break
			;;
		esac
	done
}

function diy_config_run(){
	#DIY_BANNER
	echo "$DIY_BANNER" > ./package/base-files/files/etc/banner

	#DIY_IP
	DIY_IP=${DIY_IP:=192.168.1.1}
	ip_broadcast=`echo $DIY_IP | awk -F "." '{print $1"."$2"."$3"."255}'`
	IP_LAN=`echo $DIY_IP | awk -F "." '{print $1"."$2".""$((addr_offset++))""."$4}'`

	grep 'lan) ipad=${ipaddr' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
	old_ip=$(grep -oP '((\d)+.){3}\d+' ../diy/tmp/tmp)
	sed -i "s/$old_ip/$DIY_IP/" ./package/base-files/files/bin/config_generate
	#sed -i "s/$old_ip/$DIY_IP/" ./package/base-files/files/etc/ethers
	#sed -i "s/$old_ip/$DIY_IP/" ./package/base-files/Makefile
	grep '*) ipad=${ipaddr' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
	old_ip_lan=`awk -F "[\"\"]" '{print $2}' ../diy/tmp/tmp`
	sed -i "s/$old_ip_lan/$IP_LAN/" ./package/base-files/files/bin/config_generate

	#diy_ttyd
	if [ "$DIY_TTYD" == 'y' ];then
		echo "config ttyd
		    option interface '@lan'
		    option debug '7'
		    option command '/bin/login -f root'" > ./feeds/packages/utils/ttyd/files/ttyd.config
		sed -i "s/login -f root/login -f "$DIY_USERNAME"/" ./feeds/packages/utils/ttyd/files/ttyd.config
	fi

	#diy_nginx
	if [ "$DIY_NGINX" == 'y' ];then
	cp ../diy/etc/config/nginx/nginx.config ./feeds/packages/net/nginx-util/files/
	#diy_hotkey_nginx
	#cp ../diy/etc/config/nginx/conf.d/hotkey.conf ./feeds/packages/net/nginx/files-luci-support
	fi

	#DIY_THEME
	DIY_THEME=${DIY_THEME:='bootstrap'}
	sed -i "/CONFIG_PACKAGE_luci-theme-/d" .config
	echo "CONFIG_PACKAGE_luci-theme-$DIY_THEME=y" >> .config

	#DIY_HOSTNAME
	#grep 'set system.\@system\[-1].hostname=' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
	#temp=$(cat ../diy/tmp/tmp)
	#temp=$"${temp#*\'}"
	#OLD_KEYWORDS=$"${temp%*\'}"
	#sed -i "s/hostname='$OLD_KEYWORDS'/hostname='$DIY_HOSTNAME'/" ./package/base-files/files/bin/config_generate

	DIY_HOSTNAME=${DIY_HOSTNAME:='OpenWrt'}
	function filter_keywords(){
		grep "$1" ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
		temp=$(cat ../diy/tmp/tmp)
		temp=$"${temp#*\'}"
		OLD_KEYWORDS=$"${temp%*\'}"
	}
	filter_keywords "set system.\@system\[-1].hostname="
	sed -i "s/hostname='$OLD_KEYWORDS'/hostname='$DIY_HOSTNAME'/" ./package/base-files/files/bin/config_generate

	#DIY_TIMEZONE
	DIY_TIMEZONE=${DIY_TIMEZONE:='UTC'}
	filter_keywords "set system.\@system\[-1].timezone="
	sed -i "s*timezone='$OLD_KEYWORDS'*timezone='$DIY_TIMEZONE'*" ./package/base-files/files/bin/config_generate

	#DIY_ZONENAME
	if [ -n "$DIY_ZONENAME" ];then
		sed -i '/@system\[-1].zonename=/d' ./package/base-files/files/bin/config_generate
		sed -i "/set system.\@system\[-1].hostname=/a\                set system.\@system\[-1].zonename='Asia/Shanghai'" ./package/base-files/files/bin/config_generate
		else 
		sed -i '/@system\[-1].zonename=/d' ./package/base-files/files/bin/config_generate
	fi

	##DIY_USERNAME
	##./package/system/rpcd/files/rpcd.config
	DIY_USERNAME=${DIY_USERNAME:='root'}
	function filter_keywords(){
		grep "$1" ./package/system/rpcd/files/rpcd.config > ../diy/tmp/tmp
		temp=$(cat ../diy/tmp/tmp)
		temp=$"${temp#*\'}"
		OLD_KEYWORDS=$"${temp%*\'}"
	}
	filter_keywords "option username "
	sed -i "s*option username '$OLD_KEYWORDS'*option username '$DIY_USERNAME'*" ./package/system/rpcd/files/rpcd.config
	filter_keywords "option password "
	sed -i "s*option password '\$p\$$OLD_KEYWORDS'*option password '\$p\$$DIY_USERNAME'*" ./package/system/rpcd/files/rpcd.config

	##openwrt/package/base-files/files/etc/passwd
	temp=`head -1 ./package/base-files/files/etc/passwd`
	temp=${temp%%:*}
	path="/root/$DIY_USERNAME"
	if [[ "$temp" != root ]] && [[ "$DIY_USERNAME" != root ]]; then
			sed -i '1d' ./package/base-files/files/etc/passwd
			sed -i "1i\\$DIY_USERNAME:x:0:0:root:$path:/bin/ash" ./package/base-files/files/etc/passwd
		elif [[ "$temp" != root ]] && [[ "$DIY_USERNAME" == root ]]; then
			sed -i '1d' ./package/base-files/files/etc/passwd
		elif [[ "$temp" == root ]] && [[ "$DIY_USERNAME" != root ]]; then
			sed -i "1i\\$DIY_USERNAME:x:0:0:root:$path:/bin/ash" ./package/base-files/files/etc/passwd
		else 
			echo
	fi

	##openwrt/package/base-files/files/etc/shadow
	temp=`head -1 ./package/base-files/files/etc/shadow`
	temp=${temp%%:*}
	if [[ "$temp" != root ]] && [[ "$DIY_USERNAME" != root ]]; then
			sed -i '1d' ./package/base-files/files/etc/shadow
			sed -i "1i\\$DIY_USERNAME:::0:99999:7:::" ./package/base-files/files/etc/shadow
		elif [[ "$temp" != root ]] && [[ "$DIY_USERNAME" == root ]]; then
			sed -i '1d' ./package/base-files/files/etc/shadow
		elif [[ "$temp" == root ]] && [[ "$DIY_USERNAME" != root ]]; then
			sed -i "1i\\$DIY_USERNAME:::0:99999:7:::" ./package/base-files/files/etc/shadow
		else
			echo
	fi

	#DIY_PASSWORD
	awk 'BEGIN {FS=":"; OFS=":";}  {if ($0 ~ /^root/) {print $1,"",$3,$4,$5,$6,"::";} else {print $0;}}' < ./package/base-files/files/etc/shadow > ../diy/tmp/tmp
	mv ../diy/tmp/tmp ./package/base-files/files/etc/shadow
	if [ -n "$DIY_PASSWORD" ];then
			passwd=$(openssl passwd -1 ${DIY_PASSWORD})
		if [ $DIY_USERNAME != root ];then
			awk 'BEGIN {FS=":"; OFS=":";}  {if ($0 ~ /^'$DIY_USERNAME'/) {print $1,"'$passwd'",$3,$4,$5,$6,"::";} else {print $0;}}' < ./package/base-files/files/etc/shadow > ../diy/tmp/tmp
			mv ../diy/tmp/tmp ./package/base-files/files/etc/shadow
			awk 'BEGIN {FS=":"; OFS=":";}  {if ($0 ~ /^root/) {print $1,"'$passwd'",$3,$4,$5,$6,"::";} else {print $0;}}' < ./package/base-files/files/etc/shadow > ../diy/tmp/tmp
			mv ../diy/tmp/tmp ./package/base-files/files/etc/shadow
			else
			awk 'BEGIN {FS=":"; OFS=":";}  {if ($0 ~ /^'$DIY_USERNAME'/) {print $1,"'$passwd'",$3,$4,$5,$6,"::";} else {print $0;}}' < ./package/base-files/files/etc/shadow > ../diy/tmp/tmp
			mv ../diy/tmp/tmp ./package/base-files/files/etc/shadow
		fi
	fi

	##openwrt/feeds/luci/modules/luci-mod-admin-mini/luasrc/controller/mini/index.lua
	#sed -i "s/page.sysauth = \"$temp\"/page.sysauth = \"$DIY_USERNAME\"/" ./feeds/luci/modules/luci-mod-admin-mini/luasrc/controller/mini/index.lua
	grep 'duser = ' ./feeds/luci/modules/luci-base/luasrc/dispatcher.lua > ../diy/tmp/tmp
	temp=`awk -F "[\"\"]" '{print $2}' ../diy/tmp/tmp`
	sed -i "s/duser = \"$temp\"/duser = \"$DIY_USERNAME\"/" ./feeds/luci/modules/luci-base/luasrc/dispatcher.lua

	#openwrt/feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/password.js
	grep 'return callSetPassword(' ./feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/password.js > ../diy/tmp/tmp
	temp=`awk -F "['']" '{print $2}' ../diy/tmp/tmp`
	sed -i "s/callSetPassword('$temp'/callSetPassword('$DIY_USERNAME'/" ./feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/password.js

	#DIY_HIDE
	##openwrt/feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
	if [ "$DIY_HIDE" == "y" ];then
			sed -i "s/value=\"<%=duser%>\"/value=\"\"/" ./feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
			sed -i "s/type=\"text\"<%=attr(\"value\", duser)%>/type=\"text\"/" ./feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm
		else
			sed -i "s/value=\"\"/value=\"<%=duser%>\"/" ./feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
			sed -i "s/type=\"text\"/type=\"text\"<%=attr(\"value\", duser)%>/" ./feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm
	fi

	#packages

	#echo "1.update custom packages; 2.no update"
	#read -p "选择: " CHOOSE
	#if [ "$CHOOSE" == 1 ]; then
	#	rm -rf ./package/feeds/csjtl*
	#	mkdir -p ./package/feeds/csjtl
	#	cd ./package/feeds/csjtl
	#	for packages_link in ${url[@]}
    #	do
    #    	svn export $packages_link
    #	done
	#	cd -
	#fi


}

function diy_config_recover(){
	#diy恢复#区
	every_step='diy恢复'
	#恢复banner
	echo -e "  _______                     ________        __\n |       |.-----.-----.-----.|  |  |  |.----.|  |_\n |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|\n |_______||   __|_____|__|__||________||__|  |____|\n          |__| W I R E L E S S   F R E E D O M\n -----------------------------------------------------\n %D %V, %C\n -----------------------------------------------------" > ./package/base-files/files/etc/banner
	#恢复ip
	#sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/files/etc/ethers
	#sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/Makefile
	sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/files/bin/config_generate
	sed -i "s/$IP_LAN/192.168.\$((addr_offset++)).1/" ./package/base-files/files/bin/config_generate
	#恢复ttyd
	echo -e "config ttyd\n	option interface '@lan'\n	option command '/bin/login'" > ./feeds/packages/utils/ttyd/files/ttyd.config
	#恢复nginx
	cp ../diy/tmp/nginx.config ./package/feeds/packages/nginx-util/files/
	#rm ./feeds/packages/net/nginx/files-luci-support/hotkey.conf
	#恢复theme
	sed -i "/CONFIG_PACKAGE_luci-theme-$DIY_THEME=y/d" .config
	#恢复DIY_HOSTNAME
	sed -i "s/hostname='$DIY_HOSTNAME'/hostname='OpenWrt'/" ./package/base-files/files/bin/config_generate
	#恢复DIY_TIMEZONE
	sed -i "s*timezone='$DIY_TIMEZONE'*timezone='UTC'*" ./package/base-files/files/bin/config_generate
	#恢复DIY_ZONENAME
	sed -i '/ystem\[-1\].zonename=/d' ./package/base-files/files/bin/config_generate
	#恢复DIY_USERNAME DIY_PASSWORD
	sed -i "s*option username '$DIY_USERNAME'*option username 'root'*" ./package/system/rpcd/files/rpcd.config
	sed -i "s*option password '\$p\$$DIY_USERNAME'*option password '\$p\$root'*" ./package/system/rpcd/files/rpcd.config
	if [ "$DIY_USERNAME" != "root" ]; then
		sed -i '1d' ./package/base-files/files/etc/passwd
		sed -i '1d' ./package/base-files/files/etc/shadow
		awk 'BEGIN {FS=":"; OFS=":";}  {if ($0 ~ /^root/) {print $1,"",$3,$4,$5,$6,"::";} else {print $0;}}' < ./package/base-files/files/etc/shadow > ../diy/tmp/tmp
		mv ../diy/tmp/tmp ./package/base-files/files/etc/shadow
		else
		awk 'BEGIN {FS=":"; OFS=":";}  {if ($0 ~ /^root/) {print $1,"",$3,$4,$5,$6,"::";} else {print $0;}}' < ./package/base-files/files/etc/shadow > ../diy/tmp/tmp
		mv ../diy/tmp/tmp ./package/base-files/files/etc/shadow
	fi
	sed -i "s/duser = \"$DIY_USERNAME\"/duser = \"root\"/" ./feeds/luci/modules/luci-base/luasrc/dispatcher.lua
	sed -i "s/callSetPassword('$DIY_USERNAME'/callSetPassword('root'/" ./feeds/luci/modules/luci-mod-system/htdocs/luci-static/resources/view/system/password.js
	#恢复DIY_HIDE
	sed -i "s/value=\"\"/value=\"<%=duser%>\"/" ./feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
	sed -i "s/type=\"text\"/type=\"text\"<%=attr(\"value\", duser)%>/" ./feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm
	#packages
    sed -i '/csjtl/d' ./feeds.conf.default
}

function copy_firmware(){
	every_step='固件拷贝'
	#rm -rf /home/$USER/openwrt_x86/bin/packages/x86/64/* /home/$USER/openwrt_x86/bin/firmware/x86/64/*
	#cp ./bin/packages/x86_64/*/*.ipk /home/$USER/openwrt_x86/bin/packages/x86/64/
	cp .config /mnt/win/GitHub/csjtl-openwrt-script/
	rm -rf /mnt/win/*.img.gz
	cp ./bin/targets/x86/64/*efi.img.gz /mnt/win/
	
	#ln -sf /home/$USER/openwrt_x86/bin/packages /var/www/openwrt/www/bin
	#ln -sf /home/$USER/openwrt_x86/bin/firmware /var/www/openwrt/www/bin
	
	#网页固件选择
	# OpenWrt Firmware Selector
	#$ sudo ./misc/collect.py --image-url 'http://10.0.0.134/bin/firmware/{target}' /home/csjtl/work/csjtl-openwrt/openwrt/bin www/
}

function step_result(){
	if [ "$?" == "0" ]; then
		echo "$every_step完成"
	else
		echo "$every_step失败"
		exit
	fi
}

function feeds_update(){
	./scripts/feeds update -a
}

function feeds_install(){
	./scripts/feeds install -a
}

#set -x on
diy_config
start_compile
cd openwrt
#make clean
#git pull
#feeds_update
#diy_config_run
#feeds_install
make_config
#make -j$(($(nproc)+1)) download V=s
make -j$(($(nproc)+1)) V=s || make -j1 V=s
copy_firmware
diy_config_recover
step_result

<< EOF
EOF

