---
title: "Building a Logistic Regression Model with Greenplum, MADlib, and pgvector"
lastmod: 2024-07-09T14:27:27+10:00
date: 2024-07-09T14:27:27+10:00
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

In our previous blog post, we embarked on a journey to enhance our AI/ML capabilities by setting up Greenplum, a powerful massively parallel processing (MPP) database. Now, we're ready to take the next step and explore the exciting world of in-database machine learning!
In this blog post, we’ll walk through the process of installing MADlib and pgvector on Greenplum, and then use them to build a logistic regression model for loan approvals. We’ll cover data preparation, model training, prediction, and evaluation. This tutorial aims to demonstrate the power of in-database machine learning with Greenplum, a massively parallel processing (MPP) database, leveraging the analytical capabilities of MADlib and the efficient vector operations provided by pgvector.

## Why In-Database Machine Learning?

One of the major challenges in traditional machine learning workflows is the need to move large volumes of data from the database to a separate analytics environment. This data movement can be time-consuming, expensive, and introduce potential security risks.

By building our model directly within Greenplum, we eliminate the need for this data transfer. This offers several significant benefits:

* **Improved Performance:** In-database analytics often outperforms traditional approaches, as the data doesn't need to be transferred across networks or systems.  Greenplum's parallel processing capabilities further enhance performance, especially for large datasets.
* **Reduced Complexity:** Streamlining the workflow by keeping data and analysis within the same environment simplifies development and deployment.
* **Enhanced Security:** Data remains within the secure confines of your database, minimizing exposure during transfer.
* **Real-time Insights:** With in-database processing, you can generate predictions and insights more quickly, enabling real-time decision-making.

## Part 1: The Technologies: Greenplum, MADlib, and pgvector

### Greenplum

**The Database**: Greenplum is a massively parallel processing (MPP) database designed for big data analytics. It excels at handling large datasets and complex queries, making it a great choice for machine learning tasks.

**Benefits**:

* **Scalability**: Handles massive datasets with ease, scaling out to hundreds of nodes.
* **Parallel Processing**: Distributes workloads across multiple nodes for faster query execution, improving performance for data-intensive tasks.
* **SQL-Based**: Allows you to use familiar SQL to interact with your data, making it accessible for database administrators and data analysts.
* **Extensibility**: Supports various extensions like MADlib and pgvector for enhanced functionality, enabling advanced analytics and machine learning directly within the database.

### MADlib

**The Analytics Library**: MADlib is an open-source library that brings advanced analytics capabilities to your PostgreSQL or Greenplum database. It provides a suite of machine learning, statistical, and graph algorithms that run in-database.

**Benefits**:

* **In-Database Analytics**: Eliminates the need to move data out of the database for processing, reducing data movement and ensuring data security.
* **Scalable Algorithms**: Algorithms are designed to handle large datasets efficiently, leveraging the parallel processing capabilities of Greenplum.
* **Variety of Functions**: Provides a wide range of machine learning, statistical, and graph analysis functions, including regression, classification, clustering, and more.
* **Ease of Use**: Integrates seamlessly with SQL, making it accessible to data analysts and scientists who are familiar with SQL.

### pgvector

**The Vector Extension**: pgvector is a PostgreSQL extension that adds support for vector data types and operations, which are essential for various machine learning tasks.

**Benefits**:

* **Efficient Vector Storage**: Provides a native way to store vectors within PostgreSQL, allowing for efficient storage and retrieval.
* **Similarity Search**: Offers specialized indexes and functions for fast similarity searches, which are useful for tasks like recommendation systems and nearest neighbor searches.
* **Machine Learning Applications**: Great for tasks like recommendation systems, natural language processing, and image analysis, where vector representations are commonly used.

## Part 2: The Problem: Loan Approval Prediction

The goal of our project is to build a model that can predict whether a loan application should be approved or rejected. This is a binary classification problem, and we’ll use logistic regression as our machine learning algorithm.

### Why Logistic Regression?

