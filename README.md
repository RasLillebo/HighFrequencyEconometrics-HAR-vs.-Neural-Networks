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

I started out with downloading the tick-data (Trade&Quote) from the unversity database. This is raw trading data collected at the millisecond interval, and the order books of the same trades. (Note that such data can take weeks to download, depending on the speed of your internet connection. Matlab is often the prefered tool for this process). In high frequency environments, the quotes/orders are placed faster than the trades are executed, as a trade requires a match-up between a buyer and a seller. This relationship can create volatility spikes, which we must be taken into account, using the bivariate method; Basically, all prices that falls outside 1½ of the bid-ask spread are regarded as 'noise', and thereby omitted. 

##### Cleaning and formatting
My data specifically ranges from 30-09-2017 to 30-09-2019, and is cleaneded according to the standardized methodology for high frequency data as described in “Realized kernels in practice: Trades and quotes” by Barndorff-Nielsen, Hansen, Lunde & Shephard (2009):

1. Remove all orders that does not originate for neither the NYSE nor the NASDAQ
2. Variables with timestamp before 09:30 and after 15:30 is removed*. 
3. Create a filter to capture the placement of all (few) correlated trades, which can usually be removed manually.
4. Format the timestamp coordinates into a time variable and compute a bivariate analysis which removes any trades outside the bid-ask spread, where the spread is extended by 1.5 on either side (1.5 is rule of thumb).
5. The price variable is then formatted into 5-minute intervals, from which returns, realized variance and realized volatility can be computed.
6. With these variables; create means from lagged variables corresponding to 1 day, 5 days and 22 days. The specifics of these intervals and variables will be explained in a later section

*(Despite the NYSE and NASDAQ closing at 16:00, I have limited the data to 15:30 due to the ‘liquidity smile’ or ‘liquidity smirk’, which is defined by index-tracking investment vehicles that shift behavior to match their benchmark at the end of the day, creating an asymptotic spike in volatility truncated towards the end of the trading day (Bunda & Desquilbet, 2008).)


