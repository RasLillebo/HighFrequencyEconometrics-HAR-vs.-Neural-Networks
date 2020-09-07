# High Frequency Econometrics:
# HAR vs. Neural-Networks
Inspired by Hillebrand &amp; Medeiros (2012) and Corsi (2009), I put neural networks in a High frequency environment, and tested the performance of the two models (HAR &amp; Neural Networks). - The data used in this project is 2 years worth of intraday 5-minute realized volatility (See: Sheppard, Patton, Liu, 2012) from 20 Dow Jones stocks, that has been scrutinized using bivariate analysis and manipulation into a single dimension. 

#### Introduction to the models
##### HAR (Heterogenous Autoregressive model)
Developed by Corsi in 2009, this model is based on a simple regression framework. The independent variables is simply the daily volatility lagged 1, 5 and 22 days respectively. This is to simulate the volatility of yesterday, a week ago, and approximately one month ago (Only taking open market days into account). This type of model is also called a 'Long memory'-model, at it "remembers" what happened 22 market days ago.

The model is one of the commonly used in high frequency econometrics, and there exist tons of variations (SHAR, HAR-J, CHAR, just to name a few). They all have certain strengths, but given the simple regression framework, there are hardly any limits to modefications available. 

###### Neural Network
I enjoy working with neural networks. They are easy to implements, and to understand mathematically. It is simply a weighted regression with backpropagation, caleld 'gradient descent', which optimizes for the best solution by minimizing the cost of the errors. Furthermore, we have an activation function which squeezes the data into more manageable thresholds than raw data. I will be using the simple sigmoid function as my activation function. However, ReLu would have been the prefered for this project. (Work in progress)

#### Data
This project took a lot of computational power in the data manipulative steps. However, the models themselves can easily be implemented, as long the daily data is cleaned thoroughly.

I started out with downloading the tick-data (Trade&Quote) from the unversity database. This is raw trading data collected at the millisecond interval, and the order books of the same trades. (Note that such data can take weeks to download, depending on the speed of your internet connection. Matlab is often the prefered tool for this process). In high frequency environments, the quotes are executed faster than the trades, as a trade requires a match-up between a buyer and a seller. This relationship can create volatility spikes, which we must filter from out analysis, using the bipower-variation method; Basically, all prices that falls outside 2½ standard deviations of the mean are regarded as 'noise', and thereby omitted. 
