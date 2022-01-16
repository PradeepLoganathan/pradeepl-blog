---
title: "Support Vector Machines (SVM)"
date: "2014-03-11"
categories: 
  - "machine-learning"
---

Support Vector Machines (SVMs) are powerful tools for data classification. SVM finds an optimal hyperplane that best segregates observations from different classes. Support vector machines (SVMs) are used for classification of both linear and nonlinear data. Classification is achieved by a linear or nonlinear mapping to transform the original training data into a higher dimension. Within this new dimension, it searches for the linear optimal separating hyperplane (i.e. a “decision boundary” separating the tuples of one class from another). With an appropriate nonlinear mapping to a sufficiently high dimension, data from two classes can always be separated by a hyperplane. The SVM finds this hyperplane using support vectors (“essential” training tuples) and margins (defined by the support vectors). SVM’s  became famous when, using images as input, it gave accuracy comparable to neural-network with hand-designed features in a handwriting recognition task.

Support vector machines select a small number of critical boundary instances called support vectors from each class and build a linear discriminant function that separates them as widely as possible. This instance-based approach transcends the limitations of linear boundaries by making it practical to include extra nonlinear terms in the function, making it possible to form quadratic, cubic, and higher-order decision boundaries.

SVM’s are based on an algorithm that finds a special kind of linear model: the maximum-margin hyperplane. The maximum-margin hyperplane is the one that gives the greatest separation between the classes—it comes no closer to either than it has to.

Using a mathematical transformation, it moves the original data set into a new mathematical space in which the decision boundary is easy to describe. Because this transformation depends only on a simple computation involving “kernels,” this technique is called the kernel trick. kernel can be set to one of four values: linear, polynomial, radial and sigmoid.

SVMs were developed by Cortes & Vapnik (1995) for binary classification.

**Class separation**: We are looking for the optimal separating hyperplane between the two classes by maximizing the margin between the classes’ closest points |the points lying on the boundaries are called support vectors, and the middle of the margin is our optimal separating hyperplane.

**Overlapping classes**: Data points on the “wrong” side of the discriminant margin are weighted down to reduce their influence ( “soft margin” ).

**Nonlinearity**: when we cannot find a linear separator, data points are projected into an (usually) higher-dimensional space where the data points effectively become linearly separable (this projection is realised via kernel techniques ). Problem solution: the whole task can be formulated as a quadratic optimization problem which can be solved by known techniques.

A program able to perform all these tasks is called a Support Vector Machine.
