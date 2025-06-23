
--1. How many pizzas were ordered?
select COUNT(*) as total_pizzas_ordered
from customer_orders;

--2. How many unique customer orders were made?
select count(distinct customer_id)as no_of_unique_customer_orders
from customer_orders;

--3. How many successful orders were delivered by each rider?
select rider_id, count(*) as num_of_orders_placed_successfully 
from rider_orders
where cancellation IS NULL OR cancellation = ''
group by rider_id;

--4. How many of each type of pizza was delivered?
select pn.pizza_name, count(co.order_id) as number_of_pizzas_delivered
from customer_orders co join
rider_orders ro ON co.order_id = ro.order_id
join pizza_names pn ON
co.pizza_id = pn.pizza_id
where ro.cancellation IS NULL OR ro.cancellation = ''
group by(pn.pizza_name);


--5. How many 'Paneer Tikka' and 'Veggie Delight' pizzas were ordered by each customer?
Select co.customer_id,pn.pizza_name,
COUNT(pn.pizza_name) as NumOfPizzas
from customer_orders co Join
pizza_names pn on co.pizza_id = pn.pizza_id
GROUP BY co.customer_id, pn.pizza_name
Order By co.customer_id;

--6. What was the maximum number of pizzas delivered in a single order?
WITH C1 AS(
Select co.order_id, 
COUNT(co.order_id) as number_of_pizzas_ordered
from customer_orders co join
rider_orders ro on co.order_id = ro.order_id
where ro.cancellation IS NULL OR ro.cancellation = ''
GROUP BY co.order_id
)
SELECT MAX(number_of_pizzas_ordered) as max_num_of_pizzas_ordered
FROM C1;

--7. For each customer, how many delivered pizzas had at least 1 change 
--(extras or exclusions) and how many had no changes?
WITH C AS(
SELECT co.*
FROM customer_orders co join
rider_orders ro ON co.order_id = ro.order_id
where ro.cancellation IS NULL OR ro.cancellation = ''),
C1 AS(
SELECT customer_id,COUNT(order_id) as no_changes FROM customer_orders
WHERE (exclusions IS NULL OR exclusions = '') AND
(extras IS NULL OR extras = '')
GROUP BY customer_id),
C2 AS(
SELECT customer_id, COUNT(order_id) as with_changes FROM customer_orders
WHERE ISNULL(exclusions,'') != '' OR
ISNULL(extras,'') != ''
GROUP BY customer_id)
SELECT C.customer_id, ISNULL(C1.no_changes,0) pizzas_with_no_changes,
ISNULL(C2.with_changes,0) pizzas_with_changes
From C left join C1 ON C.customer_id = C1.customer_id
left join C2 ON C.customer_id = C2.customer_id
group by c.customer_id, c1.no_changes, c2.with_changes;

--8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(co.pizza_id) num_of_pizzas_with_changes
FROM customer_orders co join
rider_orders ro ON co.order_id = ro.order_id
where (ro.cancellation IS NULL OR ro.cancellation = '') AND
(ISNULL(exclusions,'') != '' AND ISNULL(extras,'') != '')

--9. What was the total volume of pizzas ordered for each hour of the day? ** datepart use 
WITH C AS(
SELECT 1 AS Hour
UNION ALL
SELECT Hour + 1
FROM C
WHERE Hour < 24
)
SELECT c.Hour,
COUNT(order_id)as Num_of_pizzas_ordered
FROM customer_orders co right join C c 
ON c.Hour = DATEPART(HOUR,co.order_time)
GROUP BY c.Hour;

--10. What was the volume of orders for each day of the week? **datename use krna hai
WITH C AS(
SELECT 1 AS DAY
UNION ALL
SELECT DAY + 1
FROM C
WHERE DAY < 7
)
SELECT c.DAY,
COUNT(order_id)as Num_of_pizzas_ordered
FROM customer_orders co right join C c 
ON c.DAY = DATEPART(WEEKDAY,co.order_time)
GROUP BY c.DAY

--11. How many riders signed up for each 1-week period starting from 2023-01-01? handle week number using +1
SELECT DATEPART(WEEK,registration_date) week_num, COUNT(rider_id) as num_of_riders_signed_up
FROM riders
WHERE registration_date >= '2023-01-01'
GROUP BY DATEPART(WEEK,registration_date);

--datedif(week, '2023-01-01', registration_date)  + 1


