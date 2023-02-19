--raster2pgsql -s 4326 -I -M -C [raster file path] -F | psql -d [database name] -h [hostname] -U [username] -p [port] -W
--raster2pgsql -s 4326 -I -M -C C:\Users\tugcetay\Desktop\AYP1_son\GEO474_vize\uygulama\data\sym.tif -F | psql -d  DbFatih  -h localhost -U postgres -p 5432 -w 

/*
-s:EPSG kodu
-I:index oluşturur
-M:Vacuum analyze
-a:mevcut tabloya ekler
-c:yeni tablo oluşturur
-C:raster kısıtlamaları/srid, piksel boyutu vb. 
-F:add column 
*/

/*
Input:ST_RastFromWKB - ST_RastFromHexWKB
Output:ST_AsBinary/ST_AsWKB -ST_AsGDALRaster-ST_AsJPEG-ST_AsTIFF 
*/

SELECT ST_MetaData(rast) FROM sym5255;

-- en yüksek/düşük kot seviyesi(cm)
SELECT (ST_SummaryStats(rast)).max FROM sym5255;
SELECT (ST_SummaryStats(rast)).min FROM sym5255;

-- en düşük kot seviyesinin 50 m üzerindeki binalar
SELECT * FROM yapi,sym5255
WHERE ST_Value(sym5255.rast, ST_Centroid(yapi.geom5255)) > (SELECT (ST_SummaryStats(sym5255.rast)).min + 5000 FROM sym5255)


--Bakı 
ALTER TABLE parsel
ADD COLUMN geom5255 geometry;
UPDATE parsel
SET geom5255 = ST_Transform(geom, 5255)
WHERE ST_SRID(geom) = 4326;

CREATE TABLE classified_parsel (
    polygon geometry,
    mean_pixel_value float,
    aspect_direction char(1)
);

INSERT INTO classified_parsel (polygon, mean_pixel_value, aspect_direction)
SELECT parsel.geom5255 as polygon,
       AVG(ST_Value(aspect.st_aspect, ST_SetSRID(ST_Centroid(parsel.geom5255), 5255))) as mean_pixel_value,
       CASE
           WHEN AVG(ST_Value(aspect.st_aspect, ST_SetSRID(ST_Centroid(parsel.geom5255), 5255))) BETWEEN 0 AND 45 THEN 'N'
           WHEN AVG(ST_Value(aspect.st_aspect, ST_SetSRID(ST_Centroid(parsel.geom5255), 5255))) BETWEEN 46 AND 135 THEN 'E'
           WHEN AVG(ST_Value(aspect.st_aspect, ST_SetSRID(ST_Centroid(parsel.geom5255), 5255))) BETWEEN 136 AND 225 THEN 'S'
           WHEN AVG(ST_Value(aspect.st_aspect, ST_SetSRID(ST_Centroid(parsel.geom5255), 5255))) BETWEEN 226 AND 315 THEN 'W'
           ELSE 'N'
       END as aspect_direction
FROM aspect, parsel
WHERE ST_Intersects(aspect.st_aspect, parsel.geom5255)
GROUP BY parsel.geom5255;



-- Eğimin %20-%40 arasında olan alanlardaki yapılar 
CREATE TABLE slope AS
SELECT ST_Slope(sym5255.rast, 1, '32BF', 'DEGREES')  rast
FROM sym5255;

CREATE TABLE slope_yapi AS
SELECT y.*
FROM yapi y, slope s
WHERE ST_Intersects(y.geom5255, s.rast) AND ST_Value(s.rast, ST_PointOnSurface(y.geom5255)) BETWEEN 18 AND 36;


SELECT ST_MetaData(rast) FROM slope;


















