select * from album
select * from artist
select * from customer
select * from employee
select * from genre
select * from invoice
select * from invoiceline
select * from mediatype
select * from playlist
select * from playlisttrack
select * from track

--Basic SQL (SELECT, WHERE, ORDER BY, LIMIT)
--List all customers.
select * from customer

--Show all tracks with their names and unit prices.
select trackid, name, unitprice from track

--List all employees in the sales department.
select employeeid, firstname, lastname, title from employee
where Title= 'Sales Support agent'

--Retrieve all invoices from the year 2011.
select * from Invoice 
where InvoiceDate> '2011-01-01'

--Show all albums by "AC/DC".
select AlbumId, Title, al.ArtistId from Album as al
join artist as a on al.ArtistId=a.ArtistId
where a.Name='AC/DC'

--List tracks with a duration longer than 5 minutes.
select trackid, name, milliseconds , (milliseconds/60000 )as minutes
from track
where (milliseconds/60000 )>5

--Get the list of customers from Canada.
select * from customer
where Country= 'canada'

--List 10 most expensive tracks.
select top 10  * from track
order by UnitPrice  desc

--List employees who report to another employee.
select * from employee
where EmployeeId<> ReportsTo and ReportsTo is not null

--Show the invoice date and total for invoice ID 5.
select InvoiceId, InvoiceDate, total from invoice
where InvoiceId=5

--SQL Joins (INNER, LEFT, RIGHT, FULL)
--List all customers with their respective support representative's name.
select *, e.FirstName 
from customer as c
left join Employee as e on c.SupportRepId=e.EmployeeId

--Get a list of all invoices along with the customer name.
select  InvoiceId,i.CustomerId, InvoiceDate, (c.firstname + '  '+  c.lastname ) as customer_name
from Invoice as i
left join Customer as c on i.CustomerId=c.CustomerId

--Show all tracks along with their album title and artist name.
select t.trackid, t.name, t.composer, a.Title
from Track as t
join Album as a on t.AlbumId=a.AlbumId
join artist as at on a.ArtistId=at.Artistid

--List all playlists and the number of tracks in each.
select p.playlistid, p.name as playlist_name, count(pt.TrackId) as total_tracks
from Playlist as p 
left join PlaylistTrack as pt on p.PlaylistId=pt.PlaylistId
group by p.playlistid, p.name 


--Get the name of all employees and their managers (self-join).
select  (e2.lastname + ' ' + e2.firstname) as employee_name,e1.title, (e1.lastname + ' ' +e1. firstname) as manager_name
from Employee as e1 
 right join Employee as e2 on e1.EmployeeId=e2.ReportsTo


--Show all invoices with customer name and billing country.
select invoiceid, (firstname + ' ' + lastname) as customer_name, billingcountry
from Invoice as i 
left join Customer as c on i.CustomerId=c.CustomerId

--List tracks along with their genre and media type.
select t.trackid, t.name as track_name, m.name as media_name, g.name as genre_name
from Track as t
join MediaType as m on t.MediaTypeId=m.MediaTypeId
join Genre as g on t.GenreId=g.GenreId


--Get a list of albums and the number of tracks in each.
select a.albumid, title, COUNT(trackid) as total_track
from Album as a 
left join Track as t on a.AlbumId=t.AlbumId
group by a.albumid, title


--List all artists with no albums.
select a.artistid, a.name as artist_name 
from Artist as a
left join Album as al on a.ArtistId=al.ArtistId
where al.AlbumId is null

---Find all customers who have never purchased anything.
select c.CustomerId, (firstname + ' ' + lastname) as customer_name, i.InvoiceId, i.InvoiceDate
from customer as c 
left join Invoice as i on c.CustomerId=i.CustomerId
where i.InvoiceId is null


--Aggregations and Group By
--Count the number of customers in each country.
select COUNT(customerid) as total_customers, country
from customer
group by country

--Total invoice amount by each customer.
select invoiceid,(firstname + ' ' + lastname) as customer_name, SUM(total) as total_amount
from Invoice as i 
left join Customer as c on i.CustomerId=c.CustomerId
group by invoiceid, (firstname + ' ' + lastname)

