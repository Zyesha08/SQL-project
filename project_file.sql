create database airport_db;

use airport_db;
select * from airports2;

-- Problem Statement 1
select
	Origin_airport,
    destination_airport,
    sum(passengers) as total_passengers
from
	airports2
    group by Origin_airport,
    destination_airport
    order by total_passengers desc;
    
-- Problem Statement 2
  /*Seats occupancy of fights and which flights have maximum occupancy*/
  
 select
	Origin_airport,
    avg(passengers )
from
	airports2 
    group by origin_airport;
 
  select
	Origin_airport,
    Destination_airport,
    
  concat(round(avg(passengers/seats)*100,2)," %") as avg_seat_utilization
from
	airports2
    group by Origin_airport,
    Destination_airport
    order by 
    avg_seat_utilization desc ; 

-- Problem Statement 3
/*Most frequent travel route
 -- To optimize resource allocation
 -- Enhance the service */
 
 select 
	origin_airport,
    destination_airport,
    sum(passengers) as total_passengers
    
from airports2
group by 
origin_airport,
destination_Airport
order by 
total_passengers desc
limit 3;

-- Problem Statment 3
/* Find out activity level at various origin citites
-- To find out key hub
-- To take decisions for some flight operations and capacity management*/

select
	origin_city,
    count(flights) as total_flights,
    sum(passengers) as total_passengers
from airports2
group by
origin_city
order by 
total_flights desc;

-- Problem Statement 5
/* Want to look into travel pattern and also calculate future route planning*/

select
	origin_airport,
    sum(distance) as total_distance
from airports2
group by
	origin_airport
order by 
    total_distance desc;
    
-- Problem Statement 6
/* Find out seasonal trend
-- Average distance travelled per month*/

select
	year(fly_date) as year_,
    month(fly_date) as month_,
    count(flights) as total_flights,
    sum(passengers) as total_passengers,
    avg(distance) as avg_distance
 from
	airports2
group by
	year_ , month_
order by 
year_ desc , month_ desc;

-- Problem Statement 7
/* Find under utilized routes 
-- To make proper capacity management
-- to adjust route adjustment  */

select
	origin_airport,
    destination_airport,
    sum(passengers) as total_passengers,
    sum(seats) as total_seats,
    (sum(passengers)/nullif(sum(Seats),0)) as passenger_to_seat_ratio
from
	airports2
    
group by 
	origin_airport,
    destination_airport
having
	passenger_to_seat_ratio < 0.5
order by
	passenger_to_seat_ratio;
    
-- Problem Statement 8
/* Find most active airport and the airport where highest frequency of flights
-- airline & stakeholder can optimize
-- flight scheduling & they can improve sources  */

select
	origin_airport,
	count(flights) as total_flights
    
from 
airports2
group by origin_airport
order by
total_flights desc
limit 3;

-- Problem Statement 9
/* Find the flights from different locations to the destined "Bend, OR" location */
select
	origin_city,
    count(flights) as total_flights,
    sum(passengers) as total_passengers
from
airports2
where 
	destination_city ="Bend, OR" and
    origin_city <> "Bend, OR"
group by
origin_city
order by 
total_flights desc,
total_passengers desc
limit 10;

-- Problem Statement 10
/* Maximum extensive travel connection
Flight which is travel max. distance */

select 
	origin_airport,
    destination_airport,
   max(distance) as long_distance
from
airports2
group by
origin_airport,
destination_airport
order by 
long_distance desc
limit 1;

-- Problem Statement 11
/* To do analysis on seasonal trends in travel
Analyse the most and least count of flights across multiple years */

with monthly_flight as (
select 
month(fly_Date) as month_,
count(flights) as total_flights

from airports2
group by month_
order by
total_flights
)
select 
	month_,
    total_flights,
    case
		when total_flights = (select max(total_flights) from monthly_flight)
        then "most busy"
        when total_flights = (select min(total_flights) from monthly_flight)
        then "least busy"
        else null 
        end as status
	from 
    monthly_flight
    where 
    total_flights = (select max(total_flights) from monthly_flight) or
	total_flights = (select min(total_flights) from monthly_flight);
    
    
