# High Frequency Econometrics:
# HAR vs. Neural-Networks
###### (Disclaimer: High Frequency Econometrics, High Frequency data manipulation, HAR, Neural Networks, Bagging, Cross-validation, Bayesian Ensemble)

Inspired by Hillebrand &amp; Medeiros (2009) and Corsi (2009), I put neural networks in a High frequency environment, and tested the performance of the two models (HAR &amp; Neural Networks). - The data used in this project is 2 years worth of intraday 5-minute realized volatility (See: Sheppard, Patton, Liu, 2012) from S&P500 stocks, that has been scrutinized using bivariate analysis and manipulation into a single dimension. 

### Introduction to the models:
##### HAR (Heterogenous Autoregressive model):
Developed by Corsi in 2009, this model is based on a simple regression framework. The independent variables is simply the daily volatility lagged 1, 5 and 22 days respectively. This is to simulate the volatility of yesterday, a week ago, and approximately one month ago (Only taking open market days into account). This type of model is also called a 'Long memory'-model, at it "remembers" what happened 22 market days ago.

How does it work intuitively?: Because traders with a higher trading frequency base their strategy on the past long-term volatility to predict the future, and change their strategies accordingly, they create short-term volatility. This behavior has no effect on traders with lower trading frequencies, but it pours volatility into the short-term
environment, which support the argument of using different time horizons in volatility models. (Further reading: See "Rossi & Gallo (2006)" for intuition behind hidden markov models & latent partial volatility) 

The model is one of the commonly used in high frequency econometrics, and there exist tons of variations (SHAR, HAR-J, CHAR, just to name a few). They all have certain strengths, but given the simple regression framework, there are hardly any limits to modefications available. 

##### Neural Network:
I enjoy working with neural networks. They are easy to implements, and to understand mathematically. It is simply a weighted regression with backpropagation, caleld 'gradient descent', which optimizes for the best solution by minimizing the cost of the errors. Furthermore, we have an activation function which squeezes the data into more manageable thresholds than raw data. I will be using the simple sigmoid function as my activation function. However, ReLu would have been the prefered for this project.

Note that It is common for neural networks to show overfitting due to too many weights, on top of that, they also perform better when scaled. This makes it valuable to preprocess the data, which we can do by standardizing the mean and standard deviation into [0, 1]. This process ensures equal computations for all inputs in the regularization process.

### Data:
This project took a lot of computational power in the data manipulative steps. However, the models themselves can easily be implemented, as long the daily data is cleaned thoroughly.

I started out with downloading the tick-data (Trade&Quote) from the unversity database. This is raw trading data collected at the millisecond interval, and the order books of the same trades. (Note that such data can take weeks to download, depending on the speed of your internet connection. Matlab is often the prefered tool for this process). In high frequency environments, the quotes/orders are placed faster than the trades are executed, as a trade requires a match-up between a buyer and a seller. This relationship can create volatility spikes, which we must be taken into account, using the bivariate method; Basically, all prices that falls outside 1½ of the bid-ask spread are regarded as 'noise', and thereby omitted. 

##### Cleaning and formatting:
(This is all done in Matlab and I will therefore not post the code. It is however still downloadeable from the repository.)

My data specifically ranges from 30-09-2017 to 30-09-2019, and is cleaneded according to the standardized methodology for high frequency data as described in “Realized kernels in practice: Trades and quotes” by Barndorff-Nielsen, Hansen, Lunde & Shephard (2009):

1. Remove all orders that does not originate for neither the NYSE nor the NASDAQ
2. Variables with timestamp before 09:30 and after 15:30 is removed*. 
3. Create a filter to capture the placement of all (few) correlated trades, which can usually be removed manually.
4. Format the timestamp coordinates into a time variable and compute a bivariate analysis which removes any trades outside the bid-ask spread, where the spread is extended by 1.5 on either side (1.5 is rule of thumb).
5. The price variable is then formatted into 5-minute intervals, from which returns, realized variance and realized volatility can be computed.
6. With these variables; create means from lagged variables corresponding to 1 day, 5 days and 22 days. The specifics of these intervals and variables will be explained in a later section

*(Despite the NYSE and NASDAQ closing at 16:00, I have limited the data to 15:30 due to the ‘liquidity smile’ or ‘liquidity smirk’, which is defined by index-tracking investment vehicles that shift behavior to match their benchmark at the end of the day, creating an asymptotic spike in volatility truncated towards the end of the trading day (Bunda & Desquilbet, 2008).)

