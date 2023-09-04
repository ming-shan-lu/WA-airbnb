/* 1. How many total listing are there in WA?
 * 2. Do hosts rent out their entire home or just a room?
 * 3. Have hosts using airbnb as a platform for long-term rental to avoid regulations or accountability?
 * 2. Where are the most Airbnb Units in WA?
 * 
 */


## DATA PREPARATION ------------------------------------------------------------------

# Check for collect import of rows:11,507

SELECT 
COUNT(*)
FROM airbnb_wa.`listings.csv` lc ;

# Check for duplicates: NONE (rows:11,507)

SELECT DISTINCT COUNT(*)
FROM airbnb_wa.`listings.csv` lc;

# Change datatypes

ALTER TABLE airbnb_wa.`listings.csv`  
MODIFY COLUMN host_id varchar(200);


UPDATE airbnb_wa.`listings.csv` 
SET last_review = STR_TO_DATE(last_review, '%d/%m/%Y')
WHERE last_review IS NOT NULL AND last_review !='';

##------------------------------------------------------------------------------------
/* To determine inactive hosts, column 'availability_365' and 'number_of_reviews' both = 0
 * Active listing: 11415, 92 inactive  
 * (The following analysis will not exclude inactive listings)
 */ 

#  92 inactive  

SELECT 
COUNT(*) 
FROM airbnb_wa.`listings.csv` lc 
WHERE  (availability_365  = 0 AND number_of_reviews = 0);


#  Active listing: 11,415

SELECT 
COUNT(* )
FROM airbnb_wa.`listings.csv` lc 
WHERE NOT (availability_365  = 0 AND number_of_reviews = 0);


# Total 6320 distinct hosts in WA

SELECT 
 COUNT(DISTINCT(host_id))
FROM airbnb_wa.`listings.csv` lc;

/*listing_host and the percentage of listings: 
 * OVER half of hosts have more than 1 listing
 * 1412 (57.35% ) hosts have more than 1 listings (4908 hosts have 1 listing)
 */

USE airbnb_wa;
DROP TABLE IF EXISTS distinct_host;
CREATE TEMPORARY TABLE distinct_host
SELECT
  DISTINCT(lc.host_id),
  lc.host_name,
  lc.calculated_host_listings_count AS total_listings,
  (100.0 * lc.calculated_host_listings_count / total_count.total_listings_count) AS percentage_of_total_listings
FROM
  airbnb_wa.`listings.csv` lc
CROSS JOIN (
  SELECT COUNT(calculated_host_listings_count) AS total_listings_count
  FROM airbnb_wa.`listings.csv` lc
) AS total_count
ORDER BY
  total_listings DESC;
 
SELECT
COUNT(host_id),
ROUND(SUM(percentage_of_total_listings),2) 
FROM distinct_host
WHERE total_listings >1;


# There are 112 areas listed in WA 
	
SELECT 
COUNT(DISTINCT neighbourhood) AS areas
FROM airbnb_wa.`listings.csv` lc; 

/*number of listings by area:
 * Busselton has the most listings of 1560,
 * then Augusta-Margaret River: 884 and Fremantle: 884 
 */

SELECT 
 neighbourhood,
 COUNT(*) AS no_listing
FROM airbnb_wa.`listings.csv` lc 
GROUP BY neighbourhood
ORDER BY no_listing DESC;

##-------------------------------------------------------------
## ROOM TYPE:83% are entire home/apt, 16% private room
# Average price of room type

SELECT 
room_type,
COUNT(*) AS room_type_count,
ROUND(100 * COUNT(*)/ (SELECT COUNT(*) FROM airbnb_wa.`listings.csv` lc2 ),2) AS percentage,
ROUND( AVG(price),2) AS avg_price
FROM airbnb_wa.`listings.csv` lc 
GROUP BY room_type
ORDER BY avg_price DESC;

# Serviced apartments: furnished rentals for long-term stays (no shared room)

SELECT 
room_type,
avg(price) AS avg_price_serviced_apt
FROM airbnb_wa.`listings.csv` lc 
WHERE name LIKE 'Serviced%'
GROUP BY room_type;

# Average price of room type in suburbs: WAROONA tops the average price of $1,516.97

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price),2) AS avg_price
FROM airbnb_wa.`listings.csv` lc 
GROUP by neighbourhood, room_type
-- Having room_type = 'Entire Home/apt'
ORDER BY avg_price DESC;

# Entire Home/apt: Waroona has 4 listings of Entire Home/apt price $10,000 (Camper/RV in Lake Clifton)

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price),2) AS avg_price
FROM airbnb_wa.`listings.csv` lc 
GROUP by neighbourhood, room_type
Having room_type = 'Entire Home/apt'
ORDER BY avg_price DESC;

SELECT
 *
