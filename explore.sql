
copy 

load spatial;
create or replace view bounds as (
    select geom from st_read('states.geojson') where STATE_NAME Like 'West%' 
);

copy (
select *, st_point(longitude, latitude) as geom from 'Parquet/era5_australia_2000.parquet' where time=Date'2000-01-01' and st_contains((from bounds), st_point(longitude, latitude))
) to 'sample.geojson' with (format GDAL, driver 'geojson');


CREATE or replace view bounds as
select unnest(ST_DUMP(geom)).geom as geom from st_read('states.geojson') where STATE_NAME Like 'West%' limit 1;

copy bounds to 'wamaylands.geojson'  with (format gdal, driver 'geojson');

copy (
select row_number() over (), geom from (select unnest(ST_DUMP(geom)).geom as geom from  st_read('states.geojson') where STATE_NAME Like 'West%')
) to 'wa.geojson' with (format gdal, driver 'geojson');

create table waOnly as 
(from 'Parquet/era5_australia_2000.parquet' where st_contains((from bounds), st_point(longitude, latitude)) and time between Date'2000-01-01' and Date'2000-01-02');

copy (from 'Parquet/era5_australia_2000.parquet' where time = Date'2000-01-01') to 'Jan1_only.parquet';

copy (from 'Parquet/era5_australia_2000.parquet' where date_part('month', time) = 1) to 'Jan_only.parquet';

copy (from 'Parquet/era5_australia_2000.parquet' where date_part('month', time) = 1 and st_contains((from bounds), st_point(longitude, latitude))) to 'Jan_wa_only.parquet';

create table jan as (from 'Parquet/era5_australia_2000.parquet' where date_part('month', time) = 1);


DESCRIBE from 'Parquet/era5_australia_2000.parquet';

    -35.5 │            -28.0 │            114.0 │            122.5 

load spatial;
--
create or replace view tiles as 
from st_read('2. Minimal cover.geojson');

create or replace view oneTitle as 
select ST_Envelope(st_collect(list(geom))) from st_read('2. Minimal cover.geojson');

copy oneTitle to 'oneTitle.geojson' with (format gdal, driver 'geojson');
-- Carve out a square
from 'Parquet/era5_australia_2000.parquet' where latitude between -35.5 and -28 and longitude between 114 and 122.5;

copy (
select st_point(longitude, latitude) as geom, * from 'Parquet/era5_australia_2000.parquet' where time=Date'2000-01-01' and st_contains((select st_collect(list(geom)) from tiles), st_point(longitude, latitude))
) to 'pointsfound.geojson' with (format gdal, driver 'geojson');

select st_contains(ST_GeomFromText('POLYGON ((115.75 -33.75, 115.75 -33.25, 116.25 -33.25, 116.25 -33.75, 115.75 -33.75))'),
st_point(116, -33.50));

from 'Parquet/era5_australia_2000.parquet' where longitude = 116 and latitude = -33.5 and st_contains(ST_GeomFromText('POLYGON ((115.75 -33.75, 115.75 -33.25, 116.25 -33.25, 116.25 -33.75, 115.75 -33.75))'),
st_point(longitude, latitude));

-- Carve out using tiles directly
copy (

) to 'era5 for min cover.geojson' with (format gdal, driver 'geojson');

7352208

8784, 10 seconds



copy () to 'Jan1_only.parquet';

