local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local cjson = require "cjson"
local changebody = require "kong.plugins.bodytoken.changebody"
local req_get_headers = ngx.req.get_headers
local pl_path = require "pl.path"

local BodyTokenHandler = BasePlugin:extend()



function BodyTokenHandler:new()
  BodyTokenHandler.super.new(self, "bodytoken")
end

local function checktoken(conf)
  if not conf.tokenname  then
    ngx.log(ngx.ERR, "[bodytoken] no conf.tokenname set, aborting plugin execution")
    return false, {status = 500, message= "Invalid plugin configuration"}
  end

  local tokenname = conf.tokenname


  local args =nil
  local request_method = ngx.var.request_method
  if "GET" == request_method then
      args = ngx.req.get_uri_args()
  elseif "POST" == request_method then
      ngx.req.read_body()
      args = ngx.req.get_post_args()
  end

  local token
  local body
  if type(args)=="table" then
    for key,value in pairs(args) do
        if key == "body" then
           body=value
        end 
    end
  end

  if req_get_headers()[tokenname] then
      token=req_get_headers()[tokenname]
  end

  if not token then
    return false, {status = 401, message = "No token found in headers or querystring"}
  end

  if not body then
    return false, {status = 401, message = "No body found in headers or querystring"}
  end

  local curpath= pl_path.package_path("kong")
  curpath =string.gsub(curpath,"kong.lua","kong").."/plugins/"

  local cmd= io.popen("sh "..curpath.."tool/bin/run.sh bodytoken -b "..body.." -t "..token)
  local result=cmd:read("*all")
  cmd:close()
  local data,err = cjson.decode(result)
  if err then
     return false, {status = 401, message = "unknown token ,cann't decode it !"}
  end

  if data.code==0 then
     return false, {status = 401, message = data.message}
  end 

  changebody.execute("body",data.data)

  return true
end


function BodyTokenHandler:access(conf)

 BodyTokenHandler.super.access(self)
 local ok, err = checktoken(conf)
  if not ok then
      return responses.send(err.status, err.message)
  end
end

BodyTokenHandler.PRIORITY = 900
return BodyTokenHandler
