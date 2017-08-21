--  本文件处理阶段 access_by_lua_

-- 外部访问进来 必须经过这里做 授权的验证
-- 0 外部登录验证
-- 1 创始人授权后有token 以及cid
-- 2 token cid 更新到 basic auth 组件中 表示用户名密码
-- 3 拼接 请求头 读取“用户名 密码”（上面的token cid）
-- 4 访问目标

-- cookie 判断登录  通过判断 登录 读取 企业client_id secret 作为加密
local cjson=require('cjson');
local http=require('resty.http');

-- 处理json_错误  
function json_decode( str )
    local json_value = nil
    pcall(function (str) json_value = cjson.decode(str) end, str)
    return json_value
end

-- 获取 授权信息 
function get_access()
	local httpc = http.new();
    local res, err = httpc:request_uri('http://base/index.php?app=Admin&m=BackGatway', {
    method = "GET",
       headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })
    -- 终止所有非法请求
     if not res then        
        ngx.say("failed to request: ", err)
        return ngx.redirect("/50x.html?name="..err);
     end
    -- 解码 token
    local text = res.body;
    --local json=json_decode(text)
    return text
end
-- 20170815 添加手机端访问容器验证参数 mtoken  验证通过后 可以访问
-- 获取授权信息
	local acc=get_access()
	local accinfo=json_decode(acc)
if ngx.var.cookie_oa_cid ~=nil or ngx.req.get_uri_args()["mtoken"] == accinfo.client_secret then
	
	-- 获取授权信息
	local acc=get_access()
	local accinfo=json_decode(acc)
	--ngx.log(ngx.INFO, "---- RMF string:---- ok", ngx.var.cookie_oa_cid)
	--ngx.header['Set-Cookie'] = {"ID=234523452352345; path=/","client_secret=2345234523452345; path=/"}
		
		local uid=accinfo.client_id --'ranmufei'
		local token=accinfo.client_secret --'feifei'
		local str=ngx.encode_base64(uid..':'..token)
		ngx.req.set_header("Authorization", "Basic "..str)
		
	else
	 ngx.log(ngx.ERR, "---- RMF string:---- err", ngx.var.cookie_oa_cid)
	return ngx.redirect('/error.html') --ngx.exit(200)
end


--ngx.say("access")
--在这前面完成 base64 授权信息组装
local orange = context.orange
orange.access()
