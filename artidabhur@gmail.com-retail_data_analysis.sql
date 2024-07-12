--DROP DATABASE db_retaildataanalysis

--CREATE DATABASE db_retaildataanalysis


SELECT * FROM Transactions

SELECT * FROM Customer

SELECT * FROM prod_cat_info


--What is the total number of rows in each table.

SELECT * FROM (
SELECT 'Customer' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM Customer UNION ALL
SELECT 'prod_cat_info' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM prod_cat_info UNION ALL
SELECT 'Transactions' AS TABLE_NAME, COUNT(*) AS NO_OF_RECORDS FROM Transactions
) TBL



--What is the number of total transactions that have return.

SELECT COUNT (*) AS Orders_returned FROM Transactions
WHERE Qty <0

---String to date DATE DATATYPE FORMATING
--IN TRANSACTIONS table
/*


Alter table TRANSACTIONS
add TDATE date;


Update TRANSACTIONS
set TDATE =convert(date,tran_date,105);

Alter table TRANSACTIONS
drop column tran_date;

SP_RENAME 'TRANSACTIONS.TDATE','tran_date','COLUMN'
GO




--IN CUSTOMER TABLE


Alter table customer
add datebirth date;


Update Customer
set datebirth=convert(date,DOB,105);

Alter table customer
drop column DOB;

SP_RENAME 'customer.datebirth','DOB','COLUMN'
GO

*/


SELECT * FROM Transactions

SELECT * FROM Customer

SELECT * FROM prod_cat_info


---TIME RANGE of trnsaction data available. Output in days, months, years.

	SELECT DATEDIFF(DAY,oldest_date,latest_date)AS TIME_IN_DAYS,
	DATEDIFF(MONTH,oldest_date,latest_date) AS TIME_IN_MONTHS,
	DATEDIFF(YEAR,oldest_date,latest_date) AS TIME_IN_YEARS FROM
	(SELECT MAX(TRAN_DATE)as latest_date,MIN(TRAN_DATE)as oldest_date FROM Transactions)AS T



--Product category who has subcategory 'DIY'
	
	SELECT prod_cat,prod_subcat FROM prod_cat_info
	WHERE prod_subcat='DIY'





--DATA ANALYSIS

--1. The most frequently used channel for transactions


	SELECT TOP 1 STORE_TYPE, COUNT (STORE_TYPE) AS FREQ_OF_CHANNEL FROM Transactions
	GROUP BY STORE_TYPE
	ORDER BY FREQ_OF_CHANNEL DESC

	
--2. Count of male and female customers in database
	
	SELECT GENDER, COUNT (GENDER) AS NUM_OF_CUSTOMERS FROM Customer
	WHERE Gender IN ('M','F')
	GROUP BY GENDER
	ORDER BY NUM_OF_CUSTOMERS DESC


--3. Which city has maximun number of customers and how many 


	SELECT TOP 1 City_code, COUNT (city_code) AS NUM_OF_CUSTOMERS FROM Customer
	GROUP BY City_code
	ORDER BY NUM_OF_CUSTOMERS DESC



--4. how many sub-categories are under books category


	SELECT count(prod_subcat)as Num_of_subcategories_UNDER_BOOKS FROM prod_cat_info
	where prod_cat='books'


--5. what is the maximum quantity of products ever ordered


	SELECT max(Qty)as Max_qty_ordered FROM Transactions
	WHERE CAST (QTY AS INT) >0


--6. Net total revenue generated in categories 'electronics and Books'


	SELECT T.prod_cat,sum(cast(T.total_amt as float))AS Net_total_revenue FROM

	(SELECT Transactions.total_amt,prod_cat_info.prod_cat FROM prod_cat_info
	join
	Transactions
	on prod_cat_info.prod_cat_code=Transactions.prod_cat_code
	) as T
	where T.prod_cat in ('electronics' ,'Books')
	group by T.prod_cat



--7. HOW many customers have >10 transacions(excluding returns)

	SELECT COUNT(*)AS NUM_CUSTOMERS 
	FROM 
	(SELECT cust_id, COUNT(transaction_id)AS TOTAL_TRANSACTIONS FROM
	(SELECT  cust_id, transaction_id FROM Transactions WHERE Qty>0)AS T1
	GROUP BY cust_id
	HAVING COUNT(transaction_id)>10) AS T2

--8. Combined revenue from 'electronics' and 'clothing', from 'flagship stores'

		SELECT sum(cast(T.total_amt as float))AS Combined_revenue FROM

		(SELECT Transactions.total_amt,prod_cat_info.prod_cat FROM prod_cat_info
		join
		Transactions
		on prod_cat_info.prod_cat_code=Transactions.prod_cat_code and Transactions.prod_subcat_code=prod_cat_info.prod_sub_cat_code 
		where Store_type ='flagship store'
		) as T
	
		where T.prod_cat='electronics' or T.prod_cat='clothing'
		

	
--9. Total revenue from 'male' customers in 'electronics' category. output should display total revenue by prod sub-cat

		SELECT T.prod_subcat,sum( cast(t.total_amt as float))as Total_Revenue from
		(SELECT Transactions.total_amt, prod_cat_info.prod_subcat FROM
		Customer		
		join		
		Transactions
		on Transactions.cust_id=Customer.customer_Id
		join 
		prod_cat_info
		on Transactions.prod_cat_code =prod_cat_info.prod_cat_code and Transactions.prod_subcat_code=prod_cat_info.prod_sub_cat_code  
		where Customer.Gender ='M' and prod_cat_info.prod_cat='electronics'
		) as T
		GROUP BY T.prod_subcat

--10. Percentage of sales and returns by product sub-cat, display top 5 sub-categories in terms of sales

		SELECT TOP 5 prod_subcat,((sale_c)/ sum(sale_c) over() )*100 as percentage_of_sale,  ((return_c)/sum(return_c) over () ) * 100 as percentage_of_return 
		from (
		SELECT P.prod_subcat  ,sum(cast(case when cast(total_amt as float) >= 0.0 then total_amt else '0.0' end  as float)) as sale_c,
		sum(abs(cast(case when cast(total_amt as float) < 0.0 then total_amt else '0.0' end  as float))) as return_c
		from
		Transactions as T 
		JOIN prod_cat_info as P
		ON T.prod_subcat_code=P.prod_sub_cat_code AND T.PROD_CAT_CODE = P.PROD_CAT_CODE	
		group by  prod_subcat) as T1
		ORDER BY percentage_of_sale DESC;
			
			
--11. For age group 25 to 35 years-find net total revenue in last 30 days of transactions from max transaction date available in data

	 SELECT SUM(cast (total_amt as float)) as net_total_revenue FROM
	 (SELECT cust_id, total_amt,tran_date,MAX(tran_date) OVER () as max_tran_date FROM Transactions)as T 
	  JOIN
	  Customer AS C
	  ON T.cust_id = C.customer_Id
	  WHERE T.tran_date >= DATEADD(day, -30, T.max_tran_date) AND 
		  T.tran_date >= DATEADD(YEAR, 25, C.DOB) AND T.tran_date <= DATEADD(YEAR, 35, C.DOB)
	

--12. Which product category has seen the max value of returns in last 3 months of transactions

	SELECT top 1 prod_cat as product_category,abs(sum (cast(qty as int)))as quantity_returned, abs(sum (cast (total_amt as float))) as total_amount_returned from 
	(SELECT prod_cat_code,prod_subcat_code, qty,total_amt,tran_date,MAX(tran_date) OVER () as max_tran_date FROM Transactions)as T 
	  JOIN
	 prod_cat_info AS P
	  ON T.prod_cat_code = P.prod_cat_code and t.prod_subcat_code=p.prod_sub_cat_code
	  WHERE T.tran_date >= DATEADD(Month, -3, T.max_tran_date) and cast (total_amt as float)<0.0
	  group by prod_cat
	  order by total_amount_returned  desc
	

--13. Which store type sells the maximum products, by value of sales amount and  by quantity sold


		SELECT Top 1 Store_type,  sum (cast(qty as int))as total_quantitySold, 
		sum (cast (total_amt as float)) as total_amount FROM Transactions
		where cast (total_amt as float)>0.0
		group by Store_type
		order by total_amount desc,total_quantitySold desc


--14. Categories for which average revenue is above the overall average

		Select distinct prod_cat,average_revenue from 
		prod_cat_info as p  join
		(select prod_cat_code,
		 avg(cast(total_amt as float)) as average_revenue 
		 from Transactions
		 group by prod_cat_code
		 having avg(cast(total_amt as float))> (select avg(cast(total_amt as float)) as overall_average from Transactions)
		 ) as t
		 on p.prod_cat_code  =t.prod_cat_code
		 order by average_revenue desc
  

--15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of qty sold

		Select prod_subcat,avg( cast(total_amt as float)) as average_revenue,sum( cast(total_amt as float)) as Total_revenue
		FROM 
		prod_cat_info as P1
		join Transactions as T1
		ON P1.prod_cat_code = T1.prod_cat_code AND P1.prod_sub_cat_code = T1.prod_subcat_code
		where prod_cat in
		(																							--the categories which are among top 5 categories in terms of qty sold
		Select prod_cat from (SELECT top 5  prod_cat,  sum (cast(qty as int))as total_quantitySold, 
		sum (cast (total_amt as float)) as total_amount FROM 
		prod_cat_info as P
		join Transactions as T
		ON P.prod_cat_code = T.prod_cat_code AND P.prod_sub_cat_code = T.prod_subcat_code
		where cast (total_amt as float)>0.0
		group by prod_cat
		order by total_quantitySold desc
		)as S								
		)

		group by prod_subcat
		order by Total_revenue desc


		
			
				
	