--12. What was the average time in minutes it took for each rider to arrive at Pizza Delivery HQ to pick up the order?
SELECT ro.rider_id,
AVG(DATEDIFF(MINUTE, co.order_time, ro.pickup_time)) avg_time_in_minutes
FROM customer_orders co join rider_orders ro
ON co.order_id = ro.order_id
GROUP BY ro.rider_id;

--select round avg time select distinct rider id 

--13. Is there any relationship between the number of pizzas in an order and how long it takes to prepare?
SELECT co.order_id, count(co.pizza_id) as num_of_pizzas,
DATEDIFF(Minute, co.order_time, ro.pickup_time) as prepare_time
FROM customer_orders co join
rider_orders ro ON co.order_id = ro.order_id
group by co.order_id, co.order_time, ro.pickup_time;


--handle null values



--14. What was the average distance traveled for each customer?
select co.customer_id, 
Avg(Cast(Replace(distance, 'km', '') AS FLOAT)) from 
customer_orders co join rider_orders ro
on co.order_id = ro.order_id
group by co.customer_id;

--15. What was the difference between the longest and shortest delivery durations across all orders?
WITH C AS(
SELECT MIN(CAST(LEFT(duration,2) as int)) shortest_duration,
MAX(CAST(LEFT(duration,2) as int)) longest_duration
FROM rider_orders)
SELECT *, (longest_duration-shortest_duration) diff_bw_duration from C;
   
--16. What was the average speed (in km/h) for each rider per delivery? Do you notice any trends? --condition check for canceled delivery
WITH C AS(
select rider_id, Cast(Replace(distance, 'km', '') AS FLOAT) as ndistance, 
CAST(LEFT(duration,2) as FLOAT)/60 as nduration
from rider_orders),
C1 AS(
select rider_id, (ndistance/nduration) as speed_per_rider
from C)
SELECT c.rider_id,  AVG(c1.speed_per_rider) 
FROM C c JOIN C1 c1 ON c.rider_id = c1.rider_id
group by c.rider_id;

--17. What is the successful delivery percentage for each rider?
with c as(
select rider_id,count(rider_id) as number_of_pizzas_delivered
from rider_orders
where cancellation IS NULL OR cancellation = ''
group by rider_id),
c1 as(
select rider_id,count(rider_id) as total_num_of_orders
from rider_orders group by rider_id)
select c.rider_id, c.number_of_pizzas_delivered, 
c1.total_num_of_orders, 
(CAST(c.number_of_pizzas_delivered as float)/cast(c1.total_num_of_orders as float)) * 100 as perc
from c1 join c on c1.rider_id = c.rider_id;

--18. What are the standard ingredients for each pizza?
with pizza_ingredient as(
select pn.pizza_id, pn.pizza_name, value as ingredient_id
from pizza_names pn join pizza_recipes pr
on pn.pizza_id = pr.pizza_id
cross apply string_split(pr.toppings, ',')
)
select pin.pizza_name, string_agg(pt.topping_name, ', ')
from pizza_ingredient pin join pizza_toppings pt
on pin.ingredient_id = pt.topping_id
group by pin.pizza_name;

--OR
select pn.pizza_name, STRING_AGG(pt.topping_name, ',') as standard_ingredients
from pizza_names pn join pizza_recipes pr
on pn.pizza_id = pr.pizza_id
cross apply string_split(pr.toppings,',') as split
join pizza_toppings pt on pt.topping_id = try_cast(ltrim(split.value) as int)
group by pn.pizza_name;

--string spilt, string agg, cross apply, try cast, string agg


--19. What was the most commonly added extra (e.g., Mint Mayo, Corn)?
with cte as(
select order_id, value as added_extra
from customer_orders
cross apply string_split(extras, ',')
where extras IS NOT NULL AND extras != '')
select top 1 pt.topping_name as most_added_extra
from cte c join pizza_toppings pt
on c.added_extra = pt.topping_id
group by pt.topping_name
order by count(pt.topping_name) desc;

--OR

with cte as(
select order_id, value as added_extra
from customer_orders
cross apply string_split(extras, ',')
where extras IS NOT NULL AND extras != ''),
cte1 as(
select pt.topping_name,
rank() over(order by count(pt.topping_name) desc) as rank
from cte c join pizza_toppings pt
on c.added_extra = pt.topping_id
group by pt.topping_name)

select topping_name as most_added_extra from cte1 where rank = 1


--20. What was the most common exclusion (e.g., Cheese, Onions)?
with cte as(
select order_id, value as exclusion
from customer_orders
cross apply string_split(exclusions, ',')
where exclusions IS NOT NULL AND exclusions != ''),
cte1 as(
select pt.topping_name,
rank() over(order by count(pt.topping_name) desc) as rank
from cte c join pizza_toppings pt
on c.exclusion = pt.topping_id
group by pt.topping_name)

