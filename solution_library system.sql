CREATE DATABASE library_db;


DROP TABLE IF EXISTS branch;
-- Create table "branch"
CREATE TABLE branch
(
            branch_id VARCHAR(10) PRIMARY KEY,
            manager_id VARCHAR(10),
            branch_address VARCHAR(30),
            contact_no VARCHAR(15)
);

-- Create table "Employee"
CREATE TABLE employees
(
            emp_id VARCHAR(10) PRIMARY KEY,
            emp_name VARCHAR(30),
            position VARCHAR(30),
            salary DECIMAL(10,2),
            branch_id VARCHAR(10),
            FOREIGN KEY (branch_id) REFERENCES  branch(branch_id)
);

-- Create table "Members"
DROP TABLE IF EXISTS members;
CREATE TABLE members
(
            member_id VARCHAR(10) PRIMARY KEY,
            member_name VARCHAR(30),
            member_address VARCHAR(30),
            reg_date DATE
);

-- Create table "Books"
DROP TABLE IF EXISTS books;
CREATE TABLE books
(
            isbn VARCHAR(50) PRIMARY KEY,
            book_title VARCHAR(80),
            category VARCHAR(30),
            rental_price DECIMAL(10,2),
            status VARCHAR(10),
            author VARCHAR(30),
            publisher VARCHAR(30)
);

-- Create table "IssueStatus"
DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(
            issued_id VARCHAR(10) PRIMARY KEY,
            issued_member_id VARCHAR(30),
            issued_book_name VARCHAR(80),
            issued_date DATE,
            issued_book_isbn VARCHAR(50),
            issued_emp_id VARCHAR(10),
            FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
            FOREIGN KEY (issued_emp_id) REFERENCES employees(emp_id),
            FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn) 
);

