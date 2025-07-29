SELECT * 
FROM orders

SELECT * 
FROM products

SELECT * 
FROM delivery_person

SELECT * 
FROM customer

SELECT * 
FROM pincode

DROP TABLE orders
 

--1)How many customers do not have DOB information available
SELECT 
      COUNT(*) AS no_of_customers
FROM customer
WHERE dob is NULL OR TRIM(dob)='';

--2)How many customers are there in each pincode and gender combination
SELECT 
      COUNT(cust_id) AS no_of_customer, 
	  gender,
	  pincode
FROM customer
JOIN pincode ON
customer.primary_pincode=pincode.pincode
GROUP BY pincode.pincode, gender;

--3)Print product name and mrp for products which have more than 50000 MRP
SELECT 
      product_name, 
	  mrp 
FROM products
WHERE mrp >50000;

--4)How many delivery personal are there in each pincode
SELECT 
      COUNT(delivery_person_id) AS no_of_delivery_person,
	  pincode.pincode
FROM delivery_person
JOIN pincode ON
delivery_person.pincode=pincode.pincode
GROUP BY pincode.pincode;

/*5)For each Pin code, print the count of orders, sum of total amount paid, average amount
paid, maximum amount paid, minimum amount paid for the transactions which were
paid by 'cash'. Take only 'buy' order types*/
ALTER TABLE orders
ALTER COLUMN total_amount_paid INT;

SELECT 
     delivery_pincode,
	 COUNT(order_id) AS total_no_of_order_per_pincode,
	 SUM(total_amount_paid) AS sum_of_total_amount_per_pincode,
     AVG(total_amount_paid) AS avg_of_total_amount_per_pincode,
     MAX(total_amount_paid) AS max_amount_per_pincode,
     MIN(total_amount_paid) AS min_amount_per_pincode
FROM orders
WHERE payment_type ='cash' AND order_type='buy'
GROUP BY delivery_pincode;

/*6)For each delivery_person_id, print the count of orders and total amount paid for
product_id = 12350 or 12348 and total units > 8. Sort the output by total amount paid in
descending order. Take only 'buy' order types*/
SELECT 
      delivery_person_id,
	  COUNT(order_id) AS count_of_orders_per_deliveryperson,
      SUM(total_amount_paid) AS total_amount_paid 
FROM orders
WHERE (product_id=12350 OR product_id= 12348) AND tot_units>8 AND order_type='buy'
GROUP BY delivery_person_id
ORDER BY total_amount_paid DESC;

/*7)Print the Full names (first name plus last name) for customers that have email on
"gmail.com"*/
SELECT (first_name+' '+last_name)
FROM customer
WHERE email LIKE '%gmail.com';

/*8)Which pincode has average amount paid more than 150,000? Take only 'buy' order
types*/
SELECT 
      delivery_pincode,
	  AVG(total_amount_paid) AS avg_amount_paid_per_pincode
FROM orders
WHERE order_type='buy'
GROUP BY delivery_pincode
HAVING AVG(total_amount_paid)>150000

/*9)Create following columns from order_dim data -
 order_date
 Order day
 Order month
 Order year*/
UPDATE orders
SET order_date = CONVERT(DATE, order_date, 103);

ALTER TABLE orders
ALTER COLUMN order_date DATE;
SELECT 
    order_date,
    DAY(order_date) AS Order_day,
    MONTH(order_date) AS Order_month,
    YEAR(order_date) AS Order_year
FROM 
    orders;

/*10)How many total orders were there in each month and how many of them were
returned? Add a column for return rate too.
return rate = (100.0 * total return orders) / total buy orders
Hint: You will need to combine SUM() with CASE WHEN*/
SELECT 
      COUNT(order_id) AS total_orders,
	  MONTH(order_date) AS Order_month,
	  SUM(CASE WHEN order_type = 'return' THEN 1 ELSE 0 END) AS Total_Return_Orders,
	  (100.0 * SUM(CASE WHEN order_type = 'return' THEN 1 ELSE 0 END)) / COUNT(order_id) AS Return_Rate
FROM orders
GROUP BY MONTH(order_date);

/*11)How many units have been sold by each brand? Also get total returned units for each
brand.*/
ALTER TABLE orders
ALTER COLUMN tot_units INT;
SELECT 
      SUM(tot_units) AS total_units_sold,
      brand,
	  SUM(CASE WHEN order_type = 'return' THEN 1 ELSE 0 END) AS Total_Return_Orders
FROM products
JOIN orders ON 
   products.product_id=orders.product_id
GROUP BY brand;

