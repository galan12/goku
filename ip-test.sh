#! /bin/bash

host_ip=`ifconfig  | grep 'inet '| grep -v '127.0.0.1' |awk '{print $2}'`
function network(){
		for i in $host_ip
		do
			if [[ ! $i =~ ^"10." ]] && [[ ! $i =~ ^"192.168" ]] && [[ ! $i =~ ^"172" ]]
			then
				echo "可以进行部署程序"
				return 10
			fi
		done
	}
network
if [ $? -ne 10 ]
then
	echo "抱歉，此主机上未绑定公网ip！无法进行程序部署"
fi