select topping_name as most_excluded_ingredient from cte1 where rank = 1

--21. Generate an order item for each record in    the `customer_orders` table in the format:

--    * Paneer Tikka
--    * Paneer Tikka - Exclude Corn
--    * Paneer Tikka - Extra Cheese
--    * Veggie Delight - Exclude Onions, Cheese - Extra Corn, Mushrooms
with cte as(
select co.order_id, co.pizza_id, pn.pizza_name
from customer_orders co join pizza_names pn on co.pizza_id = pn.pizza_id
),
exclusion as(
select order_id, pizza_id, 'Exclude '+ STRING_AGG(pt.topping_name, ',') as excl_txt
from customer_orders
cross apply string_split(exclusions, ',') as str
join pizza_toppings pt on TRY_CAST(LTRIM(str.value) AS INT) = pt.topping_id
Where exclusions IS NOT NULL AND exclusions != ''
group by order_id, pizza_id
),
--select * from exclusion;
extra as(
select order_id, pizza_id, 'Extra '+ STRING_AGG(pt.topping_name, ',') as ext_txt
from customer_orders
cross apply string_split(extras, ',') as str
join pizza_toppings pt on TRY_CAST(LTRIM(str.value) AS INT) = pt.topping_id
Where extras IS NOT NULL AND extras != ''
group by order_id, pizza_id
)
--select * from extra;
select c.order_id, c.pizza_name + 
case 
when e.excl_txt IS NOT NULL THEN ' - ' + e.excl_txt
else
''
end +
case 
when e1.ext_txt IS NOT NULL THEN ' - ' + e1.ext_txt
else
''
end as order_item
from cte c
left join exclusion e on c.order_id = e.order_id and c.pizza_id = e.pizza_id
left join extra e1 on c.order_id = e1.order_id and c.pizza_id = e1.pizza_id;

--22. Generate an alphabetically ordered, comma-separated ingredient list for each pizza order, using "2x" for duplicates.
--    * Example: "Paneer Tikka: 2xCheese, Corn, Mushrooms, Schezwan Sauce"
with sdp as(
select co.order_id, co.pizza_id, co.exclusions, co.extras
from customer_orders co join rider_orders ro
on co.order_id = ro.order_id
where ro.cancellation IS NULL OR ro.cancellation = ''
),

toppings as(
select s.order_id, pt.topping_name
from sdp s join pizza_recipes pr
on s.pizza_id = pr.pizza_id
cross apply string_split(pr.toppings,',') as val
join pizza_toppings pt on trim(val.value) = pt.topping_id
),
--select * from toppings;

exclusions as(
select s.order_id, pt.topping_name
from sdp s
cross apply string_split(s.exclusions,',') as val
join pizza_toppings pt on trim(val.value) = pt.topping_id 
),

toppings_without_exclusions as(
select * from toppings
except
select * from exclusions
),
extra_toppings as(
select s.order_id, pt.topping_name
from sdp s
cross apply string_split(s.extras,',') as val
join pizza_toppings pt on trim(val.value) = pt.topping_id 
),
all_toppings as(
select order_id, topping_name from toppings_without_exclusions
union all
select order_id, topping_name from extra_toppings
),
--select * from all_toppings;

count_tps1 as(
select order_id, 
case when count(*) > 1 then concat(count(*), 'x', topping_name)
else topping_name
end as ing
from all_toppings
group by order_id, topping_name
),
--select * from count_tps1;

ing_list as(
select order_id, STRING_AGG(ing, ', ' ) within group(order by ing) as txt
from count_tps1
group by order_id)
--select * from ing_list;

select s.order_id, pn.pizza_name + ': ' + il.txt as toppings
from sdp s join pizza_names pn on s.pizza_id = pn.pizza_id
join ing_list il on s.order_id = il.order_id;


--23. What is the total quantity of each topping used in all 
--successfully delivered pizzas, sorted by most used first?
with sdp as(
select co.order_id, co.pizza_id, co.extras
from customer_orders co join rider_orders ro
on co.order_id = ro.order_id
where ro.cancellation IS NULL OR ro.cancellation = ''),

toppings as(
select s.order_id, pt.topping_id
from sdp s join pizza_recipes pr
on s.pizza_id = pr.pizza_id
cross apply string_split(pr.toppings,',') as split
join pizza_toppings pt on trim(split.value) = pt.topping_id),