-- Problem Statement 12
/* Analysis on passengers traffic trend over time
-- Help us in making decisions in
rate development
capacity management
requirement adjustment based on the coming demand */

with passenger_summary as(
select
origin_airport,
destination_airport,
year(fly_date) as year_,
sum(passengers) as total_passengers
from
airports2
group by
origin_airport,
destination_airport,
year_),
passenger_growth as (
select 
origin_airport,
destination_airport,
year_,
total_passengers,
lag(total_passengers) over (partition by origin_airport,destination_airport order by year_) as previous_year_data
from
passenger_summary)
select 
	origin_airport,
destination_airport,
year_,
total_passengers,
case
when previous_year_data is not null then 
((total_passengers-previous_year_data)*100.0 / nullif(previous_year_data,0))
end as growth
from
passenger_growth
order by 
origin_airport,destination_airport,year_;

-- Problem Statement 13
/* Find consistent growth and growth in percentage of trending route
from origin to destination to find year to year growth */

with summary_flight as (
select
	origin_airport,
    destination_airport,
    year(fly_date) as year_,
    count(flights) as total_flights
from
airports2
group by
origin_airport,
destination_airport,
year(fly_date)
),
flight_growth as (
select
	origin_airport,
    destination_airport,
    year_,
    total_flights,
    lag(total_flights) over (partition by origin_airport,destination_airport order by year_)
    as previous_year_flight
    from summary_flight),
    
growth_rates as (
    select
	origin_airport,
    destination_airport,
    year_,
    total_flights,
    case
    when previous_year_flight is not null and previous_year_flight >0 then
    ((total_flights-previous_year_flight)*100/previous_year_flight)
    else null
    end as growth_rate,
    case
    when previous_year_flight is not null and total_flights>previous_year_flight then
    1
    else 0
end as growth_indicator
from 
flight_growth)
select 
	origin_airport,
    destination_airport,
    max(growth_rate) as max_growth_rate,
    min(growth_rate) as min_growth_rate
from
    growth_rates
where
	growth_indicator=1
group by
	origin_airport,
    destination_airport
having
	min(growth_indicator)=1
order by
	origin_airport,
    destination_airport ;
    
-- Problem Statement 14
/* Find passengers to seat having good ratio
based on total no. of flights(performance)
wants to see operational efficiency + flight volume */

with utilization_ratio as (
select
	origin_airport,
    sum(passengers) as total_passengers,
    sum(seats) as total_seats,
    count(flights) as total_flights, 
    sum(passengers)*1.0/sum(seats) as passengers_to_seat_ratio
from 
airports2
group by 
origin_airport),
weighted_utilization as
(select 
	origin_airport,
	total_passengers,
    total_seats,
    total_flights,
	passengers_to_seat_ratio,
(passengers_to_seat_ratio*total_flights) / sum(total_flights)
over () as Weighted_utilization
from 
utilization_ratio )
select
origin_airport,
	total_passengers,
    total_seats,
    total_flights,
    Weighted_utilization
from
weighted_utilization
order by Weighted_utilization desc
limit 3;

-- Problem Statement
/* Find out seasonal travel patterns to specific city
-- peak traffic month from each city with highest number of passengers travelling
-- if more than 1 month has same passenger counts we will find all passenger details*/

with monthly_passenger_count as 
(select
	origin_city,
    month(fly_date) as month_,
    year(fly_date) as year_,
    sum(passengers) as total_passengers
from
	airports2
group by 
	origin_city,
	month_,
	year_),
max_passenger_per_city as (
select
origin_city,
max(total_passengers) as peak_passengers
from 
monthly_passenger_count
group by 
origin_city)
select 
	mpc.origin_city,
    mpc.year_,
    mpc.month_,
    mpc.total_passengers
from 
	monthly_passenger_count mpc
join
	max_passenger_per_city mppc
on
	mpc.origin_city = mppc.origin_city
