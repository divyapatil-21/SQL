  --**AdInsight Analytics: Case Study Questions**
use adinsight_analytics
select * from interest_map
select * from interest_metrix
--The following are core business questions designed to be explored using SQL queries and logical reasoning. These will help AdInsight Analytics gain actionable insights into customer behavior and interest segmentation.


--### Data Exploration and Cleansing

--1. Update the `month_year` column in `adinsight_analytics.interest_metrics` to be of `DATE` type, with values representing the first day of each month.
alter table interest_metrix
alter column month_year date

update interest_metrix
set month_year=try_CAST( concat(year, '-', month, '-01')  AS DATE);


SELECT * FROM interest_metrix;


--2. Count the total number of records for each `month_year` in the `interest_metrics` table, sorted chronologically, ensuring that NULL values (if any) appear at the top.
select month_year, count(*) as count_months
from interest_metrix
group by month_year
order by month_year asc


--3. Based on your understanding, what steps should be taken to handle NULL values in the `month_year` column?
select month_year from interest_metrix
where month_year is not null

--4. How many `interest_id` values exist in `interest_metrics` but not in `interest_map`? And how many exist in `interest_map` but not in `interest_metrics`?
with c as(
select count(*) as count_id 
from(
select distinct interest_id from interest_metrix  
where interest_id is not null
except
select id from interest_map
) as  A
),
c1 as(
select count(*) as count_id 
from(
select id from interest_map
except
select interest_id from interest_metrix 
) as  B
)
select c.count_id as interest_id, c1.count_id as id 
from c,c1

--5. Summarize the `id` values from the `interest_map` table by total record count.
select  id, interest_name, count(*) as total_count
from interest_map
group by  id, interest_name


--6. What type of join is most appropriate between the `interest_metrics` and `interest_map` tables for analysis?
--Justify your approach and verify it by retrieving data where `interest_id = 21246`, including all columns from `interest_metrics` and all except `id` from `interest_map`.
select im.* , mp.interest_name, mp.interest_summary, mp.created_at, mp.last_modified
from interest_metrix as im
left join interest_map as mp on im.interest_id=mp.id
where im.interest_id =21246

--7. Are there any rows in the joined data where `month_year` is earlier than `created_at` in `interest_map`? Are these values valid? Why or why not?
select im.month_year,  mp.created_at
from interest_metrix as im
left join interest_map as mp on im.interest_id=mp.id
where im.month_year<mp.created_at


### Interest Analysis
--8. Which interests appear consistently across all `month_year` values in the dataset?
with total_count as (
select count(distinct month_year) as month_count
from interest_metrix
),
interest_months as (
select interest_id, count(distinct month_year) as active_months
from interest_metrix
group by interest_id
)
select im.interest_id, mp.interest_name 
from interest_months as im
join interest_map as mp on im.interest_id= mp.id
cross join total_count as tc 
where im.active_months=tc.month_count

--9. Calculate the cumulative percentage of interest records starting from those present in 14 months. What is the `total_months` value where the cumulative percentage surpasses 90%?
with c as (
select interest_id, COUNT(distinct month_year) as total_months
from interest_metrix
where month_year is not null
group by interest_id
--order by total_months
),
c1 as (
select interest_id, total_months, 
round(CUME_DIST() over (order by total_months desc)*100,2) as cume_percentage
from c
)
select interest_id, total_months, cume_percentage 
from c1
where cume_percentage>90

--10. If interests with `total_months` below this threshold are removed, how many records would be excluded?
with c as (
select interest_id, COUNT(distinct month_year) as total_months
from interest_metrix
where interest_id is not null
group by interest_id
--order by interest_id
),
c1 as (
select interest_id 
from c
where total_months <6
)
select COUNT(*) as excluded_record
from interest_metrix
where interest_id in (select interest_id from c1)

