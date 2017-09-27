#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
alias echo_date='echo 【$(date +%Y年%m月%d日\ %X)】:'
eval `dbus export ss`
LOG_FILE=/tmp/upload/ss_log.txt
LOCK_FILE=/tmp/online_update.lock

decode_url_link(){
	link=$1
	num=$2
	len=$((${#link}-$num))
	mod4=$(($len%4))
	if [ "$mod4" -gt 0 ]; then
		var="===="
		newlink=${link}${var:$mod4}
		echo -n "$newlink" | sed 's/-/+/g; s/_/\//g' | /usr/bin/base64 -d -i 2>/dev/null
	else
		echo -n "$link" | sed 's/-/+/g; s/_/\//g' | /usr/bin/base64 -d -i 2>/dev/null
	fi
}

add_ssr_servers(){
	ssrindex=$(($(dbus get ssrconf_basic_node_max)+1))
	
	echo_date 添加SSR节点：$remarks >> $LOG_FILE
	dbus set ssrconf_basic_name_$ssrindex=$remarks
	[ -z "$1" ] && dbus set ssrconf_basic_group_$ssrindex=$group
	dbus set ssrconf_basic_mode_$ssrindex=$ssr_subscribe_mode
	dbus set ssrconf_basic_server_$ssrindex=$server
	dbus set ssrconf_basic_port_$ssrindex=$server_port
	dbus set ssrconf_basic_rss_protocal_$ssrindex=$protocol
	dbus set ssrconf_basic_rss_protocal_para_$ssrindex=$protoparam
	dbus set ssrconf_basic_method_$ssrindex=$encrypt_method
	dbus set ssrconf_basic_rss_obfs_$ssrindex=$obfs
	dbus set ssrconf_basic_password_$ssrindex=$password
	dbus set ssrconf_basic_node_max=$ssrindex
	echo_date 成功添加了添加SSR节点：$remarks 到节点列表第 $ssrindex 位。 >> $LOG_FILE
}

add_ss_servers(){
	ssindex=$(($(dbus get ssconf_basic_node_max)+1))
	
	echo_date 添加SS节点：$remarks >> $LOG_FILE
	dbus set ssrconf_basic_name_$ssindex=$remarks
	dbus set ssconf_basic_mode_$ssindex="1"
	dbus set ssconf_basic_server_$ssindex=$server
	dbus set ssconf_basic_port_$ssindex=$server_port
	dbus set ssconf_basic_method_$ssindex=$encrypt_method
	dbus set ssconf_basic_password_$ssindex=$password
	dbus set ssconf_basic_node_max=$ssindex
	echo_date 成功添加了添加SS节点：$remarks 到节点列表第 $ssindex 位。 >> $LOG_FILE
}

get_remote_config(){
	decode_link="$1"
	server=$(echo "$decode_link" |awk -F':' '{print $1}')
	server_port=$(echo "$decode_link" |awk -F':' '{print $2}')
	protocol=$(echo "$decode_link" |awk -F':' '{print $3}')
	encrypt_method=$(echo "$decode_link" |awk -F':' '{print $4}')
	obfs=$(echo "$decode_link" |awk -F':' '{print $5}'|sed 's/_compatible//g')
	password=$(decode_url_link $(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'/' '{print $1}') 0)
	
	if [ "$(echo "$decode_link" |grep -c "obfsparam=")" -eq 1 ]; then
		obfsparm_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $1}'|awk -F'=' '{print $2}')
		if [ -n "$obfsparm_temp" ]; then
			obfsparam=$(decode_url_link $obfsparm_temp 0)
		else
			obfsparam=''
		fi
		if [ "$(echo "$decode_link" | grep -c protoparam)" -eq 1 ]; then
			protoparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $2}'|awk -F'=' '{print $2}')
			[ -n "$protoparam_temp" ] && protoparam=$(decode_url_link $protoparam_temp 0) || protoparam=''
			remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $3}'|awk -F'=' '{print $2}')
			[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp 0) || remarks='AutoSuB'
			group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $4}'|awk -F'=' '{print $2}')
			[ -n "$group_temp" ] && group=$(decode_url_link $group_temp 0) || group='AutoSuBGroup'
		else
			protoparam=''
			remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $2}'|awk -F'=' '{print $2}')
			[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp 0) || remarks='AutoSuB'
			group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $3}'|awk -F'=' '{print $2}')
			[ -n "$group_temp" ] && group=$(decode_url_link $group_temp 0) || group='AutoSuBGroup'
		fi
	else
		obfsparam=''
		if [ "$(echo "$decode_link" | grep -c protoparam)" -eq 1 ]; then
			protoparam_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $1}'|awk -F'=' '{print $2}')
			[ -n "$protoparam_temp" ] && protoparam=$(decode_url_link $protoparam_temp 0) || protoparam=''
			remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $2}'|awk -F'=' '{print $2}')
			[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp 0) || remarks='AutoSuB'
			group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $3}'|awk -F'=' '{print $2}')
			[ -n "$group_temp" ] && group=$(decode_url_link $group_temp 0) || group='AutoSuBGroup'
		else
			protoparam=''
			remarks_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $1}'|awk -F'=' '{print $2}')
			[ -n "$remarks_temp" ] && remarks=$(decode_url_link $remarks_temp 0) || remarks='AutoSuB'
			group_temp=$(echo "$decode_link" |awk -F':' '{print $6}'|awk -F'&' '{print $2}'|awk -F'=' '{print $2}')
			[ -n "$group_temp" ] && group=$(decode_url_link $group_temp 0) || group='AutoSuBGroup'
		fi
	fi
	[ -n "$group" ] && group_md5=`echo $group | md5sum | sed 's/ -//g'`
	[ -n "$server" ] && server_md5=`echo $server | md5sum | sed 's/ -//g'`
	
	##把全部服务器节点写入文件 /usr/share/shadowsocks/serverconfig/all_onlineservers
	[ -n "$group" ] && [ -n "$server" ] && echo $server_md5 $group_md5 >> /tmp/all_onlineservers
}

