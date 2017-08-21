#!/bin/bash
# 数据库还原
# 流程
#       1 接受一个参数输入 ： 还原时间
#       2 验证该文件是否存在
#       3 存在文件 解压到数据库目录
#       4 结束
#  2017 08 07    云板容器版特别专用


codePath="/home/www/maindata/"
dbPath="/home/www/"


#date=$(date +%Y%m%d-%H%M)
#codeName='maindata_'${date}

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

#save path
saveCodePath=${codePath}backup/upload/
saveDbPath=${codePath}backup/database/

date=$1

if [ -z "${date}" ];then
        echo "please input a  param";
        exit
fi

if [ ! -f ${saveDbPath}${date} ];then 
        echo "file not find"
        exit 100
    else
        #id=$(get_container_name "databases")
        id=$2 # param is database serverid
		http_rancher 'v1/projects/1a5/services/'${id}'/?action=deactivate'   
        sleep 5
        cd ${saveDbPath}
        rm ${dbPath}www-apps-com -rvf
        cp ${date} ${dbPath}
        cd ${dbPath}
        tar -zxvf ${date}
        sleep 2
		rm ${dbPath}${date} -rvf
        http_rancher 'v1/projects/1a5/services/'${id}'/?action=activate' &>/dev/null
fi

if [[ $? = 0 ]];then
        #exit 0
        echo 'success'
else
        #exit 101
        echo 'error'
fi
