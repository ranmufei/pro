# -*- coding:utf-8 -*-
# 编辑 upstream
import pyClass.Upstream as ups
import os,sys

#PATH=sys.path[0]+'/'
PATH='/usr/local/orange/'
#upstreamName 应用服务名称
#host  应用地址
def addUpstream(upstreamName,host):
    #验证名称时候存在
	#不存在添加  存在不做处理
    files = open(PATH+"/conf/nginx.conf", "rb")
	# print "name %s" % upstreamName
	# print "host %s" % host
    try:
        content=files.read()
        post=content.find(upstreamName)
        if post==-1 :
            #没到了
            __adddata(upstreamName,host)
        else:
            return 

    except Exception, e:
        print e
    finally:
        files.close()
	pass
#确定添加
def __adddata(name,host):
    files = open(PATH+"/conf/nginx.conf", "rb")
    content = files.read()
    str_data="  upstream "+name+" { \n          server "+host+"; \n    } \n"
    pos=content.find("#--upstream--")
    if pos!=-1:
        content = content[:pos] + str_data + content[pos:]
        files=open(PATH+"/conf/nginx.conf","wb")
        files.write(content)
        files.close()
        return 'true'
    else:
        files.close()
        return 'false'
def remove():
	pass

def edit():
	pass

def main():
	#print sys.argv[0]
	#print sys.argv[1]
	addUpstream(sys.argv[1],sys.argv[2])
	#print "sys.path[0]=%s" % sys.path[0]
    #print "sys.argv[0]=%s" % sys.argv[0]
    #testfile()
	#print 'abc'
	#stream=ups.Upstream('/','host','name')
	#print stream.addStream('readme.txt')
	#print 'hello python'



if __name__ == '__main__':
	main()


