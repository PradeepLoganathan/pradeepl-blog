---
title: "Migrating From Sqlserver Postgres"
lastmod: 2024-07-31T10:26:07+10:00
date: 2024-07-31T10:26:07+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - 
  - 
  - 
categories:
  - 
#slug: kubernetes/introduction-to-open-policy-agent-opa/
description: "meta description"
summary: "summary used in summary pages"
ShowToc: true
TocOpen: true
images:
  - 
cover:
    image: "images/cover.jpg"
    alt: ""
    caption: ""
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

## Introduction

The world of databases is vast, and choosing the right one for your needs can be a complex decision. If you're considering a move from Microsoft SQL Server to PostgreSQL (often referred to as Postgres), this guide will provide you with the insights and steps needed for a successful migration. We'll explore the reasons behind this shift, the key differences between the two databases, and a step-by-step approach to ensure a smooth transition.

## Why Choose PostgreSQL?

PostgreSQL has gained immense popularity due to its open-source nature, advanced features, and robust performance. Let's delve into some of the compelling reasons why organizations are making the switch:

* **Cost Efficiency:** PostgreSQL eliminates licensing fees associated with proprietary databases, significantly reducing operational costs.
* **Vendor Independence with Optional Support:** Being open-source, PostgreSQL frees you from vendor lock-in, giving you greater control and flexibility over your database infrastructure. Additionally, organizations can benefit from the managed services and expert support provided by vendors like Tanzu PostgreSQL, ensuring robust performance, high availability, and seamless integration within enterprise environments while still leveraging the advantages of an open-source solution.
* **Performance and Scalability:** PostgreSQL excels in handling large datasets and complex queries, making it ideal for data-intensive applications.
* **High Availability and Disaster Recovery:** Features like replication, failover, and point-in-time recovery ensure minimal downtime and data protection.
* **Security and Compliance:** PostgreSQL offers robust security features, including data encryption and access controls, to help you meet regulatory requirements.
* **Community and Support:** A vibrant community and extensive ecosystem provide readily available resources and support.

Having explored the numerous benefits of PostgreSQL, it becomes evident why a growing number of organizations are choosing to make the transition. The next logical step is to plan your migration carefully to ensure a smooth and successful transition. In the following sections, we will outline the essential steps and considerations for migrating from SQL Server to PostgreSQL.

## Planning Your Migration

A successful migration hinges on meticulous planning. Here's a breakdown of the essential steps:

1. **Define Clear Goals:** Outline your objectives for the migration, whether it's improved performance, cost savings, or enhanced features.
2. **Understand Your Current Database:** Evaluate your existing SQL Server setup, including schema, data volume, and any custom configurations.
3. **Identify Challenges:** Anticipate potential issues like compatibility problems or data loss risks.
4. **Choose a Migration Strategy:** Select the most suitable approach based on your goals and database complexity. Options include schema conversion, data migration (dump and restore, logical replication, or physical replication), and hybrid methods.
5. **Resource Planning:** Allocate the necessary hardware, personnel, and training to support the migration.
6. **Contingency Planning:** Prepare a rollback plan in case of unforeseen issues.
7. **Communication Plan:** Keep stakeholders informed about the migration progress and potential impacts.

## PostgreSQL Migration Tools

Several tools can streamline your migration process:

* **pgloader:** An open-source tool that automates schema, data, and index migration.
* **pgAdmin:** A PostgreSQL management tool that can also assist with data import/export.

## Post-Migration Best Practices

After the migration, ensure a smooth transition by:

* **Verifying Data:** Thoroughly test the migrated data for accuracy and completeness.
* **Performance Testing:** Benchmark your PostgreSQL database against your expectations and previous setup.
* **Application Testing:** Ensure your applications function correctly with the new database.
* **Monitoring:** Continuously monitor the PostgreSQL environment for performance optimization and issue identification.
* **Community Engagement:** Leverage the PostgreSQL community and support resources for ongoing assistance.

## The Importance of Understanding Application-Database Interaction

The way an application interacts with its database is a critical factor in determining the complexity and approach of a database migration. Applications heavily reliant on database-specific logic, such as stored procedures and triggers, present a greater challenge when migrating to a new database system. Let's delve deeper into why this is the case and what it means for your migration planning.

### Database-Centric vs. Application-Centric Logic

* **Database-Centric Logic:** When an application pushes a significant portion of its business logic into the database, it often leverages features like stored procedures, functions, triggers, and views. These objects encapsulate complex operations, data validation, and even parts of the application's workflow. The advantage of this approach is centralized logic and potentially improved performance. However, the downside is increased coupling between the application and the database. Migrating to a new database system necessitates translating or rewriting these database objects, which can be time-consuming and error-prone.
* **Application-Centric Logic:** In contrast, applications with most of their logic residing within the application code itself tend to use the database primarily for data storage and retrieval. While this might lead to slightly more data transfer between the application and database, it offers greater flexibility when migrating databases. The core application logic remains unaffected, and the migration primarily involves adapting data access layers and queries to the new database's syntax and features.

