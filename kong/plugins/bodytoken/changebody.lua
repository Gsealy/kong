local multipart = require "multipart"
local cjson = require "cjson"

local table_insert = table.insert
local req_set_uri_args = ngx.req.set_uri_args
local req_get_uri_args = ngx.req.get_uri_args
local req_set_header = ngx.req.set_header
local req_get_headers = ngx.req.get_headers
local req_read_body = ngx.req.read_body
local req_set_body_data = ngx.req.set_body_data
local req_get_body_data = ngx.req.get_body_data
local req_clear_header = ngx.req.clear_header
local req_set_method = ngx.req.set_method
local encode_args = ngx.encode_args
local ngx_decode_args = ngx.decode_args
local type = type
local string_find = string.find
local pcall = pcall

local _M = {}

local CONTENT_LENGTH = "content-length"
local CONTENT_TYPE = "content-type"
local JSON, MULTI, ENCODED = "json", "multi_part", "form_encoded"

local function parse_json(body)
  if body then
    local status, res = pcall(cjson.decode, body)
    if status then
      return res
    end
  end
end

local function decode_args(body)
  if body then
    return ngx_decode_args(body)
  end
  return {}
end

local function get_content_type(content_type)
  if content_type == nil then
    return
  end
  if string_find(content_type:lower(), "application/json", nil, true) then
    return JSON
  elseif string_find(content_type:lower(), "multipart/form-data", nil, true) then
    return MULTI
  elseif string_find(content_type:lower(), "application/x-www-form-urlencoded", nil, true) then
    return ENCODED
  end
end


local function transform_querystrings(name,value)

  -- Replace querystring(s)
    local querystring = req_get_uri_args()
    if querystring[name] then
        querystring[name] = value
    end
    req_set_uri_args(querystring)
end


local function transform_url_encoded_body(name,value, body, content_length)
  local parameters = decode_args(body)
  local change=false
  if content_length > 0  then
      if parameters[name] then
        parameters[name] = value
        change=true
      end
  end
  if change then
    return true, encode_args(parameters)
  end
end

local function transform_multipart_body(name,value, body, content_length, content_type_value)
  local change=false
  local parameters = multipart(body and body or "", content_type_value)

  if content_length > 0 then
      if parameters:get(name) then
        parameters:delete(name)
        parameters:set_simple(name, value)
        change = true
      end
  end

  if  change then
    return true, parameters:tostring()
  end
end

local function transform_body(name,value)
  local content_type_value = req_get_headers()[CONTENT_TYPE]
  local content_type = get_content_type(content_type_value)
 
  -- Call req_read_body to read the request body first
  req_read_body()
  local body = req_get_body_data()
  local is_body_transformed = false
  local content_length = (body and #body) or 0

  if content_type == ENCODED then
    is_body_transformed, body = transform_url_encoded_body(name,value, body, content_length)
  elseif content_type == MULTI then
    is_body_transformed, body = transform_multipart_body(name,value, body, content_length, content_type_value)
  end

 if is_body_transformed then
    req_set_body_data(body)
    req_set_header(CONTENT_LENGTH, #body)
  end
end

function _M.execute(name,value)
  transform_body(name,value)
  transform_querystrings(name,value)
end

return _M
