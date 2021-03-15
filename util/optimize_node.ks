parameter score_function.
parameter node is nextnode.

parameter velocity_offsets is list(
    V(1, 0, 0), V(0, 1, 0), V(0, 0, 1), V(0, 0, 0),
    V(-1, 0, 0), V(0, -1, 0), V(0, 0, -1), V(0, 0, 0)).
parameter time_offsets is list(0, 0, 0, 1, 0, 0, 0, -1).

run once "logging".

local current_score is score_function(node).
local current_velocity is V(node:prograde, node:radialout, node:normal).
local current_node_timestamp is time:seconds + node:eta.
log_debug("initial score: " + current_score).

local total_iterations to 0.
local total_steps to 0.

function set_node {
    parameter v, timestamp.
    set node:prograde to v:x.
    set node:radialout to v:y.
    set node:normal to v:z.
    set node:eta to timestamp - time:seconds.
}

function evaluate_offset {
    parameter velocity_offset.
    parameter time_offset.
    set_node(current_velocity + velocity_offset, max(current_node_timestamp + time_offset, time:seconds)).
    local score to score_function(node).
    local score_delta to score-current_score.
    log_debug("offset: " + velocity_offset + ", " + time_offset + "; score delta: " + score_delta).
    return score_delta.
}

function do_optimization_iteration {
    local weighted_velocity_offset is V(0,0,0).
    local weighted_time_offset is 0.
    local weight is 0.

    set total_iterations to total_iterations + 1.

    from {local i is 0.} until i = velocity_offsets:length step {set i to i+1.} do {
        local velocity_offset is velocity_offsets[i].
        local time_offset is time_offsets[i].
        local score_delta is evaluate_offset(velocity_offset, time_offset).

        if score_delta > 0 {
            set weighted_velocity_offset to weighted_velocity_offset + score_delta * velocity_offset.
            set weighted_time_offset to weighted_time_offset + score_delta * time_offset.
            set weight to weight + score_delta.
        }
    }

    local result is false.

    if (weight > 0) {
        set weighted_velocity_offset to weighted_velocity_offset / weight.
        set weighted_time_offset to weighted_time_offset / weight.

        log_debug("output offset: " + weighted_velocity_offset + " " + weighted_time_offset).

        local step_size is 1.

        until false {
            set total_steps to total_steps + 1.
            local new_velocity is current_velocity + weighted_velocity_offset * step_size.
            local new_timestamp is current_node_timestamp + weighted_time_offset * step_size.
            set_node(new_velocity, new_timestamp).
            local new_score is score_function(node).
            if (new_score < current_score) {
                set_node(current_velocity, current_node_timestamp).
                break.
            } else {
                set current_velocity to new_velocity.
                set current_node_timestamp to new_timestamp.
                set current_score to new_score.
                set step_size to step_size * 2.
            }

            wait 0.
        }
        
        log_debug("new score: " + score_function(node)).
        set result to true.
    }

    return result.
}

wait 0.

until not do_optimization_iteration() {}

log_message("total iterations: " + total_iterations).
log_message("total steps: " + total_steps).