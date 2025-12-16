#!/usr/bin/env -S jq -f

# Import filters and operators
include "filters";
include "operators";

# Move focused window to the end of the list
# if it exists in the list. For cycling.
def move_focused_to_end(results):
  results | 
  if any(.is_focused == true) then
    [.[] | select(.is_focused != true)] + [.[] | select(.is_focused == true)]
  else
    .
  end;

# Helper to stop the complaining 
def default_arg($arg_name; $default):
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
  
  # sort them by id in ascending order for the focus cycling
  ($filtered_results | sort_by(.id)) as $sorted_results |

  # Apply focus exclusion filter
  ($sorted_results | filter_exclude_focused($exclude_focused)) as $focus_filtered |

  # Get the focused window, if it exists in the original input
  ($input | map(select(.is_focused == true)) | first) as $focused_window |

 # Find the focused window in the filtered results
  ($focus_filtered | map(select(.is_focused == true)) | first) as $focused_window |
  if $focused_window != null then
    # Get the ID of the focused window
    ($focused_window.id) as $focused_id |
    # Find the next largest ID, or the smallest if at the end
    ($focus_filtered | map(.id) | sort | unique) as $sorted_ids |
    ($sorted_ids | index($focused_id) + 1) as $next_index |
    if $next_index < ($sorted_ids | length) then
      $sorted_ids[$next_index]
    else
      $sorted_ids[0]
    end
  else
    # If no focused window in filtered results, return the first ID
    $focus_filtered[0].id
  end |
  if $printdebug == "true" then
    $focus_filtered
    |
    debug("Printing entire list of filtered results for debugging. Without --printdebug, only the id of the top window will be printed.") 
  end;


# Apply filters to the input
apply_filters(
  default_arg("app_id"; "");
  default_arg("title"; "");
  default_arg("exclude_focused"; "false");
  default_arg("operation"; "");
  default_arg("printdebug"; "")
)
