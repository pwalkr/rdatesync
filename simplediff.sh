#!/bin/bash

# Simple diff: compare two directories and report new/modified/removed for any
# differences.
#
# modified files are determined by comparing the inode of each
#
# retults will be placed in the new directory.
#

DIR_OLD="$(cd "$1"; pwd)";
DIR_NEW="$(cd "$2"; pwd)";
RESULTS_NAME="changes"
RESULTS_TMP="/tmp/sd.sh.tmp"
RESULTS_FILE="$DIR_NEW/$RESULTS_NAME"

if [ ! -d "$1" -o ! -d "$2" ]; then
	echo "Usage:"
	echo "    $0 old_dir new_dir"
	echo
	echo "This will create file <new_dir>/$RESULTS_NAME containing a sorted"
	echo "list of file differences:"
	echo "    <old_dir> => <new_dir>"
	echo "    + aNewFile"
	echo "    ~ modifiedFile"
	echo "    - removedFile"
	echo
	exit;
fi

inode() {
	ls -i "$1" | awk '{print $1}'
}

compare_to_new() {
	local path="$1";
	if [ ! -f "$DIR_NEW/$path" ]; then
		echo "$path -" >> $RESULTS_TMP
	elif [ $(inode "$DIR_NEW/$path") != $(inode "$DIR_OLD/$path") ]; then
		echo "$path ~" >> $RESULTS_TMP
	fi
}

compare_to_old() {
	local path="$1";
	if [ ! -f "$DIR_OLD/$path" ]; then
		echo "$path +" >> $RESULTS_TMP
	fi
	# No need to check inode again
}

rm -f $RESULTS_TMP

cd "$DIR_OLD"
find * -type f | while read file; do compare_to_new "$file"; done
cd "$DIR_NEW"
find * -type f | while read file; do compare_to_old "$file"; done

sed -i "/^$RESULTS_NAME /d" $RESULTS_TMP

echo "$(basename "$DIR_OLD") => $(basename "$DIR_NEW")" > $RESULTS_FILE
cat $RESULTS_TMP | sort | sed 's/^\(.\+\) \(.\)$/\2 \1/' >> $RESULTS_FILE
rm -f $RESULTS_TMP