--Average track duration per album.
select a.albumid, a.title, AVG(milliseconds)/60000 as avg_duration_min 
from Album as a
join Track as t  on a.albumid=t.albumid
group by  a.albumid, a.title

--Total number of tracks per genre.
select COUNT(t.trackid) as  total_track, g.name
from Track as t 
join Genre as g on t.GenreId=g.GenreId
group by g.Name

--Revenue generated per country.
select country, sum(total) as revenue
from Customer as c
join Invoice as i on c.CustomerId=i.CustomerId
group by country

--Average invoice total per billing city.
select billingcountry, AVG(total) as avg_invoice
from Invoice
group by BillingCountry

--Number of employees per title.
select title, COUNT(employeeid) as total_employee
from Employee
group by title

--Find the top 5 selling artists.
with c as (
select  al.albumid,al.ArtistId,  al.title, SUM(i.quantity*i.unitprice) as total_price
from Album as al 
join Track as t on al.AlbumId=t.AlbumId
join InvoiceLine as i on t.TrackId=i.TrackId
group by al.albumid,al.ArtistId,  al.title
)
select top 5 c.albumid, c.artistid, c.title , c.total_price
from c as c
join Artist as a  on c.artistid=a.artistid
order by total_price desc

--Number of playlists containing more than 10 tracks.
with c as (
select p.playlistid, p.name as playlist_name, count(pt.TrackId) as total_tracks
from Playlist as p 
left join PlaylistTrack as pt on p.PlaylistId=pt.PlaylistId
group by p.playlistid, p.name 
having COUNT(pt.trackid)>10
)
select  COUNT(total_tracks) as more_than_10_tracks
from c

--Top 3 customers by invoice total.
select top 3 i.Invoiceid, (c.firstname + ' ' + c.lastname) as customer_name, SUM(i.total) as total_amount
from  Invoice as i 
left join Customer as c on i.CustomerId=c.CustomerId
group by invoiceid, (firstname + ' ' + lastname)
order by SUM(i.total) desc

--Subqueries (Scalar, Correlated, IN, EXISTS)

--Get customers who have spent more than the average.
select customerid,  SUM(total) as total_spent
from invoice 
group by customerid
having SUM(total) > (select AVG(total) from Invoice)

------------------------------------
SELECT c.CustomerId, c.FirstName, c.LastName, TotalSpent
FROM Customer c
JOIN (
    SELECT CustomerId, SUM(Total) AS TotalSpent
    FROM Invoice
    GROUP BY CustomerId
) t ON c.CustomerId = t.CustomerId
WHERE t.TotalSpent > (SELECT AVG(Total) FROM Invoice);

--List tracks that are more expensive than the average price.
select trackid, name , unitprice
from Track 
where UnitPrice> (select AVG(unitprice) from Track)


--Get albums that have more than 10 tracks.
SELECT a.albumid, a.title
FROM Album AS a
JOIN Track AS t ON a.albumid = t.albumid
GROUP BY a.albumid, a.title
HAVING COUNT(t.trackid) > 10;
------------------------------------
select sub.albumid, sub.title, sub.total_track
from( 
select a.albumid, a.title, COUNT(t.trackid) as total_track
from Album as a
left join track as t on  a.albumid=t.albumid
group by a.albumid, a.title
) as sub
where sub.total_track >10


--Find artists with more than 1 album.
select a.artistid, a.name , count(al.albumid) as total_album
from artist as a
join Album as  al on a.ArtistId=al.ArtistId
group by a.artistid, a.name 
having count(al.albumid) >1

------------------------
select sub.artistid, sub.name, sub.total_album 
from (
select a.artistid, a.name, COUNT(albumid) as total_album
from artist as a
join Album as  al on a.ArtistId=al.ArtistId
group by a.artistid, a.name
) as sub 
where sub.total_album  >1

--Get invoices that contain more than 5 line items.
select i.invoiceid,  COUNT(il.InvoiceLineid) as count_invoiceline
from Invoice as i 
join InvoiceLine as il on i.InvoiceId=il.invoiceid
group by i.invoiceid
having  COUNT(il.InvoiceLineid)>5
--------------------------
select sub.Invoiceid, sub.count_invoiceline
from (select i.invoiceid, count(il.InvoiceLineid) as count_invoiceline
from invoice as i 
join invoiceLine as il on i.InvoiceId=il.invoiceid
group by i.invoiceid
)as sub
where sub.count_invoiceline>5

