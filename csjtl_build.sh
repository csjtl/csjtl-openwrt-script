#!/bin/bash
set -x on

if [ "$USER" == "root" ]; then
	echo
	echo
	echo "请勿使用root用户编译，换一个普通用户吧~~"
	sleep 3s
	exit 0
fi

echo "

1. X86_64

2. Exit

"

while :; do

read -p "你想要编译哪个固件？ " CHOOSE

case $CHOOSE in
	1)
		firmware="x86_64"
	break
	;;
	2)	exit 0
	;;

esac
done


#REPO_BRANCH="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | jq -r '.[].name' | grep v21 | head -n 1 | sed -e 's/v//')"
#REPO_CLONE_BRANCH="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | jq -r '.[].name' | grep v21 | head -n 1 | sed -e 's/v//' | cut -b1-5)"


if [ -d "openwrt" ]; then
		cd openwrt
	else
		git clone https://github.com/openwrt/openwrt.git

		#sudo mkdir -p -m 755 /home/$USER/openwrt_x86/dl /home/$USER/openwrt_x86/build_dir /home/$USER/openwrt_x86/staging_dir/hostpkg
		ln -sf /home/$USER/openwrt_x86/build_dir/hostpkg $PWD/openwrt/build_dir
		ln -sf /home/$USER/openwrt_x86/dl $PWD/openwrt
		ln -sf /home/$USER/openwrt_x86/staging_dir $PWD/openwrt
		
		cd openwrt
fi


#./scripts/feeds update -a && ./scripts/feeds install -a
exit
make menuconfig

make -j$(($(nproc)+1)) download V=s
make -j$(($(nproc)+1)) V=s || make -j1 V=s

if [ "$?" == "0" ]; then
	echo "编译完成~~~"
	else
	echo "gameover"
fi

rm -f /home/$USER/openwrt_x86/bin/packages/x86_64/* /home/$USER/openwrt_x86/bin/firmware/x86_64/*
cp ./bin/packages/x86_64/*/*.ipk /home/$USER/openwrt_x86/bin/packages/x86/64/
cp ./bin/targets/x86/64/*.img.gz /home/$USER/openwrt_x86/bin/firmware/x86/64/

sudo -i
ln -sf /home/$USER/openwrt_x86/bin/packages /var/www/openwrt/www/bin
ln -sf /home/$USER/openwrt_x86/bin/firmware /var/www/openwrt/www/bin
exit

if [ "$?" == "0" ]; then
	echo "cp over"
	else
	echo "gameover"
fi


# OpenWrt Firmware Selector
#$ sudo ./misc/collect.py --image-url 'http://10.0.0.134/bin/firmware/{target}' /home/csjtl/work/csjtl-openwrt/openwrt/bin www/



