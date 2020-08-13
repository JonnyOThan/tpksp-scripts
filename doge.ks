parameter t is 10.

set t to min(t, 60).

local adj is list(
	"wow",
	"such",
	"many",
	"much",
	"very",
	"how to",
	"so",
	"nice",
	"omg",
	"why this",
	"plz",
	"my",
	"lol",
	"100%",
	"the missile knows",
	"i can haz"
).

local obj is list(
	"thrust",
	"twr",
	"Q",
	"periapsis",
	"speed",
	"velocity",
	"apoapsis",
	"mass",
	"gravitational constant",
	"vis viva",
	"newton",
	"kepler",
	"monoprop",
	"dv",
	"G",
	"mu",
	"stage",
	"booster",
	"abort",
	"tsiolkovsky",
	"snacks",
	"turbopump",
	"scrub",
	"aerobrake",
	"debris",
	"parachute",
	"antenna",
	"docking",
	"ssto",
	"probe",
	"kessler syndrome"
).

local colors is list(
	red,
	green,
	blue,
	yellow,
	cyan,
	magenta,
	white
).

local starttime is time:seconds.

function rand
{
	parameter n.
	return min(floor(random() * n), n-1).
}

function shuffle
{
	// deck with 4 elements: max i value is 2
	parameter deck.
	for i in range(deck:length-1)
	{
		local j is rand(deck:length - i). // need a value from i to deck:length-1
		local temp is deck[i].
		set deck[i] to deck[j].
		set deck[j] to temp.
	}	
}

local a is adj:length.
local o is obj:length.
local c is colors:length.

until time:seconds > starttime + t
{
	if a = adj:length { set a to 0. shuffle(adj). }
	if o = obj:length { set o to 0. shuffle(obj). }
	if c = colors:length { set c to 0. shuffle(colors). }

	local p is ship:parts[rand(ship:parts:length)].
	local vd is vecdraw(p:position, v(0,0,0), colors[c], adj[a] + " " + obj[o], random()*2 + 0.5, true, 1.0, true, true).
	wait random()*3 + 1.5.
	set vd:show to false.

	set a to a + 1.
	set o to o + 1.
	set c to c + 1.
}