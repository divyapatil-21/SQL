--Convert the week_date to a DATE format
update dmart.qt.weekly_sales
set week_date = parse(week_date as date using 'en-GB')

ALTER table dmart.qt.weekly_sales
alter column week_date DATE;

select week_date from dmart.qt.weekly_sales

--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
alter table dmart.qt.weekly_sales
add week_number int 

update dmart.qt.weekly_sales set week_number = DATEPART(week, week_date)

--Add a month_number with the calendar month for each week_date value as the 3rd column
alter table dmart.qt.weekly_sales
add month_number int 

update dmart.qt.weekly_sales set month_number = DATEPART(month, week_date)

--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
alter table dmart.qt.weekly_sales
add calendar_year int 

update dmart.qt.weekly_sales set calendar_year = DATEPART(year, week_date)

--Add a new column called age_band after the original segment column using the 
--following mapping on the number inside the segment value
--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
update dmart.qt.weekly_sales
set segment = 'unknown'
--select * from dmart.qt.weekly_sales
where segment = 'null'

alter table dmart.qt.weekly_sales
add age_band nvarchar(30)

update dmart.qt.weekly_sales
set age_band = 
(case when right(segment,1) = 1 then 'YoungAdults'
when right(segment,1) = 2 then 'MiddleAged'
when right(segment,1) in (3,4)  then 'Retirees' end)
where segment != 'unknown'

update dmart.qt.weekly_sales
set age_band = 'unknown' where age_band is null;

--Add a new demographic column using the following mapping for the first letter in the segment values:
alter table dmart.qt.weekly_sales
add demographic nvarchar(30)

update dmart.qt.weekly_sales
set demographic = 
(case when left(segment,1) = 'C' then 'Couples'
when left(segment,1) = 'F' then 'Famillies'
else 'unknown' end)

--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record
alter table dmart.qt.weekly_sales
add avg_transaction decimal(6,2)

update dmart.qt.weekly_sales
set avg_transaction = (cast(sales as float)/cast(transactions as float))

--## Data Exploration
--1. What day of the week does each week_date fall on?
--→ Find out which weekday (e.g., Monday, Tuesday) each sales week starts on.
select distinct week_date, DATENAME(weekday, week_date)
from dmart.qt.weekly_sales

--2. What range of week numbers are missing from the dataset?
select distinct week_number
from dmart.qt.weekly_sales
order by week_number;

with week_num as(
select 1 as w
union all
select w + 1
from week_num
where w < 53
)
select w as missing_weeks from week_num
where w not in( select distinct week_number from dmart.qt.weekly_sales)

--3. How many purchases were made in total for each year?
--→ Count the total number of transactions for every year in the dataset.
select calendar_year, count(transactions) as total_purchase
from dmart.qt.weekly_sales
group by calendar_year
order by calendar_year;

--4. How much was sold in each region every month?
--→ Show total sales by region, broken down by month.
select region, month_number, sum(cast(sales as bigint)) total_sales
from dmart.qt.weekly_sales
group by region, month_number
order by region

--5. How many transactions happened on each platform?
--→ Count purchases separately for the online store and the physical store.
select platform, count(transactions) num_of_transactions
from dmart.qt.weekly_sales
group by platform;

--6. What share of total sales came from Offline vs Online each month?
--→ Compare the percentage of monthly sales from the physical store vs. the online store.
with sales_offline as(
select month_number, sum(cast(sales as bigint)) sales_offline
from dmart.qt.weekly_sales
where platform  ='Offline-store'
group by month_number),
sales_online as(
select month_number, sum(cast(sales as bigint)) sales_online
from dmart.qt.weekly_sales
where platform  ='Online-store'
group by month_number
)
select sf.month_number, round((cast(sales_offline as float) * 100/(cast(sales_offline as float) + 
cast(sales_online as float))),2) offline_sales,
round((cast(sales_online as float) * 100/(cast(sales_offline as float) + cast(sales_online as float))),2) online_sales
from sales_offline sf join sales_online so
on sf.month_number = so.month_number;

--7. What percentage of total sales came from each demographic group each year?
--→ Break down annual sales by customer demographics (e.g., age or other groupings).

with sales_offline as(
select calendar_year, sum(cast(sales as bigint)) sales_c
from dmart.qt.weekly_sales
where demographic  ='Couples'
group by calendar_year),
sales_online as(
select calendar_year, sum(cast(sales as bigint)) sales_f
from dmart.qt.weekly_sales
where demographic  ='Famillies'
group by calendar_year
)
select sf.calendar_year, round((cast(sales_c as float) * 100/(cast(sales_c as float) + 
cast(sales_f as float))),2) sales_of_couples_demography,
round((cast(sales_f as float) * 100/(cast(sales_c as float) + cast(sales_f as float))),2) sales_of_famillies_demography
from sales_offline sf join sales_online so
on sf.calendar_year = so.calendar_year;

--8. Which age groups and demographic categories had the highest sales in physical stores?
--→ Find out which age and demographic combinations contribute most to Offline-Store sales.
select TOP 1
age_band, demographic,
sum(cast(sales as bigint)) sales_total
from dmart.qt.weekly_sales
where platform  ='Offline-store' and age_band != 'unknown'
group by age_band, demographic
order by sales_total desc;

--9. Can we use the avg_transaction column to calculate average purchase size by year and platform? If not, how should we do it?
--→ Check if the avg_transaction column gives us correct yearly average sales per transaction for Offline 
--vs Online. If it doesn't, figure out how to calculate it manually (e.g., by dividing total sales by total transactions).