FROM airbnb_wa.`listings.csv` lc 
WHERE room_type = 'Entire Home/apt' AND neighbourhood = 'WAROONA'
ORDER BY price DESC;

# Hotel room price top 3: BROOME $447, JOONDALUP: 327.2, FREMANTLE & CHITTERING $299
# 1 listing in Broome top the price of $447

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price),2) AS avg_price
FROM airbnb_wa.`listings.csv` lc 
GROUP by neighbourhood, room_type
Having room_type = 'Hotel room'
ORDER BY avg_price DESC;

SELECT 
 *
FROM airbnb_wa.`listings.csv` lc 
WHERE room_type = 'Hotel room'
  AND neighbourhood  = 'BROOME';

# Private room price top 3: $298.42(AUGUSTA-Margaret Rive) $291.71(DERBY-West Kimberley) $286.57(DARDANUP)
# Host Michael in Augusta-Margaret River is a hotel and has a room cost of $10,572

 SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price),2) AS avg_price
FROM airbnb_wa.`listings.csv` lc 
GROUP by neighbourhood, room_type
Having room_type = 'Private room'
ORDER BY avg_price DESC;
 
 SELECT
 *
FROM airbnb_wa.`listings.csv` lc 
WHERE room_type = 'Private room' 
  AND neighbourhood = 'AUGUSTA-MARGARET RIVER' 
  AND host_id = 519965361
ORDER BY price DESC;

# if omit the listing of $10,572, avg_rpice = $263.36
SELECT 
 AVG(CASE WHEN latitude = -33.97177382 AND longitude = 115.0988653 THEN NULL 
      ELSE price 
      END) AS avg_price
FROM airbnb_wa.`listings.csv` lc
 
# Shared room Top 3: $999(CHITTERING) $137(ROCKINGHAM) $110(BUSSELTON)
#  Chittering 1 listing of shared room costed $999

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price),2) AS avg_price
FROM airbnb_wa.`listings.csv` lc 
GROUP by neighbourhood, room_type
Having room_type = 'Shared room'
ORDER BY avg_price DESC;

SELECT
 *
FROM airbnb_wa.`listings.csv` lc 
WHERE room_type = 'Shared room' AND neighbourhood = 'CHITTERING'  
ORDER BY price DESC;

##----------------------------------------------------------------------------------
# minimum night stay of 1 week: 97%, and over a month : 1%

SELECT 
host_id,
host_name,
neighbourhood,
room_type,
price,
minimum_nights,
(CASE 
    WHEN minimum_nights BETWEEN 1 AND 7 THEN '1 week'
    WHEN minimum_nights BETWEEN 8 AND 14 THEN '2 weeks'
    WHEN minimum_nights BETWEEN 15 AND 28 THEN '3-4 weeks'
    WHEN minimum_nights BETWEEN 30 AND 1000 THEN 'Over a month'
	 ELSE 'Unknown' 
END) AS night_range,
COUNT(minimum_nights) OVER(PARTITION BY 
(CASE 
    WHEN minimum_nights BETWEEN 1 AND 7 THEN '1 week'
    WHEN minimum_nights BETWEEN 8 AND 14 THEN '2 weeks'
    WHEN minimum_nights BETWEEN 15 AND 28 THEN '3-4 weeks'
    WHEN minimum_nights BETWEEN 30 AND 1000 THEN 'Over a month'
	 ELSE 'Unknown' 
END) 
) AS night_range_sum
FROM airbnb_wa.`listings.csv` lc;

SELECT
  night_range,
  COUNT(*) AS listing_count,
  100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS percentage_of_listing_count,
  AVG(price) AS average_price
  -- SUM(minimum_nights) AS total_minimum_nights   
FROM (
  SELECT 
    host_id,
    host_name,
    neighbourhood,
    room_type,
    price,
    minimum_nights,
    CASE 
      WHEN minimum_nights BETWEEN 1 AND 7 THEN '1 week'
      WHEN minimum_nights BETWEEN 8 AND 14 THEN '2 weeks'
      WHEN minimum_nights BETWEEN 15 AND 28 THEN '3-4 weeks'
      WHEN minimum_nights BETWEEN 30 AND 1000 THEN 'Over a month'
      ELSE 'Unknown'
    END AS night_range
  FROM airbnb_wa.`listings.csv` lc
) AS subquery
GROUP BY night_range
ORDER BY night_range;

/* 149 listings have a minimum stay of 30 days and above
 * Room type: 85% Entired home/apt (126), 15% private/shared room (23)
 */

SELECT
 name,
 neighbourhood,
 room_type,
 price,
 minimum_nights
FROM airbnb_wa.`listings.csv` lc 
WHERE minimum_nights >= 30 
ORDER BY minimum_nights  DESC;

