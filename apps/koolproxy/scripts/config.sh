#!/bin/sh
#copyright by monlor

eval `mbdb export koolproxy`
source "$(mbdb get mixbox.main.path)"/bin/base
control=${mbroot}/apps/${appname}/config/kpcontrol.conf
[ ! -f "$control" ] && touch $control
echo "********* $service ***********"
echo "[${appinfo}]"
readsh "启动${appname}服务[1/0] " "enable" "1"
if [ "$enable" == '1' ]; then
	echo "[1.全局模式 2.黑名单模式 3.视频模式]"
	read -p "请选择${appname}模式：" res
	if [ "$res" == '1' -o "$res" == '2' -o "$res" == '3' ]; then
		mbdb set $appname.main.mode="$res"
	fi
	# read -p "自动更新用户自定义规则？[1/0] " res
	# checkread $res && mbdb set $appname.main.autorule="$res"
	cat $control | while read line
	do
		name=$(cutsh ${line} 1)
		mode=$(cutsh ${line} 3)
		case "$mode" in
			0) mode="不过滤" ;;
			1) mode="http模式" ;;
			2) mode="https模式" ;;
			*) mode="空" ;;
		esac
		echo "设备[$name]运行模式为: $mode"
	done
	mode=$(mbdb get ${appname}.main.ss_acl_default_mode)
	case "$mode" in
		0) mode="不过滤" ;;
		1) mode="http模式" ;;
		2) mode="https模式" ;;
		*) mode="http模式" ;;
	esac
	echo "其余设备运行模式为: $mode"
	read -p "设置局域网http/https控制？[1/0] " res
	if [ "$res" == '1' ]; then
		read -p "清空之前的配置再添加？[1/0] " res
		[ "$res" == '1' ] && echo -n > $control
		i=0
		cat /tmp/dhcp.leases | while read line
		do
			name=$(echo ${line} | cut -d' ' -f4)
			mac=$(echo ${line} | cut -d' ' -f2)
			ip=$(echo ${line} | cut -d' ' -f3)

			let i=$i+1
			echo "$i. $name [$ip] [$mac]"
		done
		while(true) 
		do
			read -p "请选择一个设备或输入mac地址：" res
			if echo "$res" | grep -E "^[0-9]{0,3}$" &> /dev/null; then
				line=$(cat /tmp/dhcp.leases | grep -n . | grep -w "^$res")
				name=$(echo ${line} | cut -d' ' -f4)
				mac=$(echo ${line} | cut -d' ' -f2)
			else 
				line="1"
				name="$res"
				mac="$res"
			fi
			if [ ! -z "${line}" ]; then
				read -p "请选择(0.不过滤 1.http 2.https)：" res
				if [ "$res" == '0' -o "$res" == '1' -o "$res" == '2' ]; then
					if [ ! -z "$mac" ]; then
						sed -i "/^$name,$mac/d" $control
						echo "$name,$mac,$res" >> $control
					else
						echo "mac不能为空, 添加失败！"
					fi
				else
					echo "输入有误, 添加失败"
				fi
				read -p "继续增加设备？[1/0] " res
				[ "$res" == '0' ] && break
			else
				echo "输入为空，跳过..."
				break
			fi
		done
		readsh "请选择其余设备(0.不过滤 1.http 2.https) " "koolproxy_acl_default_mode" "1"
	fi
	readsh "重启${appname}服务[1/0] " "res" "1"
  [ "$res" != '0' ] && exit 0
fi
exit 1
