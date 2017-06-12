local function default_token_name(t)
  if not t.tokenname then
    return {"userToken"}
  end
end
return {
  no_consumer = true,
  fields = {
    tokenname= { required =true ,type="string" ,default=default_token_name},
    publickey = {required = true, type = "string", default = ""},
    privatekey={required = true,type="string" , default=""},
    magiccode ={required=true,type="string",default=""},
    version={required=true,type="string",default=""}
  
  }
}
