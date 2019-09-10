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

until time:seconds > starttime + t
{
	local a is adj[rand(adj:length)].
	local o is obj[rand(obj:length)].
	local p is ship:parts[rand(ship:parts:length)].
	local c is colors[rand(colors:length)].
	local vd is vecdraw(p:position, v(0,0,0), c, a + " " + o, random()*2 + 0.5, true, 1.0, true, true).
	wait random()*3 + 1.5.
	set vd:show to false.
}