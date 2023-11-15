#!/bin/bash
#
# 20231111 jens heine binbash@gmx.net
#
#

# Trap ctrl-c from user to exit gracefully
trap ctrl_c INT

set -e
SCANFILE_PREFIX=`date +%F_%H-%M-%S`
AIRODUMP_PID=-1
KISMETCSV2SQLITE_PID=-1
BASE_DIR="./"
KISMETCSV2SQLITE_BIN="kismetcsv2sqlite.sh"
WLAN_DEV="wlan0"
DATABASE_INSERT_INTERVAL_SEC=1


#
# Functions
#
function ctrl_c() {
	set +e
	echo "Stopping..."
	echo "Killing airodump-ng (PID: $AIRODUMP_PID)"
	kill -9 $AIRODUMP_PID
	echo "Killing kismetcsv2sqlite.sh... (PID: $KISMETCSV2SQLITE_PID)"
	kill -9 $KISMETCSV2SQLITE_PID
	echo
	exit 0
}

print_help() {
  echo "2023 Jens Heine"
  echo "Scan wifi's and collect the data together with gps data in a sqlite db"
  echo "Usage: `basename $0` [-d DATABASE] [-s SOURCE_DIRECTORY]|[-c CSV_FILE] [-i REPEAT_INTERVAL [-t WIRELESS_TABLE_NAME]"
  echo " -B BASE_DIR"
  echo "    Base directory where the airodump files and the sqlite db will be saved."
  echo " -w WLAN_DEV"
  echo "    Set the wlan interface. Example: -w wlan0"
  echo " -i DATABASE_INSERT_INTERVAL_SEC"
  echo "    Insert every x seconds all data collected into the database."
}


#
# Parse command line args
#
while getopts 'B:w:i:?' opt; do
  case "$opt" in
    B)
      arg="$OPTARG"
      BASE_DIR="${OPTARG}"
      ;;
    w)
      arg="$OPTARG"
      WLAN_DEV="${OPTARG}"
      ;;
    i)
      arg="$OPTARG"
      DATABASE_INSERT_INTERVAL_SEC="${OPTARG}"
      ;;
    ?|h)
      print_help
      exit 0
      ;;
  esac
done
shift "$(($OPTIND -1))"

#
# Main
#
cd "$BASE_DIR"

# Run airmon in background
airodump-ng -w "$SCANFILE_PREFIX" $WLAN_DEV --gpsd -K 1 &

# Remember airodump PID
AIRODUMP_PID=$!

# Let airodump start
echo "Waiting for airodump-ng to start..."
sleep 2

# Start database collector
$KISMETCSV2SQLITE_BIN -i 1 -d "$BASE_DIR"/database.db -c "$BASE_DIR"/"$SCANFILE_PREFIX"-01.kismet.csv &

# Remember PID
KISMETCSV2SQLITE_PID=$!

# Loop until user terminated with ctrl-c
while true; do
	sleep 1
done


