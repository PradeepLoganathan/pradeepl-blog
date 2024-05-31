---
title: "Building a Fraud Detection Model using AI/ML"
lastmod: 2024-05-15T11:39:06+10:00
date: 2024-05-15T11:39:06+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - 
  - 
  - 
categories:
  - 
#slug: kubernetes/introduction-to-open-policy-agent-opa/
description: 
summary: "summary used in summary pages"
ShowToc: true
TocOpen: true
images:
  - 
cover:
    image: "images/cover.webp"
    alt: ""
    caption: ""
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---



## Introduction

Fraud detection is a critical task for financial institutions. Identifying fraudulent transactions can save millions of dollars and protect users from malicious activities. In this blog post, we will build a fraud detection model using a public dataset from Kaggle and deploy it as a Flask API. We'll cover the entire process, including data preparation, model building, evaluation, and deployment.

## Setting Up Your Environment

Let's begin by ensuring you have the necessary tools installed.

```bash
pip install pandas numpy scikit-learn matplotlib seaborn imbalanced-learn flask
```

## Dataset Overview

We will use the [Credit Card Fraud Detection Dataset](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) from Kaggle. This dataset contains transactions made by European cardholders in September 2013. It has 284,807 transactions, with 492 frauds, making it highly imbalanced.

### Loading the Dataset

First, let's load the dataset into a pandas DataFrame.As discussed we will use the "Credit Card Fraud Detection" dataset available on [Kaggle](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud)

```python
import pandas as pd

# Load the dataset
data = pd.read_csv('creditcard.csv')

# Display the first few rows
print(data.head())
print(data.describe())
```

Key points to note about this dataset are

* Imbalanced Dataset: Fraudulent transactions are rare, so the dataset is heavily imbalanced.
* Anonymized Features: Features are labeled V1, V2, ... V28 due to privacy concerns.
* Time and Amount: These are the only features not transformed with PCA.

## Data Preparation

Before building the model, we need to prepare the data. This includes handling missing values, scaling features, and splitting the dataset into training and test sets.

### Handling Missing Values

Let's check for any missing values in the dataset.

```python
# Check for missing values
print(data.isnull().sum())
```
The dataset has no missing values, so we can proceed to the next step.

### Scaling Features

The features Time and Amount need to be scaled. We will use StandardScaler for this purpose.

```python
from sklearn.preprocessing import StandardScaler

# Scale the 'Amount' and 'Time' features
scaler = StandardScaler()
data[['Amount', 'Time']] = scaler.fit_transform(data[['Amount', 'Time']])
```

### Splitting the Dataset

We will split the dataset into training and test sets. We'll use 70% of the data for training and 30% for testing.

```python
from sklearn.model_selection import train_test_split

# Split the dataset
X = data.drop('Class', axis=1)
y = data['Class']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)
```

## Exploratory Data Analysis (EDA)

Performing EDA helps us understand the data better. We will visualize the class distribution and correlation matrix.

### Class Distribution

Let's plot the distribution of the target variable Class.

```python
import matplotlib.pyplot as plt
import seaborn as sns

# Plot class distribution
sns.countplot(x='Class', data=data)
plt.title('Class Distribution')
plt.show()
```

### Correlation Matrix

Visualizing the correlation matrix helps identify relationships between features.

```python
# Correlation matrix
corr_matrix = data.corr()
plt.figure(figsize=(12, 8))
sns.heatmap(corr_matrix, annot=True, fmt='.2f')
plt.title('Correlation Matrix')
plt.show()
```

## Model Building

We will use a Random Forest classifier for this task. Random Forests are robust and often perform well on imbalanced datasets.

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score

# Train the model
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_train, y_train)

# Predict on the test set
y_pred = model.predict(X_test)
```

## Model Evaluation

Evaluating the model's performance is crucial. We will use precision, recall, F1-score, and ROC-AUC score for evaluation.

### Classification Report and Confusion Matrix

```python
# Classification report
print(classification_report(y_test, y_pred))

# Confusion matrix
conf_matrix = confusion_matrix(y_test, y_pred)
sns.heatmap(conf_matrix, annot=True, fmt='d')
plt.title('Confusion Matrix')
plt.show()
```

### ROC-AUC Score

The ROC-AUC score provides a single metric to evaluate the model's performance.

```python
# ROC-AUC score
roc_auc = roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])
print(f'ROC-AUC Score: {roc_auc:.2f}')
```
## Saving the Model

Save the trained model to a file so it can be loaded by the Flask app.

```python
import pickle

# Save the model
with open('fraud_detection_model.pkl', 'wb') as f:
    pickle.dump(model, f)
```

## Model Deployment

Now that we have a trained model, we'll deploy it as a Flask API. Flask is a lightweight web framework for Python.

### Setting Up Flask

First, install Flask if you haven't already

```bash
pip install Flask
```

### Creating the Flask API

Create a new file called app.py and add the following code to set up the Flask API

```python
from flask import Flask, request, jsonify
import pickle
import pandas as pd

# Load the trained model
model = pickle.load(open('fraud_detection_model.pkl', 'rb'))

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json(force=True)
    df = pd.DataFrame([data])
    prediction = model.predict(df)
    return jsonify({'prediction': int(prediction[0])})

if __name__ == '__main__':
    app.run(debug=True)
```

### Testing the API

Run the Flask app

```bash
python app.py
```

To test the API, you can use a tool like curl or Postman to send a POST request to http://127.0.0.1:5000/predict with JSON data. You can use a curl command as below

```bash
curl -X POST -H "Content-Type: application/json" -d '{"Time":-1.359807134,"V1":-0.0727811733094,"V2":2.536346737,"V3":1.378155224,"V4":0.001542962,"V5":0.300687081,"V6":0.47668358,"V7":-0.358792343,"V8":0.676280733,"V9":0.027056132,"V10":0.082794295,"V11":0.078497073,"V12":-0.39500069,"V13":-0.33832077,"V14":0.462387778,"V15":-0.57534921,"V16":-0.346379052,"V17":0.623157105,"V18":0.855191578,"V19":-0.254117518,"V20":0.11794168,"V21":-0.064306244,"V22":0.305486771,"V23":-0.00610653,"V24":0.002678882,"V25":0.024708905,"V26":0.001694461,"V27":0.01771508,"V28":0.000774177,"Amount":149.62}' http://127.0.0.1:5000/predict
```

This command sends a JSON object representing a transaction to the API and returns a prediction.

## Conclusion

In this blog post, we built a fraud detection model using the Credit Card Fraud Detection Dataset from Kaggle. We performed data preparation, exploratory data analysis, feature engineering, model building, and evaluation. Finally, we deployed the model as a Flask API. This end-to-end project demonstrates how to tackle fraud detection and deploy a machine learning model for real-world use.

You can find the complete code on GitHub.

## Code and Resources

[Credit Card Fraud Detection Dataset]()

[GitHub Repository]()

By following these steps, you will have a fully functional fraud detection model and a deployed API ready for use. Happy coding!