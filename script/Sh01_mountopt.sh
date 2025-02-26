#!/bin/sh
#copyright by hiboy
source /etc/storage/script/init.sh
nvramshow=`nvram show | grep opt | awk '{print gensub(/=/,"='\''",1,$0)"'\'';";}'` && eval $nvramshow
optinstall=`nvram get optinstall`
ss_opt_x=`nvram get ss_opt_x`

[ -z $ss_opt_x ] && ss_opt_x=1 && nvram set ss_opt_x="$ss_opt_x"

if [ ! -z "$(echo $scriptfilepath | grep -v "/tmp/script/" | grep mountopt)" ] ; then
	mkdir -p /tmp/script
	ln -sf $scriptfilepath /tmp/script/_mountopt
	chmod 777 /tmp/script/_mountopt
fi
# /etc/storage/script/sh01_mountopt.sh
 opttmpfile="$hiboyfile/opttmpg7.tgz"
 optupanfile="$hiboyfile/optupang7.tgz"
 optupanfile2="$hiboyfile/optg7.txt"
# ss_opt_x 
# 1 >>自动选择:SD→U盘→内存
# 2 >>安装到内存:需要空余内存(10M+)
# 3 >>安装到 SD
# 4 >>安装到 U盘

mount_check() {
mountp=mountp
mountpoint -q /opt && mountp=0 || mountp=1 # 0已挂载 1没挂载
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs| awk '{print $1}'`"
if [ "$mountp" = "0" ] && [ -z "$optPath" ] ; then
	optPath="`df -m | grep $(df -m | grep /opt | awk '{print $1}') | grep "/media"| awk '{print $NF}' | awk 'NR==1' `"
	if [ -z "$optPath" ] ; then
		logger -t "【opt】" "opt 挂载异常，重新挂载：umount -l /opt"
		umount -l /opt
		mount_opt
	else
		logger -t "【opt】" "opt 挂载正常：$optPath"
	fi
else
	[ "$mountp" = "1" ] && logger -t "【opt】" "opt 没挂载，重新挂载"
	[ "$mountp" = "1" ] && mount_opt
fi
AiDisk00
}

mount_opt () {
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
if [ ! -z "$upanPath" ] ; then
	mkdir -p "$upanPath/opt"
	mount -o bind "$upanPath/opt" /opt
	ln -sf "$upanPath" /tmp/AiDisk_00
else
	mkdir -p /tmp/AiDisk_00/opt
	mount -o bind /tmp/AiDisk_00/opt /opt
fi
mkdir -p /opt/bin
}

AiDisk00 () {
[ -d /tmp/AiDisk_00/opt ] && return
upanPath=""
[ "$ss_opt_x" = "3" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ "$ss_opt_x" = "4" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep /dev/mmcb | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
[ -z "$upanPath" ] && [ "$ss_opt_x" = "1" ] && upanPath="`df -m | grep "/dev/sd" | grep "/media" | awk '{print $NF}' | awk 'NR==1' `"
if [ ! -z "$upanPath" ] ; then
	mkdir -p "$upanPath/opt"
	ln -sf "$upanPath" /tmp/AiDisk_00
else
	mkdir -p /tmp/AiDisk_00/opt
fi
mkdir -p /opt/bin
}

opt_file () {
optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$opttmpfile"; }
optPath="`grep ' /opt ' /proc/mounts | grep /dev`"
[ ! -z "$optPath" ] && { wgetcurl.sh '/opt/opt.tgz' "$optupanfile"; }
logger -t "【opt】" "opt 下载完成，开始解压"
tar -xzvf /opt/opt.tgz -C /opt

optPath="`grep ' /opt ' /proc/mounts | grep tmpfs`"
[ ! -z "$optPath" ] && rm -f /opt/opt.tgz
}

opt_wget () {
#opt检查更新
[ "$upopt_enable" = "1" ] && upopt
if [ "$(cat /tmp/opti.txt)"x != "$(cat /opt/opti.txt)"x ] && [ "$upopt_enable" = "1" ] && [ -f /tmp/opti.txt ] ; then
	logger -t "【opt】" "opt 需要更新, 自动启动更新"
	rm -rf /opt/opti.txt
	rm -rf /opt/lnmp.txt
fi
if [ ! -f "/opt/opti.txt" ] ; then
	logger -t "【opt】" "自动安装（覆盖 opt 文件夹）"
	logger -t "【opt】" "opt 第一次下载"
	opt_file
	if [ ! -s "/opt/opti.txt" ] ; then
		logger -t "【opt】" "/opt/opt.tgz 下载失败"
		logger -t "【opt】" "opt 第二次下载"
		opt_file
	fi
	if [ -s "/opt/opti.txt" ] ; then
		logger -t "【opt】" "opt 解压完成"
		chmod 777 /opt -R
	fi
fi
upopt
}

upopt () {
wgetcurl.sh "/tmp/opti.txt" "$optupanfile2"
wgetcurl.sh "/tmp/lnmpi.txt" "$optupanfile2"
nvram set opto="`cat /opt/opti.txt`"
nvram set optt="`cat /tmp/opti.txt`"
nvram set lnmpo="`cat /opt/lnmp.txt`"
nvram set lnmpt="`cat /tmp/lnmpi.txt`"
}

case $ACTION in
start)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget
	;;
check)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget
	;;
optwget)
	mount_check
	opt_wget
	;;
upopt)
	upopt
	;;
*)
	mount_check
	[ "$optinstall" = "1" ] && opt_wget
	;;
esac

