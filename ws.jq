def filter_by_app_id($filter_string):
  if type == "array" then
    .[] | 
    if type == "object" then
      select(.app_id | type == "string" and contains($filter_string))
      | { id, app_id, title, workspace_id, is_focused }
    else
      { error: "Not an object", value: . }
    end
  elif type == "object" then
    . | { error: "Root is an object, not an array", keys: keys }
  else
    { error: "Unexpected type", type: type }
  end;

def filter_by_title($filter_string):
  if type == "array" then
    .[] | 
    if type == "object" then
      select(.title | type == "string" and contains($filter_string))
      | { id, app_id, title, workspace_id, is_focused }
    else
      { error: "Not an object", value: . }
    end
  elif type == "object" then
    . | { error: "Root is an object, not an array", keys: keys }
  else
    { error: "Unexpected type", type: type }
  end;

def filter_by_app_id_or_title($app_id_filter; $title_filter):
  (filter_by_app_id($app_id_filter) + filter_by_title($title_filter)) | unique_by(.id);

# Top-level program
filter_by_app_id_or_title($app_id_filter; $title_filter)
