#!/bin/bash
# 删除目录数据库文件夹


stackname=$1

if [ "$1"x == ""x ]; then
	echo 'no stackname'
	exit 0
else
	echo $1
fi

path=/data/www/${stackname}

if [ -d $path ];then
    echo 'dir is true'
	rm $path -rf
else
    echo 'dir not find'
fi



#cp ${initPath}"/maindata.tar.gz" $mainPath && cd $mainPath && tar -zxvf maindata.tar.gz 

#cp ${initPath}"/www-apps-com.tar.gz" $dbPath && cd $dbPath && tar -zxvf www-apps-com.tar.gz


