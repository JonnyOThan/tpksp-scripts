parameter tail_factor is 0.2.

run once "logging.ks".
run once "util.ks".

log_message("=== execute_node ===").

if not sas or sasmode <> "maneuver" {
	sas off.
	lock steering to nextnode:deltav.
}

local burn_duration to get_burn_duration(nextnode:deltav:mag).

wait until vang(ship:facing:vector, nextnode:deltav) < 0.5.

warp_and_wait(nextnode:eta - burn_duration/2 - 60).

wait until vang(ship:facing:vector, nextnode:deltav) < 0.5.

local time_to_burn_start is nextnode:eta - burn_duration/2.

if (time_to_burn_start < -5) {
    log_error("PASSED BURN START TIME!").
}

warp_and_wait(time_to_burn_start).

local initial_node_direction is nextnode:deltav.

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

until vang(initial_node_direction, nextnode:deltav) > 90 or nextnode:deltav:mag < 0.001 {
    if ship:maxthrust = 0 {
        log_message("stage expired during node execution; remaining dv: " + round(nextnode:deltav:mag, 1)).
        stage_to_next_engine().
    }
    wait 0.
}

sas off.
lock steering to "kill".

lock throttle to 0.
wait 0.
unlock throttle.
wait 1.
remove nextnode.
wait 0.
