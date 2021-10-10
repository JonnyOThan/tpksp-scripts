parameter tail_factor is 0.2.

run once "util/logging".
run once "util/util".
run once "util/stage_utils".

log_message("=== execute_node ===").

if not sas or sasmode <> "maneuver" {
	sas off.
	lock steering to nextnode:deltav.
}

local vessel_stage_info is get_vessel_stage_info().

if get_total_ship_dv(vessel_stage_info) < nextnode:deltav:mag {
    log_warning("*** vessel does not appear to have enough dv for this maneuver ***").
}

// note: this is "duration for half the burn dv", not "half the duration of the full burn"
log_debug("-- half burn duration --").
local half_burn_duration is get_fancy_burn_duration(nextnode:deltav:mag/2, vessel_stage_info).

wait until vang(ship:facing:vector, nextnode:deltav) < 0.5.

warp_and_wait(nextnode:eta - half_burn_duration - 5 - 60).

if not sas or sasmode <> "maneuver" {
	sas off.
	lock steering to nextnode:deltav.
}

wait until vang(ship:facing:vector, nextnode:deltav) < 0.5.

local time_to_burn_start is nextnode:eta - half_burn_duration.

if (time_to_burn_start < -5) {
    log_error("PASSED BURN START TIME!").
}

warp_and_wait(time_to_burn_start).

set initial_node_direction to nextnode:deltav.

if tail_factor > 0 {
    function get_throttle {
        local result is 0.
        if (ship:maxthrust>0) {
            set result to min(1, nextnode:deltav:mag / (tail_factor * ship:maxthrust / ship:mass)).
        }
        return result.
    }
    lock throttle to get_throttle().
} else {
    lock throttle to 1.
}

local old_thrust is ship:maxthrust.
until vang(initial_node_direction, nextnode:deltav) > 90 or nextnode:deltav:mag < 0.001 {
    if ship:maxthrust < old_thrust {
        log_message("stage expired during node execution; remaining dv: " + round(nextnode:deltav:mag, 1)).
        stage_to_next_engine().
	set old_thrust to ship:maxthrust.
    }
    wait 0.
}

sas off.
lock steering to "kill".

lock throttle to 0.
unlock throttle.
wait 1.
remove nextnode.
wait 0.

local function get_fancy_burn_duration {
    parameter burn_dv.
    parameter vessel_stage_info.

    local stage_number is stage:number.
    local result is 0.

    log_debug("calculating burn duration for " + round(burn_dv, 1) + " m/s dv").

    until burn_dv <= 0.001 or stage_number < 0 {
        local stage_info is vessel_stage_info[stage_number].
        
        local dv_from_this_stage is min(burn_dv, stage_info:dv).
        
        if (dv_from_this_stage > 0) {
            set burn_dv to burn_dv - dv_from_this_stage.

            local final_stage_mass is stage_info:totalmass / (constant:e ^ (dv_from_this_stage / constant:g0 / stage_info:isp)).
            local fuel_mass_burned is stage_info:totalmass - final_stage_mass.
            local stage_burn_time is fuel_mass_burned / get_mass_flow_rate(stage_info:engines).

            log_debug("stage: " + stage_number).
            log_debug("stage dv: " + round(dv_from_this_stage)).
            log_debug("remaining burn dv: " + round(burn_dv)).
            log_debug("thrust: " + round(stage_info:thrust, 1)).
            log_debug("burn time: " + format_time(stage_burn_time)).

            set result to result + stage_burn_time.
        }

        set stage_number to stage_number - 1.
    }

    return result.
}

local function get_total_ship_dv {
    parameter vessel_stage_info.

    local result is 0.

    for stage_info in vessel_stage_info
        set result to result + stage_info:dv.

    return result.
}
