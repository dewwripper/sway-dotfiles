#!/usr/bin/env bash
TERM_CMD="${1:-foot}"

win_count() {
  swaymsg -t get_tree | jq '[recurse(.nodes[], .floating_nodes[])
    | select(.type == "con" and .pid)] | length'
}

spawn_wait() {
  local before after i
  before=$(win_count)
  swaymsg exec -- "$TERM_CMD"
  for i in $(seq 100); do
    after=$(win_count)
    [ "$after" -gt "$before" ] && return 0
    sleep 0.05
  done
}

swaymsg workspace 1

spawn_wait          # left terminal
swaymsg splith
spawn_wait          # right, top
swaymsg splitv
spawn_wait          # right, bottom

swaymsg focus left
swaymsg resize set width 75 ppt