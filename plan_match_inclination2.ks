parameter mode is 'phase'.

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
local lock rs to positionat(ship,node_timestamp)-body:position.
local lock vs to velocityat(ship,node_timestamp):obt.
local lock rt to positionat(target,node_timestamp)-body:position.
local lock vt to velocityat(target,node_timestamp):obt.
local lock ns to vcrs(vs,rs):normalized.
local lock nt to vcrs(vt,rt):normalized.

local dv is v(0,0,0).

if mode='match_phase' {
    local v_tangential is vcrs(rs,ns):normalized * vs.
    local v_radial is rs:normalized * vs.
    set dv to v_radial * rs:normalized + v_tangential * vcrs(rs,nt):normalized - vs.
}
else if mode='mindv' {
    set dv to vxcl(nt, vs)-vs.
}
else if mode='direction_and_speed' {
    set dv to vxcl(nt, vs):normalized * vs:mag - vs.
}
else
{
    log_error("Unknown argument. Known modes are: match_phase, mindv, direction_and_speed. Default is match_phase.").
}

function nodeset {parameter nd. parameter x. set nd:radialout to x:x. set nd:normal to x:y. set nd:prograde to x:z. wait 0.} function nodeget {parameter nd. return v(nd:radialout,nd:normal,nd:prograde).} function nodedelta {parameter nd. parameter d. nodeset(nd,nodeget(nd)+d).}
function rebase {parameter vv. parameter nd. local bkup is nodeget(nd).  nodeset(nd, v(1,0,0)). local vr is nd:deltav*vv. nodeset(nd,v(0,1,0)). local vn is nd:deltav*vv. nodeset(nd,v(0,0,1)). local vp is nd:deltav*vv.  nodeset(nd,bkup). return v(vr,vn,vp).} 

local ndv is rebase(dv,n).
nodeset(n, ndv).
