run once "util/logging".
run once "util/util".
run once "util/orbit_util".

log_message("=== finish orbit ===").

local engines is get_active_engines().
list engines in all_engines.

if (engines_are_vacuum(engines) or engines:length = all_engines:length) {
    log_message("finishing orbit with this stage").
    run plan_circularize.
    run execute_node.
} else {
    local booster_separation_pe is get_maximum_periapsis_for_destruction().

    local booster_sep_sma is (apoapsis + booster_separation_pe + body:radius*2) / 2.
    local speed_for_booster_sep is get_orbital_speed_at_altitude(apoapsis, booster_sep_sma).

    local speed_for_orbit is get_orbital_speed_at_altitude(apoapsis, apoapsis + body:radius).

    local speed_at_ap is get_orbital_speed_at_altitude(apoapsis).

    local fuel_mass_in_stage is get_fuel_mass_of_current_stage().
    local isp is get_combined_isp(engines).
    local dv_of_stage is isp * constant:g0 * ln(ship:mass / (ship:mass - fuel_mass_in_stage)).

    local dv_to_booster_sep is speed_for_booster_sep - speed_at_ap.

    if (dv_of_stage < dv_to_booster_sep) {
        log_message("booster will expire before maximum_pe - finishing orbit with one node").
        run plan_circularize.
        run execute_node.
    } else {
        local dv_for_sep is min(dv_to_booster_sep, dv_of_stage).
        local speed_after_sep is speed_at_ap + dv_for_sep.
        local dv_for_orbit is speed_for_orbit - speed_after_sep.

        log_debug("speed at ap:     " + speed_at_ap).
        log_debug("speed for sep:   " + speed_for_booster_sep).
        log_debug("speed for orbit: " + speed_for_orbit).
        log_debug("dv of stage:     " + dv_of_stage).
        log_debug("dv for sep:      " + dv_for_sep).
        log_debug("dv for orbit:    " + dv_for_orbit).

        // magic number: if the dv remaining in the booster could get us
        // to a significant chunk of a mun transfer, keep the booster around
        // even though it's going to become space trash
        local wasted_booster_dv is dv_of_stage - dv_for_sep - dv_for_orbit.
        if (wasted_booster_dv > 500) {
            log_message("keeping booster because it has " + round(wasted_booster_dv) + " dv remaining").
            run plan_circularize.
            run execute_node.
        } else {
            log_message("dropping booster early - leaving " + round(dv_of_stage - dv_for_sep, 1) + " dV behind").

            // TODO: need to figure out the total burn time for both burns, and start the first one earlier

            local apoapsis_time is time:seconds + eta:apoapsis.
            add node(apoapsis_time, 0, 0, dv_for_sep).
            run execute_node(0).
            log_debug("executing second half of circularization").
            stage_to_next_engine().
            add node(time:seconds, 0, 0, dv_for_orbit).
            run execute_node.
        }
    }
}
