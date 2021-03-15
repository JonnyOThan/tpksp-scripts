run once "util/logging".
run once "util/util".
run once "util/orbit_util".

log_message("=== deorbiting ===").

local current_velocity to get_orbital_speed_at_altitude(altitude).
add node(time:seconds + 5 * 60, 0, 0, -current_velocity/2).
run execute_node.
