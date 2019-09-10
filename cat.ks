parameter target_path.
if exists(target_path) {
	set contents to open(target_path):readall().
	for line in contents {
		print line.
	}
}
else
{
	print "Path " + target_path + " does not exist.".
}
