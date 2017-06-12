local function default_token_name(t)
  if not t.tokenname then
    return {"transport-security-token"}
  end
end
return {
  no_consumer = true,
  fields = {
    tokenname= { required =true ,type="string" ,default=default_token_name}
  
  }
}