* **Well-Suited for Binary Classification**: Logistic regression is designed to predict probabilities of a binary outcome (yes/no, approved/rejected), making it ideal for this problem.
* **Interpretability**: The model’s coefficients can be interpreted to understand the importance of each feature, providing insights into the decision-making process.
* **Efficiency**: Logistic regression is relatively computationally efficient, making it suitable for large datasets typically found in loan application scenarios.

### Input Data

We’ll use a dataset of loan applications, where each application is represented by a set of features (e.g., income, credit score, employment status) and a target variable indicating whether the loan was approved or rejected.

### The Role of pgvector

We’ll use pgvector to store and process the feature vectors (arrays of numbers representing the loan applicant’s characteristics) in our database. This will allow us to leverage its capabilities for efficient distance calculations and similarity searches in the future. Storing feature vectors in the database helps streamline the workflow, reducing data movement and enabling more efficient computations directly within the database environment.

## Part 3:  Installing MADlib and pgvector

### Introduction

Before we can leverage the advanced analytics capabilities of MADlib and the efficient vector operations provided by pgvector, we need to install these extensions on our Greenplum database. The installation process involves a few steps, which we will detail below.

### Step 1: Install `m4`

The `m4` macro processor is a prerequisite for installing MADlib. It is used for text processing and is required by MADlib during installation.

```bash
sudo yum install m4
```

### Step 2: Install MADlib

MADlib is an advanced analytics library that provides machine learning algorithms, statistical methods, and graph analytics directly in the database. Installing MADlib on Greenplum involves several steps:

1. **Extract the MADlib package**: First, download the MADlib package suitable for your Greenplum version and extract it.

    ```bash
    tar xzvf madlib-2.1.0-gp7-rhel8-x86_64.tar.gz
    ```

2. **Install the MADlib package**: Use the `gppkg` tool provided by Greenplum to install the extracted package.

    ```bash
    gppkg install ./madlib-2.1.0-gp7-rhel8-x86_64/madlib-2.1.0-gp7-rhel8-x86_64.gppkg.tar.gz
    ```

3. **Add MADlib to the PATH**: Ensure the MADlib tools are accessible by adding them to your system's PATH.

    ```bash
    export PATH=$PATH:/usr/local/greenplum-db-7.1.0/madlib/Versions/2.1.0/bin
    ```

4. **Install MADlib functions in the database**: Use the `madpack` tool to install MADlib functions into your Greenplum database. This step involves running two commands: one to install the functions and another to perform an installation check.

    ```bash
    madpack -p greenplum -c gpadmin@localhost:5432/risk_feature_store install
    madpack -s madlib -p greenplum -c gpadmin@localhost:5432/risk_feature_store install-check
    ```

5. **Create MADlib schema and extension**: After installing the MADlib functions, create a schema and extension in your database to organize the MADlib functions and make them accessible.

    ```sql
    CREATE SCHEMA madlib;
    CREATE EXTENSION madlib SCHEMA madlib;
    GRANT ALL ON SCHEMA madlib TO PUBLIC;
    ```

6. **Verify the installation**: Finally, verify that MADlib is correctly installed by querying the version information.

    ```sql
    SELECT * FROM madlib.version();
    ```

### Conclusion

By following these steps, you will have successfully installed MADlib and pgvector on your Greenplum database. These powerful tools will enable you to perform advanced analytics and efficient vector operations directly within your database, paving the way for sophisticated machine learning tasks.

## Part 4:  Creating and Using a Model

In this part of the tutorial, we will create a logistic regression model to predict loan approvals. We'll start by setting up our data, then use MADlib to train and evaluate the model. We'll also utilize pgvector to handle feature vectors efficiently within our Greenplum database.

### Step 1: Create the `loan_applications` Table

First, we need to create a table to store the loan application data. This table will include various features such as applicant details, loan amount, and approval status.

