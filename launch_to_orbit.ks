parameter ascent_roll is 0.
parameter hdg is 90.

run once "logging".

run launch.
run ascent(ascent_roll, hdg).
set warp to 4.
wait until altitude > body:atm:height.
set warp to 0.
run plan_circularize.
run execute_node.
