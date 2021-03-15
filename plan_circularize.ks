parameter m_which is "".
parameter m_orbit is ship:orbit.

run once "util/util".
run once "util/orbit_util".
run once "util/logging".

if (m_orbit:hasnextpatch and m_which <> "pe") {
  if (m_which <> "") log_warning("specified orbit is not closed; circularizing at PE instead").
  set m_which to "pe".
} else if (m_which = "") {
  set m_which to "next".
}

if (m_which <> "ap" and m_which <> "pe" and m_which <> "next") {
  log_error("first parameter must be one of 'pe', 'ap', or 'next'").
}

// this works for future hyperbolic orbits since meananomalyatepoch should be negative
local pe_timestamp is m_orbit:epoch - (m_orbit:meananomalyatepoch*constant:degtorad / sqrt(m_orbit:body:mu / abs(m_orbit:semimajoraxis)^3)).

// if this is an elliptical patch in the future, need to make sure that the calculated PE is after the epoch
if (m_orbit:epoch > time:seconds and m_orbit:semimajoraxis > 0) {
    set pe_timestamp to pe_timestamp + m_orbit:period.
}

// and if the periapsis is in the past, bring it forward
if time:seconds > pe_timestamp {
    set pe_timestamp to time:seconds + m_orbit:period - mod(time:seconds - pe_timestamp, m_orbit:period).
}

local time_until_next_pe is pe_timestamp - time:seconds.
local orbit_period is get_orbit_period(m_orbit:semimajoraxis, m_orbit:body).

log_debug("orbit period: " + format_time(orbit_period)).

// select the next closest AP
local time_until_next_ap is time_until_next_pe - orbit_period / 2.

// unless it's before the epoch..
if (time:seconds + time_until_next_ap < m_orbit:epoch) {
    set time_until_next_ap to time_until_next_ap + orbit_period.
}

log_debug("time until next pe: " + format_time(time_until_next_pe)).
log_debug("time until next ap: " + format_time(time_until_next_ap)).

if (m_which = "next") set m_which to choose "pe" if time_until_next_pe < time_until_next_ap else "ap".

local node_timestamp is time:seconds + (choose time_until_next_pe if m_which = "pe" else time_until_next_ap).
local sma_at_node is m_orbit:semimajoraxis * (choose (1 - m_orbit:eccentricity) if m_which = "pe" else (1 + m_orbit:eccentricity)).

log_debug("sma at node: " + sma_at_node).

local altitude_at_node is sma_at_node - m_orbit:body:radius.

log_message("=== circularizing at " + round(altitude_at_node/1000, 1) + "km ===").

local necessary_speed is get_orbital_speed_at_altitude(altitude_at_node, sma_at_node, m_orbit:body).
local current_speed is get_orbital_speed_at_altitude(altitude_at_node, m_orbit:semimajoraxis, m_orbit:body).
add node(node_timestamp, 0, 0, necessary_speed - current_speed).