### Assessing Your Application**

Before embarking on a migration, it's crucial to analyze your application's interaction with the database. Here are some key questions to consider:

* How extensively are stored procedures, functions, and triggers used? If they're pervasive and complex, anticipate a more involved migration process.
* Is the application's logic tightly intertwined with the database schema? If so, schema changes in the new database might require significant application code modifications.
* Are there any vendor-specific features or extensions being utilized? These will likely need to be replaced or reimplemented in the target database.
* How much data needs to be migrated? The volume of data impacts the migration strategy and duration.

### Migration Strategies Based on Application-Database Interaction**

* **Database-Centric Logic:**
  * Thorough Assessment: Conduct a detailed inventory of all database objects and their dependencies.
  * Code Conversion or Rewriting: Plan for significant effort in translating or rewriting stored procedures, functions, and triggers to the target database's syntax.
  * Testing and Validation: Rigorous testing is essential to ensure the migrated logic functions correctly in the new environment.

* **Application-Centric Logic:**
  * Schema and Data Migration: Focus on accurately converting the database schema and transferring the data.
  * Query Adaptation: Adjust application queries and data access code to the new database's syntax.
  * Performance Tuning: Optimize queries and database configuration for the new system.


Understanding how your application utilizes the database is paramount for a successful migration. By carefully analyzing the extent of database-centric logic and planning your migration strategy accordingly, you can minimize risks, reduce downtime, and ensure a smooth transition to your new PostgreSQL database. Remember, a well-prepared migration sets the stage for reaping the full benefits of PostgreSQL's power, flexibility, and cost-effectiveness.

## Step 1: Planning and Assessment

### 1.1 Inventory and Analysis

#### Inventory Existing Applications and Databases

* **List All Databases**: Identify all the databases that will be migrated from MS SQL Server to PostgreSQL.
* **Identify Dependencies**: Note down all dependencies, including linked servers, cross-database queries, and external systems.
* **Review Application Interfaces**: Identify how each application interfaces with the database (e.g., ORM, direct SQL queries, stored procedures).

**Example:**

```plaintext
Database Inventory:
1. CustomerDB
   - Tables: Customers, Orders, Payments
   - Dependencies: External CRM System, Linked Server to InventoryDB
2. InventoryDB
   - Tables: Products, StockLevels, Warehouses
   - Dependencies: Internal Reporting System
```

### 1.2 Evaluate Compatibility

#### 1.2.1 Data Types

* **Identify Unsupported Data Types**: MS SQL Server and PostgreSQL have different sets of data types. Identify and map unsupported data types. I have created a comprehensive table for common data types and their mappings between sql server and postgresql.

| SQL Server Data Type | PostgreSQL Data Type | Notes |
|----------------------|----------------------|-------|
| `bigint`             | `bigint`             | Direct mapping. |
| `binary(n)`          | `bytea`              | Binary data. |
| `bit`                | `boolean`            | Direct mapping. |
| `char(n)`            | `char(n)`            | Direct mapping, fixed-length character data. |
| `date`               | `date`               | Direct mapping. |
| `datetime`           | `timestamp`          | `timestamp` in PostgreSQL does not include time zone by default. Use `timestamptz` if needed. |
| `datetime2`          | `timestamp`          | Same as above. |
| `datetimeoffset`     | `timestamptz`        | Timestamp with time zone. |
| `decimal(p, s)`      | `numeric(p, s)`      | Direct mapping. |
| `float`              | `double precision`   | Direct mapping. |
| `image`              | `bytea`              | Binary data, similar to `binary`. |
| `int`                | `integer`            | Direct mapping. |
| `money`              | `numeric(19, 4)`     | Use `numeric` with precision and scale. |
| `nchar(n)`           | `char(n)`            | Fixed-length character data, no direct Unicode support as in `nvarchar`. |
| `ntext`              | `text`               | Variable-length Unicode data. |
| `numeric(p, s)`      | `numeric(p, s)`      | Direct mapping. |
| `nvarchar(n)`        | `varchar(n)`         | Variable-length character data with length limit. |
| `nvarchar(max)`      | `text`               | Variable-length character data without length limit. |
| `real`               | `real`               | Direct mapping. |
| `smalldatetime`      | `timestamp`          | Timestamp without time zone by default. |
| `smallint`           | `smallint`           | Direct mapping. |
| `smallmoney`         | `numeric(10, 4)`     | Use `numeric` with precision and scale. |
| `sql_variant`        | Not directly supported | Requires custom handling, as PostgreSQL does not support this type. |
| `text`               | `text`               | Variable-length character data. |
| `time`               | `time`               | Direct mapping. |
| `timestamp`          | `bytea`              | In SQL Server, `timestamp` is a row versioning data type; map to `bytea`. |
| `tinyint`            | `smallint` or `integer` | Use `smallint` or `integer` as PostgreSQL does not have `tinyint`. |
| `uniqueidentifier`   | `uuid`               | Direct mapping for UUID. |
| `varbinary(n)`       | `bytea`              | Binary data with length limit. |
| `varbinary(max)`     | `bytea`              | Variable-length binary data. |
| `varchar(n)`         | `varchar(n)`         | Direct mapping for variable-length character data with length limit. |
| `varchar(max)`       | `text`               | Variable-length character data without length limit. |
| `xml`                | `xml`                | Direct mapping, but consider PostgreSQL’s XML handling capabilities. |

