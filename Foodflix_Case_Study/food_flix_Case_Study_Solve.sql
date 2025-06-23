
------------------------------------------------------------------------
--### A. Customer and Plan Insights (Foodflix)
use foodflix
--1. How many unique customers have ever signed up with Foodflix?
Select count(distinct customer_id) 
as num_of_unique_customers_signed_up from subscriptions;

--2. What is the monthly distribution of trial plan start dates in the dataset?
select DATENAME(MONTH,start_date), 
count(plan_id) as trail_plan_count from subscriptions
where plan_id = 0
group by DATENAME(MONTH,start_date);

--mention label, use left join to write this in another way, cume_dist, percetage_rank, 
--rolling running running total, quaterly, half yearly to check for this

SELECT 
    customer_id,
    start_date,
    CUME_DIST() OVER (ORDER BY start_date) AS cume_dist,
    PERCENT_RANK() OVER (ORDER BY start_date) AS percent_rank
FROM subscriptions
WHERE plan_id = 0
ORDER BY start_date;

--3. Which plan start dates occur after 2020?
select distinct p.plan_name, count(s.customer_id) as num_of_plans
from subscriptions s left join plans p
on s.plan_id = p.plan_id
where YEAR(start_date) > 2020
group by p.plan_name;

--4. What is the total number and percentage of customers who have churned? **use left join in c to find the churn
with c as(
select cast(count(customer_id)as float) num_of_customers_churned
from subscriptions
where plan_id = 4),
c2 as(
select cast(count(distinct customer_id) as float) total_customers from subscriptions
)
select num_of_customers_churned, 
(c.num_of_customers_churned / c2.total_customers) * 100
from c,c2;


--***retrieve active customers from each plan category


--5. How many customers churned immediately after their free trial?
with c as (
  select s.customer_id,  p.plan_name, 
  lead(p.plan_name) over ( partition by s.customer_id order by s.plan_id) as next_plan 
  from subscriptions as s
  join plans as p on s.plan_id = p.plan_id) 
select count(customer_id) AS churned_customers from c
where plan_name = 'trial' and next_plan = 'churn';

--6. What is the count and percentage of customers who transitioned to a paid plan after their initial trial?
--****use exists or another aproach in this
with c as (
  select s.customer_id,  p.plan_name, 
  lead(p.plan_name) over ( partition by s.customer_id order by p.plan_id) as next_plan 
  from subscriptions as s
  join plans as p on s.plan_id = p.plan_id),
c1 as(
select cast(count(customer_id) as float) total_customers from subscriptions where plan_id = 0
)
select count(c.customer_id) as transitioned_customers, 
(cast(count(c.customer_id) as float)* 100 / c1.total_customers) AS transition_percentage
FROM c,c1 where c.plan_name = 'trial' AND
c.next_plan IN ('basic monthly', 'pro monthly', 'pro annual')
group by c1.total_customers;

--where plan id  = 0 and next plan is null

--7. As of 2020-12-31, what is the count and percentage of customers in each of the 5 plan types?
with c as (
select s.plan_id, count(s.customer_id) num_of_customers
from subscriptions s join plans p
on s.plan_id = p.plan_id
where s.start_date <= '2020-12-31'
group by s.plan_id)
select c.plan_id, c.num_of_customers, 
(cast(c.num_of_customers as float)/cast(count(distinct subscriptions.customer_id) as float)) * 100 as percentage_of_customers
from c, subscriptions
group by c.plan_id, c.num_of_customers
order by plan_id;


--8. How many customers upgraded to an annual plan during the year 2020?
select COUNT(customer_id)
from subscriptions
where plan_id = 3 AND YEAR(start_date) = 2020;

--9. On average, how many days does it take for a customer to upgrade to an annual plan from their sign-up date?
--with c as(
--select customer_id, plan_id, start_date
--from subscriptions
--where plan_id = 0),
--c1 as(
--select customer_id, plan_id, start_date
--from subscriptions
--where plan_id = 3)
--select Avg(DATEDIFF(DAY, c.start_date, c1.start_date)) as avg_days
--from c join c1 on c.customer_id = c1.customer_id




--10. Can you break down the average days to upgrade to an annual plan into 30-day intervals?
with c as(
select customer_id, plan_id, start_date
from subscriptions
where plan_id = 0),
c1 as(
select customer_id, plan_id, start_date
from subscriptions
where plan_id = 3)
select avg(DATEDIFF(day, c.start_date, c1.start_date)) 
from c join c1 on c.customer_id = c1.customer_id
where DATEDIFF(day, c.start_date, c1.start_date) < 31


