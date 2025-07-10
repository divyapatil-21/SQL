-- Question and Solution
select * from product_hierarchy
select * from product_details
select * from product_prices
select * from sales





## 📈 A. High Level Sales Analysis

--**1. What was the total quantity sold for all products?**
select  sum(qty) as count_quantity 
from sales

--**2. What is the total generated revenue for all products before discounts?**
select distinct prod_id, sum(price*qty) as total_revenue
from sales
where discount=0
group by prod_id

--**3. What was the total discount amount for all products?**
select prod_id, sum(discount) as total_discount from sales
group by prod_id

## 🧾 B. Transaction Analysis

--**1. How many unique transactions were there?**
select txn_id, count(*) as unique_txn
from sales
group by txn_id
having count(txn_id)=1
------------------
select count(distinct txn_id) as unique_txn
from sales

--**2. What is the average unique products purchased in each transaction?**
with c as (
select count(distinct prod_id) as count_products , txn_id
from sales
group by txn_id
)
select avg(count_products)  as avg_unique_products
from c

--**3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?**
with c as (
select txn_id, sum(price*qty) as total_price
from sales
group by txn_id
)
select 
percentile_cont(0.25) within group(order by total_price) over() as percentile_25th,
percentile_cont(0.50) within group(order by total_price) over() as percentile_50th,   
percentile_cont(0.75) within group(order by total_price) over() as percentile_75th
from c
group by percentile_25th, percentile_50th, percentile_75th

--**4. What is the average discount value per transaction?**
select txn_id, avg(discount) as avg_discount
from sales
group by txn_id

--**5. What is the percentage split of all transactions for members vs non-members?**
with c as (
select count(member) as total_members
from sales
),
c1 as(
select count(member) as members from sales where member =1
),
c2 as(
select count(member) as non_members from sales where member =0
)
select round(cast(members as float)/cast(total_members as float)*100,2) as members_percentage, 
round(cast(non_members as float)/cast(total_members as float)*100,2) as members_percentage
from c,c1, c2

--**6. What is the average revenue for member transactions and non-member transactions?**
select member, avg(price*qty-discount) as avg_revenue
from sales
group by member

--## 👚 C. Product Analysis

--**1. What are the top 3 products by total revenue before discount?**
select top 3 product_id, product_name, sum(p.price*qty) as total_revenue
from product_details as p
join sales as s on p.product_id= s.prod_id
where discount=0
group by product_id, product_name
order by total_revenue desc

--**2. What is the total quantity, revenue and discount for each segment?**
select segment_name, sum(qty)as total_qty, sum(p.price*qty) as total_revenue, sum(discount) as total_discount
from sales as s
join product_details as p on s.prod_id=p.product_id
group by segment_name
order by segment_name
--**3. What is the top selling product for each segment?**
with c as (
select product_id,segment_name , product_name,  sum(qty) as total_qty, 
Row_number() over(partition by segment_name order by sum(qty) desc) as rn

from product_details as p
join sales as s on p.product_id=s.prod_id
group by product_id, product_name, segment_name 
)
select segment_name , product_name, total_qty
from c
where rn=1


select * from product_details
--**4. What is the total quantity, revenue and discount for each category?**
select category_name, sum(qty)as total_qty, sum(p.price*qty) as total_revenue, sum(discount) as total_discount
from product_details as p
join sales as s on p.product_id=s.prod_id
group by category_name
order by category_name

--**5. What is the top selling product for each category?**
with c as (
select product_id,category_name , product_name,  sum(qty) as total_qty, 
Row_number() over(partition by category_name order by sum(qty) desc) as rn
from product_details as p
join sales as s on p.product_id=s.prod_id
group by product_id, product_name, category_name 
)
select category_name , product_name, total_qty
from c
where rn=1

--**6. What is the percentage split of revenue by product for each segment?**
with c as (
select segment_id, segment_name, product_name, sum(p.price*qty) as revenue
from product_details as p 
join sales as s on p.product_id=s.prod_id
group by segment_id, segment_name, product_name
),
c1 as (
select segment_name, sum(revenue) as total_revenue
from c
group by segment_name
)
select segment_id, c1.segment_name, product_name, round(100*cast(revenue as float)/cast(total_revenue as float),2) as percentage
from c as c
join c1 as  c1 on c.segment_name=c1.segment_name

select * from product_details
--**7. What is the percentage split of revenue by segment for each category?**
with c as (
select category_id, category_name, segment_name, sum(p.price*qty) as revenue
from product_details as p 
join sales as s on p.product_id=s.prod_id
group by category_id, category_name, segment_name
),
c1 as (
select category_name, sum(revenue) as total_revenue
from c
group by category_name
)
select category_id, c1.category_name, segment_name, round(100*cast(revenue as float)/cast(total_revenue as float),2) as percentage
from c as c
join c1 as  c1 on c.category_name=c1.category_name



--**8. What is the percentage split of total revenue by category?**
with c as (
select category_name, sum(p.price*qty) as revenue
from  product_details as p 
join sales as s on p.product_id=s.prod_id
group by  category_name
),
c1 as (
select sum(price*qty) as total_revenue
from sales
)
select  category_name, round(100*cast(revenue as float)/cast(total_revenue as float),2) as percentage
from c, c1

--**9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)**
with c as (
select product_name, count(txn_id) as count_txn
from product_details as p 
join sales as s on p.product_id=s.prod_id
where qty>0
group by product_name
),
c1 as (
select count(txn_id) as total_txn
from sales
)
select product_name, round(100*cast(count_txn as float)/cast(total_txn as float),4 )as penetration
from c,c1


--**10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?**
with c as (
select prod_id, txn_id 
from sales
where qty>1
),
select prod_id, txn_id ,count(prod_id) over(partition by txn_id ) as count_txn
from sales
where txn_id>=3



## 📝 Reporting Challenge

Write a single SQL script that combines all of the previous questions into a scheduled report that the QT team can run at the beginning of each month to calculate the previous month’s values.

Imagine that the Chief Financial Officer (which is also QT) has asked for all of these questions at the end of every month.

He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

***

## 💡 Bonus Challenge

Use a single SQL query to transform the `product_hierarchy` and `product_prices` datasets to the `product_details` table.

Hint: you may want to consider using a recursive CTE to solve this problem!

***