local function default_callback_name(t)
  if not t.callback then
    return {"callback"}
  end
end
return {
  fields = {
    callback = {required = true, type = "array", default = default_callback_name}
 
  }
}
