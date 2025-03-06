--Q1) who is the senior most employee based on job title

select first_name , last_name , title from employee
order by levels desc
limit 1

--Q2) Which countries have the most invoices?

select  count(*) as total , billing_country
from invoice
group by billing_country
order by total  desc

--Q3) What are top 3 values of total invoice.

select total from invoice
order by total desc
limit 3

--Q4) Which city has the best customers? We would like to throw a promotional music festival in the
-- city we made the most money. Write a query that returns the one city that has the highest sum of 
-- invoice totals. Return both city name & sum of all invoice totals.

select sum(total) as invoice_total , billing_city
from invoice
group by billing_city
order by invoice_total desc
limit 1

--Q5) who is the best customer ? The customer who has spent the most money will be declared the best
-- customer. Write a query that returns the person who has spent the most money.

SELECT customer.customer_id, customer.first_name , customer.last_name , SUM(invoice.total) as total
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total DESC
limit 1


---------------------------------------- Moderate level--------------------------------------------

--Q1) Write query to return the email, first name, last name & Genre of all Rock Music listeners
-- return your list ordered alphabetically by email starting with A.

select distinct email, first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id IN
            (select track_id from track
             join genre on track.genre_id = genre.genre_id
             where genre.name = 'Rock')

order by email;


--Q2) Let's invite the artists who have written the most rock music in our data set . write a query that
--- returns the artist name and total track count of the top 10 rock bands.

select artist.artist_id , artist.name , COUNT(artist.artist_id) As number_of_songs
from track
join album ON album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name = 'Rock'
group by artist.artist_id
order by number_of_songs DESC
limit 10;

--Q3) Return all the track names that have a song length longer than the average song length. Return the Name
-- and Milliseconds for each track. Order by the song length with the longest songs listed first.

select name, milliseconds
FROM track
where milliseconds > (
                   select AVG(milliseconds) as average_track_length  from track)
				   order by milliseconds DESC;

----------------------------------HIGH LEVEL---------------------------------------------------------------

--Q1) Find how much amount spent by each customer on artists ? write a query to return customer name, artists 
-- name and total spent.

WITH best_selling_artist AS (
  select artist.artist_id as artist_id , artist.name AS artist_name,
  Sum(invoice_line.unit_price*invoice_line.quantity) AS total_sales
  From invoice_line
  JOIN track on track.track_id = invoice_line.track_id
  join album on album.album_id = track.album_id
  join artist on artist.artist_id = album.artist_id
  Group by 1
  order by 3 desc
  limit 1

)

Select c.customer_id, c.first_name , c.last_name, bsa.artist_name,
SUM (il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer C on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1,2,3,4
order by 5 desc;

--Q2) We want to find out the most popular music Genre for each country. We Determine the most
-- popular genre as the genre with the highest amount of Purchases. Write a query that returns
-- each country along with the Top Genre. For Countries where the maximum number of purchases 
-- is shared return all Genre

---1st Method :-

With popular_genre AS
(
 select count (invoice_line.quantity) As Purchases, customer.country , genre.name , genre.genre_id,
 ROW_Number() Over(Partition by customer.country order by count(invoice_line.quantity)DESC) as RowNo
 FROM Invoice_line
 join invoice on invoice.invoice_id = invoice_line.invoice_id
 join customer on customer.customer_id = invoice.customer_id
 join track on  track.track_id = invoice_line.track_id
 join genre on genre.genre_id = track.genre_id
 GROUP by 2,3,4
 ORDER BY 2 ASC , 1 DESC

)

select * from popular_genre WHERE RowNo <= 1
				   
--2nd Method :-

With Recursive
  sales_per_country AS (
      SELECt count(*) as purchases_per_genre, customer.country , genre.name, genre.genre_id
	  from invoice_line
	  JOIN invoice on invoice.invoice_id = invoice_line.invoice_id
	  Join customer on customer.customer_id = invoice.customer_id
	  join track on track.track_id = invoice_line.track_id
	  join genre on genre.genre_id = track.genre_id
	  GROUP BY 2,3,4
	  order by 2
	  
     ),
	 max_genre_per_country AS (select max(purchases_per_genre) AS max_genre_number, country
	 FROM sales_per_country
	 Group by 2
	 order by 2)

select sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
Where sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number ;

--Q3)Write a query that determines the customer that has spent the most on music for each country.
-- Write a query that returns the country along with the top customer and how much they spent. For countries
-- where the top amount spent is shared , provide all cusyomers who spent this amount.

--1st Method:--

With Customer_with_country As (
        SELECT customer.customer_id , first_name, last_name, billing_country, SUM(total) AS total_spending,
		ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total)DESC) AS RowNo
		FROM invoice
		JOIN customer on customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4 
		order by 4 ASC , 5 DESC)

select * from Customer_with_country where RowNo <= 1		


--2nd Method:--

With recursive 
      customer_with_country as (
              Select customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending
			  from invoice
			  JOIN customer on customer.customer_id = invoice.customer_id
			  group by 1,2,3,4
			  order by 2,3 DEsc),

	country_max_spending AS (
       SELECt billing_country, MAX(total_spending) AS max_spending
	   FROM customer_with_country
	   GROUP By billing_country)
	   
select cc.billing_country, cc.total_spending, cc.first_name , cc.last_name, cc.customer_id
FROM customer_with_country cc
join country_max_spending ms
on cc.billing_country = ms.billing_country
where cc.total_spending = ms.max_spending
ORDER by 1;


