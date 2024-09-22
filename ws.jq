#!/usr/bin/env -S jq -f

# Import filters and operators
include "filters";
include "operators";

# Function to move focused window to the end
def move_focused_to_end(results):
  results | 
  if any(.is_focused == true) then
    [.[] | select(.is_focused != true)] + [.[] | select(.is_focused == true)]
  else
    .
  end;

# Define arg_or_default function
def arg_or_default($arg_name; $default):
  $ARGS.named[$arg_name] // $default;


def apply_filters($app_id_filter; $title_filter; $exclude_focused; $operation; $printdebug):
  . as $input |
  (if $operation == "union" then
    union_filter(
      $input | filter_by_app_id($app_id_filter);
      $input | filter_by_title($title_filter)
    )
  elif $operation == "intersection" then
    intersection_filter(
      $input | filter_by_app_id($app_id_filter);
      $input | filter_by_title($title_filter)
    )
  elif $operation == "difference" then
    difference_filter(
      $input | filter_by_app_id($app_id_filter);
      $input | filter_by_title($title_filter)
    )
  elif $operation == "or" then
    or_filter(
      $input | filter_by_app_id($app_id_filter);
      $input | filter_by_title($title_filter)
    )
  elif $app_id_filter != "" then
    $input | filter_by_app_id($app_id_filter)
  elif $title_filter != "" then
    $input | filter_by_title($title_filter)
  else
    $input
  end) as $filtered_results |
  
  # Apply focus exclusion filter
  ($filtered_results | filter_exclude_focused($exclude_focused)) as $focus_filtered |

  # Get the focused window, if it exists in the original input
  ($input | map(select(.is_focused == true)) | first) as $focused_window |

 # Get the focused window, if it exists in the original input and we're not excluding it
  if $exclude_focused != "true" then
    ($input | map(select(.is_focused == true)) | first) as $focused_window |
    # Combine results, ensuring focused window is last if it exists
    if $focused_window then
      ($focus_filtered | map(select(.id != $focused_window.id))) + [$focused_window]
    else
      $focus_filtered
    end
  else
    $focus_filtered
  end | 
  if $printdebug == "true" then
    .
    |
    debug("Printed entire list of filtered results for debugging. Without --printdebug, only the id of the top window will be printed.") 
  else
    map(.id) |
    first
  end;


# Apply filters to the input
apply_filters(
  arg_or_default("app_id"; "");
  arg_or_default("title"; "");
  arg_or_default("exclude_focused"; "false");
  arg_or_default("operation"; "");
  arg_or_default("printdebug"; "")
)