extra_toppings as(
select s.order_id, pt.topping_id
from sdp s
cross apply STRING_SPLIT(s.extras, ',') AS split
join pizza_toppings pt 
on trim(split.value) = pt.topping_id
where s.extras IS NOT NULL AND s.extras != ''
),

all_toppings as(
select * from toppings
UNION ALL
select * from extra_toppings
)

select pt.topping_name, count(*) total_quantity
from all_toppings c join pizza_toppings pt on c.topping_id = pt.topping_id
group by pt.topping_name
order by count(*) desc;

--24. If a 'Paneer Tikka' pizza costs ₹300 and a 'Veggie Delight'
--costs ₹250 (no extra charges), how much revenue has Pizza Delivery
--India generated (excluding cancellations)?
with c as (
select co.pizza_id,
(case 
when co.pizza_id = 1 then 300 * count(co.pizza_id)
when co.pizza_id = 2 then 250 * count(co.pizza_id)
end) as revenue
from customer_orders co 
join rider_orders ro on co.order_id = ro.order_id
join pizza_names pn on co.pizza_id = pn.pizza_id
where ro.cancellation is null or ro.cancellation = ''
group by co.pizza_id
)
select pizza_id, revenue, sum(revenue) over() as total_revenue from c;

--25. What if there’s an additional ₹20 charge for each extra topping?
with sdp as(
select co.order_id, co.pizza_id, co.extras
from customer_orders co join rider_orders ro
on co.order_id = ro.order_id
where ro.cancellation IS NULL OR ro.cancellation = ''),

cte as (
select s.pizza_id,
(case 
when s.pizza_id = 1 then 300 * count(s.pizza_id)
when s.pizza_id = 2 then 250 * count(s.pizza_id)
end) as revenue
from sdp s 
join pizza_names pn on s.pizza_id = pn.pizza_id
group by s.pizza_id
),
--select * from c;

extra_toppings as(
select s.pizza_id, count(pt.topping_id) as ext_topping_count,
count(pt.topping_id) * 20 as extra_charge
from sdp s
cross apply STRING_SPLIT(s.extras, ',') AS split
join pizza_toppings pt 
on trim(split.value) = pt.topping_id
where s.extras IS NOT NULL AND s.extras != ''
group by s.order_id, s.pizza_id
)
select c.pizza_id,
sum(c.revenue + et.extra_charge) as total_rev
from cte c full outer join extra_toppings et
on c.pizza_id = et.pizza_id
group by c.pizza_id
--select pizza_id, revenue, sum(revenue) over() as total_revenue from c1;


--26. Cheese costs ₹20 extra — apply this specifically where Cheese is added as an extra.

--27. Design a new table for customer ratings of riders. Include:

--    * rating_id, order_id, customer_id, rider_id, rating (1-5), comments (optional), rated_on (DATETIME)

--    Example schema:

;
    CREATE TABLE rider_ratings (
      rating_id INT IDENTITY PRIMARY KEY,
      order_id INT,
      customer_id INT,
      rider_id INT,
      rating INT CHECK (rating BETWEEN 1 AND 5),
      comments NVARCHAR(255),
      rated_on DATETIME
    );


--28. Insert sample data into the ratings table for each successful delivery.
INSERT INTO rider_ratings VALUES()



--29. Join data to show the following info for successful deliveries:

--    * customer_id
--    * order_id
--    * rider_id
--    * rating
--    * order_time
--    * pickup_time
--    * Time difference between order and pickup (in minutes)
--    * Delivery duration
--    * Average speed (km/h)
--    * Number of pizzas in the order

--30. If Paneer Tikka is ₹300, Veggie Delight ₹250, and each rider is paid ₹2.50/km, 
--what is Pizza Delivery India's profit after paying riders?
With c as (
select co.pizza_id,
case 
when co.pizza_id = 1 then 300 * count(co.pizza_id)
when co.pizza_id = 2 then 250 * count(co.pizza_id)
end as revenue
from customer_orders co 
join rider_orders ro on co.order_id = ro.order_id
join pizza_names pn on co.pizza_id = pn.pizza_id
where ro.cancellation is null or ro.cancellation = ''
group by co.pizza_id
),
c2 as(
select sum(Cast(Replace(distance, 'km', '') AS FLOAT)) * 2.50 as cost_per_rider from rider_orders
)
select (sum(c.revenue) - (select cost_per_rider from c2)) as net_profit
from c,c2

--31. If the owner wants to add a new “Supreme Indian Pizza” with 
--all available toppings, how would the existing design support that? Provide an example `INSERT`:

