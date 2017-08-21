-- content  
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
    local res, err = httpc:request_uri('http://base.main/index.php?app=Admin&m=BackGatway', {
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



local headers = ngx.req.get_headers()  
--local accinfo=get_access()
--local obj=json_decode(accinfo)
--ngx.say('accinfo:',accinfo)

--ngx.say('id ',obj.client_id)
--ngx.say('client_secret ',obj.client_secret)

