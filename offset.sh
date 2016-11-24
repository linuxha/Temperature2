#!/bin/bash

export PATH=/usr/local/bin:${HOME}/bin:${PATH}

TDIR="${HOME}/dev/Temperature2"
PNGFILE="${TDIR}/temp.png"
dat="${TDIR}/temperature.csv"

# ------------------------------------------------------------------------------
# take 6:46 and convert it to 6.76 hours
math() {
    s=$(echo "scale=2; ${1//:/+}/60" | bc -l)
    echo $s
}

# ------------------------------------------------------------------------------
# Sunrise and Sunset
#
# I now need to figure out how to offset the times so they pop up in the correct
# place and then color the before and after sections appropriately (grayer for
# night, white for day)
#
# I also need the high and low for the day so that the lines don't extend past
# the top and bottom of the graph. Finally I need to add sun rise and sun set
# labels to match the verticle lines
# ------------------------------------------------------------------------------
sunrise=$(sunrise)
srHr=${sunrise%:*}
srHr=${srHr//0/}
srMn=${sunrise##*:}
#
sunset=$(sunset)
ssHr=${sunset%:*}
ssMn=${sunset##*:}

# Magic math to go from 6:46 to 6.75 goes here
#srise=$(math ${sunrise})
#srOffset=$(echo "scale=2; ${srise}-1.5" | bc -l)
#sset=$(math ${sunset})
#ssOffset=$(echo "scale=2; ${sset}+0.25" | bc -l)

#
zeroHr=$(head -1 ${dat} | cut -d , -f 8)
echo "Zero Hour = ${zeroHr}"

#
# + sunrise=06:50
# + srHr=06
# + sunset=16:35
# + ssHr=16
# + srise=6.83
# + srOffset=5.33
# + sset=16.58
# + ssOffset=16.83
# + zeroHr=9
# + srHr=15
# + ssHr=25
#
if [ ${zeroHr} -gt ${srHr} ]; then
    srHr=$((24 + $srHr - $zeroHr))
else
    srHr=$(($srHr - $zeroHr))
fi
#
if [ ${zeroHr} -gt ${ssHr} ]; then
    ssHr=$((24 + ${srHr} - ${zeroHr}))
else
    ssHr=$((${ssHr} - ${zeroHr}))
fi

# Magic math to go from 6:46 to 6.75 goes here
srise=$(math "${srHr}:${srMn}")
srOffset=$(echo "scale=2; ${srise}-1.5" | bc -l)
sset=$(math "${ssHr}:${ssMn}")
ssOffset=$(echo "scale=2; ${sset}+0.25" | bc -l)
