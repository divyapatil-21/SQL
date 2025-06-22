 /* Welcome to Cloud Bank   The Future of Digital Banking & Cloud Storage
The financial industry is undergoing a digital revolution with the rise of 
Neo-Banks   modern, fully digital banks that operate without physical branches.

Amidst this transformation, We envisioned a futuristic blend of digital banking,
cloud technology, and the world of data. This vision gave rise to Cloud Bank   
a next-generation platform that combines traditional banking with distributed, secure cloud storage.

Cloud Bank works like any other digital bank for day-to-day financial activities.
However, it also offers a powerful twist: each customer is provided with cloud data 
storage and the amount of storage is dynamically linked to their account balance.

This hybrid banking-cloud model opens up new frontiers, but also presents unique challenges. That s where you come in.

The Cloud Bank leadership team aims to expand their customer base and needs data-driven insights to:

Forecast data storage requirements.

Understand customer behavior and growth patterns.

Optimize resource allocation and future planning.

This case study challenges you to analyze real-world metrics, growth trends, 
and operational data to help Cloud Bank make smart, scalable business decisions.
*/

--Cloud Bank Case Study Questions

--A. Customer Node Exploration
--How many unique nodes exist within the Cloud Bank system?
Select COUNT(DISTINCT node_id) as number_of_nodes
from customer_nodes;


--What is the distribution of nodes across different regions?
Select r.region_name, cn.node_id, count(cn.node_id) num_of_nodes
from customer_nodes cn join regions r
on cn.region_id = r.region_id
group by r.region_name, cn.node_id
order by r.region_name

--How many customers are allocated to each region?
Select r.region_name, count(distinct cn.customer_id) num_of_customers_allocated
from customer_nodes cn join regions r
on cn.region_id = r.region_id
group by r.region_name;

--select count(distinct customer_id) from customer_nodes

--On average, how many days does a customer stay on a node before being reallocated?
with c as(
select node_id, customer_id, DATEDIFF(day, start_date, end_date) as num_days
from customer_nodes
where year(end_date) != 9999)
select node_id,avg(num_days) avg_days
from c
group by node_id
order by node_id;

--What are the median, 80th percentile, and 95th percentile reallocation durations (in days) for customers in each region?****
with c as(
select customer_id, region_id,node_id, start_date, end_date,
lead(start_date) over(partition by region_id, customer_id  order by customer_id, start_date, end_date) as next_date
from customer_nodes 
where year(end_date) ! = 9999),
c1 as(
select regions.region_name, DATEDIFF(day, start_date, next_date) nod
from c join regions on c.region_id = regions.region_id)
select region_name, sum(nod)/count(nod) median,
0.8 * count(nod) as '80th_percentile',
95 * count(cast(nod as float))/100 as '95th_percentile'
from c1
group by region_name;


--B. Customer Transactions
--What are the unique counts and total amounts for each transaction type (e.g., deposit, withdrawal, purchase)?
select txn_type, count(txn_type) unique_count,
sum(txn_amount) as txn_amount
from customer_transactions
group by txn_type;

--What is the average number of historical deposits per customer, along with the average total deposit amount?*****
with cte as(
select customer_id, count(*) as deposit_count,
sum(txn_amount) deposit_amount
from customer_transactions
where txn_type = 'deposit'
group by customer_id)
select customer_id,
avg(deposit_count) as avg_deposit_count,
avg(deposit_amount) as avg_deposit_amount
from cte
group by customer_id
order by customer_id;


--For each month, how many Cloud Bank customers made more than one deposit and either one purchase or one withdrawal?
with cte as(
select customer_id, month(txn_date) as txn_month,
sum(case when txn_type = 'deposit' then 1 else 0 end) as deposit_count,
sum(case when txn_type = 'purchase' or txn_type = 'withdrawal' then 1 else 0 end) as other_count
from customer_transactions
group by customer_id, MONTH(txn_date)
),
c1 as(
select customer_id, txn_month
from cte 
where deposit_count > 1 and other_count = 1
)
select txn_month, count(distinct customer_id)
from c1
group by txn_month
order by txn_month;

--What is the closing balance for each customer at the end of every month?
with cte as(
select customer_id, txn_date, EOMONTH(txn_date) month_end,
case 
when txn_type = 'deposit' then txn_amount 
when txn_type = 'purchase' or txn_type = 'withdrawal' then -txn_amount
end as monthly_amount
from customer_transactions),

closing_amt as(
select customer_id, month_end,
sum(monthly_amount) as closing_amount
from cte
group by customer_id, month_end
)
select customer_id, month_end,
sum(closing_amount) over(partition by customer_id order by month_end 
rows between 1 preceding and current row) as closing_amount
from closing_amt
order by customer_id, month_end;


--What percentage of customers increased their closing balance by more than 5% month-over-month?
with cte as(
select customer_id, txn_date, EOMONTH(txn_date) month_end,
case 
when txn_type = 'deposit' then txn_amount 
when txn_type = 'purchase' or txn_type = 'withdrawal' then -txn_amount
end as monthly_amount
from customer_transactions),