```sql
CREATE TABLE loan_applications (
  application_id SERIAL PRIMARY KEY,
  applicant_name VARCHAR(100),
  applicant_age INT,
  applicant_income NUMERIC,
  loan_amount NUMERIC,
  loan_duration INT,
  credit_score INT,
  property_value NUMERIC,
  address VARCHAR(255),
  application_date DATE,
  decision_date DATE,
  loan_purpose VARCHAR(50),
  employment_status VARCHAR(50),
  employment_length NUMERIC,
  marital_status VARCHAR(20),
  number_of_dependents INT,
  occupation VARCHAR(100),
  loan_to_value_ratio NUMERIC,
  estimated_dti NUMERIC,
  approved BOOLEAN
);
```

### Step 1.1: Load Data

Once the table is created, we can load our loan application data into it. This data should be in CSV format and include headers corresponding to the table columns.

```sql
COPY loan_applications (
    applicant_name,
    applicant_age,
    applicant_income,
    loan_amount,
    loan_duration,
    credit_score,
    property_value,
    address,
    application_date,
    decision_date,
    loan_purpose,
    employment_status,
    employment_length,
    marital_status,
    number_of_dependents,
    occupation,
    loan_to_value_ratio,
    estimated_dti,
    approved
)
FROM '/home/gpadmin/loan_applications_synthetic.csv'
DELIMITER ','
CSV HEADER;
```

### Step 2: Create and Populate `loan_features` Table

Next, we will create a loan_features table to store the features derived from the loan applications. This table will include columns for various features and a vector column to store feature vectors for efficient processing with pgvector.

1. Create `loan_features` table:

    ```sql
    CREATE TABLE loan_features (
      application_id INT,
      applicant_age INT,
      applicant_income NUMERIC,
      loan_amount NUMERIC,
      loan_duration INT,
      credit_score INT,
      property_value NUMERIC,
      loan_to_value_ratio NUMERIC,
      loan_duration_months INT,
      loan_purpose_code INT,
      employment_status_code INT,
      employment_length NUMERIC,
      application_date DATE,
      approved BOOLEAN,
      feature_vector VECTOR(11)
    );
    ```

2. Insert features into `loan_features`:

We populate the loan_features table by selecting and transforming data from the loan_applications table. We also create a feature vector for each application.

    ```sql
    INSERT INTO loan_features (
      application_id,
      applicant_age,
      applicant_income,
      loan_amount,
      loan_duration,
      credit_score,
      property_value,
      loan_to_value_ratio,
      loan_duration_months,
      loan_purpose_code,
      employment_status_code,
      employment_length,
      application_date,
      approved,
      feature_vector
    )
    SELECT
      application_id,
      applicant_age,
      applicant_income,
      loan_amount,
      loan_duration,
      credit_score,
      property_value,
      COALESCE(loan_amount / property_value, 0) AS loan_to_value_ratio,
      loan_duration * 12 AS loan_duration_months,
      CASE
          WHEN loan_purpose = 'Home Purchase' THEN 1
          WHEN loan_purpose = 'Debt Consolidation' THEN 2
          ELSE 0
      END AS loan_purpose_code,
      CASE
          WHEN employment_status = 'Full-time' THEN 1
          WHEN employment_status = 'Part-time' THEN 2
          ELSE 0
      END AS employment_status_code,
      COALESCE(employment_length, 0),
      application_date,
      approved,
      ARRAY[
          COALESCE(applicant_age, 0)::float8,
          COALESCE(applicant_income, 0)::float8,
          COALESCE(loan_amount, 0)::float8,
          COALESCE(loan_duration, 0)::float8,
          COALESCE(credit_score, 0)::float8,
          COALESCE(property_value, 0)::float8,
          COALESCE(loan_amount / property_value, 0)::float8,
          COALESCE(loan_duration * 12, 0)::float8,
          COALESCE(CASE
              WHEN loan_purpose = 'Home Purchase' THEN 1
              WHEN loan_purpose = 'Debt Consolidation' THEN 2
              ELSE 0
          END, 0)::float8,
          COALESCE(CASE
              WHEN employment_status = 'Full-time' THEN 1
              WHEN employment_status = 'Part-time' THEN 2
              ELSE 0
          END, 0)::float8,
          COALESCE(employment_length, 0)::float8
      ]::VECTOR(11)
    FROM
      loan_applications;
    ```

