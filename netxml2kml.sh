#
# 2023 jens heine <binbash@gmx.net>
#

echo "Creating giskismet database..."
for f in *kismet.netxml; do 
	echo "-> Processing ${f}..."
	giskismet -x "$f" 
done
echo "Creating kml file: out.kml..."
giskismet -q "select * from wireless" -o out.kml
echo Done
