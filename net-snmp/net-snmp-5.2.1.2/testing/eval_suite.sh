#!/bin/sh
#
# eval_suite.sh [-h][<args_passed_to_getresults>]
#
# CALLS: eval_oneprogram.sh [-h][-lk] <program>
#
# RETURNS:	Number of failed tests, regardless of how that failure occured
#		or how many failures there were in a given test.
#
#


								USAGE_LONG='
#
# HOW TO ENTER A NEW TEST
#
# To add a test to the testlist, add a line to the TESTLISTFILE (eval_testlist)
# using the following format:
#
#	<#_of_expected_successes> [#]<program> <args>
#
# Any white space may be used as separator.  If <program> is immediately
# preceeded by a pound sign (#) that test will be skipped.  (No white space
# allowed after the pound.  Eg, "#<program>".)
#
#
# HOW TESTS ARE RUN AND EVALUATED
#
# The harness for individual tests is the script "eval_oneprogram.sh".
# It expects that the test print FAILED when something fails, and SUCCESS
# when something succeeds.  If a test executes properly there should be
# some SUCCESS strings and NO FAILED strings.  If the reason for the
# success or failure of the test should be printed on the SAME line as the
# SUCCESS/FAILED string to allow the dianostic to be easilly grepped from
# the its output.
#
# The long form of the output (-l flag) will capture that output which may
# help to diagnosis the problem.  For more information:
#
#	% eval_oneprogram.sh -h
#
# 
# MISSING TESTS ARE NOTED
#
# If an executable is found MISSING, a note is printed to that effect
# and TESTFAILURE is incremented by 1.
#
'

#
# Suggested improvement(s):
#	Have two (or more?) arbitrary script(s) that may be associated
#	with a given test.  One could prepare the environment, the other
#	could clean up the environment after running the test.  This could
#	help when testing large subsystems that might require legitimately
#	building or changing things such that the testable item may be 
#	accessed in the first place (eg). ...
#


#------------------------------------ -o- 
# Usage mess.  (No, it works.)
#
USAGE="Usage: `basename $0` [-h][<args_for_getresults>]"

usage() { echo; echo $USAGE; cat <<BLIK | sed 's/^#//' | sed '1d' | $PAGER
$USAGE_LONG
BLIK
exit 0
}

[ "x$1" = "x-h" ] && usage



#------------------------------------ -o- 
# Globals.
#
PROGRAM=
ARGUMENTS="$*"

TMPFILE=/tmp/eval_suite.sh$$

TESTLISTFILE=eval_testlist

EXPECTEDSUCCESSES=
TESTFAILURE=0

testname=

success_count=
failed_count=

#
# TESTLISTFILE format:
#  	<expected_successes>	<program> <arg(s)> ...
#  	<expected_successes>	<program> <arg(s)> ...
#	...
#
TESTLIST="`cat $TESTLISTFILE | sed 's/$/   ===/'`"





#------------------------------------ -o- 
# Run all tests in the testlist.  For each test do the following:
#
#	1) Note whether the test is SKIPPED or MISSING.
#
#	2) Run the test; collect the number of FAILED strings from the
#		return value of eval_oneprogram.sh.
#
#	3) Count the number of SUCCESSes from the test output.
#
#	4) Print the results.  If there were no FAILED strings *and* the
#		number of SUCCESS strings is what we expect, simply
#		note that the test passed.  Otherwise, cat the output
#		generated by eval_oneprogram.sh and (possibly)
#		print other details.
#
set x $TESTLIST
shift

while [ -n "$1" ] ; do
	#
	# Parse agument stream...
	#
	EXPECTEDSUCCESSES=$1
	shift

	PROGRAM=
	while [ "$1" != "===" ] ; do { PROGRAM="$PROGRAM $1" ; shift ; } done
	shift

	testname="`echo $PROGRAM | grep '^#' | sed 's/^#//'`"

	echo '+==================================-o-===+'
	echo



	#
	# Decide whether to skip the test, if it's mising, else run it.
	#
	[ -n "$testname" ] && {					# Skip the test?
		echo "SKIPPING test for \"$testname\"."
		echo
		continue
	}
	[ ! -e "`echo $PROGRAM | awk '{ print $1 }'`" ] && {	# Missing test?
		TESTFAILURE=`expr $TESTFAILURE + 1`

		echo "MISSING test for \"$PROGRAM\"."
		echo
		continue
	}

	echo "TESTING \"$PROGRAM\"..."				# Announce test!



	#
	# Run the test and collect the failed_count and success_count.
	#
	eval_oneprogram.sh $ARGUMENTS $PROGRAM >$TMPFILE
	failed_count=$?

	success_count=`awk '$(NF-1) == "SUCCESS:" { print $NF; exit }' $TMPFILE`
	[ -z "$success_count" ] && success_count=0


	
	#
	# Output best-effort results of the test  -OR-  a fully successful run.
	#
	[ "$failed_count" -eq 0 -a \
			"$success_count" -eq "$EXPECTEDSUCCESSES" ] &&
	{
		echo
		echo $PROGRAM PASSED		# Successful, fully, completed
		echo
		
		true
	} || {
		TESTFAILURE=`expr $TESTFAILURE + 1`

		echo
		cat $TMPFILE
		echo

		[ "$success_count" -ne $EXPECTEDSUCCESSES ] && {
			echo "Got $success_count SUCCESSes"\
						"out of $EXPECTEDSUCCESSES."
			echo
		}
		true
	}  # end -- evaluation of and output based upon test success.
done  # endwhile




#------------------------------------ -o- 
# Cleanup, exit.
#
rm -f $TMPFILE

exit $TESTFAILURE



