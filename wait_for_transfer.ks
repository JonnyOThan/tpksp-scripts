parameter tgt is target.

run "util/util".

// a more complex script might look for ancestors of the target
// (e.g. if the target is Ike and we are in LKO)
// but let's not worry about that for now.
local target_ancestor is tgt:body.
// the orbitable that is an ancestor of the ship, and a sibling of the target
// e.g. for a transfer from LKO to mun, this is the ship.
// for a transfer from LKO to duna, this is kerbin
local target_sibling is ship.
local common_ancestor is body.

until common_ancestor = target_ancestor {
    set target_sibling to common_ancestor.
    set common_ancestor to common_ancestor:body.
}

log_debug("target_sibling: " + target_sibling:name).
log_debug("common ancestor: " + common_ancestor:name).

local sibling_vector is target_sibling:position - common_ancestor:position.
local target_vector is target_ancestor:position - common_ancestor:position.

log_debug("phase angle: " + vang(sibling_vector, target_vector)).
