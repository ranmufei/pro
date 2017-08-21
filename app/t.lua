local lor = require("lor.index")
local io  = require("app.Lib.io")
local free = require("app.Lib.freeInit")
local os=os
local app = lor()

local ORANGE_PATH='/usr/local/orange/'

app:get("/", function(req, res, next)
    res:send("hello world!")
end)


app:get("/ran", function(req, res, next)
    --ngx.log('hello ranmufei fei ')
	local path=req.path
	local method =req.method 
	local query =req.query 
	local params=req.param
	local body=req.body
	local url=req.url
	local header=req.headers
	local data={}
		data[0]=path
		data[1]=method
		data[2]=query
		data[3]=params
		data[4]=body
		data[5]=url
		data[6]=header
	res:json(data)
end)


app:post("/test", function(req, res, next)
	local appname=req.body.appname
	local images=req.body.images
	local volume=req.body.volume
	--local ports=req.body.ports
	local stackname=req.body.stackname
	local psw=req.body.psw
	
	local info = io.upgradeOk(appname,stackname,psw) --io.getAppInfo(stackid,servername,psw)
	
	--ngx.say(id,' : ',accountId,' : ', name, ' : ',created,' : ', environmentId,' : ', uuid, ' : ',dataVolumes, ' : ',imageUuid)
	  ngx.say(info)
	 --local cjson=require "cjson"
	  ngx.exit(200)
	
      local http = require "resty.http"
	  local httpc = http.new()
	  
      local res, err = httpc:request_uri("http://orangedev2:7777/redirect/config", {
        method = "get",
        body = "a=1&b=2",
        headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
        }
      })
	  if not res then
        ngx.say("failed to request: ", err)
        return
      end

      -- In this simple form, there is no manual connection step, so the body is read
      -- all in one go, including any trailers, and the connection closed or keptalive
      -- for you.

      ngx.status = res.status

      for k,v in pairs(res.headers) do
          --
      end
     
	  --res:send("sss")
      ngx.say(res.body)
	  --ngx.say(res.status)
      --res:send("sss")
end)
-- 添加 upstream 配置
app:post("/addapp",function(req, res, next)
    local appname=req.body.appname
	local host=req.body.host
    --local param=req.params
	--res:send(host)
	
	local data={}
	local infodata={}
    local runpy=io.runPy(ORANGE_PATH..'pro/app/upstream.py'..' '..appname..' '..host)
	if runpy==true then
		
		infodata.appname=appname
		infodata.host=host
		
		data.statu=1
		data.info='成功'
		data.infodata=infodata
		io.reloadOrange() -- if add upstream config succ, so reloadOrange
		
		--data['data']['host']=host
	else
		infodata.appname=appname
		infodata.host=host
		
		data.statu=0
		data.info='失败'
		data.infodata=infodata
	end
    res:json(data)
    --res:send(runpy)
end)
-- reload orange
app:get("/reloadOrange", function(req, res, next)
   local data={}
   
   local reloadorange=io.reloadOrange()
	if reloadorange == true then
		data.statu=1
		data.info='reload succ'
	else
		data.statu=0
		data.info='reload error'
	end
	res:json(data)
end)
-- add divide/addRule
app:post("/divide/addRule/test",function(req,res,next)
	local appname=req.body.appname
	local selectorid='c61e813a-9f5a-499e-8f59-ada0e4377eb1'
	local url='http://192.168.1.20:7777/divide/selectors/'..selectorid..'/rules'
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
		return
	end

	-- In this simple form, there is no manual connection step, so the body is read
	-- all in one go, including any trailers, and the connection closed or keptalive
	-- for you.

	ngx.status = res.status
	ngx.say(res.body)
end)

-- add divide/addRule
app:post("/divide/addRule",function(req,res,next)
	local appname=req.body.appname
	local selectorid=req.body.selectorid
	--local urladdress=req.body.urladdress
	
	local addrule=io.addRule(selectorid,appname)
	ngx.say(addrule) -- json code
end)

-- 按装容器 会先判断是否安装
app:post("/installApp",function(req,res,next)
	local appname=req.body.appname
	local images=req.body.images
	local volume=req.body.volume
	local ports=req.body.ports
	local stackname=req.body.stackname
	local psw=req.body.psw
	
	--local host=req.body.host
	local selectorid=req.body.selectorid
	
		-- 按装容器
	local info=io.installApp(appname,images,volume,ports,stackname,psw,selectorid)
	
	
	if info=='succ' then
		
		
		
		--res:json(addRule)  
		ngx.say(info)
		--res:json(info)
	else
		--ngx.say('err',info)
		--ngx.say('err')
		ngx.say(info)
		--res:json(info)
	end
	--os.execute("sleep 5s")	
	io.reloadOrange()
	--ngx.say('after 5s run')
	return 
	--ngx.say(info) -- json code
end)

