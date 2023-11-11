#!/bin/bash
#
# Copyright 2023 Jens Heine <binbash@gmx.net>
#
# Thanks to https://github.com/HackHerz for his script
# https://gist.github.com/HackHerz/4e05681b343c7b638a33 which I used
# as a start.
#
#
DATABASE_FILENAME="database.db"
WIRELESS_TABLE_NAME="wireless"
TEMPORARY_IMPORT_FILENAME="import.tmp"
SOURCE_DIRECTORY="."
INTERVAL=0

print_help() {
  echo "2023 Jens Heine"
  echo "Import airodump-ng kismet csv files into a sqlite database table."
  echo "Usage: `basename $0` [-d DATABASE] [-s SOURCE_DIRECTORY]|[-c CSV_FILE] [-i REPEAT_INTERVAL [-t WIRELESS_TABLE_NAME]"
  echo " -c CSV_FILE"
  echo "    Import only CSV_FILE"
  echo " -d DATABASE_FILENAME"
  echo "    Set sqlite database file to store data into."
  echo " -i REPEAT_INTERVAL"
  echo "    Repeat the import every REPEAT_INTERVAL seconds"
  echo " -s SOURCE_DIRECTORY"
  echo "    Import all *kismet.csv files found in the SOURCE_DIRECTORY"
  echo " -t WIRELESS_TABLE_NAME"
  echo "    Store the data in a table named WIRELESS_TABLE_NAME"
}

while getopts 'c:d:hi:r:s:t:?' opt; do
  case "$opt" in
    c)
      arg="$OPTARG"
      SINGLE_CSV_FILENAME="${OPTARG}"
      ;;
    d)
      arg="$OPTARG"
      DATABASE_FILENAME="${OPTARG}"
      ;;
    i)
      arg="$OPTARG"
      INTERVAL="${OPTARG}"
      ;;
    r)
      arg="$OPTARG"
      INTERVAL="${OPTARG}"
      ;;
    s)
      [ "$SINGLE_CSV_FILENAME" ] && { echo "Wrong arguments."; print_help; }
      arg="$OPTARG"
      SOURCE_DIRECTORY="${OPTARG}"
      ;;
    t)
      arg="$OPTARG"
      WIRELESS_TABLE_NAME="${OPTARG}"
      ;;
    ?|h)
      print_help
      exit 0
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ "$SINGLE_CSV_FILENAME" != "" ]; then
  # single file import mode enabled
  FILE_LIST="$SINGLE_CSV_FILENAME"
else
  # multi file import mode enabled
  FILE_LIST=`ls -1 "${SOURCE_DIRECTORY}"/*kismet.csv`
fi

echo "Importing csv files:"

while true; do

  for csv_file in $FILE_LIST; do
    if [ ! -f "$csv_file" ]; then
	    echo "File not found: $csv_file"
	    sleep 1
	    continue
    fi
    lines=`wc -l "$csv_file"|cut -f1 -d" "`
    [ $lines -gt 0 ] && lines=$((lines - 1))
    echo "`date '+%Y-%m-%d %H:%M:%S'` - Processing file: ${csv_file} ($lines lines)"

  # clear temp file
  [ -f ${TEMPORARY_IMPORT_FILENAME} ] && rm ${TEMPORARY_IMPORT_FILENAME}
  # clean eol's, drop header line, add filename column
  csv_file_basename=`basename "$csv_file"`
  create_date=`date '+%Y-%m-%d %H:%M:%S'`
  cat ${csv_file}|sed 's/\r//g'|sed 's/\;$//g'|sed 1d|sed "s/^/${create_date};${csv_file_basename};/g">${TEMPORARY_IMPORT_FILENAME}

  cat <<EOF | sqlite3 "$DATABASE_FILENAME"
CREATE TABLE IF NOT EXISTS '${WIRELESS_TABLE_NAME}' (
Createdate datetime not null default (datetime(CURRENT_TIMESTAMP, 'localtime')),
Filename TEXT,
Network INTEGER,
NetType TEXT,
ESSID TEXT,
BSSID TEXT,
Info TEXT,
Channel INTEGER,
Cloaked TEXT,
Encryption TEXT,
Decrypted TEXT,
MaxRate REAL,
MaxSeenRate TEXT,
Beacon INTEGER,
LLC INTEGER,
Data INTEGER,
Crypt INTEGER,
Weak INTEGER,
Total INTEGER,
Carrier TEXT,
Encoding TEXT,
FirstTime TEXT,
LastTime TEXT,
BestQuality INTEGER,
BestSignal INTEGER,
BestNoise INTEGER,
GPSMinLat TEXT,
GPSMinLon TEXT,
GPSMinAlt TEXT,
GPSMinSpd TEXT,
GPSMaxLat TEXT,
GPSMaxLon TEXT,
GPSMaxAlt TEXT,
GPSMaxSpd TEXT,
GPSBestLat TEXT,
GPSBestLon TEXT,
GPSBestAlt TEXT,
DataSize INTEGER,
IPType INTEGER,
IP TEXT
--,PRIMARY KEY("Filename", "Network")
);
.mode csv
.separator ";"
.import '${TEMPORARY_IMPORT_FILENAME}' '${WIRELESS_TABLE_NAME}'
EOF

  [ -f ${TEMPORARY_IMPORT_FILENAME} ] && rm ${TEMPORARY_IMPORT_FILENAME}

  done

  if [ "$INTERVAL" == "0" ]; then 
    exit 0
  else
#    echo "Sleeping $INTERVAL seconds..."
    sleep $INTERVAL
  fi

done
