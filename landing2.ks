run once "logging".
run once "util".

log_message("=== landing ===").

SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
sas off.
lock steering to srfretrograde.
set navmode to "surface".
gear on.
brakes on.

if (periapsis > 0) {
    log_error("cannot run landing program if you're still in orbit").
}

local leg_modules to ship:modulesnamed("ModuleWheelBase").
local control_part_offset to vdot(ship:controlpart:position, ship:facing:vector).

local lowest_leg_offset to control_part_offset.

for leg in leg_modules {
    local leg_length is 1. // silly assumption
    local leg_offset to vdot(leg:part:position, ship:facing:vector) - leg_length.
    set lowest_leg_offset to min(lowest_leg_offset, leg_offset).
}

log_debug("control part is " + round(control_part_offset,2) + "m above center of mass").
log_debug("leg offset is " + round(-lowest_leg_offset,2) + "m below center of mass").

local radar_offset to control_part_offset - lowest_leg_offset.

function get_predicted_impact_time {
    local impact_time_lower_bound is time:seconds.
    local impact_time_upper_bound is time:seconds + eta:periapsis.

    until impact_time_upper_bound-impact_time_lower_bound < 0.1 {
        local midpoint is (impact_time_lower_bound+impact_time_upper_bound)/2.
        local impact_geoposition is get_geoposition_of_ship_at_time(midpoint).
        local future_position is positionat(ship, midpoint).
        local future_altitude is (future_position - body:position):mag - body:radius.
        local future_radar_altitude is future_altitude - impact_geoposition:terrainheight + lowest_leg_offset.

        //log_debug("t: " + format_time(midpoint) + "; ralt: " + round(future_radar_altitude, 1)).

        if (future_radar_altitude < 0) {
            set impact_time_upper_bound to midpoint.
        } else {
            set impact_time_lower_bound to midpoint.
        }
    }

    return impact_time_lower_bound.
}

// gets the geoposition underneath the ship at some future time
// this accounts for the rotation of the body
function get_geoposition_of_ship_at_time {
    parameter timestamp.
    local ship_position is positionat(ship, timestamp).
    local terrain_spot is body:geopositionof(ship_position).
    local delta_time to timestamp - time:seconds.
    return latlng(terrain_spot:lat, terrain_spot:lng - delta_time * 360 / body:rotationperiod).
}

// returns energy of the ship relative to the impact location minus distance to the impact location times thrust
function get_energy_delta {
    parameter sample_timestamp.
    parameter impact_timestamp.
    parameter ship_throttle is 1.

    local impact_position is positionat(ship, impact_timestamp).
    local impact_geoposition to get_geoposition_of_ship_at_time(impact_timestamp).
    local terrain_spot_now to body:geopositionof(impact_position).

    local velocity_at_start is velocityat(ship, sample_timestamp):orbit.
    local velocity_of_landing_point is terrain_spot_now:altitudevelocity(impact_geoposition:terrainheight):orbit.
    local speed is (velocity_at_start - velocity_of_landing_point):mag.
    
    local start_position is positionat(ship, sample_timestamp).
    local start_radius is (start_position - body:position):mag.
    local initial_potential_energy is -body:mu * ship:mass / start_radius.
    local impact_potential_energy is -body:mu * ship:mass / (impact_geoposition:terrainheight + body:radius).
    local potential_energy is initial_potential_energy - impact_potential_energy.

    local ship_energy is 0.5 * ship:mass * speed^2 + potential_energy.

    // should this be the distance to the impact location NOW or the spot in the future??
    local distance_to_impact is (impact_position - start_position):mag.

    local work_done_by_engines is distance_to_impact * ship:availablethrust * ship_throttle.

    //log_debug("t: " + format_time(sample_timestamp - time:seconds) + "; speed: " + round(speed, 1) + " start alt: " + round(start_radius-body:radius,1)). 
    //log_debug("ship energy: " + round(ship_energy/1000, 1) + " engine work: " + round(work_done_by_engines/1000, 1)).
    //log_debug("impact distance: " + round(distance_to_impact, 1)).

    return ship_energy - work_done_by_engines.
}

function estimate_burn_start_time {
    parameter impact_time.
    parameter ship_throttle is 1.

    local lower_bound to time:seconds.
    local upper_bound to impact_time.

    until (upper_bound - lower_bound < 1) {
        local midpoint is (lower_bound + upper_bound) / 2.
        local energy_delta is get_energy_delta(midpoint, impact_time, ship_throttle).
        if (energy_delta < 0) {
            set lower_bound to midpoint.
        } else {
            set upper_bound to midpoint.
        }
    }

    return lower_bound.
}

local impact_time is get_predicted_impact_time().
local burn_start_time to estimate_burn_start_time(impact_time, 0.9).

log_message("impact in " + format_time(impact_time - time:seconds)).
log_message("burn start in " + format_time(burn_start_time - time:seconds)).

local debug_arrows_enabled to logging_get_threshold() <= sev_debug.

local initial_impact_geoposition to get_geoposition_of_ship_at_time(impact_time).
local vinitial to vecdraw(V(0,0,0), V(0,0,0), RGB(0,0,1), "", 100, debug_arrows_enabled, 1).
set vinitial:startupdater to { return initial_impact_geoposition:position + up:vector * 20 * vinitial:scale. }.
set vinitial:vecupdater to { return -up:vector * 20. }.

warp_and_wait(burn_start_time - time:seconds).

local vgood to vecdraw(V(0,0,0), V(0,0,0), RGB(0,1,0), "", 100, debug_arrows_enabled, 1).
set vgood:startupdater to { return get_geoposition_of_ship_at_time(impact_time):position + up:vector * 20 * vgood:scale. }.
set vgood:vecupdater to { return -up:vector * 20. }.

set pid to pidloop().

set pid:setpoint to 2.
set pid:kp to 0.2.
//set pid:ki to 0.05.
//set pid:kd to 0.05.

set pid:maxoutput to 1.
set pid:minoutput to 0.
local thrott to 1.
lock throttle to thrott.

lock steering to srfretrograde.

local altitude_speed_factor to 10.
local final_target_speed to 2.

until velocity:surface:mag < (alt:radar - radar_offset) / altitude_speed_factor + final_target_speed {
    set impact_time to get_predicted_impact_time().
    local energy_delta to get_energy_delta(time:seconds, impact_time, thrott)/1000.
    
    local distance_to_impact to positionat(ship, impact_time):mag.

    set vinitial:scale to max(distance_to_impact/100, 0.1).
    set vgood:scale to max(distance_to_impact/100, 0.1).

    local de_ratio to -energy_delta*100/distance_to_impact.

    //set thrott to pid:update(time:seconds, de_ratio).

    log_debug("impact: " + format_time(impact_time-time:seconds) + "; dist: " + round(distance_to_impact,1) + "; dEnergy: " + round(energy_delta,1) + "; th: " + round(thrott, 2) + "; de_ratio: " + round(de_ratio, 2)).

    //if (distance_to_impact < 1000) {
        //set thrott to pid:update(time:seconds, de_ratio).
    //}

    //set pid:setpoint to -target_speed.
    //set thrott to pid:update(time:seconds, -velocity:surface:mag).
    //log_debug("throt: " + round(thrott, 2) + "; vel: " + round(velocity:surface:mag, 1) + "; dist: " + round(distance, 1)).
    wait 0.
}

set vgood:show to false.
set vinitial:show to false.

run landing_final(radar_offset, altitude_speed_factor, final_target_speed).