--1/Spatial Indexing
--index: bounding box içinde neler var (bu yüzden yaklaşık sonuçlar sağlar )

--İstatistikleri güncellemek için  toplu veri yükleme ve silme işlemlerinden sonra:
ANALYZE nyc_census_blocks;

-- Büyük bir toplu güncelleme yapıldığında, VACUUM manuel olarak çalıştırılmalı (kullanılmayan alanları kaldırmak için)
VACUUM ANALYZE nyc_census_blocks;

--VACUUM komutunun verilmesi veritabanı istatistiklerini güncellemeyecektir; aynı şekilde ANALYZE komutunun verilmesi de kullanılmayan tablo satırlarını kaldırmaz

--bazı fonksiyonlar index içermez onlarda && ( Index-Only) kullan

/*
&&  bbox lar kesişiyor mu
<-> arasındaki mesafe 
<#> bbox lar arasındaki mesafe
|=| en yakın noktaları arasındaki mesafe
*/
 

--2/Projecting Data

--tanımlı srid gösterme
SELECT ST_SRID(geom) FROM poi group by st_srid(geom);

--Transform
--sadece görünüm oluşturur
SELECT ST_AsText(ST_Transform(geom,5255),4326)
FROM poi;

-- yeni crs kolonu ekleyip yazdırdık
ALTER TABLE poi
ADD COLUMN geom2 geometry;
update poi set geom2 = st_transform(geom, 3857);



-- 3/Spatial Joins

-- Kozlu Ortaoku adres verileri
SELECT
 ST_AsText(poi.geom) xy,
 poi.name  name,
 p.ilce  ilce,
 p.mahalle  mahalle
FROM parsel5255 p
JOIN poi
ON ST_Contains(p.geom, poi.geom)
WHERE poi.name  = 'Kozlu Ortaokulu' ;



--4/Spatial Relationships
/*ST_Intersects : herhangi bir şekilde kesişiyor
ST_Disjoint:ayrık
ST_Crosses:içine dahil olmak şartıyla(sınır kabul edilmez)  
ST_Touches:sadece sınırdan kesişmeli
ST_DWithin:hayali buffer ile mesafe hesabı*/

--fatih sınırının  fay hattlarnın en yakın uzaklıkları
SELECT ST_Distance(heyelanb_5255.geom, fay_hatlari5255.geom)
from heyelanb_5255,fay_hatlari5255

--kozlu ortaokulu hangi mahallede ve ilçede?
SELECT mahalle, ilce
FROM parsel5255
WHERE ST_Intersects(geom, (SELECT geom FROM poi WHERE name = 'Kozlu Ortaokulu'));

--ANA YOLA 20m MESAFE İÇERİSİNDEKİ YAPI sayısı
SELECT COUNT(*) 
FROM yapi5255
WHERE ST_DWithin(geom, (SELECT geom FROM ulasim5255 WHERE genislik = 40), 20)
;
--ANA YOLA 20m MESAFE İÇERİSİNDEKİ yapılar
SELECT geom
FROM yapi5255
WHERE ST_DWithin(geom, (SELECT geom FROM ulasim5255 WHERE genislik = 40), 20);

--akaryakıt istasyonunun ATM lere uzaklıkları (km)
SELECT atm.name, ST_Distance(atm.geom, a.geom)/1000 AS uzaklik
FROM poi atm, poi a
WHERE atm.type = 3 AND a.type = 4
order by uzaklik desc;



--5/Geometry 
--toplam yol uzunluğu(km)
SELECT Sum(ST_Length(geom)) / 1000
  FROM ulasim5255;

--toplam ormanlık alan (hektar)
SELECT Sum(ST_Area(geom)) / 4047
  FROM alankullanimlari5255
where ad = 'Ormanlik_Alan';

--yol tiplerinin uzunlukları
SELECT genislik, Sum(ST_Length(geom)) AS length
FROM ulasim5255
GROUP BY genislik
ORDER BY length DESC;

--yapıların orta nokta koordinatları
--ağırlık merkezleri
select st_astext(st_centroid(geom))::geometry from yapi5255;
--geometrinin içinde olmaya zorlar
select st_astext(ST_PointOnSurface(geom)) from yapi5255;


--ATM ile akaryakıt istasyonu arasındaki mesafe
select atm.name atm,a.name istasyon,
st_distance(atm.geom,a.geom) uzaklik_m
from poi atm, poi a
where a.name='Opet Kozlu'  and atm.name='Ziraat Bankası ATM'; 


--simplfy
 SELECT ST_Simplify(geom, 0.1)   FROM fatih_s5255; 
 
 --DISTINCT, sonuçtan yinelenen s atırları ortadan kaldırır.



