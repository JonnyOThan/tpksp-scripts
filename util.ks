run once "logging".

lock normal to vcrs(ship:velocity:orbit, -body:position).
lock radialin to vcrs(ship:velocity:orbit, normal).

function get_active_engines {
  list engines in all_engines.
  set result to list().
  for e in all_engines
    if (e:ignition and not e:flameout) result:add(e).
  return result.
}

function get_burn_duration {
  parameter deltav.

  local engines to get_active_engines().
  local isp to get_combined_isp(engines).
  local final_mass to ship:mass / (constant:e ^ (deltav / constant:g0 / isp)).
  local fuel_mass_remaining to get_fuel_mass_of_current_stage().
  local burn_duration to (ship:mass - final_mass) / get_mass_flow_rate(engines).
  log_debug("isp: " + isp).
  log_debug("current mass: " + round(ship:mass, 2)).
  log_debug("final mass: " + round(final_mass, 2)).
  log_debug("delta mass: " + round(ship:mass - final_mass, 2)).
  log_debug("fuel remaining: " + round(fuel_mass_remaining, 2)).
  log_debug("mass flow rate: " + get_mass_flow_rate(engines)).
  log_debug("burn time: " + round(burn_duration, 2)).

  return burn_duration.
}

function get_with_default {
  parameter lex.
  parameter key.
  parameter default is 0.
  set result to default.
  if lex:haskey(key) set result to lex[key].
  return result.
}

function get_fuel_mass_of_current_stage {
  // WARNING: stage:resourceslex can be wrong!
  set liquid_fuel to get_with_default(stage:resourceslex, "liquidfuel", 0):amount.
  set oxidizer to get_with_default(stage:resourceslex, "oxidizer", 0):amount.
  set density_t_per_L to 5/1000.
  return density_t_per_L * (liquid_fuel + oxidizer).
}

function get_combined_isp {
  parameter engines.
  set numerator to 0.
  for e in engines {
    set numerator to numerator + e:availablethrust.
  }
  set mass_flow_rate to get_mass_flow_rate(engines).
  if mass_flow_rate > 0 
    return numerator / mass_flow_rate / constant:g0.
  return 0.
}

function engines_are_vacuum {
  parameter engines.
  local result to true.
  for e in engines {
    if (e:ispat(0) / e:ispat(1) < 2) {
      set result to false.
    }
  }
  return result.
}

function get_mass_flow_rate {
  parameter engines.
  set result to 0.
  for e in engines
    set result to result + e:possiblethrustat(0) / (e:ispat(0) * constant:g0).
  return result.
}

function warp_and_wait {
  parameter duration.
  if duration < 0 return.
  log_message("waiting for " + format_time(duration)).
  if duration > 10 {
    kuniverse:timewarp:cancelwarp().
    kuniverse:timewarp:warpto(time:seconds + duration - 5).
  }
  wait duration.
  set warp to 0.
}

function stage_to_next_engine {
  stage.
  until ship:maxthrustat(0) > 0 {
    wait until stage:ready.
    stage.
  }
  wait 0.
}

function format_time {
  parameter t.
  local h to floor(t/60/60).
  local m to mod(floor(t/60), 60).
  local s to mod(t, 60).
  return h + "h" + m + "m" + round(s, 2).
}

function get_maximum_periapsis_for_destruction {
    parameter b is body.
    
    if b:atm:exists {
        local upper_bound to b:atm:height.
        local lower_bound to 0.
        until upper_bound - lower_bound < 1000 {
            local midpoint to (upper_bound + lower_bound) / 2.
            local pressure to b:atm:altitudepressure(midpoint).
            if pressure > 0.01 {
                set lower_bound to midpoint.
            } else {
                set upper_bound to midpoint.
            }
        }
        return lower_bound.
    } else {
        return 0.
    }
}
