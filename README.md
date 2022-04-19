
#### 学习而已。OpenWrt 源码版本是 22.03 。Ubuntu系统为 20.04 。使用脚本命令对源码追加，筛选，替换，循环，查找，删除等实现的自定义。目前脚本可以自定义baaner，IP，主题，网页终端自动登录，Nginx 默认 80 端口，主机名，时区，TimeZone，用户名/登录名，隐藏登录用户名。

脚本链接：https://github.com/csjtl/csjtl-openwrt-script

### 脚本结构

<img width="1172" alt="script" src="https://user-images.githubusercontent.com/55336802/162694398-e022a48c-940a-47fd-bc84-e423a0b4a317.png">

简单说明一下
diy_config 自定义的参数
git_source 获取源码，以后可添加自定义package的源
Config_make make的选择
Run_diy_config 执行diy config
Diy_config_recover 恢复diy的修改
Copy_firmware 拷贝固件到指定文件夹
Step_result 用来返回上条命令执行结果
通过 # 来执行或取消 

### 自定义banner

#### 效果图

![banner](../assets/openwrt-script-csjtl/banner.png)

#### diy_config 中的 banner

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
#### Run_diy_config 中的banner

直接将diy覆盖到目标文件

```
#DIY_BANNER
	echo "$DIY_BANNER" > ./package/base-files/files/etc/banner
```

#### Diy_config_recover 中的banner

要复位的文件不需要美观，直接不换行覆盖。

```
#恢复banner
	echo -e "  _______                     ________        __\n |       |.-----.-----.-----.|  |  |  |.----.|  |_\n |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|\n |_______||   __|_____|__|__||________||__|  |____|\n          |__| W I R E L E S S   F R E E D O M\n -----------------------------------------------------\n %D %V, %C\n -----------------------------------------------------" > ./package/base-files/files/etc/banner
```

### 自定义IP

#### 效果图

#### diy_config 中的IP

```
DIY_IP=192.168.7.1
```

#### Run_diy_config 中的IP

```
	grep 'lan) ipad=${ipaddr' ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
	old_ip=$(grep -oP '((\d)+.){3}\d+' ../diy/tmp/tmp)
	sed -i "s/$old_ip/$DIY_IP/" ./package/base-files/files/bin/config_generate
	sed -i "s/$old_ip/$DIY_IP/" ./package/base-files/files/etc/ethers
	sed -i "s/$old_ip/$DIY_IP/" ./package/base-files/Makefile
```

编译会中断，IP的写入需要源码更改后的IP。否则sed命令会查找不到IP导致不替换。
后面两个sed可注释

#### Diy_config_recover 中的IP

```
	sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/files/bin/config_generate
	sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/files/etc/ethers
	sed -i "s/$DIY_IP/192.168.1.1/" ./package/base-files/Makefile
```

这个没有什么，直接将地址替换

### 主题

#### 效果图

#### diy_config 中的

```
#bootstrap material openwrt openwrt-2020
	DIY_THEME='bootstrap'
```

源码有四个主题

#### Run_diy_config 中的

```
	#DIY_THEME
	sed -i "/CONFIG_PACKAGE_luci-theme-/d" .config
	echo "CONFIG_PACKAGE_luci-theme-$DIY_THEME=y" >> .config
```

删除包括关键词的行，追加上diy主题的行
这个也可以替换makefile中默认的主题实现，路径在`feeds/luci/collections/luci/Makefile`

#### Diy_config_recover 中的

```
sed -i "/CONFIG_PACKAGE_luci-theme-$DIY_THEME=y/d" .config
```

直接删除恢复默认主题

### 终端

#### 效果图

#### diy_config 中的

```

```



#### Run_diy_config 中的

```
	echo "config ttyd
	    option interface '@lan'
	    option debug '7'
	    option command '/bin/login -f root'
	    option ssl '1'
	    option ssl_cert '/etc/nginx/conf.d/_lan.crt'
	    option ssl_key '/etc/nginx/conf.d/_lan.key'" > ./feeds/packages/utils/ttyd/files/ttyd.config
```

直接删除原文件内容追加，`/bin/login -f root`实现自动登录，开启`ssl`是 https 链接需要证书。

