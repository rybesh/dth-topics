#! /bin/bash

BASE="http://newspapers.digitalnc.org/lccn"

LCCNS=(sn92073227 sn92073228 sn92068245 sn92073230)

while read -r DATE
do
    PAGE=1
    LCCN=0
    while :
    do
        if wget -P ocr -N -x -nH --cut-dirs=2 \
             "$BASE/${LCCNS[$LCCN]}/$DATE/ed-1/seq-$PAGE/ocr.txt" ; then
            ((PAGE++))
        else
            if [ "$PAGE" -ne 1 ]; then
                break
            fi
            if [ "$LCCN" -eq 3 ]; then
                break
            else
                ((LCCN++))
            fi
        fi
    done
    touch ocr/downloaded
done < dates.txt
