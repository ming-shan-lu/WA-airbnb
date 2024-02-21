/* 1. How many total listings are there in WA?
 * 2. Which areas have the most Airbnb Units in WA and what is the price range ?
 * 3. Do hosts rent out their entire home or just a room?
 * 4. Have hosts used Airbnb as a platform for long-term rental to avoid regulations or accountability?
 */


## DATA PREPARATION ------------------------------------------------------------------

# Check for collect import of rows:11,507

SELECT 
Count(*)
FROM airbnb_wa.listings l ;

# Check for numbers of columns: 18

SELECT COUNT(column_name) 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'airbnb_wa'
  AND TABLE_NAME = 'listings'

# Change datatypes

ALTER TABLE airbnb_wa.listings  
MODIFY COLUMN host_id VARCHAR(200);


UPDATE airbnb_wa.listings 
SET last_review = STR_TO_DATE(last_review, '%d/%m/%y')
WHERE last_review IS NOT NULL AND last_review !='';

## -----     1. How many total listings are there in WA?     --------------
/* To determine inactive hosts, column 'availability_365' and 'number_of_reviews' both = 0
 * Active listing: 11415, 92 inactive  
 * (The folloing analysis will not exclude inactive listings)
 */ 

#  92 inactive  

SELECT 
COUNT(*) AS inactive_listings
FROM airbnb_wa.listings 
WHERE  (availability_365  = 0 AND number_of_reviews = 0);


#  Active listing: 11,415

SELECT 
COUNT(* )
FROM airbnb_wa.listings 
WHERE NOT (availability_365  = 0 AND number_of_reviews = 0);


# Total 6320 distinct hosts in WA

SELECT 
 COUNT(DISTINCT(host_id)) AS total_hosts
FROM airbnb_wa.listings;

/*listing_host and the percentage of listings: 
 * OVER half of hosts have more than 1 listing
 * 1412 (59.34% ) hosts have more than 1 listings (4908 hosts have 1 listing)
 */

-- How many listings do hosts have?

SELECT
  DISTINCT(host_id),
  host_name,
  calculated_host_listings_count AS total_listings
FROM  airbnb_wa.listings
ORDER BY total_listings DESC;


DROP TABLE IF EXISTS distinct_host;
CREATE TEMPORARY TABLE distinct_host
SELECT
  DISTINCT(host_id),
  host_name,
  calculated_host_listings_count AS total_listings,
  ROUND((100.0 * calculated_host_listings_count / total_count.total_listings_count), 2) AS percentage_of_total_listings
FROM 
 airbnb_wa.listings 
CROSS JOIN (
  SELECT COUNT(calculated_host_listings_count) AS total_listings_count
  FROM airbnb_wa.listings 
) AS total_count
ORDER BY
  total_listings DESC;
 
SELECT *
FROM distinct_host;

SELECT
COUNT(host_id) AS number_of_host,
ROUND(SUM(percentage_of_total_listings),2) AS percentage_of_listing
FROM distinct_host
WHERE total_listings >1;



## -------    2. Which areas have the most Airbnb Units in WA and what is the price range ?   ------------

# There are 112 areas listing in WA 

SELECT 
COUNT(DISTINCT neighbourhood) AS areas
FROM airbnb_wa.listings; 

/*number of listings by area:
 * Busselton has the most listings of 1560,
 * then Augusta-Margaret River: 884 and Fremantle: 884 
 */

SELECT 
 neighbourhood,
 COUNT(*) AS num_listing
FROM airbnb_wa.listings 
GROUP BY neighbourhood
ORDER BY num_listing DESC;


# average price: $ 264
# ROOM TYPE :83% are entire home/apt, 16% private room


SELECT 
 ROUND((AVG(price)), 0) AS avg_price
FROM airbnb_wa.listings; 

SELECT 
room_type,
COUNT(*) AS room_type_count,
ROUND(100 * COUNT(*)/ (SELECT COUNT(*) FROM airbnb_wa.listings),2) AS percentage,
ROUND(AVG(price),0) AS avg_price
FROM airbnb_wa.listings 
GROUP BY room_type
ORDER BY avg_price DESC;

##------     3. Do hosts rent out their entire home or just a room?--------------- 

#average price of room type in suburbs: WAROONA top the average price of $1,516.97

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price), 0) AS avg_price
FROM airbnb_wa.listings 
GROUP by neighbourhood, room_type
ORDER BY avg_price DESC;

