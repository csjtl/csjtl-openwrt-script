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


REPO_BRANCH="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | jq -r '.[].name' | grep v21 | head -n 1 | sed -e 's/v//')"
REPO_CLONE_BRANCH="$(curl -s https://api.github.com/repos/openwrt/openwrt/tags | jq -r '.[].name' | grep v21 | head -n 1 | sed -e 's/v//' | cut -b1-5)"


if [ -d "openwrt" ]; then
		cd openwrt
	else
		git clone -b v$REPO_BRANCH https://github.com/openwrt/openwrt

		#sudo mkdir -p -m 755 /home/$USER/openwrt_x86/dl /home/$USER/openwrt_x86/build_dir /home/$USER/openwrt_x86/staging_dir/hostpkg
		ln -sf /home/$USER/openwrt_x86/build_dir/hostpkg $PWD/openwrt/build_dir
		ln -sf /home/$USER/openwrt_x86/dl $PWD/openwrt
		ln -sf /home/$USER/openwrt_x86/staging_dir $PWD/openwrt
		
		cd openwrt
fi

if [[ $firmware == "x86_64" ]]; then
		curl -fL -o sdk.tar.xz https://mirrors.cloud.tencent.com/openwrt/releases/$REPO_BRANCH/targets/x86/64/openwrt-sdk-$REPO_BRANCH-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz || curl -fL -o sdk.tar.xz https://downloads.openwrt.org/releases/21.02-SNAPSHOT/targets/x86/64/openwrt-sdk-21.02-SNAPSHOT-x86-64_gcc-8.4.0_musl.Linux-x86_64.tar.xz
	elif [[ $firmware == nanopi-* ]]; then
		curl -fL -o sdk.tar.xz https://mirrors.cloud.tencent.com/openwrt/releases/$REPO_BRANCH/targets/rockchip/armv8/openwrt-sdk-$REPO_BRANCH-rockchip-armv8_gcc-8.4.0_musl.Linux-x86_64.tar.xz || curl -fL -o sdk.tar.xz https://downloads.openwrt.org/releases/21.02-SNAPSHOT/targets/rockchip/armv8/openwrt-sdk-21.02-SNAPSHOT-rockchip-armv8_gcc-8.4.0_musl.Linux-x86_64.tar.xz
	elif [[ $firmware == "Rpi-4B" ]]; then
		curl -fL -o sdk.tar.xz https://mirrors.cloud.tencent.com/openwrt/releases/$REPO_BRANCH/targets/bcm27xx/bcm2711/openwrt-sdk-$REPO_BRANCH-bcm27xx-bcm2711_gcc-8.4.0_musl.Linux-x86_64.tar.xz || curl -fL -o sdk.tar.xz https://downloads.openwrt.org/releases/21.02-SNAPSHOT/targets/bcm27xx/bcm2711/openwrt-sdk-21.02-SNAPSHOT-bcm27xx-bcm2711_gcc-8.4.0_musl.Linux-x86_64.tar.xz
fi

mkdir sdk
tar -xJf sdk.tar.xz -C sdk
mv -rf sdk/*/staging_dir/* ./staging_dir/

./scripts/feeds update -a && ./scripts/feeds install -a

<< EOF
read -p "请输入后台地址 [回车默认192.168.1.1]: " ip
ip=${ip:-"192.168.1.1"}
echo "您的后台地址为: $ip"
EOF

<< EOF
EOF

make menuconfig

make -j$(($(nproc)+1)) download V=s
make -j1 V=s || make -j$(($(nproc)+1)) V=s

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



