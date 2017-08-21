local os=os

-- author ranmufei 
-- date 2017 07 27
-- 简介 对云主机 调度 ，初始化，  管理； 涉及 rancher API，文件目录  OS 操作；

local _M = {}

local http = require "resty.http"
local cjson=require "cjson"
local ORANGE_PATH='/usr/local/orange/'
local url='http://172.17.0.1:8080'


-- in docker continer reload orange config
function _M.reloadOrange()
	return(os.execute("orange reload"))
end 


-- 根据应用名称 检查应用安装与否
-- host   主机ip
-- appname 应用名称
-- psw   授权密钥

-- return service 已安装  0：未安装
function _M.checkInstall(appname,psw)
	--local host=host;
	local url=url..'/v1/projects/1a5/services?name='..appname
	local psw=ngx.encode_base64(psw)
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "get",
		--body = 'rule='..selector,
		headers = {
		 -- ["Content-Type"] = "application/x-www-form-urlencoded",
		  ["authorization"] = "Basic "..psw,
		}
	})
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	ngx.status = res.status
	
	local object=cjson.decode(res.body)
	
	if pcall(function () local s=object.data[1]['type'] end) then
		return object.data[1]['type']
		else
		return 0
	end
	
	ngx.exit()
	
	--return type(object.data[1]['type']) -- service
	--return res.body
	
end
-- 根据stick name  获取 stack ID
-- @stackname rancher stackname
-- @psw rancher 登录授权密钥
function _M.getStackId(stackname,psw)
	local stackname=stackname
	
	local url=url..'/v1/projects/1a5/environments?name='..stackname
	local psw=ngx.encode_base64(psw)
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "get",
		--body = 'rule='..selector,
		headers = {
		 -- ["Content-Type"] = "application/x-www-form-urlencoded",
		  ["authorization"] = "Basic "..psw,
		}
	})
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	 
	--ngx.status = res.status
	
	local object=cjson.decode(res.body)
	
	if pcall(function () local s=object.data[1]['id'] end) then
		return object.data[1]['id']
		else
		return 0
	end
end

--'/v1/projects/1a5/services?name=base&environmentId=1e2'
-- 根据 stackid  and servername 获取 service 的ID
-- @stackid stackID 
-- @ servername 容器名称
-- @psw rancher 登录授权密钥
function _M.getserversId(stackid,servername,psw)
	--local stackname=stackname
	
	--local url=url..'/v1/projects/1a5/environments?name='..stackname
	local url=url..'/v1/projects/1a5/services?name='..servername..'&environmentId='..stackid
	local psw=ngx.encode_base64(psw)
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "get",
		--body = 'rule='..selector,
		headers = {
		 -- ["Content-Type"] = "application/x-www-form-urlencoded",
		  ["authorization"] = "Basic "..psw,
		}
	})
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	--ngx.status = res.status
	
	local object=cjson.decode(res.body)
	
	if pcall(function () local s=object.data[1]['id'] end) then
		return object.data[1]['id']
		else
		return 0
	end
end


--'/v1/projects/1a5/services?name=base&environmentId=1e2'
-- 
-- @stackid stackID 
-- @ servername 容器名称
-- @psw rancher 登录授权密钥
-- @return id accountId name created environmentId uuid dataVolumes imageUuid
function _M.getAppInfo(stackid,servername,psw)
	--local stackname=stackname
	
	--local url=url..'/v1/projects/1a5/environments?name='..stackname
	local url=url..'/v1/projects/1a5/services?name='..servername..'&environmentId='..stackid
	local psw=ngx.encode_base64(psw)
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "get",
		--body = 'rule='..selector,
		headers = {
		 -- ["Content-Type"] = "application/x-www-form-urlencoded",
		  ["authorization"] = "Basic "..psw,
		}
	})
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	--ngx.status = res.status
	
	local object=cjson.decode(res.body)
	
	if pcall(function () local s=object.data[1]['id'] end) then
		local id ,accountId, name, created, environmentId, uuid, dataVolumes, imageUuid
		local info={}
		
		info.id=object.data[1]['id']
		info.accountId=object.data[1]['accountId']
		info.name=object.data[1]['name']
		info.created=object.data[1]['created']
		info.environmentId=object.data[1]['environmentId']
		info.uuid=object.data[1]['uuid']
		info.dataVolumes=object.data[1]['launchConfig']['dataVolumes']
		info.imageUuid=object.data[1]['launchConfig']['imageUuid']
		
		return cjson.encode(info)
		else
		return 0
	end
