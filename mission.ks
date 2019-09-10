parameter phases.

run once "util".
run once "logging".

local persistence_file is "1:/persistence.json".

local phase_index is 0.
local persistence is lex().

function populate_persistence {
    set persistence["phase_index"] to phase_index.

    if hastarget {
        set persistence["target_name"] to target:name.
    } else {
        set persistence["target_name"] to "".
    }
}

if (exists(persistence_file)) {
    set persistence to readjson(persistence_file).

    set phase_index to persistence["phase_index"].
    set target to persistence["target_name"].
}

until phase_index = phases.length {
    log_debug("=== beginning phase " + phase_index + " ===").
    phases[phase_index]().
    set phase_index to phase_index + 1.
    populate_persistence().
    writejson(persistence, persistence_file).
}
