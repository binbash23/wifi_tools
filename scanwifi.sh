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



cd "$BASE_DIR"
#airodump-ng -w outfile --manufacturer --uptime --wps wlan1 --gpsd

# Run airmon in background
airodump-ng -w "$SCANFILE_PREFIX" wlan1 --gpsd -K 1 &

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