--11. Evaluate whether removing these lower-coverage interests is justified from a business perspective. 
--Provide a comparison between a segment with full 14-month presence and one that would be removed.
with c as (
select interest_id, COUNT(distinct month_year) as total_months
from interest_metrix
where month_year is not null
group by interest_id
--order by total_months
),
c1 as (
select interest_id, total_months, 
round(CUME_DIST() over (order by total_months desc)*100,2) as cume_percentage
from c
),
full_conversion as (
select top 1 count(distinct interest_id) as full_conversion, total_months, cume_percentage 
from c1
where total_months=14
group by total_months, cume_percentage 
),
low_conversion as (
select top 1 count( distinct interest_id) as low_conversion, total_months, cume_percentage
from c1 
where cume_percentage<90
group by total_months, cume_percentage
order by total_months desc
)
select f.full_conversion, f.total_months as full_months, f.cume_percentage as full_cume,
    l.low_conversion,l.total_months as low_months, l.cume_percentage as low_cume
from full_conversion f
cross join low_conversion l;



--12. After filtering out lower-coverage interests, how many unique interests remain for each month?
select interest_id, count(distinct month_year) as total_months
from interest_metrix
where month_year is not null
group by interest_id

---

### Segment Analysis

--13. From the filtered dataset (interests present in at least 6 months), identify the top 10 and bottom 10 interests based on their maximum `composition` value. Also, retain the corresponding `month_year`.
with c as (
select interest_id, count(distinct month_year) as total_months , MAX(composition) as max_composition
from interest_metrix
where interest_id is not null 
group by interest_id
having count(distinct month_year)>=6
),
top_composition as (
select  interest_id, total_months, max_composition,
ROW_NUMBER() over(order by max_composition desc) as rn
from c
),
bottom_composition as (
select interest_id, total_months, max_composition,
ROW_NUMBER() over(order by max_composition asc) as rn1
from  c
)
select t.interest_id as  top_interest_id, t.total_months, t.max_composition as top_composition, b.interest_id as botton_interest_id, b.total_months, b.max_composition as bottom_compostion
from top_composition as t
join bottom_composition as b on t.rn=b.rn1
where t.rn<=10
--------------------------------------------------
with c as (
select interest_id, count(distinct month_year) as total_months  , MAX(composition) as max_composition
from interest_metrix
where interest_id is not null 
group by interest_id
having count(distinct month_year)>=6
),
c1 as (
select c.interest_id,c.total_months ,c.max_composition, RANK() over( partition by i.interest_id order by i.composition ) as rank, i.month_year
from interest_metrix as i
join c as c on i.interest_id=c.interest_id
),
top_composition as (
select  c.interest_id, c.total_months, c.max_composition,c1.month_year,c1.rank,
ROW_NUMBER() over( order by c.max_composition desc) as rn
from c
join c1 as c1 on c.interest_id= c1.interest_id
where rank=1
),
bottom_composition as (
select  c.interest_id, c.total_months, c.max_composition,c1.month_year,c1.rank,
ROW_NUMBER() over( order by c.max_composition asc) as rn1
from  c
join c1 as c1 on c.interest_id= c1.interest_id
where rank=1

)
select t.interest_id as  top_interest_id, t.max_composition as top_composition,t.month_year,t.rn ,b.interest_id as botton_interest_id, b.max_composition as bottom_compostion,b.month_year, b.rn1
from top_composition as t
join bottom_composition as b on t.rn=b.rn1
where t.rn<=10


--14. Identify the five interests with the lowest average `ranking` value.
with c as (
select interest_id, count(distinct month_year) as total_months , AVG(ranking) as avg_ranking
from interest_metrix
where interest_id is not null 
group by interest_id
)
select top 5 interest_id as Lowest_interest, total_months, ROW_NUMBER() over(order by avg_ranking asc) as rn
from c


--15. Determine the five interests with the highest standard deviation in their `percentile_ranking`.
select top 5 interest_id, round(STDEV(percentile_ranking),2) as standered_daviation
from interest_metrix
where interest_id is not null
group by interest_id
order by standered_daviation desc