end

-- 安装容器 直接安装 不检查名称
function _M.install(appname,images,volume,ports,stackname,psw,selectorid)
	local name=appname
	local images=images
	local volume=volume   -- '/aaa/sss:/sss/sss,/asdas/asdasd:/asdas/asdas'
	local ports= ports
	local environmentId=_M.getStackId(stackname,psw) -- stack name
	local psw=ngx.encode_base64(psw)
	
	
	--return environmentId
	--ngx.exit(200)
	--local str='{"description":"serccrent", "environmentId":"'..environmentId..'", "name":"'..name..'", "scale":0, "scalePolicy":"", "launchConfig":{"capAdd":[], "capDrop":[], "count":null, "cpuSet":null, "cpuShares":null, "dataVolumes":["'..volume..'"], "dataVolumesFrom":[], "description":null, "devices":[], "dns":[], "dnsSearch":[], "domainName":null, "hostname":null, "imageUuid":"'..images..'", "kind":"container", "labels":{"io.rancher.container.pull_image":"always"}, "logConfig":{"config":{}, "driver":""}, "memory":null, "memoryMb":null, "memorySwap":null, "networkMode":"managed", "pidMode":null, "ports":["'..ports..'"], "privileged":false, "publishAllPorts":false, "readOnly":false, "requestedIpAddress":null, "startOnCreate":true, "stdinOpen":true, "tty":true, "user":null, "userdata":null, "version":"0", "volumeDriver":null, "workingDir":null, "dataVolumesFromLaunchConfigs":[], "networkLaunchConfig":null, "vcpu":1}, "secondaryLaunchConfigs":[], "assignServiceIpAddress":false, "startOnCreate":true}'
	local str2='{"description":"serccrent", "environmentId":"'..environmentId..'", "name":"'..name..'", "scale":0, "scalePolicy":"", "launchConfig":{"capAdd":[], "capDrop":[], "count":null, "cpuSet":null, "cpuShares":null, "dataVolumes":["'..volume..'"], "dataVolumesFrom":[], "description":null, "devices":[], "dns":[], "dnsSearch":[], "domainName":null, "hostname":null, "imageUuid":"docker:'..images..'", "kind":"container", "labels":{"io.rancher.container.pull_image":"always"}, "logConfig":{"config":{}, "driver":""}, "memory":null, "memoryMb":null, "memorySwap":null, "networkMode":"managed", "pidMode":null, "ports":[], "privileged":false, "publishAllPorts":false, "readOnly":false, "requestedIpAddress":null, "startOnCreate":true, "stdinOpen":true, "tty":true, "user":null, "userdata":null, "version":"0", "volumeDriver":null, "workingDir":null, "dataVolumesFromLaunchConfigs":[], "networkLaunchConfig":null, "vcpu":1}, "secondaryLaunchConfigs":[], "assignServiceIpAddress":false, "startOnCreate":true}'
	local url='http://172.17.0.1:8080/v1/projects/1a5/services'
	
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "POST",
		body = str2,
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	local object=cjson.decode(res.body)
	if object.type =='service' then
		local runpy=true -- 2017 07 21 发现不用 添加upstream 也可以访问指定的容器 --_M.runPy(ORANGE_PATH..'pro/app/upstream.py'..' '..appname..' '..appname..'.'..stackname)
		if runpy == true then
			
			addrule=_M.addRule(selectorid,appname) -- 添加规则
			
		end
		--return 'succ'
		return '{"statu":1,"info":"success install app"}'
		
	else
		--return object
		return res.body
		--return 'err'
	end
	--return res.body
	
	