### Step 3: Create Training Table

1. Drop table if it exists:

    ```sql
    DROP TABLE IF EXISTS loan_train;
    ```

2. Create `loan_train` table:

    ```sql
    CREATE TABLE loan_train AS
    SELECT *
    FROM (
        SELECT
            application_id,
            approved,
            ARRAY[
                COALESCE(applicant_age, 0)::double precision,
                COALESCE(applicant_income, 0)::double precision,
                COALESCE(loan_amount, 0)::double precision,
                COALESCE(loan_duration, 0)::double precision,
                COALESCE(credit_score, 0)::double precision,
                COALESCE(property_value, 0)::double precision,
                COALESCE(loan_amount / property_value, 0)::double precision,
                (COALESCE(loan_duration, 0) * 12)::double precision,
                COALESCE(loan_purpose_code, 0)::double precision,
                COALESCE(employment_status_code, 0)::double precision,
                COALESCE(employment_length, 0)::double precision
            ] AS feature_vector,
            random() as rnd
        FROM
            loan_features
        WHERE
            approved IS NOT NULL
    ) subquery
    WHERE rnd < 0.8;
    ```

### Step 4: Create Test Table

1. Drop table if it exists:

    ```sql
    DROP TABLE IF EXISTS loan_test;
    ```

2. Create `loan_test` table:

    ```sql
    CREATE TABLE loan_test AS
    SELECT
        application_id,
        approved,
        ARRAY[
            COALESCE(applicant_age, 0)::double precision,
            COALESCE(applicant_income, 0)::double precision,
            COALESCE(loan_amount, 0)::double precision,
            COALESCE(loan_duration, 0)::double precision,
            COALESCE(credit_score, 0)::double precision,
            COALESCE(property_value, 0)::double precision,
            COALESCE(loan_amount / property_value, 0)::double precision,
            (COALESCE(loan_duration, 0) * 12)::double precision,
            COALESCE(loan_purpose_code, 0)::double precision,
            COALESCE(employment_status_code, 0)::double precision,
            COALESCE(employment_length, 0)::double precision
        ] AS feature_vector
    FROM
        loan_features
    WHERE
        approved IS NOT NULL
        AND application_id NOT IN (SELECT application_id FROM loan_train);
    ```

### Step 5: Train Logistic Regression Model

1. Drop existing model tables if they exist:

    ```sql
    DROP TABLE IF EXISTS loan_model CASCADE;
    DROP TABLE IF EXISTS loan_model_summary;
    ```

2. Train the model:

    ```sql
    SELECT madlib.logregr_train(
        'loan_train',    -- Source table
        'loan_model',    -- Output model table
        'approved',      -- Dependent variable
        'feature_vector' -- Independent variable(s)
    );
    ```

### Step 6: Make Predictions

1. Predict using the model and get probabilities:

    ```sql
    SELECT lt.application_id,
           madlib.logregr_predict_prob(lt.feature_vector, lm.coef) AS probability
    FROM loan_test lt, loan_model lm;
    ```

## Evaluating the Model

### Step 7: Evaluate the Model

1. Match predictions with actual values:

    ```sql
    WITH predictions AS (
        SELECT
            lt.application_id,
            madlib.logregr_predict_prob(lt.feature_vector, lm.coef) AS probability
        FROM
            loan_test lt, loan_model lm
    )
    SELECT
        p.application_id,
        p.probability,
        lt.approved AS actual,
        CASE
            WHEN (p.probability >= 0.5 AND lt.approved::int = 1) OR (p.probability < 0.5 AND lt.approved::int = 0) THEN 'correct'
            ELSE 'incorrect'
        END AS prediction_match
    FROM
        predictions p
    JOIN
        loan_test lt ON p.application_id = lt.application_id
    ORDER BY
        p.application_id;
    ```

