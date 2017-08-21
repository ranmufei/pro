-- base 访问入口验证  nginx 的access_init 阶段

local uid='ranmufei'
local token='feifei'
local str=ngx.encode_base64(uid..':'..token)
local cid='222'
local access_token='adasdad'
local shell='asdasdasda'

--ngx.header['Set-Cookie'] = {"oa_uid="..uid.."; path=/", "oa_cid="..cid.."; path=/", "SGAccessToken="..ngx.md5(access_token).."; path=/","oa_shell="..shell.."; path=/"}

--ngx.req.set_header("Authorization", "Basic "..str)


local orange = context.orange
orange.header_filter()