update_config(){
	#isadded_server=$(uci show shadowsocks | grep -c "server=\'$server\'")
	isadded_server=$(cat /tmp/all_localservers | grep $group_md5 | awk '{print $1}' | grep -c $server_md5)
	if [ "$isadded_server" -eq 0 ]; then
		add_ssr_servers
		[ "$ssr_subscribe_obfspara" == "0" ] && dbus set ssrconf_basic_rss_obfs_para_$ssindex=""
		[ "$ssr_subscribe_obfspara" == "1" ] && dbus set ssrconf_basic_rss_obfs_para_$ssindex=$obfsparam
		[ "$ssr_subscribe_obfspara" == "2" ] && dbus set ssrconf_basic_rss_obfs_para_$ssindex=$ssr_subscribe_obfspara_val
		let addnum+=1
	else
		# 如果在本地的订阅节点中没找到该节点，检测下配置是否更改，如果更改，则更新配置
		index=$(cat /tmp/all_localservers| grep $group_md5 | grep $server_md5 |awk '{print $3}')
		local_server_port=$(dbus get ssrconf_basic_port_$index)
		local_protocol=$(dbus get ssrconf_basic_rss_protocal_$index)
		local_encrypt_method=$(dbus get ssrconf_basic_method_$index)
		local_obfs=$(dbus get ssrconf_basic_rss_obfs_$index)
		local_password=$(dbus get ssrconf_basic_password_$index)
		local_remarks=$(dbus get ssrconf_basic_name_$index)
		local_group=$(dbus get ssrconf_basic_group_$index)
		#echo update $index >> $LOG_FILE
		local i=0
		[ "$ssr_subscribe_obfspara" == "0" ] && dbus set ssrconf_basic_rss_obfs_para_$index=""
		[ "$ssr_subscribe_obfspara" == "1" ] && dbus set ssrconf_basic_rss_obfs_para_$index=$obfsparam
		[ "$ssr_subscribe_obfspara" == "2" ] && dbus set ssrconf_basic_rss_obfs_para_$index=$ssr_subscribe_obfspara_val
		dbus set ssrconf_basic_mode_$index=$ssr_subscribe_mode
		[ "$local_remarks" != "$remarks" ] dbus set ssrconf_basic_name_$index=$remarks
		[ "$local_server_port" != "$server_port" ] && dbus set ssrconf_basic_port_$index=$server_port && let i+=1
		[ "$local_protocol" != "$protocol" ] && dbus set ssrconf_basic_rss_protocal_$index=$protocol && let i+=1
		[ "$local_encrypt_method" != "$encrypt_method" ] && dbus set ssrconf_basic_method_$index=$encrypt_method && let i+=1
		[ "$local_obfs" != "$obfs" ] && dbus set ssrconf_basic_rss_obfs_$index=$obfs && let i+=1
		[ "$local_password" != "$password" ] && dbus set ssrconf_basic_password_$index=$password && let i+=1
		[ "$i" -gt 0 ] && echo_date 修改SSR节点：$remarks >> $LOG_FILE && let updatenum+=1
	fi
}