2. Calculate accuracy:

    ```sql
    SELECT COUNT(*) AS total,
           SUM(CASE WHEN (probability >= 0.5 AND actual_int = 1) OR (probability < 0.5 AND actual_int = 0) THEN 1 ELSE 0 END)::float / COUNT(*) AS accuracy
    FROM (
        SELECT
            lt.application_id,
            lt.approved::int AS actual_int,
            pred.probability
        FROM
            loan_test lt
        JOIN
            (SELECT lt.application_id,
                    madlib.logregr_predict_prob(lt.feature_vector, lm.coef) AS probability
             FROM loan_test lt, loan_model lm
            ) AS pred
        ON
            lt.application_id = pred.application_id
    ) subquery;
    ```

3. Calculate confusion matrix:

    ```sql
    SELECT
        SUM(CASE WHEN actual_int = 1 AND probability >= 0.5 THEN 1 ELSE 0 END) AS true_positive,
        SUM(CASE WHEN actual_int = 0 AND probability < 0.5 THEN 1 ELSE 0 END) AS true_negative,
        SUM(CASE WHEN actual_int = 1 AND probability < 0.5 THEN 1 ELSE 0 END) AS false_negative,
        SUM(CASE WHEN actual_int = 0 AND probability >= 0.5 THEN 1 ELSE 0 END) AS false_positive
    FROM (
        SELECT
            lt.application_id,
            lt.approved::int AS actual_int,
            pred.probability
        FROM
            loan_test lt
        JOIN
            (SELECT lt.application_id,
                    madlib.logregr_predict_prob(lt.feature_vector, lm.coef) AS probability
             FROM loan_test lt, loan_model lm
            ) AS pred
        ON
            lt.application_id = pred.application_id
    ) subquery;
    ```

