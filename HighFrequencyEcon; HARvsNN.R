Packages <- c("readr", "neuralnet", "HARModel", "Hmisc", "dplyr", "boot", "plyr", "forecast")
#install.packages(Packages)
lapply(Packages, library, character.only=TRUE)
Data <- read_csv("C:/Users/PC/OneDrive/Uni/Uni 7. semester/High Frequency Econometrics/Data.csv")
Data[, 1] <- NULL
Data = Data %>% mutate(Date = as.Date(Data$Date), Rvol = as.numeric(Data$Rvol))
#########################################

MyData = Data %>% mutate(Lag1 = (Rvol-Lag(Rvol, -1))/1, 
                         Lag5 = (Rvol-Lag(Rvol, -5))/5,
                         Lag22 = (Rvol-Lag(Rvol, -22))/22,
                         Date = NULL)
LagData = na.exclude(MyData)
print(lapply(LagData, mean)) #Check for stationarity

#Checking for lag. See if it looks specified correctly.
windows()
ggplot(LagData,aes(Data$Date[1:length(Rvol)], y=Value,color=Variable)) + 
      geom_point(aes(y=Lag1,col="L1")) + 
      geom_point(aes(y=Lag5,col="L5")) + 
      geom_point(aes(y=Lag22,col="L22")) +
      xlab('Date')

# Split data and do plain vanilla linear modeling
index <- sample(1:nrow(LagData),round(0.75*nrow(LagData)))

train <- LagData[index,]
test <- LagData[-index,]
lm.fit <- glm(Rvol~ Lag1 + Lag5 + Lag22, data=train) #Kan vi ændre det til HAR?
summary(lm.fit)
pr.lm <- predict(lm.fit,test)
MSE.lm <- sum((pr.lm - test$Rvol)^2)/nrow(test)

# Prepare for NN
maxs <- apply(LagData, 2, max)
mins <- apply(LagData, 2, min)
scaled <- as.data.frame(scale(LagData, center = mins, scale = maxs - mins))
train_ <- scaled[index,]
test_ <- scaled[-index,]

# Setup the model
n <- names(train_)
f <- as.formula(paste("Rvol ~", paste(n[!n %in% "Rvol"], collapse = " + ")))
nn <- neuralnet(f,data=train_,hidden=c(4,2),linear.output=F)
plot(nn)

# Predict median value
pr.nn <- neuralnet::compute(nn,test_[,1:4])
pr.nn_ <- pr.nn$net.result*(max(LagData$Rvol)-min(LagData$Rvol))+min(LagData$Rvol)
test.r <- (test_$Rvol)*(max(LagData$Rvol)-min(LagData$Rvol))+min(LagData$Rvol)
MSE.nn <- sum((test.r - pr.nn_)^2)/nrow(test_)

# Compare MSE's
print(paste(MSE.lm,MSE.nn))

# Single plot
par(mfrow=c(1,1))
plot(test$Rvol,pr.nn_,col='red',main='Real vs predicted NN',pch=18,cex=0.7, xlab="Real Data", ylab="Predicted Data")
points(test$Rvol,pr.lm,col='blue',pch=18,cex=0.7)
abline(0,1,lwd=2)
legend('bottomright',legend=c('NN','HAR'),pch=18,col=c('red','blue'))

# Cross-validation 
pbar <- create_progress_bar('text')
k <- 10
cv.errorHAR <- NULL
cv.errorNN <- NULL
pbar$init(k)
for(i in 1:k){
  #New Sample
  cv.index <- sample(1:nrow(LagData),round(0.9*nrow(LagData)))
  train.cv <- scaled[index,]
  test.cv <- scaled[-index,]
    #Har estimation
    lm.fit <-  glm(Rvol~ Lag1 + Lag5 + Lag22,data=train.cv)
    #Neural Network estimation
    nn <- neuralnet(f,data=train.cv,hidden=c(4,2),linear.output=F)
    pr.nn <- neuralnet::compute(nn,test.cv[,1:4])
    pr.nn <- pr.nn$net.result*(max(LagData$Rvol)-min(LagData$Rvol))+min(LagData$Rvol)
    test.cv.r <- (test.cv$Rvol)*(max(LagData$Rvol)-min(LagData$Rvol))+min(LagData$Rvol)
  #Vectir of errors
  cv.errorHAR[i] <-  cv.glm(train.cv,lm.fit,K=10)$delta[1]
  cv.errorNN[i] <- sum((test.cv.r - pr.nn)^2)/nrow(test.cv)
  #Progress bar signal
  pbar$step()
}

print(paste(mean(cv.errorHAR), mean(cv.errorNN)))

par(mfrow=c(2, 1))
#HAR
boxplot(cv.errorHAR,xlab='MSE CV',col='cyan',
        border='blue',names='CV error (MSE)',
        main='CV error (MSE) for HAR',horizontal=TRUE)
#NN
boxplot(cv.errorNN,xlab='MSE CV',col='cyan',
        border='blue',names='CV error (MSE)',
        main='CV error (MSE) for NN',horizontal=TRUE)


########################
#Forecasting
########################
windows()
par(mfrow=c(2, 1))
#Neural Network
pr.nn_ <- predict(nn, test.cv)
pr.nn_ <- as.numeric(pr.nn_)
NNFor <- forecast(pr.nn_,  h=5)
plot(NNFor, col="blue", main="Forecast Neural Network", xlab="Days", ylab="Volatility")
lines(fitted(NNFor), type="l", col="black")
accuracy(NNFor)
sumNN <- summary(NNFor)


#HAR
pr.lm_ <-  predict(lm.fit, test.cv)
pr.lm_ <- as.numeric(pr.lm_)
HARFor <- forecast(pr.lm_, h=5)
plot(HARFor, col="red", main="Forecast HAR", xlab="Days", ylab="Volatility")
lines(fitted(HARFor), type="l", col="black")
accuracy(HARFor)
sumHAR <- summary(HARFor)


########################
#Bagging
########################
#Neural Networks
windows()
par(mfrow=c(2, 1))
y = as.numeric(pr.nn_)
pr.NNBag = baggedModel(y, bld.mbb.bootstrap(y, 100), fn=ets)
NNBag = forecast(pr.NNBag, h = 5)
plot(NNBag, type="l", col="blue", main="Forecast from Bagged Neural Network", xlab="Days", ylab="Volatility")
lines(fitted(NNBag))
#HAR
x = as.numeric(pr.lm_)
pr.HARBag = baggedModel(x, bld.mbb.bootstrap(x, 100), fn=ets)
HARBag = forecast(pr.HARBag, h = 5)
plot(HARBag, type="l", col="red", main="Forecast from Bagged HAR", xlab="Days", ylab="Volatility")
lines(fitted(HARBag))

accuracy(NNBag)
accuracy(HARBag)

######################
#Bayesian Ensemble
#####################
library(SuperLearner)
library(arm)
cv.modelNN <- CV.SuperLearner(y, test, V=5, SL.library=list("SL.bayesglm"))
cv.modelHAR <- CV.SuperLearner(x, test, V=5, SL.library=list("SL.bayesglm"))
summary(cv.modelNN)
summary(cv.modelHAR)
plot(cv.modelHAR)
plot(cv.modelNN)
