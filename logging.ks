parameter print_severity is 0.

set sev_debug to 0. // detailed info used for debugging
set sev_message to 1. // human-readable info about the state of the rocket
set sev_warning to 2. // something weird happened, but it's probably not fatal
set sev_error to 3. // something terrible happened and the script cannot continue

set severity_stack to list(print_severity).

function logging_get_threshold {
    return severity_stack[severity_stack:length - 1].
}

function logging_push_threshold {
    parameter threshold.
    severity_stack:add(threshold).
}

function logging_pop_threshold {
    severity_stack:remove(severity_stack:length - 1).
}

function log_event {
    parameter text.
    parameter severity.

    if severity >= logging_get_threshold() {
        print text.
    }
}

function log_debug {
    parameter text.
    log_event(text, sev_debug).
}

function log_message {
    parameter text.
    log_event(text, sev_message).
}

function log_warning {
    parameter text.
    log_event(text, sev_warning).
}

function log_error {
    parameter text.
    log_event(text, sev_error).

    set x to 0/0. // janky way to crash the program
}