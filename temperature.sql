.open temperature.db
create table sensors (
   cr_temp      real,
   lr_sensor    real,
   crawl_sensor real,
   crawl_temp   real,
   porch_temp   real,
   garage_sensor real,
   kttn         real,
   hour         int,
   id           integer primary key autoincrement
);

CREATE TRIGGER delete_tail AFTER INSERT ON sensors
BEGIN
    DELETE FROM sensors WHERE id%24=NEW.id%24 AND id!=NEW.id;
END;
.mode csv
.import input.csv sensors
.headers on
select * from sensors;
.quit
