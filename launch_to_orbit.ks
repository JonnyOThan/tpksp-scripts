parameter ascent_roll is 0.
parameter hdg is 90.
parameter target_apoapsis is body:atm:height + 10000.

run once "util/logging".

local use_rcs is rcs.

if body:atm:exists
	rcs off.

run launch.
run ascent(ascent_roll, hdg, target_apoapsis).
wait until altitude > body:atm:height.
run plan_circularize.
set rcs to use_rcs.
run execute_node.
rcs off.
