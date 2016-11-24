#!/bin/bash

################################################################################
# topicgraph.sh - graph the data in the files ...
################################################################################
#
# This program started out with simple intentions, plot the sensors to
# allow comparision of temperatures in different parts of the house (and
# outside) using gnuplot.
#
# Currently we're getting the date from the MQTT topics (on mozart.uucp),
# hourly, There are 7 topics (6 sensors and the KTTN Airport) that are being
# plotted. Additionally we have Sunrise and Sunset information as verticle
# lines. This should allow for some comparison of temperatures.
#
# Future enhancements may include sun (units?) and wind. We'll see.
#
# I've started playing around with gnuplot and it's various features. Very
# powerful (even though I don't comprehend all the features).
#
# ------------------------------------------------------------------------------
# Here's what I have working
# - read the csv
# - Get the zeroth hour (the first entries hour col 8)
# - calculate and plot the offset for the sunrise and sunset dividers
# - Midnight divider
# - night and day backgrounds
# -[ ToDo ]---------------------------------------------------------------------
# - Need to figure out the max and min temperature values (may not need)
################################################################################
# Semantic Versioning
# Given a version number MAJOR.MINOR.PATCH, increment the:
#
#    MAJOR version when you make incompatible API changes,
#    MINOR version when you add functionality in a backwards-compatible manner, and
#    PATCH version when you make backwards-compatible bug fixes.
#
# Additional labels for pre-release and build metadata are available
# as extensions to the MAJOR.MINOR.PATCH format.
# ------------------------------------------------------------------------------
version="1.0.0"
################################################################################

export PATH=/usr/local/bin:${HOME}/bin:${PATH}

TDIR="${HOME}/dev/Temperature2"
PNGFILE="${TDIR}/temp.png"
dat="${TDIR}/temperature.csv"

#t=$(echo "$(date +%H)" | bc -l) # gets rid of the leading 0
# ------------------------------------------------------------------------------
function cleanup {
    rm  -r "${TDIR}/temperature.csv"  "${TDIR}/temperature.csv-x" 2>/dev/null
}

