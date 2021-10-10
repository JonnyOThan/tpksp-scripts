parameter ascent_roll is 0.
parameter hdg is 90.
parameter target_apoapsis is body:atm:height + 10000.

run once "util/logging".

run launch.
run ascent(ascent_roll, hdg, target_apoapsis).
wait until altitude > body:atm:height.
run plan_circularize.
run execute_node.