--Find tracks that do not belong to any playlist.
select trackid, name
from Track
where trackid not in ( select TrackId from PlaylistTrack)

--List customers with invoices over $15.
select  c.customerid, (c.firstname + '  ' + c.LastName ) as customer_name, i.total
from customer as c 
join  Invoice as i on c.CustomerId=i.CustomerId
where i.Total>15
----------------------------------
select *  from (
select  c.customerid, (c.firstname + '  ' + c.LastName ) as customer_name, i.total
from customer as c 
join  Invoice as i on c.CustomerId=i.CustomerId
) as sub
where sub.Total>15


--Show customers who have purchased all genres.
select  * from (
select c.customerid, COUNT(distinct GenreId) as count_genre
from Customer as c
left join Invoice as i  on c.CustomerId=i.CustomerId
left join InvoiceLine as il on i.invoiceid=il.invoiceid
left join Track as t on il.TrackId=t.TrackId
group by c.customerid
) as sub 
where count_genre in (select COUNT(distinct genreid) from track)
-------------------------------------
select c.customerid, COUNT(distinct GenreId) as count_genre
from Customer as c
left join Invoice as i  on c.CustomerId=i.CustomerId
left join InvoiceLine as il on i.invoiceid=il.invoiceid
left join Track as t on il.TrackId=t.TrackId
group by c.customerid

--Find customers who haven’t bought from the 'Rock' genre.
select distinct  customerid
from customer 
where customerid not in 
(
select  distinct c.customerid
from Customer as c
left join Invoice as i  on c.CustomerId=i.CustomerId
left join InvoiceLine as il on i.invoiceid=il.invoiceid
left join Track as t on il.TrackId=t.TrackId
left Join Genre as g on t.GenreId=g.GenreId
where  g.name<> 'rock'
)  

--List tracks where unit price is greater than the average unit price of its media type.
select trackid,name, MediaTypeId, unitprice
from Track  as t
where exists (
select 1  from Track as t1 
group by MediaTypeId 
having t.MediaTypeId=t1.MediaTypeId and t.unitprice > AVG(unitprice)
)


--Advanced Joins and Set Operations
--Get tracks in both 'Rock' and 'Jazz' playlists.
select t.name 
from Track as t 
join Genre as g on t.GenreId=g.GenreId
where g.Name='rock'
intersect
select t.name 
from Track as t 
join Genre as g on t.GenreId=g.GenreId
where g.Name='Jazz'

--List all tracks that are in 'Pop' but not in 'Rock' playlists.
select t.name 
from Track as t 
join Genre as g on t.GenreId=g.GenreId
where g.Name='pop'
except
select t.name 
from Track as t 
join Genre as g on t.GenreId=g.GenreId
where g.Name='rock'

--Union customers from USA and Canada.
select country from Customer where Country='USA'
UNION all
select country from Customer where Country='canada'

--Intersect customers from Canada and those who bought ‘AC/DC’ albums.
select customerid, firstname, Country from Customer where Country='canada'
intersect
select c.customerid, c.firstname, c.country
from Track as t
join Album as al on t.AlbumId=al.AlbumId
join artist as a on al.ArtistId=a.artistid
join Invoiceline as  il on t.TrackId=il.TrackId
join Invoice as i on il.InvoiceId=i.InvoiceId
join Customer as c on i.CustomerId=c.CustomerId
where a.Name='AC/DC'


--Get artists that have albums but no tracks.
select a.artistid, a.Name from artist as a
Join Album as al on a.ArtistId=al.ArtistId
except 
select a.artistid, a.Name  from artist as a
Join Album as al on a.ArtistId=al.ArtistId
Join Track as t on al.AlbumId=t.AlbumId


--Find employees who are not assigned any customers.
select employeeid from employee 
except
select supportrepid from Customer
where SupportRepId is not null

--List invoices where total is greater than the sum of any other invoice.
select invoiceid, customerid, total from Invoice as i 
where Total > all(select Total from Invoice as v  where i.InvoiceId<>v.InvoiceId)


