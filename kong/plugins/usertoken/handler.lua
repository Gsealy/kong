local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local cjson = require "cjson"
local UserTokenHandler = BasePlugin:extend()

function UserTokenHandler:new()
  UserTokenHandler.super.new(self, "usertoken")
end

local function checktoken(conf)
  if not conf.tokenname  then
    ngx.log(ngx.ERR, "[usertoken] no conf.tokenname set, aborting plugin execution")
    return false, {status = 500, message= "Invalid plugin configuration"}
  end

  local tokenname = conf.tokenname
  local privatekey = conf.privatekey
  local publickey = conf.publickey
  local magiccode = conf.magiccode
  local version = conf.version

  local args =nil
  local request_method = ngx.var.request_method
  if "GET" == request_method then
      args = ngx.req.get_uri_args()
  elseif "POST" == request_method then
      ngx.req.read_body()
      args = ngx.req.get_post_args()
  end

  local token
  if type(args)=="table" then
    
    for key,value in pairs(args) do
        if key == conf.tokenname then
           token=value
        end 
    end
  end

  if not token then
    return false, {status = 401, message = "No usertoken found in headers or querystring"}
  end

  local tokenversion= string.sub(token,1,string.len(version))
  if tokenversion ~= version then
    return false, {status = 401, message = "Wrong token version in headers or querystring"}
  end 

  local cmd= io.popen("sh ../tool/bin/run.sh usertoken -pu "..publickey.." -pr "..privatekey.." -v "..version.." -m "..magiccode.." -t "..token)
  local result=cmd:read("*all")
  local data,err = cjson.decode(result)
  if err then
     return false, {status = 401, message = "unknown token ,cann't decode it !"}
  end

  if data.code==0 then
     return false, {status = 401, message = data.message}
  end 
  return true
end


function UserTokenHandler:access(conf)

 UserTokenHandler.super.access(self)
 local ok, err = checktoken(conf)
  if not ok then
      return responses.send(err.status, err.message)
  end
end

UserTokenHandler.PRIORITY = 1000
return UserTokenHandler
