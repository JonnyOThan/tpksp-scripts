parameter bootfile.

if ship:status = "PRELAUNCH" {

    // note: explicitly running from the archive
    runoncepath("archive:/logging").

    core:doevent("open terminal").
    set terminal:charheight to 12.

    if bootfile = "" {
        log_error("no boot file specified!").
    }

    if not exists("archive:/boot/" + bootfile) {
        log_error("could not find boot script named " + bootfile).
    }

    if (config:arch = false) {
        log_message("deploying code...").
        copypath("archive:/", "1:/").
    }

    local new_bootfilename is "/boot/" + bootfile.
    if (core:bootfilename <> new_bootfilename) {
        set core:bootfilename to new_bootfilename.
        log_message("updated bootfile to " + core:bootfilename).
        log_message("rebooting in 3 seconds...").
        wait 3.
        reboot.
    }
}