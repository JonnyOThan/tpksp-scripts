run once "logging".
run once "util".
run once "orbit_util".

log_message("=== plan_moon_escape ===").

run "remove_all_nodes".

local desired_reentry_pe to 35000.
local desired_kerbin_sma to (body:altitude + desired_reentry_pe + 2 * kerbin:radius)/2.
local desired_kerbin_velocity_at_escape to get_orbital_speed_at_altitude(body:altitude, desired_kerbin_sma, kerbin).
local desired_hyperbolic_excess_velocity to desired_kerbin_velocity_at_escape - body:orbit:velocity:orbit:mag.

log_debug("desired kerbin velocity at escape: " + desired_kerbin_velocity_at_escape).
log_debug("desired hev: " + desired_hyperbolic_excess_velocity).

local necessary_orbital_velocity to sqrt(desired_hyperbolic_excess_velocity^2 + 2 * body:mu / (altitude + body:radius)).
local node_dv to necessary_orbital_velocity - velocity:orbit:mag.

log_debug("necessary orbital velocity: " + necessary_orbital_velocity).
log_debug("node dv: " + node_dv).

// TODO: this assumes a circular orbit; should probably use true anomaly instead
local vec_to_ship to ship:position - body:position.
local phase_angle_to_node to mod(360 + get_phase_angle_to_position(body:position + body:orbit:velocity:orbit), 360).
local phase_angle_per_second to 360 / ship:orbit:period.
local time_until_node to phase_angle_to_node / phase_angle_per_second.

local current_speed to velocityat(ship, time:seconds + time_until_node):orbit:mag.

log_debug("phase angle to node: " + phase_angle_to_node).
log_debug("phase angle per second: " + phase_angle_per_second).

local n to node(time:seconds + time_until_node, 0, 0, node_dv).
add n.

function minimize_periapsis {
    parameter n.
    if (n:orbit:hasnextpatch and n:orbit:nextpatch:body:name="kerbin") {
        return -n:orbit:nextpatch:periapsis.
    } else {
        return -kerbin:soiradius.
    }
}

function adjust_periapsis {
    parameter n.
    return -abs(n:orbit:nextpatch:periapsis - desired_reentry_pe).
}

local velocity_offsets is list(V(0, 0, 0), V(0, 0, 0)).
local time_offsets is list(1, -1).

runpath("optimize_node", minimize_periapsis@, n, velocity_offsets, time_offsets).
runpath("optimize_node", adjust_periapsis@).