##### Assumptions:
Because we're working with time series data, we need to make sure it show signs of (weak) stationarity. Because this is a simple walkthrough, I will not be delving deep into the assumptions or derivations, but I'm happy to answer any questions regarding stationarity and autocovariance and similar.

The returns gets lagged according to Corsi (2009) in 1, 5 and 22 days respectively. And is then shown in a plot to determine whether the mean is ~0.
```
Data <- read_csv("C:/Users/PC/GitHub/High Frequency Econometrics/Data.csv") #Rvol = Realized volatility, Date = Timestamp
Data = Data %>% mutate(Date = as.Date(Data$Date), Rvol = as.numeric(Data$Rvol))

MyData = Data %>% mutate(Lag1 = (Rvol-Lag(Rvol, -1))/1,   #Lag 1 day (yesterday)
                         Lag5 = (Rvol-Lag(Rvol, -5))/5,   #Lag 5 days (A week of market days)
                         Lag22 = (Rvol-Lag(Rvol, -22))/22,#Lag 22 days (A month of market days)
                         Date = NULL)
LagData = na.exclude(MyData)
print(lapply(LagData, mean)) #Check for stationarity: Is approx. 0?
```
![HFE1](https://user-images.githubusercontent.com/69420936/92719313-40a3a600-f363-11ea-88d0-ea65bf462c64.jpeg)

### Estimation:
Now when have looked at the data, it's time for estimating the models. This is done by first splitting the data into test and training sets. I use 75% data in my training set and 25% in the test set. This sepration of data ensure we do not test on data we have already trained our model on, but instead test the models on entirely new data it hasn't seen before.
```
index <- sample(1:nrow(LagData),round(0.75*nrow(LagData)))
train <- LagData[index,]
test <- LagData[-index,]
```
We can now estimate the HAR model using the simple glm-function in R:
```
lm.fit <- glm(Rvol~ Lag1 + Lag5 + Lag22, data=train) #Kan vi ændre det til HAR?
summary(lm.fit)
pr.lm <- predict(lm.fit,test)
MSE.lm <- sum((pr.lm - test$Rvol)^2)/nrow(test)
```
Note that I have also included an MSE (mean squared error) estimation in the code. This will be the prefered performance measure for the simple models in the beginning of the estimation procedure. 

Now we do the same for the neural network. However, I also include a scaling function as stated in the 'Neural Network' model introduction above:
```
maxs <- apply(LagData, 2, max)
mins <- apply(LagData, 2, min)
scaled <- as.data.frame(scale(LagData, center = mins, scale = maxs - mins))
train_ <- scaled[index,]
test_ <- scaled[-index,]

# Setup the model
n <- names(train_)
f <- as.formula(paste("Rvol ~", paste(n[!n %in% "Rvol"], collapse = " + ")))
nn <- neuralnet(f,data=train_,hidden=c(4,2),linear.output=T)
plot(nn)

# Predict median value
pr.nn <- neuralnet::compute(nn,test_[,1:4])
pr.nn_ <- pr.nn$net.result*(max(LagData$Rvol)-min(LagData$Rvol))+min(LagData$Rvol)
test.r <- (test_$Rvol)*(max(LagData$Rvol)-min(LagData$Rvol))+min(LagData$Rvol)
MSE.nn <- sum((test.r - pr.nn_)^2)/nrow(test_)
```
We can now look at the MSE's to figure which simple model performed the best:
```
# Compare MSE's
print(paste(MSE.lm,MSE.nn))
```
![MSE scores](https://user-images.githubusercontent.com/69420936/92721467-6ed6b500-f366-11ea-8489-c29c4348c3e6.png)

We see how the neural network has a slightly smaller MSE than the HAR model. Hoever, solely basing the performance of one performance criteria and estimation is not thorough enough for us to conclude which model is better. Therefore we should first take a look a the data again, and see whether there is anything noticeable in the estimation:
![HFE2](https://user-images.githubusercontent.com/69420936/92722496-fcff6b00-f367-11ea-8a95-31752358ca3e.jpeg)

We can see that the HAR estimation has slightly more outliers in regards to the testing data. However, in order to make sure this is not a one-time occurance, I use 10-fold cross-validation, I will then draw inference on the range of MSE's this will provide me with.
```
# Cross-validation 
set.seed(500)
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
```
![HFE3](https://user-images.githubusercontent.com/69420936/92723119-e279c180-f368-11ea-81ce-7178f33d9f5b.jpeg)

From the boxplots above, it is evident that the neural network is doing very well compared to the HAR-model, despite the HAR model being designed for this environment. However, the HAR-model was also designed for forecasting, and I will therefore also test the forecasting properties of the two models:

### Forecasting:
Now when we have determined the model performance within sample. We want to estimate the forecasting properties of the two models. We plot below shows the cross-validated models forecasting a week of open market days, corresponding to 5 days in the data (h=5).
```
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
``` 
![HFE4](https://user-images.githubusercontent.com/69420936/92923232-67cba780-f437-11ea-83d6-a9e3f42a0a87.jpeg)

From the forecasts we can can measure the performance using RMSE instead of MSE, as well as AIC and BIC, sigma, MAE and ACF1. 
From these performance measures, we can see that the neural network is the better forecasting model. This is in line with the MSE visible from the boxplots, as well as the MSE from the simpel model. To conclude on the forecasting performance, inspired by Hillebrand and Medeiros (2009), I will use bagging as an ensemble method to optimize my forecast. My goal is to minimize the the errors of the forecast by combining 100 bootstrapped forecasts for each model:
```
windows()
par(mfrow=c(2, 1))

#Neural Network Bagging
y = as.numeric(pr.nn_)
pr.NNBag = baggedModel(y, bld.mbb.bootstrap(y, 100), fn=ets)
NNBag = forecast(pr.NNBag, h = 5)
plot(NNBag, type="l", col="blue", main="Forecast from Bagged Neural Network")
lines(fitted(NNBag))
#HAR Bagging
x = as.numeric(pr.lm_)
pr.HARBag = baggedModel(x, bld.mbb.bootstrap(x, 100), fn=ets)
HARBag = forecast(pr.HARBag, h = 5)
plot(HARBag, type="l", col="red", main="Forecast from Bagged HAR")
lines(fitted(HARBag))

accuracy(NNBag)
accuracy(HARBag)
```
![HFE5](https://user-images.githubusercontent.com/69420936/92930113-eb8a9180-f441-11ea-9e0f-fed40cdb2ddc.jpeg)

### Conclusion:

It is clear clear from the shaded blue area, that the error of the forecast has been reduced significantly. This is also apparent in the performance measures. 

I can thereby conclude that in the specified high frequency environment, using data two years worth of data from 20 stocks in the S&P500, scrutinized by the approach of Barndorff-Nielsen, Hansen, Lunde & Shephard (2009: The neural network is a better performing model in estimation and forecasting the future volatility, despite HAR being designed for that very purpose of forecasting integrated variance (See Corsi 2009).

### Addtional computations:
To draw further inspiration from Hillebrand and Medeiros (2009), I will also be using the bayesian ensemble method. 
```
######################
#Bayesian Ensemble
#####################
library(SuperLearner)
library(arm)
cv.modelNN <- CV.SuperLearner(y, test, V=5, SL.library=list("SL.bayesglm")) #Add any other model 
cv.modelHAR <- CV.SuperLearner(x, test, V=5, SL.library=list("SL.bayesglm")) #Add any other model
summary(cv.modelNN)
summary(cv.modelHAR)
plot(cv.modelHAR)
plot(cv.modelNN)
```
Bayesian ensemble can be executed in R either by programming the function from scratch, or by the use of the package "SuperLearner". To keep this walkthrough short and the code manageable, I will use the latter: Note that you need to use "St.bayesglm" as the SL.library'-parameter. This refer to the bayesglm-function which is a bayesian generalized linear model.

### Thoughts for further analysis:
Now when the better model in this setting has been established, it would be interesting to look at the performance of different HAR-types. It would also be interesting to see how other regression-based machine learning methods would perform in this setting (Lasso, Ridge).
It would also be of interest to see the performance if the realized volatility of each stock hadn't been scrutinized into one dimension, but instead made this analysis in a loop over the 20 stocks, and gathered the result in a table. - That would be a fun exercise for another repository.

### Sources:
###### Note that these sources where used in the paper I wrote, and not only for this simple walkthrough
- Andersen, G, T; et al. (2001a). The Distribution of Realized stock return volatility. Journal of Financial Econometrics. Volume 61 – pp. 43-76
- Andersen, G, T; et al. (2003). Modeling and Forecasting Realized Volatility. Journal of the Econometric Society. Volume 71, Issue 2 – pp. 579-625
- Andersen, T; Bollerslev, T. (1997). Intraday periodicity and volatility persistence in financial markets. Journal of Empirical Finance. Volume 4, Issue 2-3 – pp. 115-158.
- Barndorff-Nielsen, O, E; Hansen, P; Lunde, A; Shephard, N. (2009). Realized kernels in practice: Trades and quotes. Volume 12, Issue 3, - pp. 397-450.
- Barndorff-Nielsen, O, E; Shephard, N. (2002). Econometrics Analysis of Realized Volatility and Its use in Estimating Stochastic Volatility Models. Journal of Royal Statistical Society. Volume 65, Issue 2. – pp. 253-280.
- Corsi, F. (2009). A Simple Approximation Long-Memory Model of Realized Volatility. Journal of Financial Econometrics. Volume 7. Issue 2. – pp. 174-196
- Donaldson, R.G. and Kamstra, M. (1997) An Artificial Neural Network—GARCH Model for International Stock Return Volatility. Journal of Empirical Finance, 4, 17-46.
- Hillebrand, E; Medeiros, M, C. (2009). Benefits of Bagging for Forecast Models of Realized Volatility. Econometric Review, 29: 5, - pp. 571-593
- Bunda, I; Desquilbet, J, B. (2008) The Bank Liquidity Smile Across Exchange Rate Regimes. International Economic Journal. Volume 22, Issue 3. – pp. 361-386
- Hu, M, Y; Tsoukalas, C (1999) Combining conditional volatility forecasts using neural networks: An application to the EMS exchange rates. Journal of International Financial Markets Institution and Money. 9(4), pp. 407-422
- Hamid, S, A; Iqbal, Z. (2004). Using Neural Networks for forecasting Volatility of S&P 500 Index futures prices. Journal of Business Research. Volume. 57, Issue 10. – pp. 1116-1125.
- Kolmogorov, A. (1931) On Analytical Methods in the Theory of Probability. Mathematics and Its Applications (Soviet Series), Volume 26. – pp 62-108.
- Müller, U, A; et al. (1993). Volatilities of different time resolutions; Analyzing the dynamics of market components. Journal of Empirical Finance. Volume 4, Issue 2-3, - pp. 213-239
- Müller, U, A; Dacorogna, M; Nagler, R; et al. (1997). A geographical model for the daily and weekly seasonal volatility in the foreign exchange market. Journal of International Money and Finance. Volume 12, Issue 4. – pp. 413-438
- Lux, T; Marchesi, M. (1999). Scaling and critically in a stochastic multi-agent model of a financial market. Nature 397, - pp. 498-500
- Lux, T; Alferano, S. (2007), Empirical validation of stochastic models of interacting agtens. The European Physical Journal B; Condensed Matter and Complex Systems, Volume 55, Issue 2. – pp. 183-187.
- Lebaron, B. (2006). Agent-based Computational Finance. Handbook of Computational Economics, Volume – pp. 1187-1233
- Inoue, A; Kilian, L. (2007). In-Sample or Out-of-Sample Tests of Predictability: Which One Should We Use?. Econometric Review, Volume 23, Issue 4 – pp. 371-402
- Rapach, D, E.; Strauss, J, K. (2007). Forecasting Real Housing Price Growth in the Eighth District States. Federal Reserve Bank of St. Louis Regional Economic Development. Volume 3, Issue 2. – pp.33-42
- Rossi, A; Gallo, G. (2006). Volatility estimation via hidden Markov models. Journal of Empirical Finance. Volume 13, Issue 2. – pp. 203-230
- James, G; Witten, D; Hastie, T, J; Tibshirani, R. (2013) Introduction to Statistical Learning: With Applications in R. Boston, MA: Springer
- Hastie, T.; Tibshirani, R.; Friedman, J. (2009). The Elements of Statistical Learning. 2nd Edition. Boston, MA: Springer
- Øksendal, B. (2003). Stochastic Differential Equations: An Introduction with Applications. 6th Edition. Berlin, DE: Springer