* **Common Mappings**:
  * \`DATETIME\` -> \`TIMESTAMP\`
  * \`MONEY\` -> \`NUMERIC(19,4)\`
  * \`UNIQUEIDENTIFIER\` -> \`UUID\`

#### 1.2.2 Functions and Expressions

* **SQL Functions**: Review SQL Server functions (e.g., \`GETDATE()\`, \`ISNULL()\`, \`NEWID()\`) and find PostgreSQL equivalents (\`NOW()\`, \`COALESCE()\`, \`GEN_RANDOM_UUID()\`).
* **Stored Procedures and Triggers**: Analyze stored procedures and triggers, as T-SQL differs significantly from PL/pgSQL.

#### 1.2.3 Indexes and Constraints

* **Primary and Foreign Keys**: Ensure primary and foreign keys are compatible.
* **Unique Constraints and Indexes**: Convert unique constraints and indexes appropriately.

#### 1.2.4 SQL Syntax Differences

* **Query Syntax**: Modify SQL queries to be compatible with PostgreSQL. For example, replace `TOP` with `LIMIT`.

**Example:**

```sql
-- SQL Server
SELECT TOP 10 * FROM Customers;

-- PostgreSQL
SELECT * FROM Customers LIMIT 10;
```

### 1.3 Assess Data Size and Complexity

#### 1.3.1 Data Size

* **Database Size**: Calculate the total size of each database to be migrated.

  ```sql
  -- SQL Server query to get database size
  USE CustomerDB;
  EXEC sp_spaceused;
  ```

* **Table Size**: Identify the size of individual tables.

  ```sql
  -- SQL Server query to get table size
  SELECT 
      t.NAME AS TableName,
      s.Name AS SchemaName,
      p.rows AS RowCounts,
      SUM(a.total_pages) * 8 AS TotalSpaceKB, 
      SUM(a.used_pages) * 8 AS UsedSpaceKB, 
      (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
  FROM 
      sys.tables t
  INNER JOIN      
      sys.indexes i ON t.OBJECT_ID = i.object_id
  INNER JOIN 
      sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
  INNER JOIN 
      sys.allocation_units a ON p.partition_id = a.container_id
  LEFT OUTER JOIN 
      sys.schemas s ON t.schema_id = s.schema_id
  WHERE 
      t.NAME NOT LIKE 'dt%' 
      AND t.is_ms_shipped = 0
      AND i.OBJECT_ID > 255 
  GROUP BY 
      t.Name, s.Name, p.Rows
  ORDER BY 
      TotalSpaceKB DESC;
  ```

#### 1.3.2 Data Complexity

* **Relationships and Joins**: Review complex relationships and joins between tables.
* **Complex Queries**: Identify complex queries and views that might need special attention during migration.

**Example:**

```plain-text
Complex Queries Inventory:
1. MonthlySalesReport
   - Joins: Orders, Payments, Customers
   - Aggregations: SUM, COUNT, AVG
2. CustomerActivityReport
   - Joins: Customers, Orders, Inventory
   - Subqueries: Nested subqueries for recent purchases
```

### 1.4 Tools and Automation

#### 1.4.1 Schema Conversion Tools

* **SQL Server Migration Assistant (SSMA)**: Automate schema conversion.
  \`\`\`sh

## Install SSMA and follow the wizard for schema conversion

  \`\`\`

#### 1.4.2 Data Migration Tools

* **pgAdmin Migration Wizard**: Simplify data migration.
  \`\`\`sh

# Use pgAdmin's Migration Wizard

  pgAdmin > Tools > Migration Wizard
  \`\`\`

#### 1.4.3 ETL Tools

* **Talend, Apache Nifi**: Use ETL tools for complex data transformation and migration.

### 1.4.4 Custom Scripts

* **Python or PowerShell**: Write custom scripts for data extraction and loading.
  \`\`\`python
  import pyodbc
  import psycopg2

## Connect to SQL Server

  sql_conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=myserver;DATABASE=mydatabase;UID=myuser;PWD=mypassword')

## Connect to PostgreSQL

  pg_conn = psycopg2.connect(database="mydatabase", user="myuser", password="mypassword", host="myserver", port="5432")

## Data Extraction and Loading

## ... Custom ETL logic

  \`\`\`