4. Calculate Precision, Recall, and F1 Score:

    ```sql
    WITH confusion_matrix AS (
        SELECT
            SUM(CASE WHEN actual_int = 1 AND probability >= 0.5 THEN 1 ELSE 0 END) AS true_positive,
            SUM(CASE WHEN actual_int = 0 AND probability < 0.5 THEN 1 ELSE 0 END) AS true_negative,
            SUM(CASE WHEN actual_int = 1 AND probability < 0.5 THEN 1 ELSE 0 END) AS false_negative,
            SUM(CASE WHEN actual_int = 0 AND probability >= 0.5 THEN 1 ELSE 0 END) AS false_positive
        FROM (
            SELECT
                lt.application_id,
                lt.approved::int AS actual_int,
                pred.probability
            FROM
                loan_test lt
            JOIN
                (SELECT lt.application_id,
                        madlib.logregr_predict_prob(lt.feature_vector, lm.coef) AS probability
                 FROM loan_test lt, loan_model lm
                ) AS pred
            ON
                lt.application_id = pred.application_id
        ) subquery
    )
    SELECT
        true_positive,
        true_negative,
        false_negative,
        false_positive,
        true_positive::float / (true_positive + false_positive) AS precision,
        true_positive::float / (true_positive + false_negative) AS recall,
        2 * ( (true_positive::float / (true_positive + false_positive)) * (true_positive::float / (true_positive + false_negative)) ) /
          ( (true_positive::float / (true_positive + false_positive)) + (true_positive::float / (true_positive + false_negative)) ) AS f1_score
    FROM confusion_matrix;

## Part 5: Using the Loan Approval Model

After training the loan approval model using MADlib, the next step is to use the model for making predictions. This section will cover different methods for deploying and using the model, including batch processing, real-time scoring, and integration with applications.

### Batch Processing

Batch processing is useful when you need to evaluate a large number of loan applications periodically. This method involves creating a new table to store the predictions and then querying the results.

1. **Create a new table to store the results**:
    ```sql
    CREATE TABLE loan_predictions AS
    SELECT
        lt.application_id,
        madlib.logregr_predict_prob(lt.feature_vector, lm.coef) AS probability,
        CASE
            WHEN madlib.logregr_predict_prob(lt.feature_vector, lm.coef) >= 0.5 THEN TRUE
            ELSE FALSE
        END AS approved
    FROM loan_test lt, loan_model lm;
    ```

2. **Query the predictions**:
    ```sql
    SELECT * FROM loan_predictions WHERE approved = TRUE;
    ```

### Real-Time Scoring

Real-time scoring is essential when you need to evaluate loan applications as they come in, providing immediate feedback. This method involves creating a stored procedure that takes an application’s features as input and returns the approval prediction.

1. **Create a stored procedure**:
    ```sql
    CREATE OR REPLACE FUNCTION predict_loan_approval(
        applicant_age INT,
        applicant_income NUMERIC,
        loan_amount NUMERIC,
        loan_duration INT,
        credit_score INT,
        property_value NUMERIC,
        loan_purpose_code INT,
        employment_status_code INT,
        employment_length NUMERIC
    ) RETURNS BOOLEAN AS $$
    DECLARE
        feature_vector VECTOR(11);
        probability NUMERIC;
    BEGIN
        feature_vector := VECTOR[
            COALESCE(applicant_age, 0)::double precision,
            COALESCE(applicant_income, 0)::double precision,
            COALESCE(loan_amount, 0)::double precision,
            COALESCE(loan_duration, 0)::double precision,
            COALESCE(credit_score, 0)::double precision,
            COALESCE(property_value, 0)::double precision,
            COALESCE(loan_amount / property_value, 0)::double precision,
            (COALESCE(loan_duration, 0) * 12)::double precision,
            COALESCE(loan_purpose_code, 0)::double precision,
            COALESCE(employment_status_code, 0)::double precision,
            COALESCE(employment_length, 0)::double precision
        ];
        SELECT madlib.logregr_predict_prob(feature_vector, lm.coef) INTO probability
        FROM loan_model lm;
        RETURN probability >= 0.5;
    END;
    $$ LANGUAGE plpgsql;
    ```

2. **Call the procedure** with application data:
    ```sql
    SELECT predict_loan_approval(
        35, 50000, 15000, 5, 700, 200000, 1, 1, 5.5
    );
    ```

## Integration with Applications

For integrating the model into a web or mobile application, you can expose the model as an API. This method allows external applications to send loan application data and receive approval predictions.

1. **Expose the model as an API**:
    - Use a framework like Flask (Python) or Express (Node.js) to create an endpoint that calls the stored procedure and returns the result.

2. **Example with Flask**:
    ```python
    from flask import Flask, request, jsonify
    import psycopg2

    app = Flask(__name__)

    def get_db_connection():
        conn = psycopg2.connect(
            dbname='risk_feature_store',
            user='gpadmin',
            password='your_password',
            host='localhost'
        )
        return conn

    @app.route('/predict', methods=['POST'])
    def predict():
        data = request.json
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT predict_loan_approval(%s, %s, %s, %s, %s, %s, %s, %s, %s)',
                    (data['applicant_age'], data['applicant_income'], data['loan_amount'],
                     data['loan_duration'], data['credit_score'], data['property_value'],
                     data['loan_purpose_code'], data['employment_status_code'], data['employment_length']))
        result = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify({'approved': result[0]})

    if __name__ == '__main__':
        app.run(debug=True)
    ```
    

## Conclusion

In this blog post, we have demonstrated how to install MADlib and pgvector, create and prepare data, train a logistic regression model, make predictions, and evaluate the model using Greenplum. This process can be applied to various other use cases where logistic regression and feature vectors are required. Using the loan approval model effectively requires choosing the right deployment strategy based on your application needs. Whether you use batch processing, real-time scoring, or API integration, following best practices ensures that your model delivers accurate and timely predictions to support decision-making processes.