end


--  安装容器
-- 1 检查同名容器是否存在
-- 2 安装容器
--@params stack stackname
--@params appname 服务名称 
--@params project 项目名称/主机名称

function _M.installApp(appname,images,volume,ports,stackname,psw,selectorid)
	
	if _M.checkInstall(appname,psw)=='service' then
		-- 已安装
		local info='this app '..appname..' have already install'
		--return 'this app '..appname..' have already install'
		return '{"statu":0,"info":"'..info..'"}'
	else
		return _M.install(appname,images,volume,ports,stackname,psw,selectorid)
	end
	
	
	
end



-- 容器升级
-- @appname : 应用key
-- @images : 升级到的容器镜像
-- @stackname : stackname   default  : base; 
-- @psw : rancher authorkey
function _M.updateApp(appname,images,volume,stackname,psw)
	local name=appname
	local images=images
	local volume=volume   -- '/aaa/sss:/sss/sss,/asdas/asdasd:/asdas/asdas'
	--local ports= ports
	local environmentId=_M.getStackId(stackname,psw) -- stack name
	local appnameid=_M.getserversId(environmentId,appname,psw)
	local appinfo=_M.getAppInfo(environmentId,name,psw)
	local psw=ngx.encode_base64(psw)
	
	local info=cjson.decode(appinfo)
	
	local str5='{"inServiceStrategy":{"batchSize":1,"intervalMillis":2000,"startFirst":false,"launchConfig":{"kind":"container","networkMode":"managed","privileged":false,"publishAllPorts":false,"readOnly":false,"startOnCreate":true,"stdinOpen":true,"tty":true,"vcpu":1,"capAdd":[],"capDrop":[],"count":null,"cpuSet":null,"cpuShares":null,"dataVolumes":["'..info.dataVolumes[1]..'"],"dataVolumesFrom":[],"description":null,"devices":[],"dns":[],"dnsSearch":[],"domainName":null,"hostname":null,"imageUuid":"docker:'..images..'","labels":{"io.rancher.container.pull_image":"always"},"logConfig":{"config":{},"driver":""},"memory":null,"memoryMb":null,"memorySwap":null,"pidMode":null,"ports":[],"requestedIpAddress":null,"user":null,"userdata":null,"version":"0","volumeDriver":null,"workingDir":null,"dataVolumesFromLaunchConfigs":[],"networkLaunchConfig":null,"type":"launchConfig","createIndex":null,"created":null,"deploymentUnitUuid":null,"externalId":null,"firstRunning":null,"healthState":null,"removed":null,"startCount":null,"systemContainer":null,"uuid":null},"secondaryLaunchConfigs":[]}}'
	local url5='http://172.17.0.1:8080/v1/projects/'..info.accountId..'/services/'..appnameid..'/?action=upgrade'
	local httpc = http.new()
	local res, err = httpc:request_uri(url5, {
		method = "POST",
		body = str5,
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	local object=cjson.decode(res.body)
	if object.type =='service' then		
		--return 'succ'
		return '{"statu":1,"info":"success Update app  '..appname..'"}'		
	else
		--return object
		return res.body
		--return 'err'
	end
	--return res.body
	
end


-- 确认升级完成接口
--@appname appkey
--@stackname stack name
--@psw ranchr 密钥
function _M.upgradeOk(appname,stackname,psw)

	local environmentId=_M.getStackId(stackname,psw) -- stack name
	local appnameid=_M.getserversId(environmentId,appname,psw)
	local appinfo=_M.getAppInfo(environmentId,appname,psw)
	local psw=ngx.encode_base64(psw)
	local info=cjson.decode(appinfo)
	
	local url='http://172.17.0.1:8080/v1/projects/'..info.accountId..'/services/'..appnameid..'/?action=finishupgrade'
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "POST",
		body = '',
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	local object=cjson.decode(res.body)
	if object.type =='service' then
		--return 'succ'
		--return res.body
		return '{"statu":1,"info":"success finishupgrade app  '..appname..'"}'		
	else
		--return object
		return res.body
		--return 'err'
	end
end

-- 查看容器服务状态
function _M.statu(appname,stackname,psw)
	local environmentId=_M.getStackId(stackname,psw) -- stack name
	local appnameid=_M.getserversId(environmentId,appname,psw)
	local appinfo=_M.getAppInfo(environmentId,appname,psw)
	local psw=ngx.encode_base64(psw)
	local info=cjson.decode(appinfo)
	
	local url='http://172.17.0.1:8080/v1/projects/'..info.accountId..'/services/'..appnameid
	--local url='http://172.17.0.1:8080/v1/projects/'..info.accountId..'/services?name='..base..'&environmentId='..environmentId
	local httpc = http.new()
	local res, err = httpc:request_uri(url, {
		method = "GET",
		body = '',
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	local object=cjson.decode(res.body)
	if object.type =='service' then
		--return 'succ'
		--return res.body
		return '{"statu":"'..object.state..'","info":" get return info with app:  '..appname..'"}'		
	else
		--return object
		return res.body
		--return 'err'
	end
end


-- 获取负载域名列表
-- return table; 
-- serviceId  负载均衡 serviceID 
--local arr='{"serviceLinks":[{"serviceId":"1s1","ports":["123.free.03in.com:8082=80","211.free.03in.com:8082=80"]},{"serviceId":"1s44","ports":["1231.free.03in.com:8082=80"]},{"serviceId":"1s38","ports":["21.free.03in.com:8082=80"]}]}'
function _M.getDomainList(serviceId,psw)
	local url = 'http://172.17.0.1:8080/v1/projects/1a5/serviceconsumemaps?serviceId='..serviceId
	local httpc = http.new()
	
	local psw = ngx.encode_base64(psw)
	local res, err = httpc:request_uri(url, {
		method = "GET",
		body = '',
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	local object=cjson.decode(res.body)
		
	local bb={ 
		["serviceLinks"]={}
	  }

	
	for v,k in pairs(object.data) do
		local cc={['serviceId']=k['consumedServiceId'],['ports']=k['ports']}
		table.insert(bb["serviceLinks"],cc)
		--bb[v]['serviceId']=k['consumedServiceId']
		--table.insert(bb[v]['ports'],k['ports'])
	end
	
	
	
	return bb --cjson.encode(bb) --res.body
end

-- 添加域名指向服务
-- lb_serviceId  负载服务ID
-- company_app_serviceid 起的公司base 应用ID
-- domain 二级域名
-- psw 密匙
function _M.addDomain(lb_serviceId,company_app_serviceid,domain,psw,stackname)
	
	local url='http://172.17.0.1:8080/v1/projects/1a5/loadbalancerservices/'..lb_serviceId..'/?action=setservicelinks'
	local postStr = _M.getDomainList(lb_serviceId,psw)
	
	local free=_M.getDomain(stackname)
	
	local domain = {domain..'.'..free..'.03in.com:8082=8888'}
    local domaarr = {['serviceId']=company_app_serviceid,['ports']=domain}
	table.insert(postStr["serviceLinks"],domaarr)

	local httpc = http.new()
	local psw = ngx.encode_base64(psw)
	local postdata=cjson.encode(postStr)
	local res, err = httpc:request_uri(url, {
		method = "POST",
		body = postdata,
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	 
	local object=cjson.decode(res.body)
	if object.type == 'loadBalancerService' then
		return '{"statu":"true","info":"add success"}'		
	else
		return '{"statu":"false","info":"add domian err}'
	end
	
	--return res.body --cjson.encode(postStr)
	
end

-- rancher http
-- psw   
-- method  : post  /  get
-- data : json string
-- return json
function _M.http(url,method,data,psw)
	local httpc = http.new()	
	local psw = ngx.encode_base64(psw)
	--local postdata=cjson.encode(data)
	--local datas='{"type":"environment","startOnCreate":true,"name":"","dockerCompose":"base:\n  tty: true\n  image: hub.03in.com:5002/base/linksamephp:B4\n  privileged: true\n  volumes:\n  - /home/www/maindata:/app/web\n  stdin_open: true\nbase2:\n  tty: true\n  image: hub.03in.com:5002/base/linksamephp:B4\n  privileged: true\n  volumes:\n  - /home/www/maindata:/app/web\n  stdin_open: true","created":null,"description":null,"externalId":"","healthState":null,"kind":null,"removed":null,"uuid":null,"previousExternalId":null}'
	local res, err = httpc:request_uri(url, {
		method = method,
		body = data,
		headers = {
		  ["authorization"] = "Basic "..psw,
		  ["Content-Type"] = "Content-Type: application/json",
		  ["Accept"] = "application/json",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end
	
	return res.body

end

-- 创建stack
function _M.createStack(stackname,psw)
	local url = 'http://172.17.0.1:8080/v1/projects/1a5/environment'
	local data='{\"type\":\"environment\",\"startOnCreate\":true,\"name\":\"'..stackname..'\",\"dockerCompose\":\"orange:\\n  labels:\\n    io.rancher.container.pull_image: always\\n  tty: true\\n  image: hub.03in.com:5002/ranmufei/orange:v6.4\\n  volumes:\\n  - /data/www/'..stackname..'/maindata/orange/conf:/usr/local/orange/conf\\n  - /data/www/'..stackname..'/maindata/orange/pro:/usr/local/orange/pro\\n  - /data/www/'..stackname..'/maindata/openresty/ngxluadev:/usr/local/openresty/ngxluadev\\n  - /data/www/'..stackname..'/maindata/openresty/logs/error.log:/usr/local/openresty/nginx/logs/error.log\\n  - /data/www/'..stackname..':/home/www\\n  stdin_open: true\\ndatabases:\\n  environment:\\n    MYSQL_ROOT_PASSWORD: ^%cqsyy@#1xyd2xsyc6z\\n  tty: true\\n  image: hub.03in.com:5002/ranmufei/mariadb:v1\\n  volumes:\\n  - /data/www/'..stackname..'/www-apps-com:/var/lib/mysql\\n  stdin_open: true\\nbase:\\n  tty: true\\n  image: hub.03in.com:5002/base/linksamephp:B4\\n  privileged: true\\n  volumes:\\n  - /data/www/'..stackname..'/maindata:/app/web\\n  stdin_open: true\\nphpmyadmin:\\n  tty: true\\n  image: hub.03in.com:5002/ranmufei/php-phpmyadmin:v1.0.1\\n  links:\\n  - databases:mysql\\n  stdin_open: true\",\"created\":null,\"description\":null,\"externalId\":\"\",\"healthState\":null,\"kind\":null,\"removed\":null,\"uuid\":null,\"previousExternalId\":null}'
	local http = _M.http(url,'POST',data,psw)
	return http
end

-- 初始化目录  数据库  代码
function _M.initDir(stack)	
	return os.execute("sh ./app/initDir.sh "..stack)
end



-- 暂停 hock 写法
function _M.sleep(n)
    if n > 0 then
        os.execute("ping -c " .. tonumber(n+1) .. " localhost > NULL") 
    end
end

-- 创建云板免费版 完整过程
-- stackname  公司cid
-- lb_serviceId LB  serviceID
-- company_app_serviceid 公司base 应用ID
-- domain 域名 code
-- psw 密钥
function _M.initCompany(stackname,lb_serviceId,domain,psw)
	if _M.initDir(stackname)==true then
		local ctinfo = cjson.decode(_M.createStack(stackname,psw))
		
		if ctinfo['type']=='environment' then   
			local stackid=_M.getStackId(stackname,psw)
			if stackid==0 then
				return '{"statu":"false","info":"stackid is 0"}'
			end
			_M.sleep(5)
			local company_app_serviceid = _M.getserversId(stackid,'orange',psw)
			if company_app_serviceid==0 then
				return '{"statu":"false","info":"company_app_serviceid is 0"}'
			end
			local add_domain = cjson.decode(_M.addDomain(lb_serviceId,company_app_serviceid,domain,psw,stackname))
			--local add_domain = _M.addDomain(lb_serviceId,company_app_serviceid,domain,psw)
			if add_domain['statu']=="true" then
				return '{"statu":"true","info":"initCompany success"}'
			else
			    _M.deleteStack(stackname,psw)
				return '{"statu":"false","info":"addDomain err"}' 
			end
		else
			_M.deleteStack(stackname,psw)
			return '{"statu":"false","info":"createStack err"}'
		end
	else
		_M.removeCompanyStack(stackname)
		return '{"statu":"false","info":"initDir error"}'
	end
end

-- 返回json字符串函数 
--  用于返回专用
function _M.returnInfo(statu,info)
	if statu=='true' then
		return '{"statu":"true","info":"'..info..'"}'
	else
		return '{"statu":"false","info":"'..info..'"}'
	end
end

-- 取消初始化
-- 当初始化企业相关过程失败时 删除相关
function _M.removeCompanyStack(stackname)
	return os.execute("sh ./app/removeDir.sh "..stackname)
end

-- 停止stack
function _M.stopStack(stackname,psw)
	local environmentId=_M.getStackId(stackname,psw)
	if environmentId==0 then
		_M.returnInfo('false','get stackID  is error')
		--return '{"statu":"false","info":"get stackID  is error"}'
	end
	
	local url='http://172.17.0.1:8080/v1/projects/1a5/environments/'..environmentId..'/?action=deactivateservices'
	local stopinfo = cjson.decode(_M.http(url,'POST','',psw))
	if stopinfo['type']=='environment' then
		return _M.returnInfo('true','stopStack succ')
	else
		return _M.returnInfo('false','stopStack err')
	end
	--return stopinfo	
	
end

-- 启动stack
function _M.startStack(stackname,psw)

	local environmentId=_M.getStackId(stackname,psw)
	if environmentId==0 then
		_M.returnInfo('false','get stackID  is error')
		--return '{"statu":"false","info":"get stackID  is error"}'
	end
	
	local url='http://172.17.0.1:8080/v1/projects/1a5/environments/'..environmentId..'/?action=activateservices'
	local stopinfo = cjson.decode(_M.http(url,'POST','',psw))
	if stopinfo['type']=='environment' then
		return _M.returnInfo('true','start Stack succ')
	else
		return _M.returnInfo('false','start Stack err')
	end
	
end

-- 删除 stack
function _M.deleteStack(stackname,psw)

	local environmentId=_M.getStackId(stackname,psw)
	if environmentId==0 then
		_M.returnInfo('false','get stackID  is error')
		--return '{"statu":"false","info":"get stackID  is error"}'
	end

	local url='http://172.17.0.1:8080/v1/projects/1a5/environments/'..environmentId
	local stopinfo = cjson.decode(_M.http(url,'DELETE','',psw))
	if stopinfo['type']=='environment' then
		_M.removeCompanyStack(stackname)
		return _M.returnInfo('true','DELETE Stack succ')
	else
		return _M.returnInfo('false','DELETE Stack err')
	end
	
end

-- 备份数据库
function _M.backupDatabases(stackname)
	return os.execute("sh ./app/dbbackup.sh "..stackname)
end

-- 数据库还原
-- datas  还原数据选择文件
-- databasesid  数据库服务ID
function _M.rebackupDatabases(datas,databasesid)
	return os.execute("sh ./app/dbrebackup.sh "..datas..' '..databasesid)
end

-- 获取云板容器版 二级域名（所属那台云主机）
-- 
function _M.getDomain(cid)
	-- /index.php?app=Core&m=V8&a=getHostDomain&cid=455
	local url = 'http://www.linksame.com/index.php?app=Core&m=V8&a=getHostDomain&cid='..cid
	local domain = _M.http(url,'xxx','','xxxx')
	return domain
end

return _M
