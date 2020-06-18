parameter ship_orbit is ship:orbit.
parameter mode is "match_phase".

run once "util".

log_message("=== planning match inclination ===").

if not hastarget {
    log_error("No target selected").
}

if (ship_orbit:body <> target:obt:body) {
    log_error("Selected orbital patch and target orbit do not share a common body.").
}
if(ship_orbit:eccentricity >= 1) {
    log_error("Cannot match inclination for open orbits.").
}
local b is ship_orbit:body.
local t is ship_orbit:epoch.
local epoch_pos is (positionat(ship,t)-b:position):normalized.
local nrm_ship is vcrs(velocityat(ship, t):obt,positionat(ship,t)-b:position):normalized.
local nrm_trgt is vcrs(velocityat(target, t):obt,positionat(target,t)-b:position):normalized.
local vec_to_AN is vcrs(nrm_ship,nrm_trgt):normalized.

local function newton {
    parameter f, fp, x0.
    local x is x0.
    for i in range(10) {
        local err is f(x).
        local deriv is fp(x).
        set x to x - err/deriv.
    }
    return x.
}

local mean_anomaly_rad is ship_orbit:meananomalyatepoch * constant:DegToRad.
local eccentricity is ship_orbit:eccentricity.
local epoch_eccentric_anomaly is newton(
    {parameter e. return e-eccentricity*sin(e*constant:RadToDeg)-mean_anomaly_rad.},
    {parameter e. return 1-eccentricity*cos(e*constant:RadToDeg).},
    mean_anomaly_rad)*constant:RadToDeg.
local epoch_true_anomaly is mod(360+arctan2(sqrt(1-eccentricity^2)*sin(epoch_eccentric_anomaly), cos(epoch_eccentric_anomaly)-eccentricity),360).
local function sign{parameter x. return choose -1 if x < 0 else 1.}
local angle_to_an is vang(vec_to_AN,epoch_pos)*sign(vcrs(vec_to_AN,epoch_pos)*nrm_ship).
local AN_true_anomaly is mod(360+epoch_true_anomaly+angle_to_an,360).
local DN_true_anomaly is mod(AN_true_anomaly+180,360).
local inclination is vang(nrm_ship,nrm_trgt).

log_debug("inclination: " + inclination).
log_debug("delta true anomaly: " + angle_to_an).

local AN_eccentric_anomaly is arctan2(sqrt(1-eccentricity^2)*sin(AN_true_anomaly), eccentricity+cos(AN_true_anomaly)).
local AN_mean_anomaly is AN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(AN_eccentric_anomaly).
local AN_timestamp is mod(360+AN_mean_anomaly-ship_orbit:meananomalyatepoch,360)/sqrt(b:mu/ship_orbit:semimajoraxis^3)/constant:RadToDeg + ship_orbit:epoch.
local DN_eccentric_anomaly is arctan2(sqrt(1-eccentricity^2)*sin(DN_true_anomaly), eccentricity+cos(DN_true_anomaly)).
local DN_mean_anomaly is DN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(DN_eccentric_anomaly).
local DN_timestamp is mod(360+DN_mean_anomaly-ship_orbit:meananomalyatepoch,360)/sqrt(b:mu/ship_orbit:semimajoraxis^3)/constant:RadToDeg + ship_orbit:epoch.

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
local rs is positionat(ship,node_timestamp)-b:position.
local vs is velocityat(ship,node_timestamp):obt.
local rt is positionat(target,node_timestamp)-b:position.
local vt is velocityat(target,node_timestamp):obt.
local ns is vcrs(vs,rs):normalized.
local nt is vcrs(vt,rt):normalized.

local dv is v(0,0,0).

if mode="match_phase" {
    local v_tangential is vcrs(rs,ns):normalized * vs.
    local v_radial is rs:normalized * vs.
    set dv to v_radial * rs:normalized + v_tangential * vcrs(rs,nt):normalized - vs.
}
else if mode="mindv" {
    set dv to vxcl(nt, vs)-vs.
}
else if mode="direction_and_speed" {
    set dv to vxcl(nt, vs):normalized * vs:mag - vs.
}
else
{
    log_error("Unknown argument. Known modes are: match_phase, mindv, direction_and_speed. Default is match_phase.").
}

local function nodeset {parameter nd. parameter x. set nd:radialout to x:x. set nd:normal to x:y. set nd:prograde to x:z. wait 0.}
local function nodeget {parameter nd. return v(nd:radialout,nd:normal,nd:prograde).}
local function nodedelta {parameter nd. parameter d. nodeset(nd,nodeget(nd)+d).}
local function rebase {parameter vv. parameter nd. local bkup is nodeget(nd).  nodeset(nd, v(1,0,0)). local vr is nd:deltav*vv. nodeset(nd,v(0,1,0)). local vn is nd:deltav*vv. nodeset(nd,v(0,0,1)). local vp is nd:deltav*vv.  nodeset(nd,bkup). return v(vr,vn,vp).} 

local ndv is rebase(dv,n).
nodeset(n, ndv).
