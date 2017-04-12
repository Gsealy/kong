local function default_sign_name(t)
  if not t.signname then
    return {"sign"}
  end
end
return {
  no_consumer = true,
  fields = {

    signname = {required = true, type = "string", default = default_sign_name},
    prefix={type="string" , default=""},
    after ={type="string",default=""},
    itemsplit={type="string",default=""},
    pairsplit={type="string",default=""}
  }
}
