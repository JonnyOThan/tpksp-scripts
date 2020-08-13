parameter b.
clearscreen.
print b:name.
print "radius:":padright(20) + round(b:radius/1e3,2) + " km".
print "surface gravity:":padright(20) + round(b:mu/b:radius^2/9.81,2) + " g".
if (not b:hassolidsurface)
	print "NO SURFACE DETECTED".
if (b:atm:exists) {
	print "atm height:":padright(20) + b:atm:height/1e3 + " km".
	print "ASL pressure:":padright(20) + round(b:atm:sealevelpressure,3) + " atm".
	if (b:atm:oxygen)
		print "OXYGEN DETECTED".
}
print "rotation period:":padright(20) + round(b:rotationperiod/60/60,1) + " hours".
if b <> sun
	print "parent body:":padright(20) + b:body:name.
print "orbital period:":padright(20) + round(b:orbit:period/kerbin:orbit:period,2) + " years".
print "orbital incl:":padright(20) + b:orbit:inclination + " deg".
print "periapsis:":padright(20) + round(b:orbit:periapsis/1e6,1) + " Mm".
print "apoapsis:":padright(20) + round(b:orbit:apoapsis/1e6,1) + " Mm".
print "current speed:":padright(20) + round(velocityat(b, time:seconds):orbit:mag, 1) + " m/s".

print "anomaly scan:":padright(20) + round(addons:scansat:getcoverage(b, "anomaly"),1) + "%".
local anomalies is addons:scansat:getanomalies(b).
local found is 0.
for anomaly in anomalies if anomaly:detail set found to found + 1.
print "anomalies visited:":padright(20) + found + "/" + anomalies:length.

if not b:orbitingchildren:empty {
	print "children:".
	for c in b:orbitingchildren
		print "  " + c:name:padright(18) + round(c:altitude/1e6,1) + " Mm".
}
	

print "----------------------------------------".
print b:description.