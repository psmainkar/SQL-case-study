USE music;

-- Q1: Who is the senior most employee based on job title? 

SELECT title, last_name, first_name 
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- Q2: Which countries have the most Invoices?

SELECT COUNT(*) AS count, billing_country 
FROM invoice
GROUP BY billing_country
ORDER BY count DESC;


-- Q3: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 


SELECT billing_city,SUM(total) AS InvoiceTotal
FROM invoice
GROUP BY billing_city
ORDER BY InvoiceTotal DESC
LIMIT 5;


-- Q4: Who is the best customer? The customer who has spent the most money will be declared the best customer. 

SELECT customer.customer_id, first_name, last_name, SUM(total) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id
ORDER BY total_spending DESC
LIMIT 1;





-- Q5: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. order by email


SELECT DISTINCT email,first_name, last_name
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN(
	SELECT track_id FROM track
	JOIN genre ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;



-- Q6: artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands.  

SELECT artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10;


-- Q7: Return all the track names that have a song length longer than the average song length of the songs of its genre.
-- Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.  

SELECT t0.name,milliseconds,genre.name AS genre
FROM track t0
JOIN genre ON genre.genre_id= t0.genre_id
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track t1 WHERE t1.genre_id= t0.genre_id)

ORDER BY milliseconds DESC;


-- Q8 Which employees were the youngest aged when hired?

SELECT 
    hire_date,
    STR_TO_DATE(hire_date, '%d-%m-%Y %H:%i') AS parsed_hire_date,
    birthdate,
    STR_TO_DATE(birthdate, '%d-%m-%Y %H:%i') AS parsed_birthdate,
    DATEDIFF(STR_TO_DATE(hire_date, '%d-%m-%Y %H:%i'), STR_TO_DATE(birthdate, '%d-%m-%Y %H:%i')) / 365 AS age 
FROM 
    music.employee
ORDER BY 
    age ASC;










-- Q9: Find how much amount spent by each customer on the top artist? Write a query to return customer name, artist name and total spent  
 

WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


-- Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
-- with the highest amount of purchases. Write a query that returns each country along with the top Genre


WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1;


-- Q11: Write a query that determines the customer that has spent the most on music for each country. 

-- Method 1: using CTE  

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1;


-- Method 2: creating another temp table where the top spender's amount is collected 

WITH 
	customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC),

	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customter_with_country
		GROUP BY billing_country)

SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customter_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1;