trap cleanup EXIT
# ------------------------------------------------------------------------------
# 1 CR Temp
# 2 LR Sensor
# 3 Crawl Contact
# 4 Crawl Temp
# 5 Porch Temp
# 6 Garage Contact
# 7 KTTN
# 8 hr
# 9 id
#
buildXtics() {
    fl="${1}"
    # this is the data tidied up for plot (temperature.csv-x)
    > "${fl}-x"
    # Interesting problem
    # Bash puts this in a sub shell so you lose the xtics:
    # sed -n '1!p'  < "${f}" | while IFS=',' read d d d d d d d hr d;do xtics="${xtics}, '${tics[${hr}]}' ${hr}"; done
    c=$(cat "${fl}" | tr -d //)

    i=0
    x=0
    # (cr_temp, lr_sensor, crawl_sensor, crawl_temp, porch_temp, garage_sensor, kttn, hour)
    # temperature.csv
    # a    b    c    d    e    f    g    hr  id
    # 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 18, 19
    #                  1 2 3 4 5 6 7 8  9
    while IFS=',' read a b c d e f g hr id
    do
	if [ -z "$zeroHr" ]; then
	    zeroHr="${hr}"
	    #xtics="'' -1"
	    xtics="'${tics[${hr}]}' ${x}"
	else
	    xtics="${xtics}, '${tics[${hr}]}' ${x}"
	fi

	junk="HR = ${hr}, ${x}"

	echo "${x}, ${a}, ${b}, ${c}, ${d}, ${e}, ${f}, ${g}" >> "${fl}-x"
	junk="${x}, ${a}, ${b}, ${c}, ${d}, ${e}, ${f}, ${g}, $hr, $id"
	x=$((${x}+1))
	i=$(($i+1))
    done <<< "${c}"
    # Use this like a return
    echo "${xtics}"
}

# take 6:46 and convert it to 6.76 hours
math() {
    s=$(echo "scale=2; ${1//:/+}/60" | bc -l)
    echo $s
}
    
# ------------------------------------------------------------------------------
#
dateStr=$(date +%c)

declare -A tic
tics=(  ['0']='Midnight' [2]='2am' [4]='4am' [6]='6am' [8]='8am' [10]='10am' [12]='Noon' [14]='2pm' [16]='4pm' [18]='6pm' [20]='8pm' [22]='10pm' )
# ${tics[1]}
# tics=( ['0']='Midnight' ['1']='One' ['3']='Three' )
# $ echo ${tics[3]}
# Three

# |   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i   i |
# \---+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-------+-----/
#     M       2       4       6       8      10       N       2       4       6       8      10
if [ -f "${dat}" ]; then
    # this sed will skip the header (1st line)
    xtics=$(buildXtics "${dat}")
else
    echo "File: ${dat}, not found"
    exit 2
fi

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

# How do we plot the srHr & ssHr?
if [ ${zeroHr} -gt ${srHr} ]; then
    srHr=$((24 + (${srHr} - ${zeroHr})))
else
    srHr=$((${srHr} - ${zeroHr}))
fi
#
if [ ${zeroHr} -gt ${ssHr} ]; then
    #ssHr=$((24 + ${ssHr} - ${zeroHr}))
    ssHr=$((24 - (${zeroHr} - ${ssHr})))
    #ssHr=$((24 - ${srHr}))
else
    ssHr=$((${ssHr} - ${zeroHr}))
fi

# Magic math to go from 6:46 to 6.75 goes here
srise=$(math "${srHr}:${srMn}")
#srOffset=$(echo "scale=2;${srise}-1.5" | bc -l)
srOffset=$(echo "scale=2;x=((${srise}+0.01)/24.0); if(x<1) print 0; x" | bc -l)

sset=$(math "${ssHr}:${ssMn}")
#ssOffset=$(echo "scale=2;${sset}-0.25" | bc -l)
#ssOffset=$(echo "scale=2;x=((${sset}+1.25)/24.0); if(x<1) print 0; x" | bc -l)
ssOffset=$(echo "scale=2;x=((${sset}+0.5)/24.0); if(x<1) print 0; x" | bc -l)

# http://www.w3schools.com/colors/colors_picker.asp
if [ ${srHr} -ge ${ssHr} ]; then
    #night="'grey'"	# 50%
    #night="'#f2f2f2'"	# 95%
    night="'#d9d9d9'"	# 85%
    day="'white'"
else	 
    day="'#d9d9d9'"
    #night="'grey'"	# 50%
    #night="'#f2f2f2'"	# 95%
    night="'white'"	# 85%
fi

# $ date
# Tue Nov 22 17:27:40 EST 2016
# $ bash -x ./topicgraph-2.sh 2>bar
# zeroHr   = 18
# 
# Sunrise  = 06:51
# srise    = 12.85
# srOffset = 0.53
# srHr     = 12		Perfect (6PM is a 0, 4AM is at 12)
# 
# sunset   = 16:35
# sset     = 30.58
# ssOffset = 1.29	                                                  ssOff       zHr   ssHr
# ssHr     = 30		Problem (4PM should be 22) 18, ss is 2 behind (16), 22 = 24 - (18 - 16)
# 
# midnight = 6          Perfect
#
# $ bash -x ./topicgraph-2.sh 2>bar
# zeroHr   = 18
#
# Sunrise  = 06:51
# srise    = 12.85
# srOffset = 0.53
# srHr     = 12
#
# sunset   = 16:35
# sset     = 18.58
# ssOffset = 0.79
# ssHr     = 18
#
# midnight = 6
#
# Plots completed
#
#echo "zeroHr = ${zeroHr}"

#echo "Sunrise = ${sunrise}"
#echo "srise = ${srise}"
#echo "srOffset = ${srOffset}"
#echo "srHr = ${srHr}"

#echo "sunset = ${sunset}"
#echo "sset = ${sset}"
#echo "ssOffset = ${ssOffset}"
#echo "ssHr = ${ssHr}"

midnight=$((24 - ${zeroHr}))
midnight1=$(echo "scale=2;x=(${midnight}/24.0); if(x<1) print 0; x" | bc -l)

#echo "midnight = ${midnight}"
# ------------------------------------------------------------------------------
# commands to send to gnuplot

# size 600, 400
#set term png color small \n
#gnuplot> set term png color small 
#                            ^
#         line 0: unrecognized terminal option

# https://www2.uni-hamburg.de/Wiss/FB/15/Sustainability/schneider/gnuplot/colors.htm
COLOR="'#FFFFFF'" # White     #FFFFFF
#COLOR="'#C0C0C0'" # silver    #C0C0C0
#COLOR="'#F0F8FF'" # aliceblue #F0F8FF
#COLOR="'#F0FFFF'" # azure     #F0FFFF
#COLOR="'#F0FFF0'" # honeydew  #F0FFF0
#COLOR="'#FFFFF0'" # ivory     #FFFFF0
#COLOR="'#F5F5DC'" # beige     #F5F5DC
#COLOR="'#FFF0F5'" # lavenderblush #FFF0F5
#COLOR="'#FFF0FF'" # lavender? #FFF0FF
#COLOR="'#E0FFFF'" # lightcyan #E0FFFF
#COLOR="'#D0FFFF'" # lightcyan #E0FFFF

# ------------------------------------------------------------------------------
# 
# http://stackoverflow.com/questions/12816963/gnuplot-coloring-background-according-to-data-range
#
# Question:
# I plot a data file containing 2 columns as a line. I also have data
# ranges for the x axis that I would like to use to color the
# background.
#
# For example, in the data range from 41 to 70, I would like to color
# the background blue.
#
# I know that these commands can color background but I haven't yet
# figured out how to use x values ...
#
# Answer:
# Gnuplot supports multiple coordinate systems. As you're already aware,
# there's graph where 0,0 is the lower left corner of the graph and
# 1,1 is the upper right corner of the graph. There's also
# screen. (0,0 is the lower left corner of the "screen"). The axes
# you're looking for is first. Note that you can even mix coordinate
# systems. the point first 50, graph 0 is at the bottom of the graph
# at the point 50 on the x axis. Putting this all together, you should
# be able to set your rectangle as:
#
#    set obj 1 rectangle behind from first 41, graph 0 to first 70, graph 1 back
#    set obj 1 fillstyle solid 1.0 fillcolor rgb "blue"
#
# I also added "back" to the command so that the rectangle is drawn
# behind all the other plot elements
#
#     | night |  day  | night |
#     |    day    |   night   |
#     |  day  | night |  day  |
#     |   night   |    day    |
#
# ------------------------------------------------------------------------------

# Missing the graph on the day side
# Need to reposition the description(?)
# Need to reposition the sunset/sunrise when all the way to the left (zeroHr == ssHr or srHr)
# set term png color background ${COLOR} size 1200, 900 \n
#PNG="pngcairo dashed"
PNG="pngcairo"		# Same as png
#PNG="png"
# \xc2\xB0 is the URF 2 byte degree symbol
Plot="set termoption dash \n
#set term ${PNG} color background rgb ${day} size 1200, 900 \n
set term ${PNG} color background rgb 'white' size 1200, 900 \n
set output \"${PNGFILE}\" \n
set title 'Temperature Sensors for ${dateStr}' \n
set linestyle 1 lt 8 \n
set grid \n

# Sunrise \n
set arrow from ${srise}, graph 0 to ${srise}, graph 1 nohead lc rgb 'red' \n
set label 1 at graph ${srOffset},1.012 \n
set label 1 \"Sunrise\" tc rgb 'red' \n

# Sunset fuchsia hotpink FF69B4\n
set arrow from ${sset}, graph 0 to ${sset}, graph 1 nohead lc rgb 'blue' \n
set label 2 at graph ${ssOffset},1.012 \n
set label 2 \"Sunset\" tc rgb 'blue' front\n

# Midnight \n
set arrow from ${midnight}, graph 0 to ${midnight}, graph 1 nohead lc rgb 'yellow' \n
#set arrow from ${midnight},0 to ${midnight},120 nohead lt 5 lc rgb 'black' \n

# set background color of entire page \n
#set object 1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb \"white\" behind \n
set object 2 rectangle from graph 0,0 to graph 1,1 fillcolor rgb ${day} behind \n
set obj 1 rectangle behind from first ${srise}, graph 0 to first ${sset}, graph 1 back \n
set obj 1 fillstyle solid 1.0 fillcolor rgb ${night} back \n

set xlabel 'Time ' \n
set ylabel 'Temp (F\xC2\xB0)' \n

set xrange [-1:24] \n
set xtics (${xtics}) \n

plot '${dat}-x' using 1:2 with lines smooth csplines title \"CR_Temp\",
     '${dat}-x' using 1:3 with lines smooth csplines title \"LR_Sensor\",
     '${dat}-x' using 1:4 with lines smooth csplines title \"Crawl_Contact\",
     '${dat}-x' using 1:5 with lines smooth csplines title \"Crawl_Temp\",
     '${dat}-x' using 1:6 with lines smooth csplines title \"Porch_Temp\",
     '${dat}-x' using 1:7 with lines smooth csplines title \"Garage_Contact\",
     '${dat}-x' using 1:8 with lines smooth csplines title \"KTTN\" \n"

#
#/bin/echo -e "${Plot}" > file.plot
/bin/echo -e ${Plot} | gnuplot 
#ls -l "${PNGFILE}"
echo "Plots completed"
exit 0
zz=<<EOF
# Midnight \t
# This doesn't work, it' just gives a 45 angle line and it's not graphed when I leave the next active \n
#set arrow from graph ${midnight1},1 to ${midnight1},11 nohead lt 5 lc rgb 'green' \n

# To draw a vertical line from the bottom to the top of the graph at x=3, use:
#     set arrow from 3, graph 0 to 3, graph 1 nohead

#set arrow from graph ${sset},0 to ${sset},1 nohead lc rgb 'blue' \n
#set label 2 at ${ssOffset},75 \n

#set arrow from graph ${srise},0 to ${srise},1 nohead lc rgb 'red' \n
#set label 1 at ${srOffset},75 \n

plot '${dat}-x' using 1:2 with lines smooth csplines title \"CR_Temp\",
     '${dat}-x' using 1:3 with lines smooth csplines title \"LR_Sensor\",
     '${dat}-x' using 1:4 with lines smooth csplines title \"Crawl_Contact\",
     '${dat}-x' using 1:5 with lines smooth csplines title \"Crawl_Temp\",
     '${dat}-x' using 1:6 with lines smooth csplines title \"Porch_Temp\",
     '${dat}-x' using 1:7 with lines smooth csplines title \"Garage_Contact\",
     '${dat}-x' using 1:8 with lines smooth csplines title \"KTTN\" \n"

Plots completed

EOF
