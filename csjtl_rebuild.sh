#!/bin/bash
set -x on

if [ "$USER" == "root" ]; then
	echo "请勿使用root用户编译，换一个普通用户吧~~"
	exit 0
fi

function STEP_RESULT(){
	if [ "$?" == "0" ]; then
	echo "$EVERY_STEP完成"
	else
	echo "$EVERY_STEP失败"
	exit
fi
}

#------------------diy配置区------------------------------
#DIY_BANNER
DIY_BANNER='  _______                     ________        __
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
DIY_IP=192.168.7.1

#bootstrap material openwrt openwrt-2020
DIY_THEME='bootstrap'

#DIY_HOSTNAME DIY_TIMEZONE DIY_ZONENAME
DIY_HOSTNAME='CSJTL-NAME'
DIY_TIMEZONE='CST-8'
DIY_ZONENAME='Asia/Shanghai'

#DIY_PASSWORD DIY_USERNAME
DIY_USERNAME='csjtl'
DIY_PASSWORD='csjtl'

#--------------------------------------------------------------

cd openwrt
#make clean
#./scripts/feeds update -a

#--------------------diy执行区--------------------------------
EVERY_STEP='diy执行'
#DIY_BANNER
echo "$DIY_BANNER" > ./package/base-files/files/etc/banner

#DIY_IP
grep 'lan) ipad=${ipaddr' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
OLD_IP=$(grep -oP '((\d)+.){3}\d+' ../diy/tmp/tmp)
sed -i "s/$OLD_IP/$DIY_IP/" ./package/base-files/files/bin/config_generate
sed -i "s/$OLD_IP/$DIY_IP/" ./package/base-files/files/etc/ethers
sed -i "s/$OLD_IP/$DIY_IP/" ./package/base-files/Makefile

#diy_ttyd
echo "config ttyd
    option interface '@lan'
    option debug '7'
    option command '/bin/login -f root'
    option ssl '1'
    option ssl_cert '/etc/nginx/conf.d/_lan.crt'
    option ssl_key '/etc/nginx/conf.d/_lan.key'" > ./feeds/packages/utils/ttyd/files/ttyd.config

#diy_nginx
cp ../diy/etc/config/nginx/nginx.config ./feeds/packages/net/nginx-util/files/
#diy_hotkey_nginx
#cp ../diy/etc/config/nginx/conf.d/hotkey.conf ./feeds/packages/net/nginx/files-luci-support

#DIY_THEME
sed -i "/CONFIG_PACKAGE_luci-theme-/d" .config
echo "
CONFIG_PACKAGE_luci-theme-$DIY_THEME=y" >> .config

#DIY_HOSTNAME
grep 'set system.\@system\[-1\].hostname=' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
TMP=$(cat ../diy/tmp/tmp)
TMP=$"${TMP#*\'}"
OLD_HOSTNAME=$"${TMP%*\'}"
sed -i "s/hostname='$OLD_HOSTNAME'/hostname='$DIY_HOSTNAME'/" ./package/base-files/files/bin/config_generate
#DIY_TIMEZONE
grep 'set system.\@system\[-1\].timezone=' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
TMP=$(cat ../diy/tmp/tmp)
TMP=$"${TMP#*\'}"
OLD_TIMEZONE=$"${TMP%*\'}"
sed -i "s*timezone='$OLD_TIMEZONE'*timezone='$DIY_TIMEZONE'*" ./package/base-files/files/bin/config_generate
#DIY_ZONENAME
sed -i '/ystem\[-1\].zonename=/d' ./package/base-files/files/bin/config_generate
sed -i "/set system.\@system\[-1\].hostname=/a\        set system.@system[-1].zonename='Asia/Shanghai'" ./package/base-files/files/bin/config_generate
#DIY_PASSWORD
#./package/system/rpcd/files/rpcd.config
#openwrt/package/base-files/files/etc/passwd
#openwrt/package/base-files/files/etc/shadow
#openwrt/feeds/luci/modules/luci-mod-admin-mini/luasrc/controller/mini/index.lua
#openwrt/package/system/rpcd/files/rpcd.config
#openwrt/feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
STEP_RESULT
exit
#-------------------------------------------------------------


<< EOF
EOF

#./scripts/feeds install -a

EVERY_STEP='编译'
while :; do
read -p "1.menuconfig; 2.defconfig \n 选择" CHOOSE
case $CHOOSE in
	1)	make menuconfig
	break
	;;
	2)	make defconfig
	break
	;;
esac
done

#make -j$(($(nproc)+1)) download V=s
make -j$(($(nproc)+1)) V=s || make -j1 V=s
STEP_RESULT

EVERY_STEP='固件拷贝'
rm -f /home/$USER/openwrt_x86/bin/packages/x86_64/* /home/$USER/openwrt_x86/bin/firmware/x86_64/*
cp ./bin/packages/x86_64/*/*.ipk /home/$USER/openwrt_x86/bin/packages/x86/64/
cp ./bin/targets/x86/64/*.img.gz /home/$USER/openwrt_x86/bin/firmware/x86/64/

#ln -sf /home/$USER/openwrt_x86/bin/packages /var/www/openwrt/www/bin
#ln -sf /home/$USER/openwrt_x86/bin/firmware /var/www/openwrt/www/bin
STEP_RESULT


# OpenWrt Firmware Selector
#$ sudo ./misc/collect.py --image-url 'http://10.0.0.134/bin/firmware/{target}' /home/csjtl/work/csjtl-openwrt/openwrt/bin www/

#--------------------------------diy恢复#区--------------------------------------------------------
EVERY_STEP='diy恢复'
#恢复banner
echo '  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 -----------------------------------------------------
 %D %V, %C
 -----------------------------------------------------' > ./package/base-files/files/etc/banner
#恢复ip
sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/files/bin/config_generate
sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/files/etc/ethers
sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/Makefile
#恢复ttyd
echo "config ttyd
	option interface '@lan'
	option command '/bin/login'" > ./feeds/packages/utils/ttyd/files/ttyd.config
#恢复nginx
cp ../diy/tmp/nginx.config ./package/feeds/packages/nginx-util/files/
#rm ./feeds/packages/net/nginx/files-luci-support/hotkey.conf
#恢复theme
sed -i "/CONFIG_PACKAGE_luci-theme-$DIY_THEME=y/d" .config
#恢复DIY_HOSTNAME
sed -i "s/hostname='$DIY_HOSTNAME'/hostname='OpenWrt'/" ./package/base-files/files/bin/config_generate
#恢复DIY_TIMEZONE
sed -i "s*timezone='$DIY_TIMEZONE'*timezone='UTC'*" ./package/base-files/files/bin/config_generate

sed -i '/ystem\[-1\].zonename=/d' ./package/base-files/files/bin/config_generate
STEP_RESULT
#----------------------------------------------------------------------------------------------


