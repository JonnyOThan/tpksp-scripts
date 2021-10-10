parameter destination is target.
parameter user_options is lexicon().

local options is lexicon(
	"create_maneuver_nodes", "both",
	"verbose", true,
	"cleanup_maneuver_nodes", false).

if destination:istype("body") {
	set options["final_orbit_periapsis"] to destination:atm:height + 10000.
}

for key in user_options:keys
	set options[key] to user_options[key].

runoncepath("rsvp/main").

print rsvp:goto(destination, options).