#### Diy_config_recover 中的

```
	#恢复ttyd
	echo -e "config ttyd\n	option interface '@lan'\n	option command '/bin/login'" > ./feeds/packages/utils/ttyd/files/ttyd.config
```

### nginx

#### 效果图

#### diy_config 中的

```

```



#### Run_diy_config 中的

```
cp ../diy/etc/config/nginx/nginx.config ./feeds/packages/net/nginx-util/files/
```

直接替换diy配置文件

#### Diy_config_recover 中的

```
cp ../diy/tmp/nginx.config ./package/feeds/packages/nginx-util/files/
```

### 主机名

#### 效果图

![hostname1](../assets/openwrt-script-csjtl/hostname1.png)

![hostname](../assets/openwrt-script-csjtl/hostname.png)

#### diy_config 中的

```
DIY_HOSTNAME='CSJNAME'
```

#### Run_diy_config 中的

```
	function filter_keywords(){
		grep "$1" ./package/base-files/files/bin/config_generate > ../diy/tmp/tmp
		temp=$(cat ../diy/tmp/tmp)
		temp=$"${temp#*\'}"
		OLD_KEYWORDS=$"${temp%*\'}"
	}
	filter_keywords "set system.\@system\[-1].hostname="
	sed -i "s/hostname='$OLD_KEYWORDS'/hostname='$DIY_HOSTNAME'/" ./package/base-files/files/bin/config_generate
```

筛选出源码中的名，在替换diy名。
filter_keywords 在时区 TimeZone中使用。

#### Diy_config_recover 中的

```
	#恢复DIY_HOSTNAME
	sed -i "s/hostname='$DIY_HOSTNAME'/hostname='OpenWrt'/" ./package/base-files/files/bin/config_generate
```



### 时区 TimeZone

#### 效果图

#### diy_config 中的

```
	DIY_TIMEZONE='CST-8'
	DIY_ZONENAME='Asia/Shanghai'
```



#### Run_diy_config 中的

```
	#DIY_TIMEZONE
	filter_keywords "set system.\@system\[-1\].timezone="
	sed -i "s*timezone='$OLD_KEYWORDS'*timezone='$DIY_TIMEZONE'*" ./package/base-files/files/bin/config_generate

	#DIY_ZONENAME
	sed -i '/ystem\[-1\].zonename=/d' ./package/base-files/files/bin/config_generate
	sed -i "/set system.\@system\[-1\].hostname=/a\        set system.@system[-1].zonename='Asia/Shanghai'" ./package/base-files/files/bin/config_generate
```



#### Diy_config_recover 中的

```
	#恢复DIY_TIMEZONE
	sed -i "s*timezone='$DIY_TIMEZONE'*timezone='UTC'*" ./package/base-files/files/bin/config_generate
	#恢复DIY_ZONENAME
	sed -i '/ystem\[-1\].zonename=/d' ./package/base-files/files/bin/config_generate
```



### 用户名登录名

#### 效果图

![username](../assets/openwrt-script-csjtl/username.png)

![username1](../assets/openwrt-script-csjtl/username1.png)

#### diy_config 中的

```
	#DIY_PASSWORD DIY_USERNAME
	DIY_USERNAME='admin'
```



#### Run_diy_config 中的

