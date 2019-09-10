PRINT "airplane steering setup.".
set steeringmanager:pitchtorquefactor to 0.2.
set steeringmanager:yawtorquefactor to 0.5.
set steeringmanager:rollcontrolanglerange to 180.
steeringmanager:resetpids().
