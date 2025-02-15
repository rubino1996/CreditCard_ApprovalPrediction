
library(dplyr)
library(tidyr)
library(ggplot2)
library(cluster)
library(caTools)
library(nnet)

df_1 <- read.csv("application_record.csv")
df_2 <- read.csv("credit_record.csv")

# Convert STATUS to numeric values with shifting
df_2 <- df_2 %>%
  mutate(STATUS_NUM = case_when(
    STATUS == "X" ~ 0,  # No loan that month
    STATUS == "C" ~ 1,  # Paid off, no overdue
    STATUS == "0" ~ 2,  # 1-29 days overdue
    STATUS == "1" ~ 3,  # 30-59 days overdue
    STATUS == "2" ~ 4,  # 60-89 days overdue
    STATUS == "3" ~ 5,  # 90-119 days overdue
    STATUS == "4" ~ 6,  # 120-149 days overdue
    STATUS == "5" ~ 7,  # 150+ days overdue
    TRUE ~ NA_real_  # Handle unexpected values
  ))


# Aggregate credit history per ID
df_2_agg <- df_2 %>%
  group_by(ID) %>%
  summarize(
    num_months = n(),  # Total months recorded
    latest_status = STATUS_NUM[which.max(MONTHS_BALANCE)],  # Most recent status
    worst_status = max(STATUS_NUM, na.rm = TRUE),  # Worst recorded status
    num_no_loan_months = sum(STATUS_NUM == 0, na.rm = TRUE),  # Months with no loan
    num_good_months = sum(STATUS_NUM == 1, na.rm = TRUE),  # Months with full payment
    num_bad_months = sum(STATUS_NUM >= 3, na.rm = TRUE),  # Months overdue by 60+ days
  )

# Meging Data
merged_df <- df_1 %>% left_join(df_2_agg, by = "ID")


# replacing NA Values
merged_df <- merged_df %>%
  mutate(
    num_months = replace_na(num_months,0),
    num_good_months = replace_na(num_good_months,0),
  )

#-----------------------------------------------------------------------
# Clustering Begins here:

X <- merged_df[, c(19, 23)] #Number of Months, Number of Good Months


# Using elbow method
wcss = vector()
for (i in 1:10) wcss[i] = sum(kmeans(X, i)$withinss)
plot(x = 1:10,
     y = wcss,
     type = 'b',
     main = paste('The Elbow Method'),
     xlab = 'Number of clusters',
     ylab = 'WCSS')


set.seed(29)
kmeans = kmeans(x = X,
                centers = 4,
                iter.max = 100,
                nstart = 12)


# Visualizing the clusters using ggplot2
merged_df$Group <- as.factor(kmeans$cluster)
plot <- ggplot(dat = merged_df, aes(x = num_months , y = num_good_months)) +
  geom_point(aes(color = Group, shape = NAME_FAMILY_STATUS), size = 3) +
  xlab("Number of Months")+
  ylab("Good Months")+
  ggtitle("Credit History") +
  theme(axis.title.x = element_text(colour="Blue", size = 20),
        axis.title.y = element_text(colour = "Blue", size = 20),
        axis.text.x = element_text(size = 10),
        axis.text.y = element_text(size = 10),
        legend.title = element_text(size = 10),
        legend.text = element_text(size = 10),
        plot.title = element_text(colour = "Black", size = 30, hjust = 0.5))

plot$labels$shape = "Family Status"

plot


#-------------------------------------------------------
# Logistic Regression begins here:

# Transforming the DAYS_EMPLOYED column
merged_df <- merged_df %>%
  mutate(DAYS_EMPLOYED = ifelse(DAYS_EMPLOYED < 0, abs(DAYS_EMPLOYED), 0))

# Transforming the DAYS_Birth column
merged_df <- merged_df %>%
  mutate(DAYS_BIRTH = if (TRUE) abs(DAYS_BIRTH))


# Training Logistic Regression Method
dataset <- merged_df[, c(6, 11, 12, 18, 19, 23, 25)]
set.seed(123)
split = sample.split(dataset$Group, SplitRatio = 0.75)
training_set = subset(dataset, split == TRUE)
test_set = subset(dataset, split == FALSE)


# Feature Scaling
training_set[-7] = scale(training_set[-7])
test_set[-7] = scale(test_set[-7])

# Fitting Logistic Regression to the Training set
classifier <- multinom(Group ~ ., data = training_set)

# Predicting the Test set results
prob_pred <- predict(classifier, newdata = test_set[-7], type = 'class')

# Create the confusion matrix
confusion_matrix <- table(test_set$Group, prob_pred)
print(confusion_matrix)

# Calculate overall accuracy
accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)

# Calculate precision, recall, and F1-score for each class
n_classes <- nrow(confusion_matrix)
metrics <- data.frame(Class = 1:n_classes, 
                      Precision = NA, 
                      Recall = NA, 
                      F1_Score = NA)

for(i in 1:n_classes) {
  # Precision
  precision <- confusion_matrix[i,i] / sum(confusion_matrix[,i])
  # Recall
  recall <- confusion_matrix[i,i] / sum(confusion_matrix[i,])
  # F1 Score
  f1 <- 2 * (precision * recall) / (precision + recall)
  
  metrics[i,2:4] <- c(precision, recall, f1)
}

# Print the metrics
print("Overall Accuracy:")
print(accuracy)
print("\nPer-class metrics:")
print(metrics)


