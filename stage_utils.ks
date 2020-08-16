@lazyglobal off.

run once "logging".
run once "util".

// possiblethrust / possiblethrustat will work for engines that are not yet active, also takes thrust limiter into account
// ispat works for inactive engines, but isp does not
// part:stage seems to be the stage that the engine/decoupler will activate in, or the stage that the part will be decoupled in
// engine:consumedresources:values[0]:maxmassflow can indicate massflow for inactive engines

// returns a list of stageinfo
// each stageinfo is a lexicon containing the following keys:
//   tanks: a list of parts that contain fuel
//   engines: a list of the engine parts that will be active in this stage
//   resources: a list of resources in this stage
//   resourceslex: a lexicon of resources in this stage
//   mass: the stage's current mass
//   totalmass: the mass of the entire rocket including this stage (but not later stages)
//   fuelmass: the mass of the fuel in this stage
//   thrust: the thrust of the engines in this stage
//   isp: the isp at the current pressure 
//   dv: available dv at current pressure
//   burntime: available burntime at max throttle
function get_vessel_stage_info {
    parameter result is list().
    result:clear().

    for i in range(stage:number+1) result:add(lexicon(
        "parts", list(),
        "tanks", list(),
        "engines", list(),
        "resources", list(),
        "resourceslex", lexicon(),
        "mass", 0,
        "totalmass", 0,
        "fuelmass", 0,
        "thrust", 0,
        "isp", 0,
        "dv", 0,
        "burntime", 0
    )).

    // NOTE: this only really works correctly for asparagus setups or ships with a 1:1 stage:engine mapping
    // it assumes the fuel tanks for each stage will be full when that stage activates
    // which will not be true in e.g. a sustainer engine + SRB setup
    // need to attribute some fuel mass from later stages down into earlier ones

    local engines is list().
    list engines in engines.

    for engine in engines {
        // add the engine properties to all the stages from where it activates to where it decouples
        // if it's already active then put it in the current stage instead of the stage where it would normally activate
        local last_stage_index is (choose stage:number if engine:ignition else engine:stage).
        for stage_index in range(get_part_stage(engine), last_stage_index+1) {
            local stage_info is result[stage_index].
            stage_info:engines:add(engine).
            set stage_info:thrust to stage_info:thrust + engine:possiblethrust.
        }
    }

    for part in ship:parts {
        local stage_info is result[get_part_stage(part)].
        add_part_to_stage_info(part, stage_info).
    }

    finalize_vessel_stage_info(result).

    return result.
}

local function add_part_to_stage_info {
    parameter part.
    parameter stage_info.

    stage_info:parts:add(part).

    set stage_info:mass to stage_info:mass + part:mass.

    local part_is_tank is false.

    for resource in part:resources {
        if (resource:enabled) {
            // TODO: consider if the engines actually burn this fuel, and which resource is the limiting factor
            // the engine's consumedresources is buggy because it uses displayname
            set stage_info:fuelmass to stage_info:fuelmass + resource:amount * resource:density.

            if resource:density > 0 {
                set part_is_tank to true.
            }
        }
    }

    if (part_is_tank) {
        stage_info:tanks:add(part).
    }
}

local function finalize_vessel_stage_info {
    parameter vessel_stage_info.

    for stage_index in range(vessel_stage_info:length) {
        local stage_info is vessel_stage_info[stage_index].

        set stage_info:totalmass to stage_info:mass + (choose 0 if stage_index = 0 else vessel_stage_info[stage_index-1]:totalmass).
        set stage_info:isp to get_combined_isp(stage_info:engines).
        // NOTE: this is only correct if the engines are associated with a single stage
        if (stage_info:fuelmass > 0 and stage_info:engines:length) {
            local drymass is stage_info:totalmass - stage_info:fuelmass.
            set stage_info:dv to stage_info:isp * constant:g0 * ln(stage_info:totalmass / drymass).
            set stage_info:burntime to stage_info:fuelmass / get_mass_flow_rate(stage_info:engines).
        }
    }
}

local function get_part_stage {
    parameter part.
    // NOTE: this ignores directionality of the decoupler and assumes it does not stay with the ship
    if part:istype("launchclamp") or part:istype("decoupler") return part:stage+1.
    return part:decoupledin+1.
}