-- Create table "ReturnStatus"
DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(
            return_id VARCHAR(10) PRIMARY KEY,
            issued_id VARCHAR(30),
            return_book_name VARCHAR(80),
            return_date DATE,
            return_book_isbn VARCHAR(50),
            FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
-- ### 2. CRUD Operations

-- Task 1: Create a New Book Record
INSERT INTO books (isbn,book_title,category,rental_price,status,author,publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';


-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS104' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';


-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_emp_id, COUNT(*) 
FROM issued_status
GROUP BY 1
HAVING COUNT(*)>1
ORDER BY count(*) DESC;


-- ### 3. CTAS (Create Table As Select)

-- Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results each book and total book_issued_cnt

-- foreign keys when creating tables
CREATE TABLE book_issued_cnt  AS 
	SELECT b.isbn,
			b.book_title,
			count(ist.issued_id)
	FROM books as b
	JOIN issued_status as ist
	ON ist.issued_book_isbn = b.isbn
	GROUP BY b.book_title,b.isbn;


-- without foreign keys when creating tables
CREATE TABLE book_issued_cnt2  AS 
	SELECT issued_book_isbn, issued_book_name, COUNT(issued_book_name) 
	FROM issued_status
	GROUP BY 1,2

-- ### 4. Data Analysis & Findings

-- Task 7. **Retrieve All Books in a Specific Category:
SELECT category, book_title
FROM books
ORDER BY category;

-- Task 8: Find Total Rental Income by Category:
SELECT b.category,SUM(b.rental_price)
FROM books as b
JOIN issued_status as ist
ON ist.issued_book_isbn = b.isbn
GROUP BY b.category
ORDER BY SUM(b.rental_price) DESC

-- Task 9. **List Members Who Registered in the Last 1500 Days**:
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '1500 days';


-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:
SELECT e1.emp_id, e1.emp_name,b.*,e2.emp_name as manager
FROM employees as e1
JOIN branch as b 
ON b.branch_id = e1.branch_id
JOIN employees as e2
ON e2.emp_id=b.manager_id;


-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold
CREATE TABLE book_price_above7 AS
	SELECT *
	FROM books
	WHERE rental_price > 7.00;


-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT *
FROM return_status as r
RIGHT JOIN issued_status as i
ON i.issued_id = r.issued_id
WHERE return_date IS NULL

-- Advanced SQL Operations

-- Task 13: Identify Members with Overdue Books Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.
-- Assumption: Current date: 2024-04-27
SELECT member_name, issued_book_name, '2024-04-27' - issued_date as overdue_days
FROM return_status as r
RIGHT JOIN issued_status as i
ON i.issued_id = r.issued_id
JOIN members m
ON m.member_id = i.issued_member_id
WHERE 
		return_date IS NULL 
	AND
	  '2024-04-27' - issued_date > 30

-- Task 14: Update Book Status on Return 
-- Write a query to update the status of books in the books table to "available" when they are returned (based on entries in the return_status table).
SELECT * FROM books
SELECT * FROM return_status
SELECT * FROM issued_status
SELECT * FROM employees

UPDATE  books
SET status = 'no'
WHERE book_title = 'Fahrenheit 451'

UPDATE  books
SET status = 'no'
WHERE book_title = 'Dune'

-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

SELECT b.branch_id, 
	COUNT(i.issued_id) as total_issued,
	COUNT(r.return_id) as total_returned,
	SUM(bs.rental_price) as total_revenue
FROM branch b
JOIN employees e
ON e.branch_id = b.branch_id
RIGHT JOIN issued_status i
ON i.issued_emp_id = e.emp_id
LEFT JOIN books bs
ON bs.isbn = i.issued_book_isbn
LEFT JOIN return_status r
ON r.issued_id = i.issued_id
GROUP BY b.branch_id




-- Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 25 months.

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '25 month'
                    )
;


SELECT * FROM active_members;


-- Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2

/*
-- Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.    
*/
SELECT * FROM books;

SELECT * FROM members;

SELECT * FROM issued_status;


SELECT m.member_name, book_title, count(*) num_issued
FROM issued_status i
JOIN books b ON i.issued_book_isbn = b.isbn
JOIN members m ON i.issued_member_id = m.member_id
WHERE b.status = 'damaged'
GROUP BY 1,2
HAVING COUNT(*) >= 2;

/*
-- Task 19: Stored Procedure 
Objective: Create a stored procedure to manage the status of books in a library system.
    Description: Write a stored procedure that updates the status of a book based on its issuance or return. Specifically:
    If a book is issued, the status should change to 'no'.
    If a book is returned, the status should change to 'yes'.
*/


CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10),p_issued_member_id VARCHAR (30), p_issued_book_name VARCHAR(80), p_issued_book_isbn VARCHAR(50),p_issued_emp_id VARCHAR(10))
language plpgsql
AS $$

DECLARE 
 v_status VARCHAR(10);

BEGIN
-- all code
	SELECT status 
	 INTO v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	IF v_staus = 'Yes' THEN
		INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
		VALUES (p_issued_id,p_issued_member_id,CURRENT_DATE,p_issued_book_isbn,p_issued_emp_id );

		UPDATE books
		SET status = 'no'
		WHERE isbn = p_issued_book_isbn;

		RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;
		
	ELSE 
	
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable book_isbn: %',	p_issued_book_isbn;
		
	END IF;

END;
$$



SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;


CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');



CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');


SELECT * FROM books
WHERE isbn = '978-0-375-41398-8'


/*
-- Task 20: Create Table As Select (CTAS)
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each day's fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines
*/


SELECT * FROM books;
SELECT * FROM issued_status;
SELECT * FROM return_status;

CREATE TABLE  fine_calculator AS
	SELECT issued_member_id Member_ID, COUNT(*) count_overdue, SUM(CURRENT_DATE - i.issued_date)*0.5 AS total_fines FROM issued_status i
	LEFT JOIN return_status r ON i.issued_id = r.issued_id
	WHERE return_date IS NULL AND CURRENT_DATE - i.issued_date > 30
	GROUP BY 1


SELECT * FROM fine_calculator;