del_none_exist(){
	#删除订阅服务器已经不存在的节点
	for localserver in $(cat /tmp/all_localservers| grep $group_md5|awk '{print $1}')
	do
		if [ "`cat /tmp/all_onlineservers | grep -c $localserver`" -eq "0" ];then
			del_index=`cat /tmp/all_localservers | grep $localserver | awk '{print $3}'`
			#for localindex in $(dbus list ssrconf_basic_server|grep -v ssrconf_basic_server_ip_|grep -w $localserver|cut -d "_" -f 4 |cut -d "=" -f1)
			for localindex in $del_index
			do
				echo_date 删除节点：`dbus get ssrconf_basic_name_$localindex` ，因为该节点在订阅服务器上已经不存在... >> $LOG_FILE
				dbus remove ssrconf_basic_group_$localindex
				dbus remove ssrconf_basic_method_$localindex
				dbus remove ssrconf_basic_mode_$localindex
				dbus remove ssrconf_basic_name_$localindex
				dbus remove ssrconf_basic_password_$localindex
				dbus remove ssrconf_basic_port_$localindex
				dbus remove ssrconf_basic_rss_obfs_$localindex
				dbus remove ssrconf_basic_rss_obfs_para_$localindex
				dbus remove ssrconf_basic_rss_protocal_$localindex
				dbus remove ssrconf_basic_server_$localindex
				dbus remove ssrconf_basic_server_ip_$localindex
				dbus remove ssrconf_basic_lb_enable_$localindex
				dbus remove ssrconf_basic_lb_policy_$localindex
				dbus remove ssrconf_basic_lb_weight_$localindex
				dbus remove ssrconf_basic_lb_dest_$localindex
				let delnum+=1
			done
		fi
	done
}

