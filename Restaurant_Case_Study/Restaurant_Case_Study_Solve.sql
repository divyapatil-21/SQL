
CREATE database restaurant_case_study;

use restaurant_case_study

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales (customer_id, order_date, product_id) VALUES
  ('A', '2025-01-01', 1),
  ('A', '2025-01-01', 2),
  ('A', '2025-01-07', 2),
  ('A', '2025-01-10', 3),
  ('A', '2025-01-11', 3),
  ('A', '2025-01-11', 3),
  ('B', '2025-01-01', 2),
  ('B', '2025-01-02', 2),
  ('B', '2025-01-04', 1),
  ('B', '2025-01-11', 1),
  ('B', '2025-01-16', 3),
  ('B', '2025-02-01', 3),
  ('C', '2025-01-01', 3),
  ('C', '2025-01-01', 3),
  ('C', '2025-01-07', 3);

  
INSERT INTO sales (customer_id, order_date, product_id) VALUES
  ('c', null , 4)

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(20),
  price INTEGER
);

INSERT INTO menu (product_id, product_name, price) VALUES
  (1, 'biryani', 10),
  (2, 'paneer', 15),
  (3, 'dosai', 12);

  INSERT INTO menu (product_id, product_name, price) VALUES
  (4, 'Pizza', 18)

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members (customer_id, join_date) VALUES
  ('A', '2025-01-07'),
  ('B', '2025-01-09');

  select * from sales;
  select * from menu;
  select * from members


  -- Practice Question Case Study 1

-- 1. Total amount spent by each customer
select distinct s.customer_id, SUM(p.price) as Total_amount
from sales as s
join menu as p on  s.product_id= p.product_id
group by s.customer_id;

-- 2. Number of distinct visit days per customer
select s.customer_id, count(distinct(order_date)) as visit_days
from sales as s
group by s.customer_id

-- 3. First item purchased by each customer
select *  from (
select  customer_id, order_date, product_id,
ROW_NUMBER() over(PARTITION by  customer_id order by order_date asc) as rn
from sales 
) as ranked_orders
where rn =1;

-- 4. Most purchased item and count
 select top 1 product_id, COUNT(product_id) as countt 
 from sales 
 group by product_id
 order by countt desc

-- 5. Most popular item per customer
with popular_Item as (
select s.customer_id ,p.product_name, COUNT(*) as pop_item,
ROW_NUMBER() over(PARTITION by  s.customer_id order by COUNT(*) desc) as rn
from sales as  s
join menu as p
on s.product_id=p.product_id
group by  s.customer_id, p.product_name, s.product_id
)
select  customer_id ,product_name, pop_item from  popular_Item 
where rn=1

-- 6. First item after becoming a member
with first_item as (
select s.customer_id, p.product_name, s.order_date, s.product_id, 
row_number() over(partition by s.customer_id order by s.order_date ) as rn
from sales as s
join members as m 
on s.customer_id=m.customer_id
join menu as p
on s.product_id=p.product_id
where s.order_date>m.join_date
)
select customer_id, order_date, product_id, product_name
from first_item 
where rn=1;



select * from sales
select * from members
select * from menu

-- 7. Last item before becoming a member
with first_item as (
select s.customer_id, s.order_date, s.product_id, 
row_number() over(partition by s.customer_id order by s.order_date desc) as rn
from sales as s
join members as m 
on s.customer_id=m.customer_id
where s.order_date<m.join_date
)
select customer_id, order_date, product_id
from first_item 
where rn=1;


-- 8. Items and amount before becoming a member
with first_item as (
select s.customer_id, p.product_name, p.price, s.order_date,
row_number() over(partition by s.customer_id order by s.order_date desc) as rn
from sales as s
join members as m 
on s.customer_id=m.customer_id
join menu as p 
on s.product_id=p.product_id
where s.order_date<m.join_date
)
select customer_id, product_name, price, order_date
from first_item ;



select * from sales
select * from menu
select * from members


-- 9. Loyalty points: 2x for biryani, 1x for others
select s.customer_id,  p.product_name,

  SUM(case 
   when p.product_name='biryani' then 2*(p.price)
	else p.price
	end
	)as loyalty_points
	from sales as s
join menu as p 
on s.product_id= p.product_id
group by s.customer_id, p.product_name


select * from sales
select * from menu
select * from members

-- 10. Points during first 7 days after joining
select s.customer_id, 
 SUM(case 
   when p.product_name='biryani' then 2*(p.price)
	else p.price
	end
	)as loyalty_points
	from sales as s
join menu as p 
on s.product_id= p.product_id
join members as m
on s.customer_id=m.customer_id
where s.order_date>m.join_date and s.order_date<= DATEADD(DAY, 7, m.join_date) 
group by s.customer_id
 


-- 11. Total spent on biryani
 select p.product_name, SUM(p.price) as Total_spent
 from menu as p
 join sales as s on p.product_id= s.product_id
 where product_name='biryani'
 group by  p.product_name;

-- 12. Customer with most dosai orders
select top 3 s.customer_id, p.product_name, count(p.product_id)  as most_orders 
from sales as s
join menu as p on s.product_id= p.product_id
where product_name='dosai'
group by s.customer_id, product_name
order by  most_orders desc

 
-- 13. Average spend per visit
select s.customer_id, avg(p.price) as Total_amount
from sales as s
join menu as p on  s.product_id= p.product_id
group by s.customer_id;


-- 14. Day with most orders in Jan 2025
select top 1 order_date, COUNT(order_date) as total_orders  
from sales 
where month(order_date)=1  and YEAR(order_date)=2025
group by order_date
order by total_orders desc

-- 15. Customer who spent the least
select top  1 s.customer_id,  SUM(p.price) as total_spent
from sales as s
join menu as p 
on s.product_id=p.product_id
group by s.customer_id
order by  total_spent


-- 16. Date with most money spent
select  top 1 s.order_date, SUM(p.price) as money_spent
from sales as s
join menu as p
on s.product_id=p.product_id
group by  s.order_date
order by money_spent desc

-- 17. Customers with multiple orders on same day
select customer_id , order_date , COUNT(order_date) as multiple_orders
from sales
group by customer_id , order_date
having  COUNT(order_date) > 1


-- 18. Visits after membership
select s.customer_id, s.order_date
from sales as s
join members as m
on s.customer_id= m.customer_id
where s.order_date > m.join_date


-- 19. Items never ordered
select  p.product_id, p.product_name , s.order_date
from menu as p
join sales as s
on p.product_id=s.product_id
where s.order_date is null

-- 20. Customers who ordered but never joined
select s.customer_id, join_date
from sales as s
left join members as m
on s.customer_id=m.customer_id
where m.customer_id is null
group by s.customer_id, join_date  
