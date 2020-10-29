#! /bin/bash


function uninstall(){
	if [[ -d /galan ]]
		then
		inbounds_port=`cat /galan/galan/config.json|grep port|awk '{print $2}'|awk -F , 'NR==1{print $1}'`
		pid=`netstat -lnpt |grep ${inbounds_port}|awk '{print $7}'| awk -F / '{print $1}'`
		if [[ $pid == "" ]]
		then
			rm -rf /galan
			rm -rf /nginx
			nginx -s reload
			echo "节点卸载成功"
		else
			kill -9 $pid
			rm -rf /galan
			rm -rf /nginx
			nginx -s reload
			echo "节点卸载成功"
		fi
	else
		echo "节点未安装！"
	fi
}
uninstall
