parameter ship_orbit is ship:orbit.
parameter node_selector is "highest".
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

local function sign{parameter x. return choose -1 if x < 0 else 1.}
local function newton {
    parameter f, fp, x0.
    local x is x0.
    local err is f(x).
    local steps is 0.
    until abs(err)< 1e-12 or steps > 20 {
        local deriv is fp(x).
        local step is err/deriv.
        // only allow a maximum change of half a radian at a time to prevent small derivatives from throwing off the
        // stability of the algorithm.
        if abs(step) > 0.5 set step to 0.5 * sign(step).
        set x to x - step.
        set steps to steps+1.
        set err to f(x).
    }
    log_debug("Calculated eccentric anomaly gives a mean anomaly error of " + err + " in " + steps + " step" +
    (choose "." if steps=0 else "s.")).
    return x.
}

local mean_anomaly_rad is ship_orbit:meananomalyatepoch * constant:DegToRad.
local eccentricity is ship_orbit:eccentricity.
local epoch_eccentric_anomaly is newton(
    {parameter e. return e-eccentricity*sin(e*constant:RadToDeg)-mean_anomaly_rad.},
    {parameter e. return 1-eccentricity*cos(e*constant:RadToDeg).},
    mean_anomaly_rad)*constant:RadToDeg.
local epoch_true_anomaly is mod(360+arctan2(sqrt(1-eccentricity^2)*sin(epoch_eccentric_anomaly), cos(epoch_eccentric_anomaly)-eccentricity),360).
local angle_to_an is vang(vec_to_AN,epoch_pos)*sign(vcrs(vec_to_AN,epoch_pos)*nrm_ship).
local AN_true_anomaly is mod(360+epoch_true_anomaly+angle_to_an,360).
local DN_true_anomaly is mod(AN_true_anomaly+180,360).
local inclination is vang(nrm_ship,nrm_trgt).

log_debug("inclination: " + inclination).
log_debug("delta true anomaly: " + angle_to_an).

local base_time is ship_orbit:epoch.
local base_meananomaly is ship_orbit:meananomalyatepoch.
if(ship_orbit:epoch < time:seconds)
{
    set base_time to time:seconds.
    set base_meananomaly to mod(mod(base_time-ship_orbit:epoch, ship_orbit:period)/ship_orbit:period*360+ship_orbit:meananomalyatepoch,360).
}

local AN_eccentric_anomaly is arctan2(sqrt(1-eccentricity^2)*sin(AN_true_anomaly), eccentricity+cos(AN_true_anomaly)).
local AN_mean_anomaly is AN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(AN_eccentric_anomaly).
local AN_timestamp is mod(360+AN_mean_anomaly-base_meananomaly,360)/sqrt(b:mu/ship_orbit:semimajoraxis^3)/constant:RadToDeg + base_time.
local DN_eccentric_anomaly is arctan2(sqrt(1-eccentricity^2)*sin(DN_true_anomaly), eccentricity+cos(DN_true_anomaly)).
local DN_mean_anomaly is DN_eccentric_anomaly-eccentricity*constant:RadToDeg*sin(DN_eccentric_anomaly).
local DN_timestamp is mod(360+DN_mean_anomaly-base_meananomaly,360)/sqrt(b:mu/ship_orbit:semimajoraxis^3)/constant:RadToDeg + base_time.

log_debug("time to AN: " + format_time(AN_timestamp - time:seconds)).
log_debug("time to DN: " + format_time(DN_timestamp - time:seconds)).

local AN_true_anomaly_to_AP is abs(AN_true_anomaly - 180).
local DN_true_anomaly_to_AP is abs(DN_true_anomaly - 180).

log_debug("AN true anomaly: " + AN_true_anomaly).
log_debug("DN true anomaly: " + DN_true_anomaly).
log_debug("AN true anomaly to ap: " + AN_true_anomaly_to_AP).
log_debug("DN true anomaly to ap: " + DN_true_anomaly_to_AP).

local node_timestamp is 0.
if(node_selector="highest") {
    set node_timestamp to choose AN_timestamp if AN_true_anomaly_to_AP < DN_true_anomaly_to_AP else DN_timestamp.
}
else if(node_selector="lowest") {
    set node_timestamp to choose AN_timestamp if AN_true_anomaly_to_AP > DN_true_anomaly_to_AP else DN_timestamp.
}
else if(node_selector="AN") {set node_timestamp to AN_timestamp.}
else if(node_selector="DN") {set node_timestamp to DN_timestamp.}
else if(node_selector="first") {
    set node_timestamp to choose AN_timestamp if AN_timestamp < DN_timestamp else DN_timestamp.
}
else if(node_selector="last") {
    set node_timestamp to choose AN_timestamp if AN_timestamp > DN_timestamp else DN_timestamp.
}
else log_error("Invalid node selector. Valid selectors are AN, DN, highest, lowest, first, and last.").

if(ship_orbit:transition <> "FINAL")
{
    set t_transition to ship_orbit:nextpatcheta + time:seconds.
    if(t_transition < node_timestamp)
    {
        local other_timestamp is choose AN_timestamp if node_timestamp=DN_timestamp else DN_timestamp.
        if(other_timestamp < node_timestamp)
        {
            log_error("No node exists before the end of the orbital patch.").
        }
        else
        {
            log_debug("Orbital patch ends before chosen node! Selecting other node.").
            set node_timestamp to other_timestamp.
        }
    }
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
local function rebase {
    parameter vv.
    parameter nd.
    local bkup is nodeget(nd).
    nodeset(nd, v(0,0,0)).
    local t is time:seconds+nd:eta.
    local prograde is velocityat(ship, t):obt:normalized.
    local normal is vcrs(prograde,positionat(ship,t)-nd:obt:body:position):normalized.
    local radialout is vcrs(normal, prograde).
    nodeset(nd, bkup).
    return v(vv*radialout,vv*normal,vv*prograde).
} 

local ndv is rebase(dv,n).
nodeset(n, ndv).
