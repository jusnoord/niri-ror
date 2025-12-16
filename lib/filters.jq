#!/usr/bin/env jq -f

def filter_by_app_id($filter_string):
  if type == "array" then
    map(
      select(.app_id | type == "string" and endswith($filter_string))
      | { id, app_id, title, workspace_id, is_focused }
    )
  elif type == "object" then
    [{ error: "Root is an object, not an array", keys: keys }]
  else
    [{ error: "Unexpected type", type: type }]
  end;

def filter_by_title($filter_string):
  if type == "array" then
    map(
      select(.title | type == "string" and contains($filter_string))
      | { id, app_id, title, workspace_id, is_focused }
    )
  elif type == "object" then
    [{ error: "Root is an object, not an array", keys: keys }]
  else
    [{ error: "Unexpected type", type: type }]
  end;

def filter_exclude_focused($exclude_focused):
  if type == "array" then
    if $exclude_focused == "true" then
      map(select(.is_focused != true))
    else
      .  # If $exclude_focused is not "true", return all results
    end
  elif type == "object" then
    [{ error: "Root is an object, not an array", keys: keys }]
  else
    [{ error: "Unexpected type", type: type }]
  end;
