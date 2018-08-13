#! /bin/bash

BASE="http://newspapers.digitalnc.org/lccn/sn92073228"

while read -r DATE
do
    PAGE=1
    while :
    do
        wget -P ocr -N -x -nH --cut-dirs=2 "$BASE/$DATE/ed-1/seq-$PAGE/ocr.txt"\
            || break
        ((PAGE++))
    done
done < dates.txt
