parameter body_name is "kerbin".

run once "util/util".
run once "util/orbit_util".

if (body:name <> body_name) {
    local kerbin_patch_lex to find_patch(body_name).
    warp_and_wait(kerbin_patch_lex["eta"] + 10).
    wait until body:name = body_name.
}

local target_alt is body:atm:height + 20000.

local upper_bound is eta:periapsis.
local lower_bound is 0.

until upper_bound - lower_bound < 1 {
    local midpoint is (upper_bound + lower_bound) / 2.
    local t is time:seconds + midpoint.
    local a is body:altitudeof(positionat(ship, t)).
    if (a > target_alt) {
        set lower_bound to midpoint.
    } else {
        set upper_bound to midpoint.
    }
}

warp_and_wait(upper_bound).

when altitude < body:atm:height then
    lock steering to srfretrograde.

set navmode to "surface".

local heat_shield_stage is -1.
local ablator_modules is ship:modulesnamed("ModuleAblator").

for m in ablator_modules {
    set heat_shield_stage to max(heat_shield_stage, m:part:stage).
}

log_debug("heat shield stage: " + heat_shield_stage).

when stage:number > heat_shield_stage and stage:ready and body:atm:exists and altitude < body:atm:height then {
    stage.
}

when not chutessafe then {
    chutessafe on.
    return not chutes.
}

until apoapsis < body:atm:height {
    wait until altitude > body:atm:height.
    warp_and_wait(eta:periapsis).
}

when altitude < 20 then unlock steering.

wait until status = "landed" or status = "splashed".