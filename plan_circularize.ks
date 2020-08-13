run once "util.ks".
run once "orbit_util.ks".

local h is apoapsis.
local duration_until_node is 0.

if h < 0 {
  set h to periapsis.
  set duration_until_node to eta:periapsis.
} else {
  set duration_until_node to eta:apoapsis.
}

log_message("=== circularizing at " + round(h/1000, 1) + "km ===").

run "remove_all_nodes".

local necessary_speed is get_orbital_speed_at_altitude(h, h + body:radius).
local current_speed is get_orbital_speed_at_altitude(h).
add node(time:seconds + duration_until_node, 0, 0, necessary_speed - current_speed).
