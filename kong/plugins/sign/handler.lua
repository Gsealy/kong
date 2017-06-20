local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"

local SignHandler = BasePlugin:extend()

function SignHandler:new()
  SignHandler.super.new(self, "sign")
end


local function checksign(conf)
  if not conf.signname  then
    ngx.log(ngx.ERR, "[sign] no conf.signname set, aborting plugin execution")
    return false, {status = 500, message= "Invalid plugin configuration"}
  end
  local signname = conf.signname
  local prefix = conf.prefix
  local after = conf.after
  local itemsplit = conf.itemsplit
  local pairsplit = conf.pairsplit
  local tbl={}
  local tblkey={}

  
  local args =nil
  local request_method = ngx.var.request_method
  if "GET" == request_method then
      args = ngx.req.get_uri_args()
  elseif "POST" == request_method then
      ngx.req.read_body()
      args = ngx.req.get_post_args()
  end

  local sign
  if type(args)=="table" then
    
    for key,value in pairs(args) do
        if key~=conf.signname then
           tbl[key]=value
           table.insert(tblkey,key)
        else
           sign=value
        end 
    end
  end

  if not sign then
    return false, {status = 401, message ={code=401,data={message= "No sign key found in headers"
                                          .." or querystring"}} }
  end
  table.sort(tblkey)
  local index=0

  local  temp=""
  for  _,key in pairs(tblkey) do
       index=index+1
         temp=temp..key..pairsplit..tbl[key]..itemsplit
  end
    temp =string.sub(temp,1,string.len(temp)-string.len(itemsplit))
  
  temp=prefix..temp..after
  local  formatkey = ngx.md5(temp)
  if ( string.lower(formatkey) ~= string.lower(sign)) then
      return false, {status = 403, message ={code=403,data={message="Unauthorized"}} }
  end

  return true
end


function SignHandler:access(conf)

 SignHandler.super.access(self)
 local ok, err = checksign(conf)
  if not ok then
      return responses.send(err.status, err.message)
  end
end

SignHandler.PRIORITY = 1000


return SignHandler
