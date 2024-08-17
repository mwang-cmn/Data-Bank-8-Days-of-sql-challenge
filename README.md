# Data Bank - 8 Days of SQL Challenge by Danny Ma.
## Problem Overview
Data Bank is an online digital bank, that not only provides banking solutions, but also serves as an online secure distributed data storage platform. Customers are allocated cloud data storage limit, directly linked to their account balances. The management of Data Bank want to increase their total customer base and improve tracking of how much data storage their customers will need. In this project, I will attempt to solve this [challenge](https://8weeksqlchallenge.com/case-study-4/).
Read more - [here](https://dev.to/caroline_mwangi/exploration-of-digital-banking-transactions-a-sql-analysis-1hl0)
### Entity Relationship Diagram
![Capture](https://github.com/mwang-cmn/Data-Bank-8-Days-of-sql-challenge/assets/73072045/ca438b66-eb6d-4b3e-ba9f-94ea75347732)







Here is a detailed summary of all columns in the three tables
1. Regions table - 
   
| Column Name | Description                                |
|-------------|--------------------------------------------|
| region_id   | Unique identifier for each region          |
| region_name | Name of the region                         |

Customer Nodes - 

| Column Name  | Description                                    |
|--------------|------------------------------------------------|
| customer_id  | Unique identifier for each customer            |
| region_id    | Identifier for the region associated with the customer |
| node_id      | Identifier for the node associated with the customer |
| start_date   | The start date of the customer's activity or transaction |
| end_date     | The end date of the customer's activity or transaction |

Customer Transactions -

| Column Name | Description                                   |
|-------------|-----------------------------------------------|
| customer_id | Unique identifier for each customer           |
| txn_date    | Date of the transaction                       |
| txn_type    | Type of the transaction (e.g., deposit)       |
| txn_amount  | Amount of the transaction                     |

## Challenge questions


