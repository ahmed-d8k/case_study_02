#Case Study 2 Attrition Model
library(magrittr)
library(ggplot2)
library(tidyverse)
library(class)
library(caret)
library(e1071)
library(lsmeans)

df_raw = read.csv(file = 'C:\\Users\\amada\\OneDrive\\Desktop\\RStudioFiles\\Scripts\\SMU\\Term1\\DS6306\\CaseStudy2\\CaseStudy2_data.csv')

#Check NAs
df_raw %>% 
  summarise(across(everything(), ~ sum(is.na(.x)))) %>%
  gather(Column, NA_Count) %>%
  ggplot(aes(x=NA_Count, y=Column, fill = Column)) + geom_col() + ylab("Feature")

#No NAs

#Create Model with our previous reported three features
#Age
#MonthlyIncome
#OverTime
#TotalWorkingYears* 
#JobLevel*

##New Variables
#StockOptionLevel
#DistanceFromHome
#EnvironmentSatisfaction
#MaritalStatus

df_model = df_raw %>% select("Age", "MonthlyIncome", "OverTime", "TotalWorkingYears", "JobLevel", "Attrition",
                             "StockOptionLevel", "DistanceFromHome", "EnvironmentSatisfaction", "MaritalStatus")

#Adjust OverTime such that its a dummy
df_model$OverTime_Yes = ifelse(df_model$OverTime == "Yes", 1, 0)
df_model$OverTime_No = ifelse(df_model$OverTime == "No", 1, 0)

#Adjust MaritalStatus
df_model$MS_Single = ifelse(df_model$MaritalStatus == "Single", 1, 0)
df_model$MS_Divorced = ifelse(df_model$MaritalStatus == "Divorced", 1, 0)
df_model$MS_Married = ifelse(df_model$MaritalStatus == "Married", 1, 0)


#Normalize the other variables
df_model$Age_Norm = (df_model$Age  - mean(df_model$Age))/sd(df_model$Age)
df_model$MonthlyIncome_Norm = (df_model$MonthlyIncome  - mean(df_model$MonthlyIncome))/sd(df_model$MonthlyIncome)
df_model$TotalWorkingYears_Norm = (df_model$TotalWorkingYears  - mean(df_model$TotalWorkingYears))/sd(df_model$TotalWorkingYears)
df_model$JobLevel_Norm = (df_model$JobLevel  - mean(df_model$JobLevel))/sd(df_model$JobLevel)

df_model$StockOptionLevel_Norm = (df_model$StockOptionLevel  - mean(df_model$StockOptionLevel))/sd(df_model$StockOptionLevel)
df_model$DistanceFromHome_Norm = (df_model$DistanceFromHome  - mean(df_model$DistanceFromHome))/sd(df_model$DistanceFromHome)
df_model$EnvironmentSatisfaction_Norm = (df_model$EnvironmentSatisfaction  - mean(df_model$EnvironmentSatisfaction))/sd(df_model$EnvironmentSatisfaction)

#Setup Final Data State
df_model_final = df_model %>% select("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
                                     "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
                                     "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
                                     "MS_Single", "MS_Divorced", "MS_Married", "Attrition")


str(df_model_final)

#Randomly Shuffle df
df_model_final_shuffled = df_model_final[sample(1:nrow(df_model_final)), ]


#Split into Train/Validation set and test set 60 20 20 split
tt_l = train_test_split(df_model_final_shuffled, splitPerc = 0.9)

train_data = tt_l[[1]]
test_data = tt_l[[2]]
train_data %>% ggplot(aes(x=Attrition)) + geom_bar()
test_data %>% ggplot(aes(x=Attrition)) + geom_bar()

#SPecify Features and Target
fea = c("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
        "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
        "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
        "MS_Single")
fea = c("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
        "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
        "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
        "MS_Single", "MS_Divorced", "MS_Married")

tar = c("Attrition")

#KNN Hyperparameter Tuning
perc_downsample = 0.8
rep_upsample = 4
optimal_k = find_optimal_k2(train_data, fea, tar, 
               5, 50, split = 0.888,  s_num=30, avg_loop=5, rep_upsample = rep_upsample, perc_downsample = perc_downsample,
                          title = "K versus Accuracy for KNN Model")

#Randomly Shuffle df
df_model_final_shuffled = df_model_final[sample(1:nrow(df_model_final)), ]


#Split into Train/Validation set and test set 60 20 20 split
tt_l = train_test_split(df_model_final_shuffled, splitPerc = 0.9)

train_data = tt_l[[1]]
test_data = tt_l[[2]]
train_data %>% ggplot(aes(x=Attrition)) + geom_bar()
test_data %>% ggplot(aes(x=Attrition)) + geom_bar()

perc_downsample = 0.8
rep_upsample = 4
optimal_k = 34
#UpSampling and DownSampling

minority_target = train_data %>% filter(Attrition == "Yes")
majority_target = train_data %>% filter(Attrition == "No")
trainIndices = sample(1:dim(majority_target)[1], round(perc_downsample * dim(majority_target)[1]))
train_data2 = majority_target[trainIndices,]
for(l in 1:rep_upsample){
  train_data2 = rbind(train_data2, minority_target)
}

#train_data2 %>% ggplot(aes(x=Attrition)) + geom_bar()

#Setup train and test data
train_fea = train_data2 %>% select(contains(fea))
train_tar = train_data2 %>% select(contains(tar))
test_fea = test_data %>% select(contains(fea))
test_tar = test_data %>% select(contains(tar))

#Final KNN Model
clsf_rep = knn(train_fea[,], test_fea[,], train_tar[,], k=optimal_k, prob = T)
CM_rep = confusionMatrix(table(clsf_rep, test_tar[,]))
CM_rep

