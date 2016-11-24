#!/bin/bash

#db=test
#sqlUser=root
#sqlPswd=test
#inputfile="test.txt"
#cat ${inputfile} | while read ip mac server; do
#    echo "INSERT INTO test (IP,MAC,SERVER) VALUES ('$ip', '$mac', '$server');"
#done | mysql -u ${sqlUser} -p ${sqlPswd} ${db};

# cr_temp      real,
# lr_sensor    real,
# crawl_sensor real,
# crawl_temp   real,
# porch_temp   real,
# garage_sensor real,
# kttn         real,
# hour         int,
# id           integer primary key autoincrement

table="sensors"
db="temperature.db"
# get the highest ID from the temperature.db

# get topics
cr_temp="11.0"
lr_sensor="12.0"
crawl_sensor="13.0"
crawl_temp="14.0"
porch_temp="15.0"
garage_sensor="16.0"
kttn="17.0"
hour=20
id=""

# build the sql query
query2="INSERT INTO ${table} 
 (cr_temp, lr_sensor, crawl_sensor, crawl_temp, porch_temp, garage_sensor, kttn, hour, id)
 VALUES
 ('${cr_temp}', '${lr_sensor}', '${crawl_sensor}', '${crawl_temp}', '${porch_temp}',
  '${garage_sensor}', '${kttn}', '${hour}', '${id}');"

query="INSERT INTO ${table} 
 (cr_temp, lr_sensor, crawl_sensor, crawl_temp, porch_temp, garage_sensor, kttn, hour)
 VALUES
 ('${cr_temp}', '${lr_sensor}', '${crawl_sensor}', '${crawl_temp}', '${porch_temp}',
  '${garage_sensor}', '${kttn}', '${hour}');"

echo "Query: [${query}]"
# execute the sql command
sqlite3 ${db} <<< "${query}"