/*12)How many distinct customers and delivery boys are there in each state*/
SELECT 
      pincode.state,
      COUNT(DISTINCT customer.cust_id) AS distinct_customer,
	  COUNT(DISTINCT delivery_person.delivery_person_id) AS distinct_deliery_boys
FROM pincode
JOIN customer ON 
              pincode.pincode=customer.primary_pincode
JOIN delivery_person ON 
              pincode.pincode=delivery_person.pincode
GROUP BY pincode.state;

/*13)For every customer, print how many total units were ordered, how many units were
ordered from their primary_pincode and how many were ordered not from the
primary_pincode. Also calulate the percentage of total units which were ordered from
primary_pincode(remember to multiply the numerator by 100.0). Sort by the
percentage column in descending order.*/
SELECT 
      C.cust_id,
	  SUM(O.tot_units) AS total_units_ordered,
	  SUM(CASE WHEN O.delivery_pincode = C.primary_pincode THEN O.tot_units ELSE 0 END) AS units_ordered_from_primary_pincode,
      SUM(CASE WHEN O.delivery_pincode <> C.primary_pincode THEN O.tot_units ELSE 0 END) AS units_ordered_not_from_primary_pincode,
    (100.0 * SUM(CASE WHEN O.delivery_pincode = C.primary_pincode THEN O.tot_units ELSE 0 END)) / SUM(O.tot_units) AS percentage_ordered_from_primary_pincode 
FROM orders O
JOIN customer C ON
               O.cust_id=C.cust_id
GROUP BY C.cust_id
ORDER BY percentage_ordered_from_primary_pincode DESC;

/*14)For each product name, print the sum of number of units, total amount paid, total
displayed selling price, total mrp of these units, and finally the net discount from selling
price.*/
ALTER TABLE orders
ALTER COLUMN displayed_selling_price_per_unit INT;

SELECT 
      P.product_name,
	  SUM(O.tot_units) AS sum_of_no_of_units,
	  SUM(O.total_amount_paid) AS total_amount_paid_per_product,
	  SUM(O.displayed_selling_price_per_unit*O.tot_units) AS total_displayed_selling_price,
	  SUM(P.mrp*O.tot_units) AS total_mrp,
	  (100.0 - 100.0 * SUM(O.total_amount_paid) / SUM(O.displayed_selling_price_per_unit* O.tot_units)) AS net_discount_from_selling_price,
	  (100.0 - 100.0 * SUM(O.total_amount_paid) / SUM(P.mrp * O.tot_units)) AS net_discount_from_mrp
FROM orders O
JOIN products P ON 
                O.product_id= P.product_id
GROUP BY P.product_name;

/*15)For every order_id (exclude returns), get the product name and calculate the discount
percentage from selling price. Sort by highest discount and print only those rows where
discount percentage was above 10.10%.*/   
SELECT 
       O.order_id, 
	   P.product_name,
	   (100.0-100.0* SUM(O.total_amount_paid) / SUM(O.displayed_selling_price_per_unit* O.tot_units)) AS discount_perc
FROM orders O
JOIN products P ON
                  O.product_id=P.product_id
WHERE O.order_type <> 'return'
GROUP BY O.order_id, P.product_name
HAVING (100.0-100.0* SUM(O.total_amount_paid) / SUM(O.displayed_selling_price_per_unit* O.tot_units)) > 10.10
ORDER BY discount_perc DESC;

/*16)Using the per unit procurement cost in product_dim, find which product category has
made the most profit in both absolute amount and percentage. */
ALTER TABLE products
ALTER COLUMN procurement_cost_per_unit INT;

SELECT 
     --SUM(P.procurement_cost_per_unit*O.tot_units) AS total_procurement_cost,
	 --SUM(O.total_amount_paid) AS total_amount,
     SUM(O.total_amount_paid)-SUM(P.procurement_cost_per_unit* O.tot_units) AS absoulte_profit,
	 (100.0 *SUM(O.total_amount_paid) / SUM(P.procurement_cost_per_unit* O.tot_units)-100.0) AS percentage_profit,
	 P.category
FROM orders O
JOIN products P ON
     O.product_id=P.product_id
GROUP BY P.category;

/*17)For every delivery person(use their name), print the total number of order ids (exclude
returns) by month in separate columns i.e. there should be one row for each
delivery_person_id and 12 columns for every month in the year*/
UPDATE orders
SET order_date = CONVERT(DATE, order_date, 103);

ALTER TABLE orders
ALTER COLUMN order_date DATE;