--11. How many customers downgraded from a Pro Monthly to a Basic Monthly plan in 2020?
with c1 as(
select customer_id, plan_id,start_date
from subscriptions
where YEAR(start_date) = 2020 AND 
plan_id = 2),
c2 as(
select customer_id, plan_id,start_date
from subscriptions
where YEAR(start_date) = 2020 AND 
plan_id = 1)
select count(*) as num_of_customers
from c1 join c2 on c1.customer_id = c2.customer_id
where c2.start_date > c1.start_date

--or--
with c1 as(
select customer_id, plan_id, start_date,
lead(plan_id) over(partition by customer_id order by start_date) next_plan
from subscriptions
where YEAR(start_date) = 2020)
select count(customer_id) as count_of_customers
from c1
where plan_id = 2 and next_plan = 1
-----

--Challenge � Payments Table for Foodflix (2020)

--The Foodflix team would like you to generate a payments table 
--for the year 2020 that reflects actual payment activity. The logic should include:

--* Monthly payments are charged on the same day of the month as the start date of the plan.
--* Upgrades from Basic to Pro plans are charged immediately, with the upgrade cost reduced by the 
--amount already paid in that month.
--* Upgrades from Pro Monthly to Pro Annual are charged at the end of the current 
--monthly billing cycle, and the new plan starts at the end of that cycle.
--* Once a customer churns, no further payments are made.

--Example output rows for the payments table could include:
--("customer_id", "plan_id", "plan_name", "payment_date", "amount", "payment_order")

CREATE TABLE payments (
  customer_id INT,
  plan_id INT,
  plan_name VARCHAR(50),
  payment_date DATE,
  amount DECIMAL(5,2),
  payment_order INT
);

--Step 1: Filter and exclude churn and trial plans and year 2020
WITH ordered_subs AS (
SELECT customer_id, plan_id, start_date, 
LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_start_date,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) AS rn
FROM subscriptions
),

valid_subs AS (
SELECT os.*, p.plan_name, p.price
FROM ordered_subs os
JOIN plans p ON os.plan_id = p.plan_id
WHERE os.plan_id NOT IN (0, 4) -- Exclude trial and churn
),

recurring_payments AS (
  -- Generate monthly payments using recursion
SELECT vs.customer_id, vs.plan_id, vs.plan_name, vs.price, vs.start_date AS payment_date,
vs.next_start_date, 1 AS payment_order
FROM valid_subs vs
WHERE vs.plan_id IN (1, 2) -- Basic Monthly and Pro Monthly

UNION ALL

SELECT rp.customer_id, rp.plan_id, rp.plan_name, rp.price,
DATEADD(month, 1, rp.payment_date), rp.next_start_date, rp.payment_order + 1
FROM recurring_payments rp
WHERE DATEADD(Month, 1, rp.payment_date) < COALESCE(rp.next_start_date, '2021-01-01')
),

upgrade_payments AS (
SELECT os.customer_id, os.next_plan_id AS plan_id,
p.plan_name,
CASE
-- Basic to Pro Monthly (1 -> 2)
WHEN os.plan_id = 1 AND os.next_plan_id = 2 THEN
ROUND(pm.price - bm.price * DATEDIFF(day, os.next_start_date, os.start_date) / 30, 2)
-- Basic to Pro Annual (1 -> 3)
WHEN os.plan_id = 1 AND os.next_plan_id = 3 THEN
ROUND(pa.price - bm.price * DATEDIFF(day, os.next_start_date, os.start_date) / 30, 2)
-- Pro Monthly to Pro Annual (2 -> 3): full price of Pro Annual
WHEN os.plan_id = 2 AND os.next_plan_id = 3 THEN
pa.price
ELSE NULL
END AS amount,

CASE
WHEN os.plan_id = 2 AND os.next_plan_id = 3 THEN
-- Charge at end of monthly cycle
DATEADD(month, 1, os.start_date)
ELSE os.next_start_date
END AS payment_date,
99 AS payment_order
FROM ordered_subs os
JOIN plans p ON os.next_plan_id = p.plan_id
LEFT JOIN plans bm ON bm.plan_id = 1 -- basic
LEFT JOIN plans pm ON pm.plan_id = 2 -- pro monthly
LEFT JOIN plans pa ON pa.plan_id = 3 -- pro annual
WHERE os.plan_id NOT IN (0, 4)
AND os.next_plan_id IN (2, 3)
),

all_payments AS (
SELECT customer_id, plan_id, plan_name, payment_date, price AS amount, payment_order
FROM recurring_payments

UNION

SELECT customer_id, plan_id, plan_name, payment_date, amount, payment_order
FROM upgrade_payments)

--select * from all_payments
INSERT INTO payments (customer_id, plan_id, plan_name, payment_date, amount, payment_order)
SELECT
  customer_id,
  plan_id,
  plan_name,
  payment_date,
  amount,
  ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date)
FROM all_payments
WHERE payment_date < '2021-01-01'
ORDER BY customer_id, payment_date;

select * from payments;