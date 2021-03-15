run once "util".

function target_distance_at_time
{
	parameter t.
	return (positionat(ship, t) - positionat(target, t)):mag.
}

function closeApproach
{
	local step_length is orbit:period / 20. 
	local test_time is time:seconds.
	local best_time is test_time.
	local best_dist is target:distance.
	
	until test_time > time:seconds + orbit:period {
		local newdist is target_distance_at_time(test_time).

		if (newdist < best_dist)
		{
			set best_dist to newdist.
			set best_time to test_time.
		}

		set test_time to test_time + step_length.
	}

	log_debug("initial guess: " + format_time(best_time - time:seconds) + " " + round(best_dist)).

	local mint is best_time - step_length.
	local maxt is best_time + step_length.
	local mind is target_distance_at_time(mint).
	local maxd is target_distance_at_time(maxt).

	local steps is 0.

	until maxt - mint < 1 {
		local test_time is (mint + maxt) / 2.
		local newdist is target_distance_at_time(maxt).

		if (mind < maxd) {
			set maxd to newdist.
			set maxt to test_time.
		} else {
			set mind to newdist.
			set mint to test_time.
		}

		set steps to steps + 1.
	}

	log_debug("took " + steps + " steps").

	return target_distance_at_time((mint + maxt) / 2).
}

global result is closeApproach().