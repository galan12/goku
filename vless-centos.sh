#! /bin/bash

# v2ray centos系统一键安装教程

echo "#############################################################"
echo "#         CentOS 7/8 v2ray 一键安装脚本                      #"
echo "#############################################################"
echo ""

red='\033[0;31m'
green="\033[0;32m"
plain='\033[0m'


function checkSystem()
{
    result=$(id | awk '{print $1}')
    if [ $result != "uid=0(root)" ]; then
        echo "请以root身份执行该脚本"
        exit 1
    fi

    if [ ! -f /etc/centos-release ];then
        res=`which yum`
        if [ "$?" != "0" ]; then
            echo "系统不是CentOS"
            exit 1
         fi
         res=`which systemctl`
         if [ "$?" != "0" ]; then
            echo "系统版本过低，请重装系统到高版本后再使用本脚本！"
            exit 1
         fi
    else
        result=`cat /etc/centos-release|grep -oE "[0-9.]+"`
        main=${result%%.*}
        if [ $main -lt 7 ]; then
            echo "不受支持的CentOS版本"
            exit 1
         fi
    fi
}




function preinstall()
{
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' /etc/ssh/sshd_config
    systemctl restart sshd
    ret=`nginx -t`
    if [ "$?" != "0" ]; then
        echo "更新系统..."
        yum update -y
    fi
    echo "安装必要软件"
    yum install -y epel-release telnet wget vim net-tools ntpdate unzip git
    res=`which wget`
    [ "$?" != "0" ] && yum install -y wget
    res=`which netstat`
    [ "$?" != "0" ] && yum install -y net-tools
    yum install -y nginx
    systemctl enable nginx && systemctl start nginx

    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}


function installV2ray()
{
    echo 安装v2ray...
	pid=`ps -ef |grep v2ray|grep -v grep|awk 'NR==1{print $2}'`
	kill $pid 
	rm -rf /vless
	rm -rf  /etc/nginx/conf.d/v2fly.conf
	if [ ! -d /vless ];then
		mkdir /vless
		cd /vless
		git clone https://github.com/liaojiwei1/goku.git
		cd goku
		tar -zxvf vless.tar.gz
		cd vless
		systemctl stop nginx
		read -p "请输入你的域名：" domain
		yum install -y python3 && pip3 install certbot
		certbot certonly --standalone -d $domain
		if [ $? -ne 0 ]
		then
			echo "域名申请错误"
			echo "出现To fix these errors, please make sure that your domain name wasentered correctly and the DNS A/AAAA record(s) for that domaincontain(s) the right IP address，域名记录未指向服务器的IP，会报错并提示域名解析问题。"	
			echo "如果运行过程中出现 “ ImportError: ‘pyOpenSSL’ module missing required functionality. Try upgrading to v0.14 or newer.”的错误，请参考 https://tlanyan.me/certbot-importerror-pyopenssl-module-missing-required-functionality/ "
			echo "出现“Let’s Encrypt renew出现“Challenge failed for domain xxxx””的错误，请参考 https://tlanyan.me/lets-encrypt-renew-error-challenge-failed-for-domain-xxxx/ "
			rm -rf /vless
			exit 1
		fi
		systemctl start nginx
		certificateFile=`cat config.json |grep certificateFile |awk '{print $2}'|awk -F \" '{print $2}'`
		keyFile=`cat config.json |grep keyFile |awk '{print $2}'|awk -F \" '{print $2}'`
		uuid=`cat config.json |grep id|awk '{print $2}'|awk -F \"  '{print $2}'`
		serverName=`cat config.json |grep serverName |awk '{print $2}'|awk -F \" '{print $2}'`
		new_certificateFile=`ls /etc/letsencrypt/live/${domain}/fullchain.pem`
		new_keyFile=`ls /etc/letsencrypt/live/${domain}/privkey.pem`
		new_uuid=`./v2ctl uuid`
		sed -i "s#${certificateFile}#${new_certificateFile}#" config.json
		sed -i "s#${keyFile}#${new_keyFile}#" config.json
		sed -i "s#${serverName}#${domain}#" config.json
		sed -i "s#${uuid}#${new_uuid}#" config.json
		cp v2fly.conf /etc/nginx/conf.d/
		nginx -s reload
		/bin/bash start.sh
		echo "启动成功"
		echo "uuid:  ${new_uuid}"
		echo "域名： ${domain}"
		echo "端口： 443"
		echo ""
	else
		echo "可能是误删或者未卸载，请先执行命令: /bin/bash vless.sh uninstall"
		exit
	fi
}


function uninstall()
{
    read -p "您确定真的要卸载vless吗？(y/n)" answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
		pid=`ps -ef |grep v2ray|grep -v grep|awk 'NR==1{print $2}'`
		kill $pid 
		rm -rf /vless
		rm -rf  /etc/nginx/conf.d/v2fly.conf
		nginx -s reload
        echo -e " ${red}卸载成功${plain}"
    fi
}



if [ $1 == install ]
then
	checkSystem
	preinstall
	installV2ray
elif [ $1 == uninstall ]
then
	uninstall
else
	echo "参数请传install或者uninstall"
	
fi


























