select calendar_year, platform, avg(avg_transaction) as avg_purchase
from dmart.qt.weekly_sales
group by calendar_year, platform;

select calendar_year, platform, round(cast(sum(cast(sales as bigint)) as float)/
cast(sum(transactions) as float), 2) as avg_purchase
from dmart.qt.weekly_sales
group by calendar_year, platform;

--### Pre-Change vs Post-Change Analysis
--This technique is usually used when we inspect an important event and want to inspect the impact 
--before and after a certain point in time.

--Taking the week_date value of 2020-06-15 as the baseline week where the DMart sustainable packaging changes came into effect.

--We would include all week_date values for 2020-06-15 as the start of the period after the change and 
--the previous week_date values would be before

--1. What is the total sales for the 4 weeks pre and post 2020-06-15?
--What is the growth or reduction rate in actual values and percentage of sales?
with prev_w as(
select sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2020-06-15' and week_date >= dateadd(week, -4,'2020-06-15')),
post_w as(
select sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2020-06-15' and week_date < dateadd(week, 4,'2020-06-15')
)
select prev_sales, post_sales, (prev_sales-post_sales) sales_change,
round(((post_sales-prev_sales)*100/prev_sales),2) percentage_change
from prev_w, post_w;

--2. What is the total sales for the 12 weeks pre and post 2020-06-15? What is the growth or 
--reduction rate in actual values and percentage of sales?
with prev_w as(
select sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2020-06-15' and week_date >= dateadd(week, -12,'2020-06-15')),
post_w as(
select sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2020-06-15' and week_date < dateadd(week, 12,'2020-06-15')
)
select prev_sales, post_sales, (prev_sales-post_sales) sales_change,
round(((post_sales-prev_sales)/cast(prev_sales  as float)),4)*100 percentage_change
from prev_w, post_w;

--3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

---------------12 weeks pre and post comparison--------------------
with y18_prev_w as(
select '2018' as sales_year, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2018-06-15' and week_date >= dateadd(week, -12,'2018-06-15')),
y18_post_w as(
select '2018' as sales_year, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2018-06-15' and week_date < dateadd(week, 12,'2018-06-15')
),
y19_prev_w as(
select '2019' as sales_year, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2019-06-15' and week_date >= dateadd(week, -12,'2019-06-15')),
y19_post_w as(
select '2019' as sales_year, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2019-06-15' and week_date < dateadd(week, 12,'2019-06-15')
),
y20_prev_w as(
select '2020' as sales_year, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2020-06-15' and week_date >= dateadd(week, -12,'2020-06-15')),
y20_post_w as(
select '2020' as sales_year, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2020-06-15' and week_date < dateadd(week, 12,'2020-06-15')
)
--select * into #prev_sales_record from y18_prev_w union all select * from y19_prev_w union all select * from y20_prev_w;
--select * into #post_sales_record from y18_post_w union all select * from y19_post_w union all select * from y20_post_w;

----------------for 4weeks pre and post---------------------------
with y18_prev_w as(
select '2018' as sales_year, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2018-06-15' and week_date >= dateadd(week, -4,'2018-06-15')),
y18_post_w as(
select '2018' as sales_year, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2018-06-15' and week_date < dateadd(week, 4,'2018-06-15')
),
y19_prev_w as(
select '2019' as sales_year, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2019-06-15' and week_date >= dateadd(week, -4,'2019-06-15')),
y19_post_w as(
select '2019' as sales_year, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2019-06-15' and week_date < dateadd(week, 4,'2019-06-15')
),
y20_prev_w as(
select '2020' as sales_year, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2020-06-15' and week_date >= dateadd(week, -4,'2020-06-15')),
y20_post_w as(
select '2020' as sales_year, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2020-06-15' and week_date < dateadd(week, 4,'2020-06-15')
)
--select * into #prev_4w_sales_record from y18_prev_w union all select * from y19_prev_w union all select * from y20_prev_w;
--select * into #post_4w_sales_record from y18_post_w union all select * from y19_post_w union all select * from y20_post_w;

--sales record for prev and post 12 weeks 
select pre.sales_year, pre.prev_sales, post.post_sales,
(post_sales-prev_sales) sales_change,
round(((post_sales-prev_sales)/cast(prev_sales  as float)),4)*100 percentage_change
from #prev_sales_record pre join #post_sales_record post
on pre.sales_year  = post.sales_year

union all
--sales record for prev and post 4 weeks 
select pre.sales_year, pre.prev_sales, post.post_sales,
(post_sales-prev_sales) sales_change,
round(((post_sales-prev_sales)/cast(prev_sales  as float)),4)*100 percentage_change
from #prev_4w_sales_record pre join #post_4w_sales_record post
on pre.sales_year  = post.sales_year;

--### Bonus Question
--Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

--1. region
--2. platform
--3. age_band
--4. demographic
--5. customer_type

with prev_w as(
select region, sum(cast(sales as bigint)) prev_sales
from dmart.qt.weekly_sales
where week_date < '2020-06-15' and week_date >= dateadd(week, -12,'2020-06-15')
group by region),
post_w as(
select region, sum(cast(sales as bigint)) post_sales
from dmart.qt.weekly_sales
where week_date >='2020-06-15' and week_date < dateadd(week, 12,'2020-06-15')
group by region
)
select prev_w.region, prev_sales, post_sales, (prev_sales-post_sales) sales_change,
round(((post_sales-prev_sales)/cast(prev_sales as float)),4)*100 percentage_change
from prev_w join post_w on prev_w.region = post_w.region;