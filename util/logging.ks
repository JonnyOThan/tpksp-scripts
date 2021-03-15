parameter print_severity is 0.

global sev_debug is 0. // detailed info used for debugging
global sev_message is 1. // human-readable info about the state of the rocket
global sev_warning is 2. // something weird happened, but it's probably not fatal
global sev_error is 3. // something terrible happened and the script cannot continue

local severity_stack is list(print_severity).

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

    print 0/0. // janky way to crash the program
}