--16. For the five interests found in the previous step, report the minimum and maximum `percentile_ranking` values and their corresponding `month_year`. What trends or patterns can you infer from these fluctuations?
with c1 as(
select interest_id,interest_name,
STDEV(percentile_ranking) as std_deviation
from interest_metrix ime
left join interest_map im
on ime.interest_id=im.id
where interest_id is not null and month_year is not null
group by interest_id,interest_name
),
c2 as (
select c1.interest_id,c1.interest_name,c1.std_deviation,month_year,percentile_Ranking,rank()over(partition by c1.interest_id order by percentile_ranking desc)as rank_desc,
rank()over(partition by c1.interest_id order by percentile_ranking asc)
as rank_asc from c1
join interest_metrix ime on c1.interest_id=ime.interest_id
),
maximum as(
    SELECT interest_id,interest_name,std_deviation,month_year AS max_month, percentile_ranking AS max_percentile
    FROM c2 WHERE rank_desc = 1
),
minimum as(
    SELECT interest_id,interest_name,std_deviation,month_year AS min_month, percentile_ranking AS min_percentile
    FROM c2 WHERE rank_asc = 1
	)
 
SELECT mx.interest_id,mx.interest_name,mx.std_deviation,mx.max_month,mx.max_percentile,mi.min_month,mi.min_percentile
FROM maximum mx JOIN minimum mi  ON mx.interest_id = mi.interest_id;



 


--17. Based on composition and ranking data, describe the overall customer profile represented in this segment. What types of products/services should be targeted, and what should be avoided?

---

### Index Analysis

--18. Calculate the average composition for each interest by dividing `composition` by `index_value`, rounded to 2 decimal places.
with c as (
select interest_id, (composition/index_value)as divide_composition 
from interest_metrix
where interest_id is not null 
)
select interest_id, round(AVG(divide_composition),2) as avg_composition
--into #avg_composition
from c
group by interest_id
order by round(AVG(divide_composition),2) desc


--19. For each month, identify the top 10 interests based on this derived average composition.
with c as (
select a.interest_id, month_year, avg_composition, ROW_NUMBER() over(partition by month_year order by avg_composition desc) as rn
from interest_metrix as i
join #avg_composition as a on i.interest_id=a.interest_id 
where  month_year is not null 
)
select *
into #top10_interest 
from c 
where rn<=10
order by month_year , rn 

-----Temproary_Table  select * from #top10_interest

--20. Among these top 10 interests, which interest appears most frequently?
with c as (
select interest_id, count(interest_id) as frequent_interest
from #top10_interest
group by interest_id
--order by frequent_interest desc
)
select interest_id,  frequent_interest
from c
where frequent_interest = (select max(frequent_interest) from c)


--21. Calculate the average of these monthly top 10 average compositions across all months.
select month_year, avg(avg_composition) as avg_month_composition
from #top10_interest
group by month_year
--------------------------------
SELECT AVG(avg_month_composition) AS overall_avg_composition
FROM (
    SELECT month_year, AVG(avg_composition) AS avg_month_composition
    FROM #top10_interest
    GROUP BY month_year
) AS monthly_avgs;

--22. From September 2018 to August 2019, calculate a 3-month rolling average of the highest average composition. Also, include the top interest names for the current, 1-month-ago, and 2-months-ago periods.
--23. Provide a plausible explanation for the month-to-month changes in the top average composition. Could it indicate any risks or insights into AdInsight’s business model?

---

### Sample Output for Rolling Average (Q22)

| month\_year | interest\_name             | max\_index\_composition | 3\_month\_moving\_avg | 1\_month\_ago                    | 2\_months\_ago                   |
| ----------- | -------------------------- | ----------------------- | --------------------- | -------------------------------- | -------------------------------- |
| 2018-09-01  | Work Comes First Travelers | 8.26                    | 7.61                  | Las Vegas Trip Planners: 7.21    | Las Vegas Trip Planners: 7.36    |
| 2018-10-01  | Work Comes First Travelers | 9.14                    | 8.20                  | Work Comes First Travelers: 8.26 | Las Vegas Trip Planners: 7.21    |
| 2018-11-01  | Work Comes First Travelers | 8.28                    | 8.56                  | Work Comes First Travelers: 9.14 | Work Comes First Travelers: 8.26 |
| ...         | ...                        | ...                     | ...                   | ...                              | ...                              |

---