# Entire Home/apt: Waroona has 4 listings of Entire Home/apt price $10,000 (Camper/RV in Lake Clifton)

SELECT 
 name,
 host_id,
 neighbourhood,
 room_type,
 price 
FROM airbnb_wa.listings 
WHERE neighbourhood = 'WAROONA'
ORDER BY price DESC;

# average price of Waroona become $260 after excluded $10,000 (Camper/RV in Lake Clifton)
SELECT 
ROUND(AVG(price), 0) AS avg_price
FROM airbnb_wa.listings l 
WHERE neighbourhood  = 'WAROONA'
AND  host_id  <> '367775749' 


# Entire Home/apt: Kalgoolie $604, Broome $529, Shark Bay $521
SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(CASE WHEN host_id = '367775749' THEN NULL 
      ELSE price 
      END), 0) AS avg_price
FROM airbnb_wa.listings 
GROUP by neighbourhood, room_type
HAVING room_type = 'Entire home/apt'
ORDER BY avg_price DESC;



# Hotel room price top 3 : BROOME $447, JOONDALUP: 327.2, FREMANTLE & CHITTERING $299
# 1 listing in Broome top the price of $447

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price), 0) AS avg_price
FROM airbnb_wa.listings 
GROUP by neighbourhood, room_type
Having room_type = 'Hotel room'
ORDER BY avg_price DESC;

SELECT 
 *
FROM airbnb_wa.listings 
WHERE room_type = 'Hotel room'
  AND neighbourhood  = 'BROOME';

# Private room price top 3: $298.42(AUGUSTA-Margaret Rive) $291.71(DERBY-West Kimberley) $286.57(DARDANUP)
# host Michael in Augusta-Margaret River is a hotel and has a room cost $10,572

 SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price), 0) AS avg_price
FROM airbnb_wa.listings
GROUP by neighbourhood, room_type
Having room_type = 'Private room'
ORDER BY avg_price DESC;
 


SELECT AVG(price)
--  name,
--  price,
--  room_type 
FROM airbnb_wa.listings l 
WHERE name LIKE '%Hotel%'

 SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(CASE WHEN name LIKE '%Hotel%' THEN NULL ELSE price END), 0) AS avg_price
FROM airbnb_wa.listings
GROUP by neighbourhood, room_type
Having room_type = 'Private room'
ORDER BY avg_price DESC;

# if omit the listing of $10,572, avg_rpice = $263.36
SELECT 
 AVG(CASE WHEN latitude = -33.97177382 AND longitude = 115.0988653 THEN NULL 
      ELSE price 
      END) AS avg_price
FROM airbnb_wa.listings
 
# Shared room Top 3: $999(CHITTERING) $137(ROCKINGHAM) $110(BUSSELTON)
#  Chittering 1 listing of shared room costed $999

SELECT 
neighbourhood AS suburb,
room_type,
ROUND(Avg(price), 0) AS avg_price
FROM airbnb_wa.listings
GROUP by neighbourhood, room_type
Having room_type = 'Shared room'
ORDER BY avg_price DESC;

SELECT
 *
FROM airbnb_wa.listings 
WHERE room_type = 'Shared room' AND neighbourhood = 'CHITTERING'  
ORDER BY price DESC;


##-----   4. Have hosts used Airbnb as a platform for long-term rental to avoid regulations or accountability?   --------------

# 4.1: Serviced apartments: funished rentals for long-term stays (no shared room)

SELECT 
*
FROM airbnb_wa.listings l 
WHERE name LIKE 'serviced%';

SELECT 
room_type,
COUNT(*) AS count_of_roomtype,
ROUND(AVG(price),0) AS avg_price_serviced_apt
FROM airbnb_wa.listings 
WHERE name LIKE 'Serviced%'
GROUP BY room_type;


# 4.2 minimum night stay of 1 week: 97%, and over a month : 1%

SELECT
  night_range,
  COUNT(*) AS listing_count,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_of_listing_count,
  ROUND(AVG(price), 0) AS average_price 
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
    ELSE 'Over a month'
    END AS night_range
  FROM airbnb_wa.listings
) AS subquery
GROUP BY night_range
ORDER BY night_range;

/* 149 listings hhve minimum stay of 30 days and above
 * room type: 85% Entired home/apt (126), 15% private/shared room (23)
 */

SELECT
 name,
 neighbourhood,
 room_type,
 price,
 minimum_nights
FROM airbnb_wa.listings
WHERE minimum_nights >= 25
ORDER BY minimum_nights  DESC;