remove_node_gap(){
	SEQ=$(dbus list ssrconf_basic_port|cut -d "_" -f 4|cut -d "=" -f 1|sort -n)
	MAX=$(dbus list ssrconf_basic_port|cut -d "_" -f 4|cut -d "=" -f 1|sort -rn|head -n1)
	NODE_NU=$(dbus list ssrconf_basic_port|wc -l)
	KCP_NODE=`dbus get ss_kcp_node`
	
	echo_date 现有节点顺序：$SEQ >> $LOG_FILE
	echo_date 最大SSR节点序号：$MAX >> $LOG_FILE
	echo_date SSR节点数量：$NODE_NU >> $LOG_FILE
	
	if [ "$MAX" != "$NODE_NU" ];then
		echo_date 节点排序需要调整! >> $LOG_FILE
		y=1
		for nu in $SEQ
		do
			if [ "$y" == "$nu" ];then
				echo_date 节点 $y 不需要调整 ! >> $LOG_FILE
			else
				echo_date 调整节点 $y ! >> $LOG_FILE
				[ -n "$(dbus get ssrconf_basic_group_$nu)" ] && dbus set ssrconf_basic_group_"$y"="$(dbus get ssrconf_basic_group_$nu)" && dbus remove ssrconf_basic_group_$nu
				[ -n "$(dbus get ssrconf_basic_method_$nu)" ] && dbus set ssrconf_basic_method_"$y"="$(dbus get ssrconf_basic_method_$nu)" && dbus remove ssrconf_basic_method_$nu
				[ -n "$(dbus get ssrconf_basic_mode_$nu)" ] && dbus set ssrconf_basic_mode_"$y"="$(dbus get ssrconf_basic_mode_$nu)" && dbus remove ssrconf_basic_mode_$nu
				[ -n "$(dbus get ssrconf_basic_name_$nu)" ] && dbus set ssrconf_basic_name_"$y"="$(dbus get ssrconf_basic_name_$nu)" && dbus remove ssrconf_basic_name_$nu
				[ -n "$(dbus get ssrconf_basic_password_$nu)" ] && dbus set ssrconf_basic_password_"$y"="$(dbus get ssrconf_basic_password_$nu)" && dbus remove ssrconf_basic_password_$nu
				[ -n "$(dbus get ssrconf_basic_port_$nu)" ] && dbus set ssrconf_basic_port_"$y"="$(dbus get ssrconf_basic_port_$nu)" && dbus remove ssrconf_basic_port_$nu
				[ -n "$(dbus get ssrconf_basic_rss_obfs_$nu)" ] && dbus set ssrconf_basic_rss_obfs_"$y"="$(dbus get ssrconf_basic_rss_obfs_$nu)" && dbus remove ssrconf_basic_rss_obfs_$nu
				[ -n "$(dbus get ssrconf_basic_rss_obfs_para_$nu)" ] && dbus set ssrconf_basic_rss_obfs_para_"$y"="$(dbus get ssrconf_basic_rss_obfs_para_$nu)" && dbus remove ssrconf_basic_rss_obfs_para_$nu
				[ -n "$(dbus get ssrconf_basic_rss_protocal_$nu)" ] && dbus set ssrconf_basic_rss_protocal_"$y"="$(dbus get ssrconf_basic_rss_protocal_$nu)" && dbus remove ssrconf_basic_rss_protocal_$nu
				[ -n "$(dbus get ssrconf_basic_rss_protocal_para_$nu)" ] && dbus set ssrconf_basic_rss_protocal_para_"$y"="$(dbus get ssrconf_basic_rss_protocal_para_$nu)" && dbus remove ssrconf_basic_rss_protocal_para_$nu
				[ -n "$(dbus get ssrconf_basic_server_$nu)" ] && dbus set ssrconf_basic_server_"$y"="$(dbus get ssrconf_basic_server_$nu)" && dbus remove ssrconf_basic_server_$nu
				[ -n "$(dbus get ssrconf_basic_server_ip_$nu)" ] && dbus set ssrconf_basic_server_ip_"$y"="$(dbus get ssrconf_basic_server_ip_$nu)" && dbus remove ssrconf_basic_server_ip_$nu
				[ -n "$(dbus get ssrconf_basic_lb_enable_$nu)" ] && dbus set ssrconf_basic_lb_enable_"$y"="$(dbus get ssrconf_basic_lb_enable_$nu)" && dbus remove ssrconf_basic_lb_enable_$nu
				[ -n "$(dbus get ssrconf_basic_lb_policy_$nu)" ] && dbus set ssrconf_basic_lb_policy_"$y"="$(dbus get ssrconf_basic_lb_policy_$nu)" && dbus remove ssrconf_basic_lb_policy_$nu
				[ -n "$(dbus get ssrconf_basic_lb_weight_$nu)" ] && dbus set ssrconf_basic_lb_weight_"$y"="$(dbus get ssrconf_basic_lb_weight_$nu)" && dbus remove ssrconf_basic_lb_weight_$nu
				[ -n "$(dbus get ssrconf_basic_lb_dest_$nu)" ] && dbus set ssrconf_basic_lb_dest_"$y"="$(dbus get ssrconf_basic_lb_dest_$nu)" && dbus remove ssrconf_basic_lb_dest_$nu

				# change kcpnode nu
				if [ "$nu" == "$KCP_NODE" ];then
					dbus set ss_kcp_node="$y"
				fi
			fi
			let y+=1
		done
	else
		echo_date 节点排序正确! >> $LOG_FILE
	fi
	dbus set ssrconf_basic_node_max=$NODE_NU
	dbus set ssrconf_basic_max_node=$NODE_NU
}


