run once "logging".
run once "util".
run once "orbit_util".

log_message("=== plan_moon_intercept === ").

run "remove_all_nodes".

local average_speed to get_average_orbital_speed().

local transfer_sma to (ship:orbit:semimajoraxis + target:orbit:semimajoraxis) / 2.
local transfer_speed to get_orbital_speed_at_altitude(altitude, transfer_sma).
local transfer_dv to transfer_speed - average_speed.
local transfer_half_period to get_orbit_period(transfer_sma) / 2.
local transfer_phase_angle to 180 - 360 * transfer_half_period / target:orbit:period.

log_debug("avg vel: " + average_speed).
log_debug("transfer vel: " + transfer_speed).
log_debug("transfer dv: " + transfer_dv).
log_debug("transfer T/2: " + transfer_half_period).
log_debug("transfer phase angle: " + transfer_phase_angle).
log_debug("current phase: " + get_phase_angle_to(target)).

local angle_to_wait to mod(get_phase_angle_to(target) - transfer_phase_angle + 360, 360).
local phase_change_per_second to 360 / target:orbit:period - 360 / ship:orbit:period.
local time_to_node to angle_to_wait / -phase_change_per_second.

log_debug("angle to wait: " + angle_to_wait).
log_debug("phase deg/s: " + phase_change_per_second).
log_debug("time to node: " + format_time(time_to_node)).

set node to node(time:seconds + time_to_node, 0, 0, transfer_dv).
add node.

function score_distance_to_target {
    parameter node.

    local apoapsis_timestamp is get_timestamp_at_mean_anomaly(node:orbit, 180).
    local future_ship_position is positionat(ship, apoapsis_timestamp).
    local future_target_position is positionat(target, apoapsis_timestamp).
    local distance is (future_ship_position - future_target_position):mag.
    
    if (node:orbit:hasnextpatch and node:orbit:nextpatch:body = target) {
        // found an intercept, yay
        return 100.
    }

    return -distance.
}

function score_apoapsis_height {
    parameter node.
    local apoapsis_timestamp is get_timestamp_at_mean_anomaly(node:orbit, 180).
    local future_target_position is positionat(target, apoapsis_timestamp).
    local future_target_altitude is (future_target_position - node:orbit:body:position):mag - node:orbit:body:radius.

    if (node:orbit:hasnextpatch and node:orbit:nextpatch:body = target) {
        // found an intercept, yay
        return 100.
    }

    return -abs(node:orbit:apoapsis - future_target_altitude).
}

local prograde_offsets is list(V(1, 0, 0), V(-1, 0, 0)).
local null_time_offsets is list(0, 0).

logging_push_threshold(sev_message).

// optimize the prograde burn on the node to match the apoapsis to the target's altitude exactly.
runpath("optimize_node", score_apoapsis_height@, node, prograde_offsets, null_time_offsets).

// if we still don't have an intercept, try to optimize further
if (not node:orbit:hasnextpatch or node:orbit:nextpatch:body = target) {
    runpath("optimize_node", score_distance_to_target@).
}

logging_pop_threshold().