cte1 as(
select customer_id, month_end,
sum(monthly_amount) as amt
from cte
group by customer_id, month_end
),
--calculating the closing amount per month
cte2 as(
select customer_id, month_end,
sum(amt) over(partition by customer_id order by month_end 
rows between unbounded preceding and current row) as closing_amount
from cte1),
--finding the prev month 
cte3 as(
select customer_id, month_end, closing_amount,
lag(closing_amount) over(partition by customer_id order by month_end) prev_mon_amt
from cte2
),--select * from cte3;

cte4 as(
select customer_id, month_end, closing_amount, prev_mon_amt,
case when prev_mon_amt > 0 then ((closing_amount - prev_mon_amt) / prev_mon_amt) * 100
else null end as perc_chng
--group by customer_id
from cte3
),
--select * from cte4;
cte5 as(
select distinct customer_id, closing_amount, prev_mon_amt from cte4
where perc_chng > 5
)
--select * from cte5
select 
(select count(distinct customer_id) from cte5) * 100.0 / 
(select count(distinct customer_id) from cte4 where prev_mon_amt is not null) 
as percent_of_customers;


--C. Cloud Storage Allocation Challenge
--The Cloud Bank team is experimenting with three storage allocation strategies:

--Option 1: Storage is provisioned based on the account balance at the end of the previous month

--Option 2: Storage is based on the average daily balance over the previous 30 days

--Option 3: Storage is updated in real-time, reflecting the balance after every transaction

--To support this analysis, generate the following:

--A running balance for each customer that accounts for all transaction activity
select customer_id, txn_date, txn_type, txn_amount,
sum(
case when txn_type = 'deposit' then txn_amount
else -txn_amount end
) over(partition by customer_id order by txn_date) as running_balance
from customer_transactions;


--The end-of-month balance for every customer
with cte as(
select customer_id, txn_date, EOMONTH(txn_date) month_end,
case 
when txn_type = 'deposit' then txn_amount 
when txn_type = 'purchase' or txn_type = 'withdrawal' then -txn_amount
end as monthly_amount
from customer_transactions),

closing_amt as(
select customer_id, month_end,
sum(monthly_amount) as closing_amount
from cte
group by customer_id, month_end
)

select customer_id, datename(month, month_end),
sum(closing_amount) over(partition by customer_id order by month_end 
rows between 1 preceding and current row) as closing_amount
from closing_amt
order by customer_id, month_end;

--The minimum, average, and maximum running balances per customer
with cte as(
select customer_id, txn_date, txn_type, txn_amount,
sum(
case when txn_type = 'deposit' then txn_amount
when txn_type IN ('purchase', 'withdrawal') then -txn_amount
else 0
end
) over(partition by customer_id order by txn_date) as running_balance
from customer_transactions)
select customer_id, min(running_balance) as min_running_balance,
avg(running_balance) as avg_running_balance,
max(running_balance) as max_running_balance
from cte group by customer_id;

--Using this data, estimate how much cloud storage would have been required for each allocation option on a monthly basis.
--STORAGE ALLOCATION FOR OPTION 1
--Storage is provisioned based on the account balance at the end of the previous month

with cte as(
select customer_id, eomonth(txn_date)month_end,
case when txn_type = 'deposit' then txn_amount
else -txn_amount end as amount
from customer_transactions
),
monthly_amt as(
select customer_id, month_end, sum(amount) monthly_txn_amt
from cte
group by customer_id, month_end
),--select * from monthly_amt order by customer_id

closing_amt as(
select customer_id, month_end,
sum(monthly_txn_amt) over(partition by customer_id order by month_end
rows between unbounded preceding and current row) as closing_balance
from monthly_amt
)--select * from closing_amt

select customer_id, month_end,
concat(lag(closing_balance, 1, 0) over(partition by customer_id order by month_end), ' GB') as storage_allocated
from closing_amt
order by customer_id;

--Option 3: Storage is updated in real-time, reflecting the balance after every transaction
with cte as(
select customer_id, txn_date, EOMONTH(txn_date) month_end,
case 
when txn_type = 'deposit' then txn_amount 
when txn_type = 'purchase' or txn_type = 'withdrawal' then -txn_amount
end as monthly_amount
from customer_transactions),

closing_amt as(
select customer_id, month_end,
sum(monthly_amount) as closing_amount
from cte
group by customer_id, month_end
)

select customer_id, datename(month, month_end),
sum(closing_amount) over(partition by customer_id order by month_end 
rows between 1 preceding and current row) as closing_amount
from closing_amt
order by customer_id, month_end;


--D. Advanced Challenge: Interest-Based Data Growth
--Cloud Bank wants to test a more complex data allocation method: applying an interest-based growth model similar to traditional savings accounts.

--If the annual interest rate is 6%, how much additional cloud storage would customers receive if:

--Interest is calculated daily, without compounding?

--(Optional Bonus) Interest is calculated daily with compounding?
