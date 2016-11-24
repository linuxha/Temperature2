# Temperature Plot 2

## Description
My tools for getting and plotting the information from SmartThings sensors and a local Airport. Soecifically temperatures around the house and outside.

## Background
This is for my notes as to why we got here. In the past I've created projects for friends and found that documenting them is extremely useful as I'll just have to do it again if I don't document. So some reasonable effort to document this mess and I won't have to start from scratch and guess what I did previously.

I've been playing with SmartThings home automation) and MQTT for a while. I have a number of custom (my own design) and ZigBee sensors that publish to MQTT. My Temperature Plot repos has the basic information for a quick and dirty scripts to get the data and generate the png image. This version will be web based, data will be put in a db (a trigger make it behave like a limit size FIFO), I'll let the browser handle the display of the data.

Now, why would I do this? Well mostly because I'm curious and because understanding your local weather can be very useful to a long distance cyclist (like myself). It can help with planning of routes.

### MQTT topics

* smartthings/Computer Room Temperature/temperature
* smartthings/Crawl Space Contact Sensor/temperature
* smartthings/Crawl Space Temp-Humidity Sensor/temperature
* smartthings/Front Porch Temp-Humidity Sensor/temperature
* smartthings/LR Multipurpose Sensor A/temperature
* smartthings/Garage Side Door iContact Sensor/temperature
* weather/metar/json

### SQL

I've decided that I'll use eithe MYSQL or SQLite3 to create a FIFO for the temperature data. I haven't figured out the table layout yet but I have found information of how to create a trigger to delete the older data. I also haven't figured out how much data to keep.

```
-- http://sqlite.1065341.n5.nabble.com/Sqlite-as-a-FIFO-buffer-td49644.html

-- *****************************************************************************
-- I don't know if this will work, but the basic idea is that after an insert
-- a trigger runs that deletes all the entries with an m_key is greater than
-- 4000 (I think)
-- *****************************************************************************

-- trigger: trg_EventLog
-- table:   tbl_EventLog
-- lenght:  4000
create table tbl_EventLog (
   m_key	integer primary key autoincrement,
   m_eventCode	integer,
   m_timestamp	integer
);

create trigger trg_EventLog after insert
 on tbl_EventLog
   begin delete
   from tbl_EventLog
   where m_key <= (SELECT max(m_key) FROM tbl_EventLog) - 4000;
end;

-- *[ Fini ]********************************************************************

-- https://gist.github.com/elyezer/6450054
-- Example table
CREATE TABLE ring_buffer (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT);

-- Number 10 on where statement defines the ring buffer's size
CREATE TRIGGER delete_tail AFTER INSERT ON ring_buffer
BEGIN
    DELETE FROM ring_buffer WHERE id%10=NEW.id%10 AND id!=NEW.id;
END;
```
### Scripts and Programs

* several node-red scripts (need to figure out how to add them to this repos)
** http://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&hoursBeforeNow=3&mostRecent=true&stationString={{{payload}}} (where {{{payload}}} is set to KTTN)
* mmove.sh (moves previous day's temp.png & dat files to .1 and .2)
* mosquitto_sub (part of the mosquitto tools)
* gettopicval.sh (creates the dat files from the data in the MQTT topics)
* topicgraph.sh (creates the graph temp.png from the dat files)
* clean-topicval.sh (cleans out older dat files)
* hilo.sh (pulls data from wx200 weather station ???)
* hilo.pl (pulls data from wx200 weather station ???)
* tempgraph.sh (creates temp.png from the tmp files)
* check_battery.sh (pulls MQTT battery topics using wildcards and checks for drain)
* smartthings-mqtt-bridge (node.js software to bridge between the SmartThings hub and my local MQTT)
* sunrise (compiled C code from my today repos)
* sunset
## Crontab

```
# Stuff for
# mosquitto_sub -h mozart.uucp -t "weather/metar/json" -C 1 >/tmp/metar.json & ~/bin/get-json.js /tmp/metar.json 'response.data[0].METAR[0].temp_c[0]'my graphs
# 
2 0 * * *	${HOME}/dev/Temperature/mmove.sh
3 * * * *	/usr/local/bin/mosquitto_sub -h mozart.uucp -t "weather/metar/json" -C 1 >/tmp/metar.json && ${HOME}/bin/gettopicval.sh && ${HOME}/bin/topicgraph.sh
4 1 * * *	${HOME}/bin/clean-topicval.sh
```

## Notes

* Verified with Firefox, Node.js v0.10.29, and Bash under Linux.
* Mosquitto 1.4.8 or better (need the -C option)
* I won't make any attempt to make this portable.
* This really is a learning exercise to learn a little about gnuplot and scratch an itch (see how temperatures around the house relate to each other and other environmental factors).
* Yes this is a kludge of one script pulled into duty to work with another (I'm a lazy programmer).

## Installation

* Follow the directions for installing Mosquitto and command line tools.
* Follow the directions for the SmartThings MQTT Bridge (you'll need node.js).
* copy the scripts ... (@TODO hmm, how to explain?)

* create a db for sqlite3
** sqlite3 temperature.db << input.sql
* add to cron ...
** ```
# Stuff for
# mosquitto_sub -h mozart.uucp -t "weather/metar/json" -C 1 >/tmp/metar.json & ~/bin/get-json.js /tmp/metar.json 'response.data[0].METAR[0].temp_c[0]'my graphs
# 
2 0 * * *	/home/njc/dev/Temperature/mmove.sh
3 * * * *	/usr/local/bin/mosquitto_sub -h mozart.uucp -t "weather/metar/json" -C 1 >/tmp/metar.json && /home/njc/bin/gettopicval.sh && /home/njc/bin/topicgraph.sh
4 * * * *	/home/njc/dev/Temperature2/gettopicval-2.sh && /home/njc/dev/Temperature2/topicgraph-2.sh
4 1 * * *	/home/njc/dev/Temperature/clean-topicval.sh
```

weather/metar/json gets populated from : http://www.aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&hoursBeforeNow=3&mostRecent=true&stationString={{{payload}}} (where {{{payload}}} is set to KTTN)
convert the XML to JSON (I use node-red)


## ToDo

* You're kidding right? ;-)
* Add more sensor data to the plot until it's useful (or totally unreadable)
* add a bit more labeling
* Migrate to a web page, perhaps using javacript. I've not liked what I've found so far to this is good enough for the moment.

## Program list

* README.md
* gettopicval-2.sh
* topicgraph-2.sh
* temperature.db
* temperature.sql

* temperature.csv
* temperature.csv-x
* temp.png
* notes.txt
# Temperature2 Readem