--Get customers who have made more than 5 purchases using a correlated subquery.
select customerid, firstname from Customer as c
where (
    select count(*)
    from Invoice i
    where i.CustomerId = c.CustomerId
) > 5;


--List tracks that appear in more than 2 playlists.
select t.trackid, t.name, COUNT(p.Playlistid) as count_playlist
from Track t
join PlaylistTrack as p on t.TrackId=p.trackid
group by  t.trackid, t.name
having COUNT(p.Playlistid)>2


--Show albums where all tracks are longer than 3 minutes.
select albumid, title 
from Album 
except 
select a.albumid, a.title from Album as a 
join Track as t on a.AlbumId=t.AlbumId
where t.Milliseconds/60000.0 <= 3
--------------------------------------------------------------------------------------------
--Window Functions
--Rank customers by total spending.
select c.Customerid, c.firstname, sum(i.total) as total_spent, RANK() over(order by sum(i.total) desc) as rank
from Customer as c
join Invoice as i on c.CustomerId=i.customerid
group by c.Customerid, c.firstname

--Show top 3 selling genres per country.
with c as (
select t.genreid , c.country, sum(i.total) as totalsales,   Rank() over(partition by country order by sum(i.total) desc) as rn
from Customer as c
join Invoice as i on c.CustomerId=i.CustomerId
join InvoiceLine as il on i.InvoiceId=il.InvoiceId
join Track as t on il.trackid=t.TrackId
group by  t.genreid, c.country
)
select genreid, country, totalsales, rn
from c
where rn<4

--Get running total of invoice amounts by customer.
select invoiceid, c.customerid, SUM(total) over(partition by c.customerid order by invoiceid rows between unbounded preceding and current row) as  amount
from Invoice as i 
join Customer as c on i.customerid=c.CustomerId

--Find the invoice with the highest amount per customer.
with c as (
select i.invoiceid, c.customerid, i.total , ROW_NUMBER() over(partition by c.customerid order by i.total desc ) as rn
from Customer as c
join Invoice as i on c.CustomerId=i.CustomerId
)
select * from c
where rn=1


--Get the dense rank of employees by hire date.
select employeeid, firstname, lastname, hiredate, dense_rank() over(order by hiredate asc) as rank
from employee

--List tracks along with their rank based on unit price within each genre.
select trackid, g.genreid, g.name, unitprice, dense_RANK() over(partition by g.genreid order by unitprice) as  rank
from Track as t
join Genre as g  on t.GenreId=g.GenreId

--Compute average invoice total by country using window functions.
select i.invoiceid, c.customerid,c.country, i.total, AVG(total) over(partition by country )as rank
from Customer as c
join Invoice as i on c.CustomerId=i.customerid

--Show lag/lead of invoice totals per customer.
select c.customerid,i.invoiceid, i.total, Lag(i.total) over(partition by c.customerid order by i.total) as  previous_total, lead(i.total) over(partition by c.customerid order by i.total) as next_total
from Customer as c
left join Invoice as i on c.CustomerId=i.CustomerId

--List customers and their second highest invoice.
with c as (
select i.invoiceid, c.customerid, i.total , ROW_NUMBER() over(partition by c.customerid order by i.total desc ) as rn
from Customer as c
join Invoice as i on c.CustomerId=i.CustomerId
)
select * from c
where rn=2


--Get the difference in invoice total from previous invoice for each customer.
select c.customerid, invoiceid, total, LAG(total) over(partition by c.customerid order by total) as previous_total,
total - LAG(total) over(partition by c.customerid order by total)  as diff_invoices
from Customer as  c
join Invoice as i on c.CustomerId=i.CustomerId
---------------------------------------------------------------------

--CTEs and Recursive Queries
--List employees and their managers using recursive CTE.
with recursive_cte as(
select employeeid, cast((firstname + '  ' + lastname) AS nvarchar(20)) as employee_name, reportsto, CAST(null as nvarchar(20)) as manager_name
from Employee
where ReportsTo is null
 
 union all

 select e.employeeid, cast((firstname + '  ' + lastname) AS nvarchar(20)) as employee_name , e.reportsto, r.employee_name
 from Employee as e
 join recursive_cte as r on e.ReportsTo=r.employeeid
 )
 select * from recursive_cte


