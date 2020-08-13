parameter desired_roll is 0.
parameter desired_heading is 90.
parameter target_apoapsis is body:atm:height + 10000.
parameter turn_target_altitude is target_apoapsis + 20000. // slightly higher than target AP
parameter throttle_down_altitude is target_apoapsis - 20000.

run once "logging.ks".
run once "util.ks".

log_message("=== ascent ===").

lock throttle to 1.
sas off.

function turn {
    parameter target_altitude is turn_target_altitude.
    parameter exponent is 0.5.
    lock steering to heading(desired_heading, max(0, 90*(1-(apoapsis/target_altitude)^exponent))) * R(0, 0, desired_roll).
}

turn().

local old_thrust is ship:maxthrustat(0).

local tanks_by_stage to list().
from { local i to 0. } until i = stage:number+1 step {set i to i+1.} do {
    tanks_by_stage:add(list()).
}

local all_parts to list().
list parts in all_parts.
for p in all_parts {
    if (p:stage >= 0) {
        for r in p:resources {
            if (r:name = "liquidfuel" and r:enabled and r:amount > 0) {
                tanks_by_stage[p:stage]:add(p).
                break.
            }
        }
    }
}

// log_debug(tanks_by_stage).

lock gravity to body:mu/(altitude+body:radius)^2.
lock twr to (ship:availablethrust / ship:mass / gravity).

when apoapsis > throttle_down_altitude and twr > 1 then lock throttle to 0.5.

until apoapsis > target_apoapsis {
    local should_stage is false.

    if ship:maxthrustat(0) < old_thrust {
        set should_stage to true.
    }

    if stage:number > 1 and not tanks_by_stage[stage:number-1]:empty {
        local fuel_in_stage is 0.
        for t in tanks_by_stage[stage:number-1] {
            for r in t:resources {
                if r:name = "liquidfuel" {
                    set fuel_in_stage to fuel_in_stage + r:amount.
                    break.
                }
            }
        }
        if (fuel_in_stage < 0.001) {
            log_message("empty fuel tank detected.").
            set should_stage to true.
        }
    }

    if should_stage {
        if (body:atm:exists and body:atm:altitudepressure(altitude) > 0.01) {
            lock steering to srfprograde * R(0, 0, desired_roll).
            log_message("turning prograde for staging").
            local start_stage_time to time:seconds.
            wait until vang(ship:facing:vector, srfprograde:vector) < 1 or time:seconds - start_stage_time > 5.
        }
        stage_to_next_engine().
        set old_thrust to ship:maxthrustat(0).
        wait 1.
        log_message("resuming turn").
        turn().
    }
    wait 0.5.
}

// TODO: fairings

lock steering to velocityat(ship, time:seconds + eta:apoapsis):orbit.

lock throttle to 0.
wait 0.

log_message("coasting to exit atmosphere").

wait until altitude > body:atm:height.