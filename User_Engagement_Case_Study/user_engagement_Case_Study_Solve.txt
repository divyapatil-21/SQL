--# SET A

--1. How many distinct users are in the dataset?
select count(distinct user_id) no_of_distinct_users from users;

--2. What is the average number of cookie IDs per user?
select avg(c1) avg_cookie_id from (select
count(cookie_id) c1
from users
group by user_id) as cc

--3. What is the number of unique site visits by all users per month?
select month(event_time) month, count(distinct visit_id) site_visits
from events
group by month(event_time)
order by month(event_time);

--4. What is the count of each event type?
select event_type, count(event_type) as count_of_et
from events
group by event_type
order by event_type;

--5. What percentage of visits resulted in a purchase? ********
select cast(count(distinct visit_id) as float)/
(
 select cast(count(distinct visit_id) as float) total_visits
 from events
) * 100 as perc_of_visits
from events
where event_type = 3;


--6. What percentage of visits reached checkout but not purchase? *******
select cast(count(distinct visit_id) as float)/
(
 select cast(count(distinct visit_id) as float) total_visits
 from events
) * 100 as perc_of_visits
from events
where page_id = 12 and event_type != 3;


--7. What are the top 3 most viewed pages?
select most_viewed_pages, no_of_visits from(
select ph.page_name as most_viewed_pages, count(e.page_id) no_of_visits,
dense_rank() over(order by count(e.page_id) desc) dr
from events e join page_hierarchy ph
on ph.page_id = e.page_id
where ph.product_id is not null
group by ph.page_name) as pg_count
where dr < 4

--8. What are the views and add-to-cart counts per product category?
select ph.product_category, 
count(case when e.event_type = 1 then 1 end) views_count,
count(case when e.event_type = 2 then 1 end) add_to_cart_count
from page_hierarchy ph join events e
on ph.page_id = e.page_id
where ph.product_category IS NOT NULL
group by ph.product_category;

--select page_id,count(*) from events where event_type = 2
--group by page_id

--9. What are the top 3 products by purchases? ******
with purchsed_prods as(
select visit_id, event_type, page_id
from events
where event_type = 2 AND
visit_id IN (select distinct visit_id from events where event_type = 3))

select TOP 3 ph.page_name as product, count(ph.page_name) no_of_purchase
from purchsed_prods p join page_hierarchy ph
on p.page_id = ph.page_id
group by ph.page_name
order by count(ph.page_name) desc;

--# SET B

--10. Create a product-level funnel table with views, cart adds, abandoned carts, and purchases.

with purchase_count as(
select ph.product_id, count(ph.product_id) no_of_purchase
from events e join page_hierarchy ph
on e.page_id = ph.page_id
where event_type = 2 AND
visit_id IN (select distinct visit_id from events where event_type = 3)
group by ph.product_id),

abandoned_prods as(
select ph.product_id, count(ph.product_id) abondened_count
from events e join page_hierarchy ph
on ph.page_id = e.page_id
where event_type = 2 AND ph.product_id IS NOT NULL
AND e.visit_id NOT IN (select DISTINCT visit_id from events where event_type = 3)
group by ph.product_id
)
select ph.product_id,
count(case when event_type = 1 then 1 end) views,
count(case when event_type = 2 then 1 end) cart_adds,
ap.abondened_count as abandoned_carts, pc.no_of_purchase as purchases
into #product_level_tbl
from
page_hierarchy ph join events e
on ph.page_id = e.page_id
join purchase_count pc on pc.product_id = ph.product_id
join abandoned_prods ap on ap.product_id = ph.product_id
where ph.product_id IS NOT NULL
group by ph.product_id,pc.no_of_purchase, ap.abondened_count;


--11. Create a category-level funnel table with the same metrics as above.
with purchase_count as(
select ph.product_category, count(ph.product_category) no_of_purchase
from events e join page_hierarchy ph
on e.page_id = ph.page_id
where event_type = 2 AND
visit_id IN (select distinct visit_id from events where event_type = 3)
group by ph.product_category),

