-- sqlite3 temperature.db < output.sql
.headers on
.mode csv
.output temperature.csv
-- drop the ID
select cr_temp,lr_sensor,crawl_sensor,crawl_temp,porch_temp,garage_sensor,kttn,hour from sensors;
.quit
-- =[ Fini ]=====================================================================
