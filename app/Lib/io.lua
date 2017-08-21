local os=os
--require "lfs" 
-- author ranmufei 
-- date 2017 06 19
-- 简介 这是一个对相关业务的模块封装 

local _M = {}

local http = require "resty.http"
local cjson=require "cjson"
local ORANGE_PATH='/usr/local/orange/'
local url='http://172.17.0.1:8080'
local url7777='http://172.17.0.1:7777' -- orange api url 
-- rename
function _M.rename(path,oldname,newname)
	os.rename(oldname,newname)
end


-- say hello
function _M.hello(name)
	return 'hello'..name
end

-- run python
function _M.runPy(pyname)
	return(os.execute("python "..pyname))
	--return lfs.currentdir
end

-- in docker continer reload orange config
function _M.reloadOrange()
	return(os.execute("orange reload"))
end 

-- 添加代理分流规则
--urladdress orange 可访问地址
--selectorid 分流选择器ID
--appname 添加应用名称
function _M.addRule(selectorid,appname)
	local urladdress='orange:7777'
	local appname=appname
	local selectorid=selectorid
	if (appname or selectorid or urladdress) == nil then
		ngx.say('params must not nil')
		return 
	end
	
	local url='http://'..urladdress..'/divide/selectors/'..selectorid..'/rules'
	local selector='{ "name": "'..appname..'", "judge": { "type": 0, "conditions": [ { "type": "URI", "operator": "match", "value": "/'..appname..'/" } ] }, "extractor": { "type": 1, "extractions": [] }, "upstream_host": "", "upstream_url": "http://'..appname..'", "log": true, "enable": true }'
	--7777/divide/selectors/c61e813a-9f5a-499e-8f59-ada0e4377eb1/rules
	local http = require "resty.http"
	local httpc = http.new()

	local res, err = httpc:request_uri(url, {
		method = "POST",
		body = 'rule='..selector,
		headers = {
		  ["Content-Type"] = "application/x-www-form-urlencoded",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		ngx.say('url:',url)
		return
	end

	-- In this simple form, there is no manual connection step, so the body is read
	-- all in one go, including any trailers, and the connection closed or keptalive
	-- for you.

	ngx.status = res.status
	
	return res.body
	--ngx.say(res.body)
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
--
-- 根据stack Name  and  servername  get servername id with  rancher
function _M.getServerNameId(stackname,servername,psw)

	local stackid=_M.getStackId(stackname,psw)
	local serviceid=_M.getserversId(stackid,servername,psw)
	return serviceid
end



return _M
