#!/bin/bash
# date 2017 08 07
# 云板容器版 数据库备份 shell代码；容器版专项
# 
# 一键备份代码 和 数据库   方便测试回滚
# 代码存放 /home/www/  数据库存放 /home/database/version/
# 
# 注意：备份附件 和 数据库
# 
# 全套思路
# 1 系统定时任务crontabe.sh 拷贝备份相关代码 到 /var/www/html/目录
#       修正： 用crontabe.sh 修改系统 宿主机的Apache 配置文件
# 2 系统 备份调用  http://172.17.0.1/ 执行 备份---  
# 3 业务流程
# 	复制 数据库目录 到 XXX/backup/

codePath="/home/www/maindata/"
dbPath="/home/www/www-apps-com/"
uploadfile=${codePath}"Uploads/"

date=$(date +%Y%m%d-%H%M)
codeName='maindata_'${date}

#curl http rancher method
# $1 api     v1/projects/1a5/services/1s37/?action=deactivate 停止数据库
#                       /v1/projects/1a5/services/1s37/?action=activate 启动
#                       "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}"
http_rancher() {
        curl -u "CA536FF6119B49B21403:z5KLJ5RVH9gqzL5rrZw45G5LdKP9r5GeFpNAV6ZT" \
        -X POST \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d '{}' \
        'http://172.17.0.1:8080/'$1     
}

# this func it's get containaer id  ; used container name
# @params container_name  container name 
# @return string    container id
get_container_name() {
        containerName=$1
        container=$(curl -u "CA536FF6119B49B21403:z5KLJ5RVH9gqzL5rrZw45G5LdKP9r5GeFpNAV6ZT" \
        -X GET \
        -H 'Accept: application/json' \
        -H 'Content-Type: application/json' \
        -d {} \
        'http://172.17.0.1:8080/v1/projects/1a5/services/?name='$1 | jq .data[0].id|sed 's/\"//g')
        echo $container
        #return $container
}


#id=$(get_container_name "databases")
id=$1
#save path
saveCodePath=${codePath}backup/upload/${date}/
saveDbPath=${codePath}backup/database/${date}/
# stop database
http_rancher 'v1/projects/1a5/services/'${id}'/?action=deactivate'   
sleep 5
if  [ ! -d ${saveCodePath} ];then
        mkdir ${saveCodePath}
        echo "create ${saveCodePath}"
fi

if [ ! -d ${saveDbPath} ];then
        mkdir ${saveDbPath}
        echo " create ${saveDbPath}"
fi


cp ${dbPath} ${saveDbPath} -rvf

sleep 1
http_rancher 'v1/projects/1a5/services/'${id}'/?action=activate'

# 压缩数据库文件
cd ${codePath}backup/database/${date}/
tar -zcvf db-${date}.tar.gz www-apps-com
mv db-${date}.tar.gz ../
cd ../
rm ${date} -rvf

# cp ${uploadfile} ${saveCodePath} -rvf

if [[ $? = 0 ]];then
        echo 'success'
else
        echo 'error'
fi

#echo "end"




