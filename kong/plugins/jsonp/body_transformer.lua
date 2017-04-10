local cjson_decode = require("cjson").decode
local cjson_encode = require("cjson").encode
local pcall = pcall
local _M = {}



function _M.jsonp(conf,buffered_data)
   local json_body=read_json_body(buffered_data)
   if json_body == nil then return end
   local callback = conf.callback;
   if (ngx.header[callback] ~=nil) then
       return string.format( ngx.header[callback].."(%s)",cjson_encode(json_body))
   else
     return  cjson_encode(json_body)
   end
end


local function read_json_body(body)
  if body then
    local status, res = pcall(cjson_decode, body)
    if status then
      return res
    end
  end
end

return _M
