parameter countdown is 3.

run once "util/logging".
run once "util/util".

log_message("=== launch ===").

local v0 is getvoice(0).

from {local i is countdown.} until i = 0 step { set i to i-1.} do {
    log_message(i).
    v0:play(note("f4", 0.1, 0.5)).
    wait 1.
}

log_message("0").
v0:play(note("c5", 0.3, 0.5)).

unlock steering.
sas on.

lock throttle to 1.

if ship:status = "prelaunch" {
	stage.
}

until ship:modulesnamed("LaunchClamp"):empty and ship:modulesnamed("ModuleRestockLaunchClamp"):empty {
        wait until stage:ready.
        stage.
	wait 0.
}

wait until velocity:surface:mag > 50.

sas off.