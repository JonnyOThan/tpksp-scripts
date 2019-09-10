wait until ship:loaded and ship:unpacked.

run once "logging".

if hasnode {
    log_message("=== boot file: execute_all_nodes ===").

    until not hasnode {
        run execute_node.
    }
}