SELECT 
    D.delivery_person_id,
	D.name,
    SUM(CASE WHEN MONTH(order_date) = 1 THEN 1 ELSE 0 END) AS January,
    SUM(CASE WHEN MONTH(order_date) = 2 THEN 1 ELSE 0 END) AS February,
    SUM(CASE WHEN MONTH(order_date) = 3 THEN 1 ELSE 0 END) AS March,
    SUM(CASE WHEN MONTH(order_date) = 4 THEN 1 ELSE 0 END) AS April,
    SUM(CASE WHEN MONTH(order_date) = 5 THEN 1 ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(order_date) = 6 THEN 1 ELSE 0 END) AS June,
    SUM(CASE WHEN MONTH(order_date) = 7 THEN 1 ELSE 0 END) AS July,
    SUM(CASE WHEN MONTH(order_date) = 8 THEN 1 ELSE 0 END) AS August,
    SUM(CASE WHEN MONTH(order_date) = 9 THEN 1 ELSE 0 END) AS September,
    SUM(CASE WHEN MONTH(order_date) = 10 THEN 1 ELSE 0 END) AS October,
    SUM(CASE WHEN MONTH(order_date) = 11 THEN 1 ELSE 0 END) AS November,
    SUM(CASE WHEN MONTH(order_date) = 12 THEN 1 ELSE 0 END) AS December
FROM orders O
JOIN delivery_person D ON 
         O.delivery_person_id = D.delivery_person_id
WHERE O.order_type <> 'return'
GROUP BY D.delivery_person_id,D.name;

/*18)For each gender - male and female - find the absolute and percentage profit (like in Q15) by product name*/
SELECT 
      C.gender,
	  P.product_name,
	  SUM(CASE WHEN gender='male' THEN (O.total_amount_paid - P.procurement_cost_per_unit*O.tot_units) ELSE 0 END) AS male_absolute_profit,
	  SUM(CASE WHEN gender='female' THEN (O.total_amount_paid - P.procurement_cost_per_unit*O.tot_units) ELSE 0 END) AS female_absolute_profit,
	  100.0 * SUM(CASE WHEN gender = 'male' THEN (o.total_amount_paid - (p.procurement_cost_per_unit * o.tot_units)) ELSE 0 END) / NULLIF(SUM(CASE WHEN gender = 'male' THEN o.total_amount_paid ELSE 0 END), 0) AS male_percentage_profit,
      100.0 * SUM(CASE WHEN gender = 'female' THEN (o.total_amount_paid - (p.procurement_cost_per_unit * o.tot_units)) ELSE 0 END) / NULLIF(SUM(CASE WHEN gender = 'female' THEN o.total_amount_paid ELSE 0 END), 0) AS female_percentage_profit
FROM orders O
JOIN products P ON
         O.product_id=P.product_id
JOIN customer C ON
         O.cust_id= C.cust_id
GROUP BY C.gender, P.product_name;

/*19)Generally the more numbers of units you buy, the more discount seller will give you. For
'Dell AX420' is there a relationship between number of units ordered and average
discount from selling price? Take only 'buy' order types*/
SELECT 
    CASE 
        WHEN tot_units >= 1 AND tot_units <= 5 THEN '1-5'
        WHEN tot_units >= 6 AND tot_units <= 10 THEN '6-10'
        WHEN tot_units>= 11 AND tot_units <= 15 THEN '11-15'
        ELSE '16+'
    END AS total_units_range,
    AVG(o.displayed_selling_price_per_unit - (o.total_amount_paid / o.tot_units)) AS avg_discount
FROM 
    orders O
JOIN products P ON O.product_id = P.product_id
	WHERE P.product_name = 'Dell AX420'AND O.order_type = 'buy'
GROUP BY 
    CASE 
        WHEN tot_units >= 1 AND tot_units <= 5 THEN '1-5'
        WHEN tot_units >= 6 AND tot_units <= 10 THEN '6-10'
        WHEN tot_units>= 11 AND tot_units <= 15 THEN '11-15'
        ELSE '16+' END


SELECT o.tot_units,
       AVG((O.displayed_selling_price_per_unit* O.tot_units)-O.total_amount_paid ) AS average_discount
FROM orders o
JOIN products p ON o.product_id = p.product_id
WHERE p.product_name = 'Dell AX420' AND o.order_type = 'buy'
GROUP BY O.tot_units
ORDER BY O.tot_units ;


SELECT SUM(total_amount_paid) AS total_amount , gender
FROM orders
JOIN customer ON orders.cust_id = customer.cust_id
GROUP BY customer.gender