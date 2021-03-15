parameter ascent_roll is 0.
parameter hdg is 90.

run once "logging".

run launch.
run ascent(ascent_roll, hdg).
wait until altitude > body:atm:height.
run plan_circularize.
run execute_node.
