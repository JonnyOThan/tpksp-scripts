run once "logging".

function get_orbital_speed_at_altitude {
  parameter a. // altitude
  parameter sma is ship:orbit:semimajoraxis.
  parameter b is body.
  return sqrt(b:mu * (2/(a + b:radius) - 1/sma)).
}

function get_average_orbital_speed {
  parameter sma is ship:orbit:semimajoraxis.
  parameter b is body.
  
  return sqrt(b:mu/sma).
}

function get_average_orbital_speed_of {
  parameter obj is ship.
  return get_average_orbitable_speed(obj:orbit:semimajoraxis, obj:body).
}

function get_orbit_period {
  parameter sma is ship:orbit:semimajoraxis.
  parameter b is body.

  return 2 * constant:pi * sqrt(sma^3 / b:mu).
}

function get_orbit_period_of {
  parameter obj is ship.
  return get_orbit_period(obj:orbit:semimajoraxis, obj:body).
}

function get_phase_angle_to_position {
  parameter position.

  local ship_vec is ship:position - body:position.
  local target_vec is position - body:position.
  local angle is vang(ship_vec, target_vec).
  local cross is vcrs(ship_vec, target_vec).
  if (cross:y > 0) set angle to -angle.
  return angle.
}

function get_phase_angle_to {
  parameter tgt is target.
  return get_phase_angle_to_position(tgt:position).
}

function mean_anomaly_from_true_anomaly {
    parameter e, a. // eccentricity, true anomaly
    local eccentric_anomaly is 2 * arctan(((1+e)/(1-e))^(-1/2) * tan(a/2)).
    local mean_anomaly_radians is eccentric_anomaly / 180 * constant:pi - e * sin(eccentric_anomaly).
    return mod(360 + mean_anomaly_radians * (180 / constant:pi), 360).
}

function true_anomaly_from_mean_anomaly {
    parameter e, M. // eccentricity, mean anomaly
    return M + (2*e - 1/4 * e^3) * sin(M) + 5/4 * e^2 * sin(2*M) + 13/12 * e^3 * sin(3*M).
}

function get_mean_anomaly_at_time {
    parameter o, t.
    return mod(o:meananomalyatepoch + 360/o:period * (t - o:epoch), 360).
}

function get_current_mean_anomaly {
    parameter o. // orbit
    return get_mean_anomaly_at_time(o, time:seconds).
}

// returns a lex with keys:
// inclination - the signed angle between the two orbits
// vector_to_AN - a vector from the body center to the ascending node
// true_anomaly_delta - how far ahead of the 'a' object (or behind if negative) the ascending node is
function get_inclination_info_between_orbits {
    parameter orbit_a, orbit_b.

    if (orbit_a:body <> orbit_b:body) {
        log_error("cannot compare inclination between orbits " + orbit_a:name + " and " + orbit_b:name + 
            " because they are around different bodies: " + orbit_a:body:name + " and " + orbit_b:body:name).
    }

    local vector_to_a is orbit_a:position - orbit_a:body:position.
    local normal_a is vcrs(orbit_a:velocity:orbit, vector_to_a).
    local normal_b is vcrs(orbit_b:velocity:orbit, orbit_b:position - orbit_b:body:position).
    local vector_to_AN is vcrs(normal_a, normal_b).
    
    local true_anomaly_delta is vang(vector_to_a, vector_to_AN).

    local sign_test is vcrs(vector_to_AN, vector_to_a).
    if (vdot(sign_test, normal_a) < 0) {
        set true_anomaly_delta to -true_anomaly_delta.
    }

    return lex(list(
        "inclination", vang(normal_a, normal_b),
        "vector_to_AN", vector_to_AN,
        "true_anomaly_delta", true_anomaly_delta)).
}

function find_patch {
    parameter body_name.
    parameter orbit is ship:orbit.

    local patch is orbit.
    local eta is 0.
    until patch:body:name = body_name {
        if (patch:hasnextpatch) {
            set eta to patch:nextpatcheta.
            set patch to patch:nextpatch.
        } else {
            log_error(body_name + " NOT FOUND ON FLIGHT PATH!").
            break.
        }
    }

    local result to lexicon("patch", patch, "eta", eta).
    return result.
}

// returns the time at which the given orbit will be at the given mean anomaly
function get_timestamp_at_mean_anomaly {
    parameter orbit, mean_anomaly.
    local current_mean_anomaly is get_current_mean_anomaly(orbit).
    local delta_mean_anomaly is mod(360 + mean_anomaly - current_mean_anomaly, 360).
    local delta_time is delta_mean_anomaly / 360 * orbit:period.
    return time:seconds + delta_time.
}

// returns the time at which the given orbitable will be at the given true anomaly
function get_timestamp_at_true_anomaly {
    parameter orbit, true_anomaly.
    local mean_anomaly is mean_anomaly_from_true_anomaly(orbit:eccentricity, true_anomaly).
    return get_timestamp_at_mean_anomaly(orbit, mean_anomaly).
}