--Use CTE to get top 3 customers by total spending.
with c as (
select invoiceid, c.customerid, sum(total) as total_spent
from Customer as c
join Invoice as i on c.CustomerId=i.customerid
group by invoiceid, c.customerid
) 
select top 3 * from c
order by total_spent desc

--Create a CTE to list all invoice lines for albums by 'Metallica'.
with c as (
select i.InvoiceLineid, i.invoiceid,i.trackid, i.unitprice, i.quantity, a.name as artist_name
from invoiceline as i
join track as t on i.TrackId=t.TrackId
join Album as al on t.AlbumId=al.AlbumId
join Artist as a on al.ArtistId=a.artistid
) 
select * from c
where  c.artist_name='metallica'

--Use a CTE to show all tracks that appear in more than one playlist.
with c as (
select t.trackid, t.name as track_name,  COUNT(p.playlistid) as count_playlist
from Track as t
join PlaylistTrack as pt on t.TrackId=pt.TrackId
join Playlist as p on pt.PlaylistId=p.PlaylistId
group by t.trackid, t.name
)
select * from c
where count_playlist >1
order by trackid 

--Recursive CTE to list employee hierarchy (if > 2 levels).


--CTE to get all albums with total track time > 30 minutes.
with c as (
select a.albumid, a.title, sum(milliseconds)/60000 as total_min
from Track  as t 
left join Album as a on t.albumid=a.AlbumId
group by a.AlbumId,a.title
)
select *  from c 
where total_min>30

--Get top 5 albums by total revenue using CTE and window functions.
with c as (
select albumid, SUM(i.unitprice*quantity) as total_revenue
from InvoiceLine as i 
left Join Track as t on i.TrackId=t.trackid
group by AlbumId
) 
select top 5 albumid, total_revenue, ROW_NUMBER() over (order by total_revenue desc) as rn
from c

--Use CTE to find average track price per genre and filter only those above global average.
with c as(
select  Genreid,  AVG(unitprice) as avg_track
from track
group by  Genreid
) 
select c.genreid,g.name, avg_track
from c
join Genre as g on c.genreid=g.GenreId
where avg_track> (select AVG(unitprice) from Track)

--Create a CTE to rank all albums by number of tracks.
with c as  (
select a.albumid, a.title, COUNT(t.trackid) as total_tracks
from Album as a
join Track as t on a.AlbumId=t.AlbumId
group by a.albumid, a.title
)
select albumid, title, total_tracks, dense_RANK() over(order by total_tracks desc) as rank
from c


--Advanced Analytics
--Get month-over-month revenue change.
with c as (
select SUM(total) as revenue, FORMAT(invoicedate, 'yyyy-MM') as year_month
from Invoice 
group by FORMAT(invoicedate, 'yyyy-MM')
),
c1 as (
select year_month, revenue,  LAG(revenue) over(order by year_month) as previous_revenue
from c
)
select year_month, revenue, previous_revenue, ((revenue-previous_revenue)/previous_revenue)*100 as m_o_m
from c1


--Calculate customer lifetime value.
with c as (
SELECT  CustomerId,AVG(total) as total_avg, SUM(Total) AS total_value, COUNT(InvoiceDate) count_frequency,  DATEDIFF(day, MIN(InvoiceDate), GETDATE()) as active_days
FROM Invoice
GROUP BY CustomerId
)
select * , round(total_avg*count_frequency*(active_days/365.0), 2) as lifetime_value  from c

--Get retention: how many customers returned for a second purchase?
with c as (
  select customerid, COUNT(invoiceid) as total_purchase
  from Invoice 
  group by customerid     
)
select COUNT(*) as return_count
from c
where total_purchase>=2

--Identify top selling track in each country.
with c as (
select  t.trackid, t.name as track_name, i.billingcountry as country, sum(il.unitprice*il.quantity) as total_sales
from track as t
join invoiceline as il on t.trackid=il.trackid
join invoice as i on il.invoiceid=i.invoiceid
group by  i.billingcountry , t.trackid, t.name 
),
c1 as (
select *, row_number() over(partition by country order by total_sales desc) as rn
from c
)
select * from c1 
where rn=1