-- test reload
app:get("/reload",function(req,res,next)
	local re=os.execute("orange reload")
	ngx.say(re)
end)

-- 添加独立应用授权 cid  token
-- 用的少 
app:post("/Oauth",function(req,res,next)
	local cid=req.body.cid
	local token=req.body.token
	local selectorid='f25528d6-2796-4124-a5a7-695c406ee025'
	local url='http://orange:7777/basic_auth/selectors/'..selectorid..'/rules' --'http://172.17.0.1:7777/basic_auth/selectors/'..selectorid..'/rules'
	--local selector='{ "name": "'..appname..'", "judge": { "type": 0, "conditions": [ { "type": "URI", "operator": "match", "value": "/'..appname..'/" } ] }, "extractor": { "type": 1, "extractions": [] }, "upstream_host": "", "upstream_url": "http://'..appname..'", "log": true, "enable": true }'
    -- put
	--local put_selector='{"name":"author","judge":{"type":0,"conditions":[{"type":"URI","operator":"match","value":"/"}]},"handle":{"credentials":[{"username":"'..cid..'","password":"'..token..'"}],"code":401,"log":true},"enable":true,"id":"6951965c-4fab-440b-808a-6544483aa0a4"}'
	-- post
	local post_selector='{"name":"add","judge":{"type":0,"conditions":[{"type":"URI","operator":"match","value":"/"}]},"handle":{"credentials":[{"username":"'..cid..'","password":"'..token..'"}],"code":401,"log":true},"enable":true}'
	local http = require "resty.http"
	local httpc = http.new()

	local res, err = httpc:request_uri(url, {
		method = "POST",
		body = 'rule='..post_selector,
		headers = {
		  ["Content-Type"] = "application/x-www-form-urlencoded",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end


	ngx.status = res.status
	ngx.say(res.body)
end)
-- 更新
-- cid 企业cid
-- token 类似密码
app:put("/Oauth",function(req,res,next)
	local cid=req.body.cid
	local token=req.body.token
	
	local selectorid='f25528d6-2796-4124-a5a7-695c406ee025'
	local url='http://172.17.0.1:7777/basic_auth/selectors/'..selectorid..'/rules'
	--local selector='{ "name": "'..appname..'", "judge": { "type": 0, "conditions": [ { "type": "URI", "operator": "match", "value": "/'..appname..'/" } ] }, "extractor": { "type": 1, "extractions": [] }, "upstream_host": "", "upstream_url": "http://'..appname..'", "log": true, "enable": true }'
    -- put
	local put_selector='{"name":"author","judge":{"type":0,"conditions":[{"type":"URI","operator":"match","value":"/"}]},"handle":{"credentials":[{"username":"'..cid..'","password":"'..token..'"}],"code":401,"log":true},"enable":true,"id":"6951965c-4fab-440b-808a-6544483aa0a4"}'
	
	-- post
	--local post_selector='{"name":"add","judge":{"type":0,"conditions":[{"type":"URI","operator":"match","value":"/"}]},"handle":{"credentials":[{"username":"'..cid..'","password":"'..token..'"}],"code":401,"log":true},"enable":true}'
	local http = require "resty.http"
	local httpc = http.new()

	local res, err = httpc:request_uri(url, {
		method = "PUT",
		body = 'rule='..put_selector,
		headers = {
		  ["Content-Type"] = "application/x-www-form-urlencoded",
		}
	})
	
	if not res then
		ngx.say("failed to request: ", err)
		return
	end


	ngx.status = res.status
	ngx.say(res.body)
end)

-- 更新升级应用
-- @appname appkey
-- @images  升级目标镜像
-- @volume !似乎 容器的目录是不能更新执行 站位
-- @stackname mian公司组 云板免费版 4  位公司cid
-- @psw rancher 密钥 --aaa:xdsds
app:post("/updataApp",function(req,res,next)
	local appname=req.body.appname
	local images=req.body.images
	local volume=req.body.volume
	--local ports=req.body.ports
	local stackname=req.body.stackname
	local psw=req.body.psw
	
	local info = io.updateApp(appname,images,volume,stackname,psw) --io.getAppInfo(stackid,servername,psw)
	ngx.say(info)
end)

-- 确认安装完成
-- @appname
app:post("/upgradeOk",function(req,res,next)

    local appname=req.body.appname
	local stackname=req.body.stackname
	local psw=req.body.psw
	
	local info = io.upgradeOk(appname,stackname,psw) 
	ngx.say(info)
	  
end)

-- 应用状态

app:post("/AppStatu",function(req,res,next)
	local appname=req.body.appname
	local psw=req.body.psw
	local stackname=req.body.stackname
	local info = io.statu(appname,stackname,psw) 
	ngx.say(info)
	
end)

----------   为云板调度管理主机 编写的API 接口 -------------
----------   2017 07 27     @ranmufei          -------------


-- rancher 创建访问网关
app:post("/createGateway",function(req,res,next)
	local lb_serviceId=req.body.lb_serviceId
	local company_app_serviceid=req.body.company_app_serviceid
	local domain=req.body.domain
	local psw=req.body.psw
	local stackname=req.body.stackname
	
	local info = free.addDomain(lb_serviceId,company_app_serviceid,domain,psw,stackname)
	
	ngx.say(info)
end)

-- 初始化 stack
app:post("/initStack",function(req,res,next)
	local str = '{"type":"environment","startOnCreate":true,"dockerCompose":"databases:\n  environment:\n    MYSQL_ROOT_PASSWORD: ^%cqsyy@#1xyd2xsyc6z\n  tty: true\n  image: hub.03in.com:5002/ranmufei/mariadb:v1\n  volumes:\n  - /home/database/www-apps-com:/var/lib/mysql\n  stdin_open: true\nbase:\n  tty: true\n  image: hub.03in.com:5002/base/linksamephp:B4\n  privileged: true\n  volumes:\n  - /home/www/maindata:/app/web\n  stdin_open: true\nphpmyadmin:\n  ports:\n  - 8383:80/tcp\n  tty: true\n  image: hub.03in.com:5002/ranmufei/php-phpmyadmin:v1.0.1\n  links:\n  - databases:mysql\n  stdin_open: true","name":"19221","created":null,"description":null,"externalId":"","healthState":null,"kind":null,"removed":null,"uuid":null,"previousExternalId":null}'
	
end)

-- 初始化 代码  数据库
app:post("/initDatabase",function(req,res,next)
	
end)

-- test
app:post("/test2",function(req,res,next)

	local stackname=req.body.stackname
	local psw=req.body.psw
	local lb_serviceId=req.body.lb_serviceId
	local domain=req.body.domain
	
	local stackid = free.getStackId(stackname,psw)
	--local info = free.getserversId(stackid,'base',psw)
	local info=free.initCompany(stackname,lb_serviceId,domain,psw)
	--local info = free.sleep(5)
	--local info = free.removeCompanyStack(stackname) -- 删除目录
	--local info = free.deleteStack(stackname,psw) -- 停止stack
	ngx.say(info)
end)

-- 创建访公司stack & 绑定域名
-- stackname

app:post("/createStack",function(req,res,next)
	
	local stackname=req.body.stackname
	local psw=req.body.psw
	local lb_serviceId=req.body.lb_serviceId
	local domain=req.body.domain
	
	local info=free.initCompany(stackname,lb_serviceId,domain,psw)
	
	ngx.say(info)
	
end)


-- 启动 stack
app:post("/startStack",function(req,res,next)
	
	local stackname=req.body.stackname
	local psw=req.body.psw
	
	local info=free.startStack(stackname,psw)
	
	ngx.say(info)
	
end)

-- 停止stack
app:post("/stopStack",function(req,res,next)
	
	local stackname=req.body.stackname
	local psw=req.body.psw
	
	local info=free.stopStack(stackname,psw)
	
	ngx.say(info)
	
end)

-- 删除stack
app:post("/deleteStack",function(req,res,next)

	local stackname=req.body.stackname
	local psw=req.body.psw
	
	local info=free.deleteStack(stackname,psw)
	
	ngx.say(info)
	
end)


-- 容器版 备份数据库
app:post("/backupDataBases",function(req,res,next)

	local stackname=req.body.stackname
	local servername='databases'
	local psw=req.body.psw
    
	local serverid=io.getServerNameId(stackname,servername,psw)
	local info=free.backupDatabases(serverid)

	ngx.say(info)

end)

-- 容器版 还原数据库
-- date 还原文件
app:post("/rebackupDatabases",function(req,res,next)

	local dates=req.body.date
	local stackname=req.body.stackname
	local psw=req.body.psw
	local servername='databases'

	local serverid=io.getServerNameId(stackname,servername,psw)

	local info=free.rebackupDatabases(dates,serverid)

	ngx.say(info)
end)

-- 根据stackname  and  servername 获取容器的serverid
app:post("/getServerId",function(req,res,next)
	local stackname=req.body.stackname
	local servername=req.body.servername
	local psw=req.body.psw
	local info=io.getServerNameId(stackname,servername,psw)

	ngx.say(info)
end)

app:post("/getDomain",function(req,res,next)
	local cid=req.body.cid
	local domain=free.getDomain(cid)
	ngx.say(domain)
end)

app:run()

