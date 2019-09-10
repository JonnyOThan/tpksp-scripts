run once "util.ks".
run once "orbit_util.ks".

set h to apoapsis.

if h < 0 {
  set h to periapsis.
  set duration_until_node to eta:periapsis.
} else {
  set duration_until_node to eta:apoapsis.
}

log_message("=== circularizing at " + round(h/1000, 1) + "km ===").

run "remove_all_nodes".

set necessary_speed to get_orbital_speed_at_altitude(h, h + body:radius).
set current_speed to get_orbital_speed_at_altitude(h).
set n to node(time:seconds + duration_until_node, 0, 0, necessary_speed - current_speed).
add n.