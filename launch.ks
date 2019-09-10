parameter countdown is 3.

run once "logging".
run once "util.ks".

log_message("=== launch ===").

local v0 is getvoice(0).

from {local i is countdown.} until i = 0 step { set i to i-1.} do {
    log_message(i).
    v0:play(note("f4", 0.1, 0.5)).
    wait 1.
}

log_message("0").
v0:play(note("c5", 0.3, 0.5)).

sas on.

lock throttle to 1.
stage.

local clamps to ship:modulesnamed("LaunchClamp").
for clamp in clamps {
    if clamp:part:stage = stage:number-1 {
        wait until stage:ready.
        stage.
        break.
    }
}

wait until velocity:surface:mag > 50.

sas off.