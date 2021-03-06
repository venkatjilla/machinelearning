#load packages
library(data.table)
library(caret)

#load data and preparation
train = read.table("train.csv",sep=",",header = T) 
test =  read.table("test-comb.csv",sep=",",header = T) 
test = test[,-c(1,13)]
test$Purchase = NA
data = rbind(train,test)

# *************************** data exploration  ****************************************************
head(data)
dim(data)
str(data)
'dimensions:550068X12'

#missing counts
sum(is.na(data$Purchase))
sum(is.na(data$Product_Category_3))
sum(is.na(data$Product_Category_2))
sum(is.na(data$Marital_Status))
sum(is.na(data$Stay_In_Current_City_Years))
sum(is.na(data$City_Category))
sum(is.na(data$Occupation))
'all the data is is with no missing data'

# *************************** data preparation  ****************************************************
#coverting to factors
data$Marital_Status = as.factor((data$Marital_Status))
data$Product_Category_1 = as.factor((data$Product_Category_1))
data$Product_Category_2 = as.factor((data$Product_Category_2))
data$Product_Category_3 = as.factor((data$Product_Category_3))
data$Occupation = as.factor((data$Occupation))
data$Stay_In_Current_City_Years = as.integer((data$Stay_In_Current_City_Years))

#one-hot encoding

dummy = dummyVars("~.",data=data[,9:11])
ohe_dummy = data.frame(predict(dummy,newdata = data[,c(9,10,11)]))
dummy_2 = dummyVars("~.",data=data[,c(3:6,8)])
ohe_dummy2 = data.frame(predict(dummy_2,newdata = data[,c(3:6,8)]))
ohe_data = cbind(data,ohe_dummy,ohe_dummy2)
ohe_data_final = ohe_data[ , -which(names(ohe_data) %in% c("Product_Category_1","Product_Category_2","Product_Category_3","Gender","Age","Occupation","City_Category","Marital_Status"))]

#ohe_data_final$Product_Category_2.1 = 0
#ohe_data_final$Product_Category_2.19 = 0
#ohe_data_final$Product_Category_2.20 = 0
#ohe_data_final$Product_Category_3.1 = 0
#ohe_data_final$Product_Category_3.2 = 0
#ohe_data_final$Product_Category_3.19 = 0
#ohe_data_final$Product_Category_3.20 = 0

ohe_train = ohe_data_final[1:550068,]
ohe_test = ohe_data_final[550069:783667,]
ohe_train[is.na(ohe_train)] = 0
ohe_test[is.na(ohe_test)] = 0

# *************************** base line model  ****************************************************
linearMod <- lm(Purchase~.,data=ohe_train[,-c(1,2)])
summary(linearMod)

# make base line predictions
Purchase = predict(linearMod,ohe_test[,-4]
submit = data.frame(cbind(ohe_test[,c(1,2)],Purchase))
write.csv(submit,file="submit.csv")
#score: 2292 on AV leaderboard
#**************************************** base line model ******************************************
modelSummary <- summary(linearMod)  # capture model summary as an object
modelCoeffs <- modelSummary$coefficients  # model coefficients
beta.estimate <- modelCoeffs["Stay_In_Current_City_Years", "Estimate"]  # get beta estimate for speed
std.error <- modelCoeffs["Stay_In_Current_City_Years", "Std. Error"]  # get std.error for speed
t_value <- as.numeric(beta.estimate)/as.numeric(std.error)  # calc t statistic
p_value <- 2*pt(-abs(t_value), df=nrow(ohe_data_final)-ncol(ohe_data_final))  # calc p Value
f_statistic <- linearMod$fstatistic[1]  # fstatistic
f <- summary(linearMod)$fstatistic  # parameters for model p-value calc
model_p <- pf(f[1], f[2], f[3], lower=FALSE)
# *************************** creating train/validation set  ****************************************************
#replace NA to 0
ohe_data_final[is.na(ohe_data_final)] <- 0

library(DAAG)
cv.lm(ohe_data_final[,-c(1,2)], linearMod)

set.seed (1)
library(boot)
#k-fold cross validation
glm.fit = glm(Purchase~.,data=ohe_data_final[,-c(1,2)])
cv.err =cv.glm(ohe_data_final[,-c(1,2)] ,glm.fit,K=10)
cv.err$delta
glm.diag(cv.err$call)

set.seed(17)
cv.error.10= rep (0 ,10)
for (i in 1:10)
  {
    glm.fit = glm(Purchase~poly(ohe_data_final$.,i),data=ohe_data_final[,-c(1,2)])
    cv.error.10[i] =cv.glm(ohe_data_final[,-c(1,2)] ,glm.fit,K=10)
}
# ********************parameter tuning with CARET*********************************************
library(caret)
