parameter ascent_roll is 0.

wait until ship:loaded and ship:unpacked.

if (ship:status = "PRELAUNCH") {
    runpath("archive:/deploy", path(scriptpath()):name).
}

run once "logging"(1).

local mission_phases is list(
    {
        print "Please select a target".
        wait until hastarget and target:body = body.
    },
    { run launch. },
    { run ascent(ascent_roll). },
    { run finish_orbit. },
    { run plan_match_inclination.
      run execute_node. },
    { run plan_moon_intercept.
      run execute_node. },
    { run plan_periapsis_adjustment(target:name, 15000).
      run execute_node. },
    { run plan_circularize.
      run execute_node. },
    { run deorbit. },
    { run landing2. },
    { run ascent. },
    { run finish_orbit. },
    { run plan_moon_escape.
      run execute_node. },
    { run reenter. }
).

run mission(mission_phases).