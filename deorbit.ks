run once "logging".
run once "util".
run once "orbit_util".

log_message("=== deorbiting ===").

local current_velocity to get_orbital_speed_at_altitude(altitude).
local n to node(time:seconds + 5 * 60, 0, 0, -current_velocity/2).
add n.
run execute_node.
