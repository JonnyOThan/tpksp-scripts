parameter radar_offset is 0.
parameter altitude_factor is 10.
parameter final_target_speed is 2.

run once "util/logging".

log_message("=== final approach ===").

lights on.

lock distance to alt:radar - radar_offset.
lock target_speed to max(distance/10, 0) + final_target_speed.
lock gravity to body:mu / body:position:sqrmagnitude.
lock max_twr to ship:availablethrust / ship:mass / gravity.

local pid is pidloop().
set pid:setpoint to -target_speed.
set pid:maxoutput to max_twr.
set pid:minoutput to 0.
local thrott is 0.
lock throttle to thrott.

sas off.
lock steering to srfretrograde.

until status="landed" or status = "splashed" {
    set pid:setpoint to -target_speed.
    set pid:maxoutput to max_twr.

    local surface_velocity is velocity:surface:mag.
    if vdot(velocity:surface, up:vector) < 0 set surface_velocity to -surface_velocity.

    local desired_twr to pid:update(time:seconds, surface_velocity).
    set thrott to desired_twr / max_twr.

    wait 0.

    clearscreen.
    print "distance:  " + round(distance, 1) at (0, 0).
    print "tgt speed: " + round(target_speed, 1) at (0, 1).
    print "max twr:   " + round(max_twr, 2) at (0, 2).
    print "des twr:   " + round(desired_twr, 2) at (0, 3).
    print "throttle:  " + round(thrott, 2) at (0, 4).
    print "velocity:  " + round(surface_velocity, 1) at (0, 5).
}

clearscreen.

log_message("Landed!!").

unlock distance.
unlock target_speed.

unlock throttle.
unlock steering.
set throttle to 0.
sas on.
lights off.
wait 3.