run once "util".
run once "orbit_util".

log_message("=== planning match inclination ===").

run "remove_all_nodes".

if not hastarget {
    log_error("No target selected").
}

local inclination_info is get_inclination_info_between_orbits(ship:orbit, target:orbit).
local inclination is inclination_info["inclination"].

local angle_to_node is inclination_info["true_anomaly_delta"].

log_debug("inclination: " + inclination).
log_debug("delta true anomaly: " + angle_to_node).

local AN_true_anomaly is mod(360 + ship:orbit:trueanomaly + angle_to_node, 360).
local AN_timestamp is get_timestamp_at_true_anomaly(ship:orbit, AN_true_anomaly).
local DN_true_anomaly is mod(AN_true_anomaly + 180, 360).
local DN_timestamp is get_timestamp_at_true_anomaly(ship:orbit, DN_true_anomaly).

log_debug("time to AN: " + format_time(AN_timestamp - time:seconds)).
log_debug("time to DN: " + format_time(DN_timestamp - time:seconds)).

local AN_true_anomaly_to_AP is abs(AN_true_anomaly - 180).
local DN_true_anomaly_to_AP is abs(DN_true_anomaly - 180).

log_debug("AN true anomaly: " + AN_true_anomaly).
log_debug("DN true anomaly: " + DN_true_anomaly).
log_debug("AN true anomaly to ap: " + AN_true_anomaly_to_AP).
log_debug("DN true anomaly to ap: " + DN_true_anomaly_to_AP).

// select whichever node is closer to AP
// TODO: if there is a transition on our orbit, make sure to select a node before that
local node_timestamp is AN_timestamp.
if (DN_true_anomaly_to_AP < AN_true_anomaly_to_AP) {
    set node_timestamp to DN_timestamp.
}

log_debug("time to burn: " + format_time(node_timestamp - time:seconds)).

local n is node(node_timestamp, 0, 0, 0).
add n.

function score_plane_change {
    parameter node.

    local inclination_info is get_inclination_info_between_orbits(node:orbit, target:orbit).

    return -abs(inclination_info["inclination"]).
}

local velocity_offsets is list(V(0, 0, 1), V(0, 0, -1)).
local time_offsets is list(0, 0).

logging_push_threshold(sev_message).
runpath("optimize_node", score_plane_change@, n, velocity_offsets, time_offsets).
logging_pop_threshold().
