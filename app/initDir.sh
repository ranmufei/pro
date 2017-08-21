#!/bin/bash
# 初始化程序目录 数据库


stackname=$1

path=/data/www/${stackname} #项目目录


initPath=/home/www #原始代码目录

mkdir -p $path

cp ${initPath}"/maindata.tar.gz" $path && cd $path && tar -zxvf maindata.tar.gz 

cp ${initPath}"/www-apps-com.tar.gz" $path && cd $path && tar -zxvf www-apps-com.tar.gz


