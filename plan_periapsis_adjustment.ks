parameter body_name.
parameter target_periapsis.

run once "util/logging".
run once "util/util".
run once "util/orbit_util".

log_message("=== adjusting periapsis to " + target_periapsis + " ===").

run "remove_all_nodes".

local target_patch_lex to find_patch(body_name).

log_debug(target_patch_lex).

local n to node(time:seconds + target_patch_lex["eta"] + 10, 0, 0, 0).
add n.

function score_node {
    parameter n.
    local target_patch_lex to find_patch(body_name, n:orbit).

    return -abs(target_patch_lex["patch"]:periapsis - target_periapsis).
}

runpath("util/optimize_node", score_node@).
