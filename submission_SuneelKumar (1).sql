/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries

-----------------------------------------------------------------------------------------------------------------------------------*/
-- Selecting "new_wheels" as default database, so that we dont need to use schema in query everytime
use new_wheels;  
-- Checking for duplicates

select customer_id,count(*) 
	from customer_t 
	group by customer_id 
    having count(*) >1;
select 
	order_id,count(*) 
	from order_t 
    group by order_id 
    having count(*) >1;
select sum(quantity) from order_t;
select product_id,count(*) 
	from product_t 
    group by product_id 
    having count(*) >1;
select shipper_id,count(*) 
	from shipper_t 
    group by shipper_id 
    having count(*) >1;
    
-- Total Revenue in Millions
select * from order_t;
select sum(quantity*(vehicle_price-(vehicle_price*discount)))/1000000 as total_revenue from order_t;

-- Total orders
select count(order_id) from order_t;

-- Total Customers
select count(customer_id) from customer_t;

-- Average Rating
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.
select avg(rating),max(rating),min(rating) from 
(select 
case when customer_feedback = 'Very bad' then 1
	 when customer_feedback = 'Bad' then 2 
     when customer_feedback = 'Okay' then 3
     when customer_feedback = 'Good' then 4 
     when customer_feedback = 'Very Good' then 5 end as rating
from order_t
) as a;


-- Average rating from the states with high number of customers
select avg(rating),max(rating),min(rating) from 
(select 
case when customer_feedback = 'Very bad' then 1
	 when customer_feedback = 'Bad' then 2 
     when customer_feedback = 'Okay' then 3
     when customer_feedback = 'Good' then 4 
     when customer_feedback = 'Very Good' then 5 end as rating
from order_t o join customer_t c on o.customer_id=c.customer_id where c.state in('Texas','California')
) as a;



-- Last Quarter Revenue
select sum(quantity*(vehicle_price-(vehicle_price*discount)))/1000000 as total_revenue from order_t where quarter_number=4;

-- Last Quarter Revenue
select quarter_number,count(distinct order_id) from order_t group by quarter_number;

-- Average days to ship
select quarter_number,avg(datediff(ship_date,order_date)) from order_t group by quarter_number;

-- Percentage of Very Good Rating
select (select count(*) from order_t where customer_feedback='Very Good')/(count(*))*100 from order_t;
select sum(case when customer_feedback='Very Good' then 1 else 0 end)/(count(*))*100 from order_t;
    
-- Quarter with highest "Very Good" ratings
select quarter_number,count(*) from order_t where customer_feedback='Very Good' group by quarter_number;
select quarter_number,count(*) from order_t where customer_feedback='Very Bad' group by quarter_number;
    
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/


select state,count(customer_id) as no_of_customers
	from customer_t 
    group by state 
    order by 2 desc;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

*/

with rating_cte as (select order_id,quarter_number,customer_feedback,
case when customer_feedback = 'Very bad' then 1
	 when customer_feedback = 'Bad' then 2 
     when customer_feedback = 'Okay' then 3
     when customer_feedback = 'Good' then 4 
     when customer_feedback = 'Very Good' then 5 end as rating
     from order_t)
select quarter_number,avg(rating) as average_rating from rating_cte group by quarter_number order by 1;
     



-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
 */
with Q3_CTE as (
 select order_id,customer_feedback,quarter_number,count(customer_feedback) over(partition by customer_feedback,quarter_number)as tot_rating from order_t) 
 select distinct c.customer_feedback,c.quarter_number,c.tot_rating,d.tot, round(tot_rating*100/tot,2) as rating_percentage from q3_cte c 
 join (select quarter_number,count(*) as tot from order_t group by quarter_number) d on c.quarter_number=d.quarter_number;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/
select * from product_t;
select * from order_t;
select vehicle_maker,count(distinct customer_id) as no_of_customers from product_t p join order_t o 
on p.product_id=o.product_id group by vehicle_maker order by 2 desc limit 5;

select vehicle_maker,count(vehicle_color),avg(vehicle_price) from product_t group by vehicle_maker order by 2 desc limit 5;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/
select state,vehicle_maker from (select state,vehicle_maker,count(*),rank() over(partition by state order by count(*) desc) as rnk 
from order_t o join product_t p 
on p.product_id = o.product_id 
join customer_t c 
on c.customer_id=o.customer_id group by state,vehicle_maker) as a where a.rnk=1;


-- Another query to acheive the same output
select state,vehicle_maker from (select state,vehicle_maker,no_of_customers,dense_rank() over(partition by state order by no_of_customers desc) as rnk from 
(select state,vehicle_maker,count(*) as no_of_customers 
from order_t o join product_t p 
on p.product_id = o.product_id 
join customer_t c 
on c.customer_id=o.customer_id
group by state,vehicle_maker) as a) as b where rnk=1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/
select * from order_t;
select distinct quarter_number,count(order_id) over(partition by quarter_number) as no_of_orders, sum(quantity) over(partition by quarter_number) as  total_quantity
  from order_t;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/

with orders_cte as (
	select distinct quarter_number,count(order_id) over(partition by quarter_number) as no_of_orders, 
    sum(quantity) over(partition by quarter_number) as  total_quantity,
    sum(quantity*(vehicle_price-(vehicle_price*discount))) over(partition by quarter_number) as revenue
	from order_t)
select quarter_number,no_of_orders as curr_orders,lag(no_of_orders) over(order by quarter_number) as prev_orders,
	(no_of_orders-(lag(no_of_orders) over(order by quarter_number)))*100/no_of_orders as QoQ_Percentage 
	,total_quantity,lag(total_quantity) over(order by quarter_number) as prev_orders,revenue,
    lag(revenue) over(order by quarter_number) as QoQ_revenue,
    (revenue-(lag(revenue) over(order by quarter_number)))*100/revenue as QoQ_percentage_change_in_revenue
	from orders_cte;
      

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

with orders_cte as (
	select distinct quarter_number,
    count(order_id) over(partition by quarter_number) as no_of_orders, 
    sum(quantity) over(partition by quarter_number) as  total_quantity,
    sum(quantity*(vehicle_price-(vehicle_price*discount))) over(partition by quarter_number) as revenue
from order_t)
select * from orders_cte;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/
select credit_card_type,avg(o.discount) as avg_discount from shipper_t s join order_t o on s.shipper_id=o.shipper_id
join customer_t c on c.customer_id=o.customer_id group by credit_card_type;
-- average discount over quarters
select quarter_number,avg(o.discount) as avg_discount from shipper_t s join order_t o on s.shipper_id=o.shipper_id
join customer_t c on c.customer_id=o.customer_id group by quarter_number order by 1;




-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

select quarter_number,avg(datediff(ship_date,order_date)) as days_taken_to_ship from order_t group by quarter_number order by 1;



-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



