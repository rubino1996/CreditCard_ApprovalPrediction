# CreditCard_ApprovalPrediction
The project is written using the programming language R and in this repository two things are being approached. (1) Clustering to group different clients that have a total number of months vs good months in their credit history and (2) Logistic Regression (classifier) to predict if a new customer based on important features that were used to train the model will be either a good borrower or not

## Clustering ##
K-means is used here as the clustering method and it was shown that the number of clusters that would be optimal for this model is 4 using the elbow method

![](wcss.png)
![](credit_history_group.png)

## Classfier ##
For the classifer method, Logistic Regression was used and it was shown that the model trained had a high accuracy of almost 100% with high values of recall and f-1 sccore for the four different groups


