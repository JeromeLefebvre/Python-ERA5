load spatial;

-- Returns the direction of a span using the start and end point in degrees
create or replace macro directionOfSpan(span) AS 
(degrees(atan2(ST_Y(st_EndPoint(span)) - ST_Y(st_StartPoint(span)), ST_X(st_EndPoint(span)) - ST_X(st_StartPoint(span)))) + 270) % 360;

-- Query #1 Collect data only for MOR-TS Line
-- This returns to me 9 points
create or replace view TransmissionLine as
select line_name, kv, instln_yr, st_simplify(geom, 0.001) as geom

from st_read('Transmission_Overhead_Powerlines_WP_032_WA_GDA2020_Public_Secure_Shapefile/Transmission_Overhead_Powerlines_WP_032.shp') where line_name = 'MOR-TS 81';


from 'Era5/era5_australia_2000.parquet' limit 10;


create or replace view spans as
from TransmissionLine, range(1,11)
select
       -- The geometry are the individual line spans
       st_makeline(st_pointN(geom, range::int), st_pointN(geom, range::int + 1)) as span,
       -- Features
       directionOfSpan(span) as "direction",
       line_name as "line name",
       range as "index",
       kv "capacity",
       -- Foreign key to the Era5 files
       round(st_x(ST_StartPoint(span))*4)/4 as "weather longitude",
       round(st_y(ST_StartPoint(span))*4)/4 as "weather latitude",
where span is not null;

select concat('https://www.google.com/maps/@', st_y(st_StartPoint(span)), ',', st_x(st_StartPoint(span)), ',1004m/data=!3m1!1e3?entry=ttu') from spans where index = 3;

copy spans to 'maps/1. Spans.geojson' with (format GDAL, driver 'geojson');


-- Query #2 Get the weather and the KPI
create or replace view weather as
from 'Era5/era5_australia_2000.parquet'
select -- Geometry, key    
       latitude,
       longitude,
       -- Time, key
       --any_value(time),
       date_part('Month', time) as month,
       -- Features
       avg(t2m) - 273.15 as "avg temperature (deg C)", -- switch from Kelvin
       stddev_pop(t2m) as "std dev temperature",
       -- TODO: Take a proper sum and give the number in kWhm^2
       --avg(ssr) as "avg solar irradiance" ((W/m2)),
       --stddev_pop(ssr) as "std dev solar irradiance",
       avg(u10) as "avg u10",
       avg(v10) as "avg v10",
       avg(sqrt(power("u10", 2) + power("v10", 2))) as "avg wind speed"
       /*
       (180 + 180/pi()*atan2("avg u10", "avg v10"))%360 as "avg wind direction",
       sqrt(power("avg u10", 2) + power("avg v10", 2)) as "avg wind speed",
       --avg(100 * (exp((17.27 * d2m) / (237.3 + d2m)) / exp((17.27 * t2m) / (237.3 + t2m)))) as "humidity"
       */
group by all;

from weather where month = 2 and latitude = -27.0 and longitude = 113.5;

-- Visualise the data
copy (
       select st_point(longitude, latitude), "avg wind speed" from Weather where month = 2
)
to 'maps/2. Weather.geojson' with (format GDAL, driver 'geojson', );

-- Query #3 power
create or replace view spansWithWeather as
from spans, weather
select
       /*round(least(abs(("avg wind direction" % 180) - (direction % 180)), 180 - abs(("avg wind direction" % 180) - (direction % 180))), 1) AS "line of attack",*/
       *
       /** exclude("avg wind direction","direction", "avg u10", "avg v10", latitude, longitude, "weather longitude", "weather latitude")*/
where weather.latitude = spans."weather latitude" and weather.longitude = spans."weather longitude";

select * from spansWithWeather where month = 6 order by index ;

copy (
     select * from spansWithWeather order by index
) to 'Maps/weather.csv';

copy (
select concat('2000-', lpad(month::varchar, 2, '0'), '-01 00:00:00' )::Datetime, * exclude(month) from spansWithWeather
) to 'Maps/3. Transmissions with Weather.geojson' with (format GDAL, driver 'geojson');

-- one month
copy (
       select ST_AsWKB(span) as geometry, concat('2000-' month '-01:00:00' )::Datetime, * exclude(span, month) from spansWithWeather where month = 1
) to 'Maps/3. Transmissions with Weather.parquet' (format 'parquet');

/*
Update the database:
duckdb transmissions.db < "Demo - Generate Transmission Maps.sql"
*/