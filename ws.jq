def filter_by_app_id:

if type == "array" then
    .[] | 
    if type == "object" then
      select(.app_id | type == "string" and contains("aicha"))
      | { id, app_id, is_focused: (.is_focused | type) }
    else
      { error: "Not an object", value: . }
    end
  elif type == "object" then
    . | { error: "Root is an object, not an array", keys: keys }
  else
    { error: "Unexpected type", type: type }
  end