get_oneline_rule_now(){
	# ss订阅
	ssr_subscribe_link="$1"
	echo_date "开始更新在线订阅列表..." >> $LOG_FILE 
	echo_date "开始下载订阅链接到本地临时文件，请稍等..." >> $LOG_FILE
	rm -rf /tmp/ssr_subscribe_file* >/dev/null 2>&1
	curl --connect-timeout 8 -q $ssr_subscribe_link > /tmp/ssr_subscribe_file.txt
	if [ "$?" == "0" ];then
		echo_date 下载订阅成功... >> $LOG_FILE
		echo_date 开始解析节点信息... >> $LOG_FILE
		cat /tmp/ssr_subscribe_file.txt | base64_decode > /tmp/ssr_subscribe_file_temp1.txt
		# 检测ss ssr
		NODE_FORMAT=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -E "^ss://"`
		if [ -n "$NODE_FORMAT" ];then
			echo_date 暂时不支持ss节点订阅... >> $LOG_FILE
			echo_date 退出订阅程序... >> $LOG_FILE
		else
			NODE_NU=`cat /tmp/ssr_subscribe_file_temp1.txt | grep -c "ssr://"`
			echo_date 检测到ssr节点格式，共计$NODE_NU个节点... >> $LOG_FILE
			
			# 收集本地节点名到文件
			LOCAL_NODES=`dbus list ssrconf_basic_group|cut -d "_" -f 4|cut -d "=" -f 1`
			if [ -n "$LOCAL_NODES" ];then
				for LOCAL_NODE in $LOCAL_NODES
				do
					#echo `dbus list ssrconf_basic_server_$LOCAL_NODE` `dbus list ssrconf_basic_group_$LOCAL_NODE`>> /tmp/all_localservers
					echo `dbus get ssrconf_basic_server_$LOCAL_NODE|md5sum|sed 's/ -//g'` `dbus get ssrconf_basic_group_$LOCAL_NODE|md5sum|sed 's/ -//g'`| eval echo `sed 's/$/ $LOCAL_NODE/g'` >> /tmp/all_localservers
				done
			else
				touch /tmp/all_localservers
			fi
			#判断格式
			maxnum=$(cat /tmp/ssr_subscribe_file.txt | base64 -d | grep "MAX=" |awk -F"=" '{print $2}')
			if [ -n "$maxnum" ]; then
				urllinks=$(cat /tmp/ssr_subscribe_file.txt | base64 -d | sed '/MAX=/d' | shuf -n${maxnum} | sed 's/ssr:\/\///g')
			else
				urllinks=$(cat /tmp/ssr_subscribe_file.txt | base64 -d | sed 's/ssr:\/\///g')
			fi
			[ -z "$urllinks" ] && continue
			for link in $urllinks
			do
				decode_link=$(decode_url_link $link 1)
				get_remote_config $decode_link
				update_config
			done
			# 去除订阅服务器上已经删除的节点
			del_none_exist
			# 节点重新排序
			remove_node_gap	
		fi
		sleep 1

		USER_ADD=$(($(dbus list ssrconf_basic_server|grep -v ssrconf_basic_server_ip_|wc -l) - $(dbus list ssrconf_basic_group|wc -l))) || 0
		ONLINE_GET=$(dbus list ssrconf_basic_group|wc -l) || 0
		echo $group >> /tmp/group_info.txt
		echo_date "本次更新，订阅来源 【$group】， 新增服务器节点 $addnum 个，修改 $updatenum 个，删除 $delnum 个；" >> $LOG_FILE
		echo_date "现共有自添加SSR节点：$USER_ADD 个。" >> $LOG_FILE
		echo_date "现共有订阅SSR节点：$ONLINE_GET 个。" >> $LOG_FILE
		echo_date "在线订阅列表更新完成!" >> $LOG_FILE
		echo_date "=============================================================================================" >> $LOG_FILE
		echo_date "" >> $LOG_FILE
	else
		echo_date 下载订阅失败...请检查你的网络... >> $LOG_FILE
		rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1 &
		sleep 2
		echo_date 退出订阅程序... >> $LOG_FILE
	fi
}


start_update(){
	#防止并发开启服务
	[ -f "$LOCK_FILE" ] && return 3
	touch "$LOCK_FILE"
	echo_date "" > $LOG_FILE
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/ssr_subscribe_file_temp1.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers >/dev/null 2>&1
	rm -rf /tmp/all_onlineservers >/dev/null 2>&1
	rm -rf /tmp/group_info.txt >/dev/null 2>&1
	online_url_nu=`dbus list ss_online_link|wc -l`
	z=0
	until [ "$z" == "$online_url_nu" ]
	do
		z=$(($z+1))
		url=`dbus get ss_online_link_$z`
		echo_date "=============================================================================================" >> $LOG_FILE
    	echo_date "                                                       服务器订阅程序(Shell by stones & sadog)" >> $LOG_FILE
    	echo_date "=============================================================================================" >> $LOG_FILE
		echo_date "从 $url 获取订阅..." >> $LOG_FILE
		addnum=0
		updatenum=0
		delnum=0
		get_oneline_rule_now "$url"
	done
	# 删除去掉的订阅链接对应的节点
	local_groups=`dbus list ss|grep group|cut -d "=" -f2|sort -u`
	for local_group in $local_groups
	do
		MATCH=`cat /tmp/group_info.txt | grep $local_group`
		if [ -z "$MATCH" ];then
			echo_date $local_group 节点已经不再订阅，将进行删除...  >> $LOG_FILE
			confs_nu=`dbus list ssrconf |grep "$local_group"| cut -d "=" -f 1|cut -d "_" -f 4`
			for conf_nu in $confs_nu
			do
				dbus remove ssrconf_basic_group_$conf_nu
				dbus remove ssrconf_basic_method_$conf_nu
				dbus remove ssrconf_basic_mode_$conf_nu
				dbus remove ssrconf_basic_name_$conf_nu
				dbus remove ssrconf_basic_password_$conf_nu
				dbus remove ssrconf_basic_port_$conf_nu
				dbus remove ssrconf_basic_rss_obfs_$conf_nu
				dbus remove ssrconf_basic_rss_obfs_para_$conf_nu
				dbus remove ssrconf_basic_rss_protocal_$conf_nu
				dbus remove ssrconf_basic_server_$conf_nu
				dbus remove ssrconf_basic_server_ip_$conf_nu
				dbus remove ssrconf_basic_lb_enable_$conf_nu
				dbus remove ssrconf_basic_lb_policy_$conf_nu
				dbus remove ssrconf_basic_lb_weight_$conf_nu
				dbus remove ssrconf_basic_lb_dest_$conf_nu
			done
			echo_date 删除完成完成！ >> $LOG_FILE
			need_adjust=1
		fi
	done
	sleep 1
	# 再次排序
	if [ "$need_adjust" == "1" ];then
		echo_date 因为进行了删除订阅节点操作，需要对节点顺序进行检查！ >> $LOG_FILE
		remove_node_gap
	fi
	# 结束
	echo_date "请等待3秒，本页面将自动刷新！" >> $LOG_FILE
	echo_date "=============================================================================================" >> $LOG_FILE
	sleep 3
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/ssr_subscribe_file_temp1.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers >/dev/null 2>&1
	rm -rf /tmp/all_onlineservers >/dev/null 2>&1
	rm -rf /tmp/group_info.txt >/dev/null 2>&1
	rm -f "$LOCK_FILE"
}

get_ss_config(){
	decode_link=$1
	server=$(echo "$decode_link" |awk -F':' '{print $2}'|awk -F'@' '{print $2}')
	server_port=$(echo "$decode_link" |awk -F':' '{print $3}')
	encrypt_method=$(echo "$decode_link" |awk -F':' '{print $1}')
	password=$(echo "$decode_link" |awk -F':' '{print $2}'|awk -F'@' '{print $1}')
}

add() {
	[ -f "$LOCK_FILE" ] && return 3
	touch "$LOCK_FILE"
	echo_date "=============================================================================================" > $LOG_FILE
	sleep 1
	echo_date 通过SS/SSR链接添加节点... >> $LOG_FILE
	rm -rf /tmp/ssr_subscribe_file.txt >/dev/null 2>&1
	rm -rf /tmp/ssr_subscribe_file_temp1.txt >/dev/null 2>&1
	rm -rf /tmp/all_localservers >/dev/null 2>&1
	rm -rf /tmp/all_onlineservers >/dev/null 2>&1
	rm -rf /tmp/group_info.txt >/dev/null 2>&1
	#echo_date 添加链接为：`dbus get ss_ssr_add_link` >> $LOG_FILE
	ssrlinks_nu=`dbus list ss_base64_link_|cut -d "=" -f 1|cut -d "_" -f 4`
	for link_nu in $ssrlinks_nu
	do
		ssrlink=$(dbus get ss_base64_link_$link_nu)
		if [ -n "$ssrlink" ];then
			if [ -n "`echo -n "$ssrlink" | grep "ssr://"`" ]; then
				echo_date 检测到SSR链接...开始尝试解析... >> $LOG_FILE
				new_ssrlink=`echo -n "$ssrlink" | sed 's/ssr:\/\///g'`
				decode_ssrlink=$(decode_url_link $new_ssrlink 1)
				get_remote_config $decode_ssrlink
				add_ssr_servers 1
			else
				echo_date 检测到SS链接...开始尝试解析... >> $LOG_FILE
				if [ -n "`echo -n "$ssrlink" | grep "#"`" ]; then
					new_sslink=`echo -n "$ssrlink" | awk -F'#' '{print $1}' | sed 's/ss:\/\///g'`
					remarks=`echo -n "$ssrlink" | awk -F'#' '{print $2}'`
					
				else
					new_sslink=`echo -n "$ssrlink" | sed 's/ss:\/\///g'`
					remarks='AddedByLink'
				fi
				decode_sslink=$(decode_url_link $new_sslink 1)
				get_ss_config $decode_sslink
				add_ss_servers
			fi
		fi
		dbus remove ss_base64_link_$link_nu
	done
	dbus remove ss_ssr_add_link
	echo_date "=============================================================================================" >> $LOG_FILE
	rm -f "$LOCK_FILE"
}

if [ -z "$1" ] && [ -z "$2" ];then
	start_update
fi

case $2 in
add)
	add
	sleep 3
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
7)
	start_update
	http_response "$1"
	echo XU6J03M6 >> $LOG_FILE
	;;
esac