and
	mpc.total_passengers = mppc.peak_passengers
order by
	mpc.origin_city,
    mpc.year_,
    mpc.month_;

-- Problem Statement 16
/* Find the Routes that demand is reduced
Identify the routes that have experienced largest decline in passengers year over year*/

with yearly_passengers as (
select
	origin_airport,
    destination_airport,
	year(fly_date) as year_,
    sum(passengers) as total_passengers
    
from
	airports2
group by
	origin_airport,
    destination_airport,
    year(fly_date)),
 yearly_decline as (   
select
	y1.destination_airport,
    y1.origin_airport,
    y1.year_ as year1,
    y1.total_passengers as passenger_year1,
    y2.year_ as year2,
    y2.total_passengers as passenger_year2,
    ((y2.total_passengers - y1.total_passengers) / nullif(y1.total_passengers,0))*100 as percentage_change
from
yearly_passengers y1
join
yearly_passengers y2
on
y1.origin_airport = y2.origin_airport 
and
y1.destination_airport=y2.destination_airport
and 
y1.year_=y2.year_+1)
select
	destination_airport,
    origin_airport,
    year1,
    passenger_year1,
    year2,
    passenger_year2,
     percentage_change
from yearly_decline
where 
 percentage_change < 0 and passenger_year2>0 -- only decline routes
 order by 
 percentage_change
 limit 5;

-- Problem Statement 17
/* Highlight the underperforming routes */

with flight_stat as (
select
	origin_airport,
    destination_airport,
    sum(seats) as total_seats,
    count(flights) as total_flights,
    sum(passengers) as total_passengers,
    (sum(passengers)/nullif(sum(seats),0)) as avg_passenger
from
airports2
group by
origin_airport,
destination_airport)
select
	origin_airport,
    destination_airport,
    total_seats,
    total_passengers,
    total_flights,
    round((avg_passenger*100),2) as avg_seat_percent
from
flight_stat
where total_seats>10
and
 round((avg_passenger*100),2) <50
order by
avg_seat_percent desc;

-- Problem Statement 18
/* longest avg distance route
-- Insights to the airlines for long-haul travel pattern*/

with dist_stat as 
(select
	origin_city,
    destination_city,
    avg(distance) as avg_flight_distance
from airports2
group by 
origin_city,
destination_city)
select
	origin_city,
    destination_city,
    round((avg_flight_distance*100),0) as avg_flight_distance
from dist_stat
order by avg_flight_distance desc;

-- Problem Statement 19
/* Overview the annual trend
-- to calculate the total number of flights & passengers for each year
-- to calculate the growth in %   */

with yearly_flight as (
select 
	year(fly_date) as year_,
	count(flights) as total_flights,
    sum(passengers) as total_passengers
from
	airports2
group by
	year_),
growth_yearly as (
select
	year_,
	total_flights,
	total_passengers,
    lag(total_flights) over (order by year_) as prev_flights,
    lag(total_passengers) over (order by year_) as prev_passengers
from
yearly_flight)
select
	year_,
	total_flights,
	total_passengers,
    round(((total_flights - prev_flights)/nullif(prev_flights,0)*100),2) as flights_growth_percent,
     round(((total_passengers - prev_passengers)/nullif(prev_passengers,0)*100),2) as passenger_growth_percent
    from 
	growth_yearly
    order by
    year_ ;
    
-- Problem Statement 20
/* Find the most significant route in terms of
1. distance
2. on the basis of operational activities

** Find the busy route i.e top 3-5 */

with route_dist as (
select
	origin_airport,
    destination_airport,
    sum(distance) as total_distance,
    sum(flights) as total_flights
from 	
	airports2
group by
origin_airport,
destination_airport),
weighted_dist as (
select
	origin_airport,
    destination_airport,
    total_distance,
    total_flights,
    total_distance*total_flights as weighted_distance
from
	route_dist)
select 
	origin_airport,
    destination_airport,
    total_distance,
    total_flights,
    weighted_distance
from
	weighted_dist
order by 
	weighted_distance desc
limit 3;