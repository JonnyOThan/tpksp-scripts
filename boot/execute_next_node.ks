wait until ship:loaded and ship:unpacked.

run once "util/logging".

if hasnode {
    log_message("=== boot file: execute_next_node ===").

    run execute_node.
}