CM_rep$byClass

df_model_final %>% ggplot(aes(x=MonthlyIncome_Norm, y=MonthlyIncome_Norm, col = Attrition)) + geom_point()

#KNN Model is not doing too great. Try Random Forest Instead
library(randomForest)

#Randomly Shuffle df
df_model_final_shuffled = df_model_final[sample(1:nrow(df_model_final)), ]


#Split into Train/Validation set and test set 60 20 20 split
tt_l = train_test_split(df_model_final_shuffled, splitPerc = 0.9)

train_data = tt_l[[1]]
test_data = tt_l[[2]]

#SPecify Features and Target

fea = c("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
        "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
        "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
        "MS_Single")
fea = c("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
        "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
        "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
        "MS_Single", "MS_Divorced", "MS_Married")
tar = c("Attrition")




#Forest Hyperparameter Tuning
perc_downsample = 0.8
rep_upsample = 4
optimal_d = find_optimal_depth(train_data, fea, tar, 
                               2, 20, split = 0.888,  s_num=30, avg_loop=5, rep_upsample = rep_upsample, perc_downsample = perc_downsample,
                               title = "K versus Accuracy for Forest Model")

#Split into Train/Validation set and test set 60 20 20 split
tt_l = train_test_split(df_model_final_shuffled, splitPerc = 0.9)

train_data = tt_l[[1]]
test_data = tt_l[[2]]

#SPecify Features and Target

fea = c("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
        "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
        "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
        "MS_Single")
tar = c("Attrition")

perc_downsample = 0.7
rep_upsample = 4
optimal_d = 9
#UpSampling and DownSampling

minority_target = train_data %>% filter(Attrition == "Yes")
majority_target = train_data %>% filter(Attrition == "No")
trainIndices = sample(1:dim(majority_target)[1], round(perc_downsample * dim(majority_target)[1]))
train_data3 = majority_target[trainIndices,]
for(l in 1:rep_upsample){
  train_data3 = rbind(train_data3, minority_target)
}

#Setup train and test data
train_fea = train_data3 %>% select(contains(fea))
train_tar = train_data3 %>% select(contains(tar))
test_fea = test_data %>% select(contains(fea))
test_tar = test_data %>% select(contains(tar))

#Build Final Model

forest = randomForest(x=train_fea, y=as.factor(train_tar$Attrition),
                      ntree = 1000, maxnodes = optimal_d)

#Test Final Model
pred_forest = predict(forest, test_fea)
CM_rep = confusionMatrix(table(pred_forest, test_tar[,]))
CM_rep


#Output Predictions
df_comp = read.csv(file = 'C:\\Users\\amada\\OneDrive\\Desktop\\RStudioFiles\\Scripts\\SMU\\Term1\\DS6306\\CaseStudy2\\CaseStudy2CompSet_No_Attrition.csv')

#Setup output Dataframe
output = data.frame(ID = df_comp$ID)

#Perform the same parameter adjustments we did before

#Adjust OverTime such that its a dummy
df_comp$OverTime_Yes = ifelse(df_comp$OverTime == "Yes", 1, 0)
df_comp$OverTime_No = ifelse(df_comp$OverTime == "No", 1, 0)

#Adjust MaritalStatus
df_comp$MS_Single = ifelse(df_comp$MaritalStatus == "Single", 1, 0)
df_comp$MS_Divorced = ifelse(df_comp$MaritalStatus == "Divorced", 1, 0)
df_comp$MS_Married = ifelse(df_comp$MaritalStatus == "Married", 1, 0)


#Normalize the other variables
df_comp$Age_Norm = (df_comp$Age  - mean(df_comp$Age))/sd(df_comp$Age)
df_comp$MonthlyIncome_Norm = (df_comp$MonthlyIncome  - mean(df_comp$MonthlyIncome))/sd(df_comp$MonthlyIncome)
df_comp$TotalWorkingYears_Norm = (df_comp$TotalWorkingYears  - mean(df_comp$TotalWorkingYears))/sd(df_comp$TotalWorkingYears)
df_comp$JobLevel_Norm = (df_comp$JobLevel  - mean(df_comp$JobLevel))/sd(df_comp$JobLevel)

df_comp$StockOptionLevel_Norm = (df_comp$StockOptionLevel  - mean(df_comp$StockOptionLevel))/sd(df_comp$StockOptionLevel)
df_comp$DistanceFromHome_Norm = (df_comp$DistanceFromHome  - mean(df_comp$DistanceFromHome))/sd(df_comp$DistanceFromHome)
df_comp$EnvironmentSatisfaction_Norm = (df_comp$EnvironmentSatisfaction  - mean(df_comp$EnvironmentSatisfaction))/sd(df_comp$EnvironmentSatisfaction)

#Setup Final Data State
df_comp_final = df_comp %>% select("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
                                     "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
                                     "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
                                     "MS_Single", "MS_Divorced", "MS_Married")

#Specify Features

fea = c("Age_Norm", "MonthlyIncome_Norm", "TotalWorkingYears_Norm", 
        "JobLevel_Norm", "OverTime_Yes", "OverTime_No",
        "StockOptionLevel_Norm", "DistanceFromHome_Norm", "EnvironmentSatisfaction_Norm",
        "MS_Single")


#Create features for comp dataframe
test_fea = df_comp_final %>% select(contains(fea))

#Output predictions
output$Attrition = predict(forest, test_fea)

#Write to CSV
write.csv(output,'Case2PredictionsAwadallah Attrition.csv', row.names = FALSE)






