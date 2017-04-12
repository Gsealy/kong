local BasePlugin = require "kong.plugins.base_plugin"
local body_filter = require "kong.plugins.jsonp.body_transformer"

local JsonpHandler = BasePlugin:extend()


function JsonpHandler:new()
  JsonpHandler.super.new(self, "jsonp")
end

function JsonpHandler:access(conf)
  JsonpHandler.super.access(self)
  ngx.ctx.buffer = ""
end

function JsonpHandler:header_filter(conf)
  JsonpHandler.super.header_filter(self)
  ngx.header.content_length = nil
end

function JsonpHandler:body_filter(conf)
  JsonpHandler.super.body_filter(self)
  
  if string.find(ngx.header["content-type"],"text/json") then
    local chunk, eof = ngx.arg[1], ngx.arg[2]
    if eof then
       local  body =body_filter.jsonp(conf, ngx.ctx.buffer)
        ngx.arg[1] = body
     else
        ngx.ctx.buffer = ngx.ctx.buffer..chunk
        ngx.arg[1] = nil
     end  
   end  
end

JsonpHandler.PRIORITY = 800

return JsonpHandler