abandoned_prods as(
select ph.product_category, count(ph.product_category) abondened_count
from events e join page_hierarchy ph
on ph.page_id = e.page_id
where event_type = 2 AND ph.product_id IS NOT NULL
AND e.visit_id NOT IN (select DISTINCT visit_id from events where event_type = 3)
group by ph.product_category
)
select ph.product_category,
count(case when event_type = 1 then 1 end) views,
count(case when event_type = 2 then 1 end) cart_adds,
ap.abondened_count as abandoned_carts, pc.no_of_purchase as purchases
--into #product_level
from
page_hierarchy ph join events e
on ph.page_id = e.page_id
join purchase_count pc on pc.product_category = ph.product_category
join abandoned_prods ap on ap.product_category = ph.product_category
where ph.product_category IS NOT NULL
group by ph.product_category,pc.no_of_purchase, ap.abondened_count;

--12. Which product had the most views, cart adds, and purchases?
select(
select top 1 product_id
from #product_level_tbl
order by views desc) as most_viewd_product,
(
select top 1 product_id
from #product_level_tbl
order by cart_adds desc
) as most_cart_adds,
(
select top 1 product_id
from #product_level_tbl
order by purchases desc
) as most_purchases;

--13. Which product was most likely to be abandoned?
with view_add as(
select distinct visit_id, e.page_id, ph.page_name
from events e join page_hierarchy ph
on ph.page_id = e.page_id
where event_type = 2 AND ph.product_id IS NOT NULL
AND e.visit_id NOT IN (select DISTINCT visit_id from events where event_type = 3)
)
select TOP 1 page_name as product_mostly_abundened
from view_add
group by page_name
order by count(page_name) desc

--14. Which product had the highest view-to-purchase conversion rate?
select top 1 product_id,
cast(purchases as float) * 100/cast(views as float) as conv_rate
from #product_level_tbl
order by conv_rate desc;

select * from #product_level_tbl

--15. What is the average conversion rate from view to cart add?
select 
round(cast(sum(cart_adds) as float)/cast(sum(views) as float) * 100,2) avg_conversion_rate
from #product_level_tbl

--16. What is the average conversion rate from cart add to purchase?
select 
round(cast(sum(purchases) as float)/cast(sum(cart_adds) as float),2) avg_conversion_rate
from #product_level_tbl;

--# SET C.
--17. Create a visit-level summary table with user_id, visit_id, visit start time, event counts, and campaign name.
with user_visits as(
select visit_id,user_id, min(e.event_time) visit_start_time, count(event_type) event_counts
from events e left join users u
on u.cookie_id = e.cookie_id
group by visit_id,user_id),

product_campaigns as(
select visit_id,event_time,
(case 
when ph.product_id < 4 then 'BOGOF - Festival Deals'
when ph.product_id IN (4,5) then '25% Off - Wedding Essentials'
when ph.product_id IN (6,7,8) then 'Half Off - New Year Bonanza'
end) as campaign_name
from events e
join page_hierarchy ph on e.page_id = ph.page_id
where ph.product_id is not null
)
select uv.user_id, uv.visit_id, uv.event_counts, uv.visit_start_time, min(pc.campaign_name)
from user_visits uv left join product_campaigns pc
on uv.visit_id = pc.visit_id
group by uv.user_id, uv.visit_id, uv.event_counts, uv.visit_start_time
order by uv.user_id

--18. (Optional) Add a column for comma-separated cart products sorted by order of addition.

--# Further Investigations

--19. Identify users exposed to campaign impressions and compare metrics with those who were not.
select u.user_id
from users u join events e
on u.cookie_id = e.cookie_id
where e.event_type = 4
group by u.user_id

--20. Does clicking on an impression lead to higher purchase rates?
--21. What is the uplift in purchase rate for users who clicked an impression vs. those who didn t?
--22. What metrics can be used to evaluate the success of each campaign?