```
	##DIY_USERNAME
	##./package/system/rpcd/files/rpcd.config
	function filter_keywords(){
		grep "$1" ./package/system/rpcd/files/rpcd.config > ../diy/tmp/tmp
		temp=$(cat ../diy/tmp/tmp)
		temp=$"${temp#*\'}"
		OLD_KEYWORDS=$"${temp%*\'}"
	}
	filter_keywords "option username "
	sed -i "s*option username '$OLD_KEYWORDS'*option username '$DIY_USERNAME'*" ./package/system/rpcd/files/rpcd.config
	filter_keywords "option password "
	sed -i "s*option password '$OLD_KEYWORDS'*option password '\$p\$$DIY_USERNAME'*" ./package/system/rpcd/files/rpcd.config

	##openwrt/package/base-files/files/etc/passwd
	temp=`head -1 ./package/base-files/files/etc/passwd`
	temp=${temp%%:*}
	if [ "$temp" == "root" ]; then
		sed -i "1i\\$DIY_USERNAME:x:0:0:root:/root:/bin/ash" ./package/base-files/files/etc/passwd
		else
		sed -i '1d' ./package/base-files/files/etc/passwd
		sed -i "1i\\$DIY_USERNAME:x:0:0:root:/root:/bin/ash" ./package/base-files/files/etc/passwd
	fi

	##openwrt/package/base-files/files/etc/shadow
	temp=`head -1 ./package/base-files/files/etc/shadow`
	temp=${temp%%:*}
	if [ "$temp" == "root" ]; then
		sed -i "1i\\$DIY_USERNAME:::0:99999:7:::" ./package/base-files/files/etc/shadow
		else
		sed -i '1d' ./package/base-files/files/etc/shadow
		sed -i "1i\\$DIY_USERNAME:::0:99999:7:::" ./package/base-files/files/etc/shadow
	fi

		##openwrt/feeds/luci/modules/luci-mod-admin-mini/luasrc/controller/mini/index.lua
	#sed -i "s/page.sysauth = \"$temp\"/page.sysauth = \"$DIY_USERNAME\"/" ./feeds/luci/modules/luci-mod-admin-mini/luasrc/controller/mini/index.lua
	grep 'duser = ' ./feeds/luci/modules/luci-base/luasrc/dispatcher.lua > ../diy/tmp/tmp
	temp=`awk -F "[\"\"]" '{print $2}' ../diy/tmp/tmp`
	sed -i "s/duser = \"$temp\"/duser = \"$DIY_USERNAME\"/" ./feeds/luci/modules/luci-base/luasrc/dispatcher.lua

```

##./package/system/rpcd/files/rpcd.config 登录页面使用的用户，密码项，只能使用此用户登录。
##openwrt/package/base-files/files/etc/passwd 新增用户
##openwrt/package/base-files/files/etc/shadow 用户密码
##./feeds/luci/modules/luci-base/luasrc/dispatcher.lua 页面显示的用户名

#### Diy_config_recover 中的

```
	#恢复DIY_USERNAME
	sed -i "s*option username '$DIY_USERNAME'*option username 'root'*" ./package/system/rpcd/files/rpcd.config
	sed -i "s*option password '$DIY_USERNAME'*option password '\$p\$root'*" ./package/system/rpcd/files/rpcd.config
	sed -i '1d' ./package/base-files/files/etc/passwd
	sed -i '1d' ./package/base-files/files/etc/shadow
	#sed -i "s/page.sysauth = \"$DIY_USERNAME\"/page.sysauth = \"root\"/" ./feeds/luci/modules/luci-mod-admin-mini/luasrc/controller/mini/index.lua
	sed -i "s/duser = \"$DIY_USERNAME\"/duser = \"root\"/" ./feeds/luci/modules/luci-base/luasrc/dispatcher.lua
```

### 隐藏登录名

#### 效果图

![hid](../assets/openwrt-script-csjtl/hid.png)

#### diy_config 中的

```
	#DIY_HIDE
	DIY_HIDE='n'
```



#### Run_diy_config 中的

```
	#DIY_HIDE
	##openwrt/feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
	case $DIY_HIDE in
		"y")
			sed -i "s/value=\"<%=duser%>\"/value=\"\"/" ./feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
			sed -i "s/type=\"text\"<%=attr(\"value\", duser)%>/type=\"text\"/" ./feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm
			;;
		"n")
			sed -i "s/value=\"\"/value=\"<%=duser%>\"/" ./feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
			sed -i "s/type=\"text\"/type=\"text\"<%=attr(\"value\", duser)%>/" ./feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm
			;;
	esac
```



#### Diy_config_recover 中的

```
	#恢复DIY_HIDE
	sed -i "s/value=\"\"/value=\"<%=duser%>\"/" ./feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
	sed -i "s/type=\"text\"/type=\"text\"<%=attr(\"value\", duser)%>/" ./feeds/luci/themes/luci-theme-bootstrap/luasrc/view/themes/bootstrap/sysauth.htm
```



参考：

https://www.right.com.cn/FORUM/forum.php?mod=viewthread&tid=158971
https://blog.csdn.net/Junping1982/article/details/107030229