--Show invoice trends by quarter.
select YEAR(invoicedate) as invoice_year, DATEPART(QUARTER, invoicedate)as quarter, COUNT(invoiceid) as total_invoice, SUM(total) as total
from invoice
group by YEAR(invoicedate),DATEPART(QUARTER, invoicedate)

--Count customers acquired per year.
select COUNT(distinct Customerid) as count_customers, YEAR(Invoicedate) as acquired_year
from Invoice 
group by YEAR(Invoicedate)

--Find churned customers (no purchases in last 12 months).
with c as (
select  customerid, MAX(invoicedate) last_purchase_date
from invoice
group by CustomerId
)
select * from c
where last_purchase_date< DATEADD(MONTH, -12, GETDATE())

--Show most played tracks per user (using playlist track if usage data is simulated).
with c as (
select i.CustomerId, pt.TrackId, t.Name,  COUNT(*) AS num_of_times_played,
Rank() over(partition by customerid order by  COUNT(*) desc) as rn
from Invoiceline il 
left join Invoice i on il.InvoiceId = i.InvoiceId
left join track t on t.TrackId = il.TrackId
left join PlaylistTrack pt on pt.TrackId = il.TrackId
group by i.CustomerId, pt.TrackId, t.Name
)
select * from c
where rn=1
--Simulate cohort analysis by signup month.


--Calculate total revenue per artist using joins and group by.
select a.artistid,  isnull(SUM(i.unitprice*i.quantity),0) as total_revenue
from Artist as a
left join Album as al on a.ArtistId=al.ArtistId
left join Track as t on al.AlbumId=t.AlbumId
left join InvoiceLine as i on t.TrackId=i.TrackId
group by a.ArtistId


--Data Validation and Integrity Checks
--Find invoice lines with NULL unit price.
select * from InvoiceLine
where UnitPrice is null

--Detect duplicate tracks (by name, album, duration).
select name, albumid, milliseconds, COUNT(trackid) as duplicate_count
from Track 
group by Name, AlbumId, Milliseconds
having COUNT(trackid)>1

--List tracks with unit price < 0.
select * from Track 
where UnitPrice<0

--Find customers with missing emails.
select * from Customer
where Email is null

--Check for invoices without invoice lines.
select * from Invoice as i
join InvoiceLine as il on i.InvoiceId=il.InvoiceId
where il.InvoiceId is null

--Validate if total in invoices match the sum of invoice lines.
SELECT  i.InvoiceId,i.Total AS invoice_total,SUM(il.UnitPrice * il.quantity ) AS calculated_total
FROM Invoice i
JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
GROUP BY i.InvoiceId, i.Total
HAVING i.Total <> SUM(il.UnitPrice * il.quantity );

--Find tracks assigned to multiple genres (data anomaly).
select TrackId, COUNT(GenreId) AS genre_count
from Track
group by  TrackId
having COUNT(GenreId) > 1;

--Check for albums without artists.
select * from Album as al
join Artist as a on al.ArtistId=a.ArtistId
where a.ArtistId is null

--List employees who support more than 20 customers.
select e.EmployeeId, e.FirstName, e.LastName, COUNT(c.CustomerId) AS customer_count
FROM Employee e
JOIN Customer c ON e.EmployeeId = c.SupportRepId
GROUP BY e.EmployeeId, e.FirstName, e.LastName
HAVING COUNT(c.CustomerId) > 20;

--Show customers who have the same first and last names.
select * from Customer
where FirstName=LastName

--Business Scenarios
--Recommend top 3 tracks for a customer based on genre preference.

--Identify slow-moving tracks (not sold in last 12 months).
--Get summary of purchases per customer per genre.
--Find the artist with highest average track duration.
--Show difference in price between highest and lowest track per genre.
--Find customers who buy only once vs those who buy multiple times.
--List countries with the most revenue per capita (assume fixed population per country).
--Recommend albums with similar genre to customer past purchases.
--Estimate revenue impact if top 10% customers churn.
--Calculate the average invoice total per support rep’s customer group.



