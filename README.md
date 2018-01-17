---
title: "Stock Price Model"
output:
  html_document: 
    self_contained: no
  pdf_document: default
  md_document:
    variant: markdown_github
---



## Goal
The model attempts to predict the stock price of thousands of companies at a given date in the future (prediction date) based on current (or past) financial information and ranks the companies according to their stock performance. The model uses information freely available on the web (stock prices, reported quaterly financial data, etc.). The model uses financial data prior to a given date (end of model date). The figure of merit used to predict the performance of each stock is given by the equation  *(stock price at prediction date - stock price by end of model date)/(stock price by end of model date)*. 

## Data
The model is built using free financial information available from [yahoo](https://finance.yahoo.com/) and [google](https://www.google.com/finance?ei=5xv9V_DjGMnKmAG_kJBg) finance websites. Financial information is downloaded in a local directory using functions written in R (https://github.com/Fernando-Montes/Finance) (the code is based on   <https://github.com/mkfs> but had to be modified since the yahoo website has recently been changed). 
Since the model requires historical financial information from a given starting date (currently two years prior to end of model date), not all companies found on the [yahoo](https://finance.yahoo.com/) and/or [google](https://www.google.com/finance?ei=5xv9V_DjGMnKmAG_kJBg) websites satisfy this requirement. The information required by the model includes stock daily price and quaterly financial data for each company. The model takes into account the type of industry (services, financial, technology, etc.) and sector (electronics, multimedia, telecom domestic, etc.) each company belongs to.  The industry and sector information is obtained from the yahoo website. The model uses comparisons against peers within a given industry and sector. Stock prices and quaterly data are obtained using the quantmod and PerformanceAnalytics R packages.

There are companies that have been rejected in the model due to peculiarities in their
stock price. An example is a company like *brgo* that have what it seems wrong information since the price is unrealistically high for a couple of days and suddenly decreases to normal values. Another example is *mspc* that has information that is different in the google and yahoo websites. There are also a few companies (~20) that have a price less than 1 cent during the two years prior to the end model date (*brgo* and *mspc* among them). Those companies were not taken into account when constructing the model. Currently, only companies that have a stock price greater than $5 and belong to the Nasdaq or NYSE stock exchanges are included in the model.  There are currently about 2800-3000 companies that have all the information required by the model. 

## Code

The financial information is saved locally since it is time consuming to access both the yahoo and google websites every time the model is run and because google asks for user input (captcha screen) while downloading the information. All the files are written in R.

#### Files to download data:
- **SymbolBySector.R**: Helper functions to classify all stocks based on sector and industry based on information from yahoo finance. It contains function *list.sectors.industries* that returns a data frame with these information. It also saves the data frame *listAll* in *SectorIndustryInfo.RData* that contains sector and industry numbers and names.
- **Download.R**: Main file to download and save information to be used by the model. It uses helper functions to create data frame (*stockInfo*) containining stock symbol, sector and industry numbers (in *StockInfo.RData*). It also downloads daily and quaterly financial data for all the companies listed in *stockInfo*.

#### Files to run the model:
- **StockModel.R**: Main file that prepares the model and runs it.
- **StockInfo.R**: Helper functions to be used by PrepareTable.R
- **PrepareTable.R**: Creates data frame *table.model* that contains information for each stock (i.e. current stock price, earnings in the last quarter, equity/debt, moving stock price averages, etc.). Some of these variables will be used in the model.
- **PrepareTableSector.R**: Adds peer-based-comparison variables to data frame *table.model* (i.e. enterprise value/earnings of the stock / average ratio of its peers).
- **StockInfoHistorical.R**: Adds historical quaterly comparison variables to data frame *table.model* (i.e. enterprise value/earnings of the stock / ratio from same quarter the previous year).
- **PrepareStockModel.R**: Function to select which ML method and which variables will be used by the model. 

## Model

The model was constructed using the following variables (keep in mind the model is not final and I update it about every 6 months or so). Reference to the stock price in the following variables correspond to the stock price at the time the model is constructed (end of model date). Variables that use financial data such as total assets, enterprise value, book value, etc. are from the most recent quarter prior to end of model date. 

Variable                    |Meaning
----------------------------|-------------------------------------------------------------------------------------------------------------
Ev.earning                  |Enterprise value / earnings 
Ev.ebitda                   |Enterprise value / EBITDA (earnings before interests, taxes, depreciation, amortization and unusual expenses) 
Ev.book                     |Enterprise value / book value
Ev.revenue                  |Enterprise value / revenue
Ev.cash                     |Enterprise value / cash
Price.equity.debt           |Stock price /(Total equity/ Total debt)

Variables that use comparisons with their peers:

Variable                    |Meaning
----------------------------|-------------------------------------------------------------------------------------------------------------
Ev.earning.peers            |Enterprise value / earnings divided by the average of the same ratio obtained from companies within the same sector-industry
Ev.ebitda.peers             |Enterprise value / EBITDA divided by the average of the same ratio obtained from companies within the same sector-industry
Ev.book.peers               |Enterprise value / book value divided by the average of the same ratio obtained from companies within the same sector-industry
Ev.revenue.peers            |Enterprise value / revenue divided by the average of the same ratio obtained from companies within the same sector-industry
Ev.cash.peers               |Enterprise value / cash divided by the average of the same ratio obtained from companies within the same sector-industry
Price.equity.debt.peers     |Stock price /(Total equity/ Total debt) divided by the average of the same ratio obtained from companies within the same sector-industry
Price.sma.200.peers         |Stock price / Simple moving 200-day-average of the stock price divided by the average of the other companies within the same sector-industry
Price.sma.50.peers          |Stock price / Simple moving 50-day-average of the stock price divided by the average of the other companies within the same sector-industry

Variables that use historical information:

Variable                          |Meaning
----------------------------------|--------------------------------------------------------------------------------------------------------
Price.Model.end.low.ratio   |Stock price / lowest stock price during the last 2 years
Price.Model.end.high.ratio  |Stock price / highest stock price during the last 2 years
predicted.hw.win.loss       |Predicted future performance using a Holt-Winters model of the stock price
predicted.hwLB.win.loss     |Predicted future lower bound performance with 90% confidence using a Holt-Winters model of the stock price
predicted.arima.win.loss    |Predicted future performance using ARIMA forecast
Price.sma.200               |Stock price / Simple moving 200-day-average of the stock price
Price.sma.50                |Stock price / Simple moving 50-day-average of the stock price
rsi.10                      |Relative Strength Index RSI over 10 days: it expresses the fraction of gains and losses over the past lookback periods, 100 - (100/(1 + RS)), where RS is the average gain over the average loss over the lookback window decided.
rsi.50                      |Relative Strength Index RSI over 50 days
dvo                         |Value representing the percentage rank of the stock price between the lowest and highest stock price during the last 2 years
earning.histo               |Enterprise value / earnings divided by the same ratio the same quarter the previous year
ebitda.histo                |Enterprise value / EBITDA divided by the same ratio the same quarter the previous year
book.histo                  |Enterprise value / book value divided by the same ratio the same quarter the previous year
revenue.histo               |Enterprise value / revenue divided by the same ratio the same quarter the previous year
cash.histo                  |Enterprise value / cash divided by the same ratio the same quarter the previous year
equity.debt.histo           |Stock price /(Total equity/ Total debt) divided by the same ratio the same quarter the previous year

A variable specifying the sector the stock belong to was removed from the model since that variable ended up being one of the most important variables while training the model. Unfortunately since it is likely that the same performance will not be repeated in the future, it is not very helpful in predicting the future (as verified while checking the model performance). Other variables included in earlier iterations of the model were specific stock price categories and/or assets but are currently removed since the same information is already included in the current variables. 

The model uses a random forest, generalized linear model and/or a boosted regression methods. The implementation is done using the caret R package ($ranger$, $glmnet$, $gbm$, methods respectively). Some hyper-parameter optimization has been done but further optimization and method exploration is one of the main areas where the model could still be improved.

## Comments on results

#### Importance of sector and industry information:

In an earlier iteration of the model, no peer comparison variables were used but instead a variable specifying the sector-industry of each company was used. Not all historical variables were used. The time horizon used in the following was 15 months in the future (from the data financial information is last available). The model was prepared with data from 2013/06/03 to 2015/06/30 for a prediction at 2016/09/30. The most important variables using the $gbm$ method were:


<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Wed Jan 17 08:36:20 2018 -->


<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID57952c4932c1 () {
var data = new google.visualization.DataTable();
var datajson =
[
 [
"SectorIndustry.Num134",
29.76021963
],
[
"Price.Model.end.high.ratio",
23.80213048
],
[
"Ev.revenue",
11.17564829
],
[
"predicted.win.loss",
8.484423223
],
[
"Price.Model.end",
5.514723066
],
[
"Ev.cash",
5.455602343
],
[
"Assets",
4.456982792
],
[
"SectorIndustry.Num133",
3.956282445
],
[
"Ev.book",
2.382580942
],
[
"Ev.earning",
1.931493247
],
[
"predictedLB.win.loss",
1.087784194
],
[
"Ev.ebitda",
1.020041704
],
[
"Price.equity.debt",
0.972087644
] 
];
data.addColumn('string','var');
data.addColumn('number','rel.inf');
data.addRows(datajson);
return(data);
}
 
// jsDrawChart
function drawChartTableID57952c4932c1() {
var data = gvisDataTableID57952c4932c1();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID57952c4932c1')
    );
    chart.draw(data,options);
    

}
  
 
// jsDisplayChart
(function() {
var pkgs = window.__gvisPackages = window.__gvisPackages || [];
var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
var chartid = "table";
  
// Manually see if chartid is in pkgs (not all browsers support Array.indexOf)
var i, newPackage = true;
for (i = 0; newPackage && i < pkgs.length; i++) {
if (pkgs[i] === chartid)
newPackage = false;
}
if (newPackage)
  pkgs.push(chartid);
  
// Add the drawChart function to the global list of callbacks
callbacks.push(drawChartTableID57952c4932c1);
})();
function displayChartTableID57952c4932c1() {
  var pkgs = window.__gvisPackages = window.__gvisPackages || [];
  var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
  window.clearTimeout(window.__gvisLoad);
  // The timeout is set to 100 because otherwise the container div we are
  // targeting might not be part of the document yet
  window.__gvisLoad = setTimeout(function() {
  var pkgCount = pkgs.length;
  google.load("visualization", "1", { packages:pkgs, callback: function() {
  if (pkgCount != pkgs.length) {
  // Race condition where another setTimeout call snuck in after us; if
  // that call added a package, we must not shift its callback
  return;
}
while (callbacks.length > 0)
callbacks.shift()();
} });
}, 100);
}
 
// jsFooter
</script>
 
<!-- jsChart -->  
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID57952c4932c1"></script>
 
<!-- divChart -->
  
<div id="TableID57952c4932c1" 
  style="width: 500; height: automatic;">
</div>

All other variables are not relevant (rel.inf = 0). A variable specifying if __SectorIndustry.Num__ were 134 and 133 (Gold and Industrial Metals & Minerals, respectively) was the most important. The prediction performance compared to the actual performance in the train data looks reasonable. Not only for the highest performers but also for the laggarts. The same comparison in the validation data also seems decent,

![](Figures/GBM.png)

but there is a problem. These are the best 10 results in the validation data:

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Wed Jan 17 08:36:20 2018 -->


<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID5795193241e () {
var data = new google.visualization.DataTable();
var datajson =
[
 [
"goro",
5.25,
2.149824,
7.839369,
2.149824,
"2",
112.75,
107.4912,
99.55338831,
1.231262836,
5.005477624,
5.541268521,
0.0361334055,
4.609798172,
-19.11833416,
"134",
1,
0.2742343166,
144.2060373,
114.4267704,
-989.2976428,
91.92387046
],
[
"ora.to",
0.17,
0.08,
0.19,
0.08,
"1",
166.17,
-8,
-10.10725664,
0.3623477157,
0.5913124515,
4.954967462,
0.02791878173,
-0.007876290735,
-273.5865487,
"134",
1,
0.4210526316,
112.5,
-109.8453634,
-342083.1858,
84.91237586
],
[
"mmy.v",
0.11,
0.09,
0.34,
0.09,
"1",
262.51,
9,
9.598618421,
0.1210127317,
2.813866924,
0.9858040541,
0.0001455646332,
0.1141094967,
-244.9169167,
"134",
1,
0.2647058824,
22.22222222,
26.78832968,
-272229.9075,
80.03390172
],
[
"ngd.to",
5.14,
2.89,
7.46,
2.89,
"2",
3910.5,
-41.28571429,
18.52985013,
0.651004469,
4.370974747,
4.50205049,
1.124414602,
3.251208366,
-46.22327196,
"134",
1,
0.3873994638,
77.85467128,
12.49855937,
-1699.421175,
79.87213718
],
[
"ric",
8.43,
1,
3.52,
2.63,
"2",
191.95,
52.6,
41.58553134,
0.9988147906,
3.763721332,
1.958410112,
0.149572644,
2.4100212,
-17.96087945,
"134",
2.63,
0.7471590909,
220.5323194,
-8.364212935,
-782.9231729,
79.64038075
],
[
"grc.v",
0.21,
0.345953,
0.775248,
0.738471,
"1",
60.23,
73.8471,
111.9294814,
1.65915993,
41.57380738,
3.569880418,
0.2601910365,
0.5584040767,
-63.38087795,
"134",
2.134599209,
0.9525609869,
-71.56286435,
-24.38375011,
-8682.717256,
77.17805313
],
[
"cg.to",
6.42,
2.96488,
7.472937,
6.363673,
"2",
1692.09,
70.70747778,
68.67367008,
1.039554469,
10.25776387,
2.563349252,
0.3339934035,
7.390097596,
-103.8438199,
"134",
2.146350948,
0.8515625115,
0.8851334756,
16.12943651,
-1731.82206,
76.81539776
],
[
"dmm.to",
0.24,
0.52,
1.74,
0.52,
"1",
70.83,
-5.777777778,
-5.887786667,
0.4056439464,
4.961617978,
12.61668571,
0.06066507441,
0.3130269683,
-41.1954322,
"134",
1,
0.2988505747,
-53.84615385,
-39.80250609,
-8022.198499,
75.14076625
],
[
"aem",
44.950001,
21.859224,
37.621254,
21.859224,
"3",
6749.81,
437.18448,
26.52265547,
1.140473484,
9.300165425,
22.58776072,
6.366745905,
25.58341483,
-706.1877991,
"134",
1,
0.5810339017,
105.6340198,
17.03715936,
-3330.616965,
74.99989019
],
[
"nem",
33.970001,
17.081755,
30.734064,
17.081755,
"3",
25961,
94.89863889,
16.89178034,
0.8018013027,
4.736426878,
2.704909453,
9.673750525,
23.7548679,
-252.1979375,
"134",
1,
0.5557922636,
98.86715973,
39.06573356,
-1576.417017,
74.99989019
] 
];
data.addColumn('string','Stock.SYM');
data.addColumn('number','Price.Current');
data.addColumn('number','Price.Min');
data.addColumn('number','Price.Max');
data.addColumn('number','Price.Model.end');
data.addColumn('string','Price.Category');
data.addColumn('number','Assets');
data.addColumn('number','Ev.earning');
data.addColumn('number','Ev.ebitda');
data.addColumn('number','Ev.book');
data.addColumn('number','Ev.revenue');
data.addColumn('number','Ev.cash');
data.addColumn('number','Price.equity.debt');
data.addColumn('number','Price.Prediction');
data.addColumn('number','Price.Prediction.LB');
data.addColumn('string','SectorIndustry.Num');
data.addColumn('number','Price.Model.end.low.ratio');
data.addColumn('number','Price.Model.end.high.ratio');
data.addColumn('number','actual.win.loss');
data.addColumn('number','predicted.win.loss');
data.addColumn('number','predictedLB.win.loss');
data.addColumn('number','model_pred');
data.addRows(datajson);
return(data);
}
 
// jsDrawChart
function drawChartTableID5795193241e() {
var data = gvisDataTableID5795193241e();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID5795193241e')
    );
    chart.draw(data,options);
    

}
  
 
// jsDisplayChart
(function() {
var pkgs = window.__gvisPackages = window.__gvisPackages || [];
var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
var chartid = "table";
  
// Manually see if chartid is in pkgs (not all browsers support Array.indexOf)
var i, newPackage = true;
for (i = 0; newPackage && i < pkgs.length; i++) {
if (pkgs[i] === chartid)
newPackage = false;
}
if (newPackage)
  pkgs.push(chartid);
  
// Add the drawChart function to the global list of callbacks
callbacks.push(drawChartTableID5795193241e);
})();
function displayChartTableID5795193241e() {
  var pkgs = window.__gvisPackages = window.__gvisPackages || [];
  var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
  window.clearTimeout(window.__gvisLoad);
  // The timeout is set to 100 because otherwise the container div we are
  // targeting might not be part of the document yet
  window.__gvisLoad = setTimeout(function() {
  var pkgCount = pkgs.length;
  google.load("visualization", "1", { packages:pkgs, callback: function() {
  if (pkgCount != pkgs.length) {
  // Race condition where another setTimeout call snuck in after us; if
  // that call added a package, we must not shift its callback
  return;
}
while (callbacks.length > 0)
callbacks.shift()();
} });
}, 100);
}
 
// jsFooter
</script>
 
<!-- jsChart -->  
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID5795193241e"></script>
 
<!-- divChart -->
  
<div id="TableID5795193241e" 
  style="width: 500; height: automatic;">
</div>

All of the top results were from __SectorIndustry.Num__ 134 (Gold).  If industries 134 and 133 are removed from the final results (but still keeping them in the model), the model results are much worse and there does not seem to be a correlation between prediction and actual performance in the validation data:

![](Figures/GBM_no134-133.png)

In order to reduce the influence of the variable specifying the sector and industry of the company (it is likely that that performance will not be repeated in the future), the variables specifying the valuations of a given stock compared to other companies with the same sector-industry-number (peer-comparison variables) were added.

The variables importance in the $gbm$ model are in the following table:

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Wed Jan 17 08:36:20 2018 -->


<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID579544a06302 () {
var data = new google.visualization.DataTable();
var datajson =
[
 [
"Price.Model.end.high.ratio",
21.3518907
],
[
"predicted.win.loss",
13.17831143
],
[
"Price.Model.end",
12.58687093
],
[
"Ev.revenue",
7.634509135
],
[
"Ev.cash.peers",
5.444282989
],
[
"Ev.ebitda",
5.278781082
],
[
"Ev.book.peers",
5.256853741
],
[
"Ev.book",
4.869078573
],
[
"Price.equity.debt",
4.532309664
],
[
"Price.Model.end.low.ratio",
3.964346969
],
[
"Assets",
3.397256038
],
[
"Ev.revenue.peers",
2.954587674
],
[
"Price.equity.debt.peers",
2.366455656
] 
];
data.addColumn('string','var');
data.addColumn('number','rel.inf');
data.addRows(datajson);
return(data);
}
 
// jsDrawChart
function drawChartTableID579544a06302() {
var data = gvisDataTableID579544a06302();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID579544a06302')
    );
    chart.draw(data,options);
    

}
  
 
// jsDisplayChart
(function() {
var pkgs = window.__gvisPackages = window.__gvisPackages || [];
var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
var chartid = "table";
  
// Manually see if chartid is in pkgs (not all browsers support Array.indexOf)
var i, newPackage = true;
for (i = 0; newPackage && i < pkgs.length; i++) {
if (pkgs[i] === chartid)
newPackage = false;
}
if (newPackage)
  pkgs.push(chartid);
  
// Add the drawChart function to the global list of callbacks
callbacks.push(drawChartTableID579544a06302);
})();
function displayChartTableID579544a06302() {
  var pkgs = window.__gvisPackages = window.__gvisPackages || [];
  var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
  window.clearTimeout(window.__gvisLoad);
  // The timeout is set to 100 because otherwise the container div we are
  // targeting might not be part of the document yet
  window.__gvisLoad = setTimeout(function() {
  var pkgCount = pkgs.length;
  google.load("visualization", "1", { packages:pkgs, callback: function() {
  if (pkgCount != pkgs.length) {
  // Race condition where another setTimeout call snuck in after us; if
  // that call added a package, we must not shift its callback
  return;
}
while (callbacks.length > 0)
callbacks.shift()();
} });
}, 100);
}
 
// jsFooter
</script>
 
<!-- jsChart -->  
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID579544a06302"></script>
 
<!-- divChart -->
  
<div id="TableID579544a06302" 
  style="width: 500; height: automatic;">
</div>

Calculating the RMSE directly in the train and validation data sets result in 56.1 and 59.4 respectively. 

![](Figures/GBM_model2.png)

The random forest model $ranger$ results in 26.9 (the model still needs to be improved as it is severly overfitting) and 57.6 for the RMSE in train and validation data respectively:

![](Figures/ranger_model2.png)

The linear regression model $glmnet$ performs badly and results in an RMSE in the validation data larger than a 100.

#### Variables containing historical information:

Adding variables containing historical information does not result in a large improvement in any of the models. Moreover, the calculated RMEs are highly variable depending on the splitting between training and testing data indicating there is over-fitting. The relative importance of the variables for the $ranger$ method is shown in this Figure:

![](Figures/ranger3_varImp.png)     

The train data is over-fitted with the $ranger$ method but the validation data modeling is not worse than using the $gbm$ (or any other method) method. 

#### Time horizon:

Using a shorter time horizon of 3 months instead of the 15 months used in the previous sections, results in much improved predictions for the model. The RMSE of both the training and validation data get better (in the 20-30 range) for all methods. For the $gbm$ method, this is what the predictions look like:

![](Figures/GBM_timeHorizon3.png)

The relative importance of the different variables also change. Variables containing Enterprise Value become more relevant. Peer comparison variables does not seem to matter much compared to valuation and historical variables.

![](Figures/ranger4_varImp.png) 

#### Variables containing quaterly information (assets, equity, etc.):

If all the variables containing quaterly data information (earnings, revenue, book value, etc.) are eliminated, the results do not change much.

![](Figures/ranger_gbm_timeHorizon3_redVar.png)

For the $gbm$ method, this is what the predictions look like:

![](Figures/GBM_timeHorizon3_redVar.png)

#### Robustness of the results using different ML methods:

In the following valuation, peer-comparison and historical variables are included except quaterly valuation variables or the same quarter previous year historical variables. 

This is how the ranking of predictions compare between $gbm$ and $ranger$ methods:

![](Figures/ranger_gbm_robust_3.png)

Notice how there are some companies that have a high rank in one of the methods but not in both. There are also some companies highly ranked in both methods. The colors indicate the ranking based on the ranking of actual performances. Notice that there are more high ranking (high gains) companies in the top right corner than in the bottom left corner. However, the correlation between model ranking and actual win/loss ranking is not great (rank2 refers to the ranking obtained using the $gbm$ method): 

![](Figures/ranger_actual_robust_3.png)

The last figure should show a linear correlation if the model were perfect. As it, there is still a lot of room for improvement. 

The correlation between results using $glmnet$ and $ranger$ is not as clean as in the previous figures. Companies with high rankings in both methods also seem to have good rankings in the actual win/loss ranking.

![](Figures/ranger_glmnet_robust_3.png)

As expected, the previous results are robust when using different train data sets.

The following companies are obtained when requiring a rank above 90% for all methods ($ranger$, $gbm$ and $glmnet$) using data from 2013/06/03 to 2015/06/30 (end of model date) for a 2015/09/30 stock price prediction: 


<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Wed Jan 17 08:36:20 2018 -->


<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID579528c208ed () {
var data = new google.visualization.DataTable();
var datajson =
[
 [
"msex",
92.27941176,
87.00980392,
91.42156863,
88.1127451,
6.580328492
],
[
"it",
92.89215686,
91.66666667,
91.78921569,
76.10294118,
-2.156678738
] 
];
data.addColumn('string','Stock.SYM');
data.addColumn('number','rank_ranger');
data.addColumn('number','rank_gbm');
data.addColumn('number','rank_glmnet');
data.addColumn('number','rank_actual');
data.addColumn('number','actual.win.loss');
data.addRows(datajson);
return(data);
}
 
// jsDrawChart
function drawChartTableID579528c208ed() {
var data = gvisDataTableID579528c208ed();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID579528c208ed')
    );
    chart.draw(data,options);
    

}
  
 
// jsDisplayChart
(function() {
var pkgs = window.__gvisPackages = window.__gvisPackages || [];
var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
var chartid = "table";
  
// Manually see if chartid is in pkgs (not all browsers support Array.indexOf)
var i, newPackage = true;
for (i = 0; newPackage && i < pkgs.length; i++) {
if (pkgs[i] === chartid)
newPackage = false;
}
if (newPackage)
  pkgs.push(chartid);
  
// Add the drawChart function to the global list of callbacks
callbacks.push(drawChartTableID579528c208ed);
})();
function displayChartTableID579528c208ed() {
  var pkgs = window.__gvisPackages = window.__gvisPackages || [];
  var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
  window.clearTimeout(window.__gvisLoad);
  // The timeout is set to 100 because otherwise the container div we are
  // targeting might not be part of the document yet
  window.__gvisLoad = setTimeout(function() {
  var pkgCount = pkgs.length;
  google.load("visualization", "1", { packages:pkgs, callback: function() {
  if (pkgCount != pkgs.length) {
  // Race condition where another setTimeout call snuck in after us; if
  // that call added a package, we must not shift its callback
  return;
}
while (callbacks.length > 0)
callbacks.shift()();
} });
}, 100);
}
 
// jsFooter
</script>
 
<!-- jsChart -->  
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID579528c208ed"></script>
 
<!-- divChart -->
  
<div id="TableID579528c208ed" 
  style="width: 500; height: automatic;">
</div>

Using the trained $ranger$ and $gbm$ methods for data from 2013/09/03 to 2015/09/30 for a 2015/12/31 prediction results in a RMS of 34 for both methods. Method $glmnet$ has an outlier that makes the RMS blow up. These are the companies with the highest actual ranking and their method rankings:


<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Wed Jan 17 08:36:20 2018 -->


<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID57954aafd009 () {
var data = new google.visualization.DataTable();
var datajson =
[
 [
"pli.to",
38.03907114,
35.16402506,
39.7714707,
99.66826391,
128.5714286
],
[
"lm.v",
46.81164762,
48.72834501,
87.91006266,
99.70512348,
144.7368421
],
[
"adat",
41.39329156,
36.56468854,
8.551419093,
99.74198304,
144.8275994
],
[
"zyxi",
51.71396978,
68.74308883,
39.69775157,
99.77884261,
150
],
[
"cylu",
98.08330262,
68.00589753,
0.8846295614,
99.81570217,
200
],
[
"erii",
9.62034648,
12.45853299,
15.11242167,
99.85256174,
230.3738318
],
[
"lei",
27.5340951,
15.66531515,
1.990416513,
99.8894213,
239.5348837
],
[
"pacb",
15.22300037,
22.85293034,
27.4235164,
99.92628087,
258.7431694
],
[
"linc",
77.51566532,
29.67194987,
3.28050129,
99.96314043,
290.1960784
],
[
"dpdm",
25.69111684,
23.99557685,
12.08993734,
100,
566.6666667
] 
];
data.addColumn('string','Stock.SYM');
data.addColumn('number','rank_ranger');
data.addColumn('number','rank_gbm');
data.addColumn('number','rank_glmnet');
data.addColumn('number','rank_actual');
data.addColumn('number','actual.win.loss');
data.addRows(datajson);
return(data);
}
 
// jsDrawChart
function drawChartTableID57954aafd009() {
var data = gvisDataTableID57954aafd009();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID57954aafd009')
    );
    chart.draw(data,options);
    

}
  
 
// jsDisplayChart
(function() {
var pkgs = window.__gvisPackages = window.__gvisPackages || [];
var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
var chartid = "table";
  
// Manually see if chartid is in pkgs (not all browsers support Array.indexOf)
var i, newPackage = true;
for (i = 0; newPackage && i < pkgs.length; i++) {
if (pkgs[i] === chartid)
newPackage = false;
}
if (newPackage)
  pkgs.push(chartid);
  
// Add the drawChart function to the global list of callbacks
callbacks.push(drawChartTableID57954aafd009);
})();
function displayChartTableID57954aafd009() {
  var pkgs = window.__gvisPackages = window.__gvisPackages || [];
  var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
  window.clearTimeout(window.__gvisLoad);
  // The timeout is set to 100 because otherwise the container div we are
  // targeting might not be part of the document yet
  window.__gvisLoad = setTimeout(function() {
  var pkgCount = pkgs.length;
  google.load("visualization", "1", { packages:pkgs, callback: function() {
  if (pkgCount != pkgs.length) {
  // Race condition where another setTimeout call snuck in after us; if
  // that call added a package, we must not shift its callback
  return;
}
while (callbacks.length > 0)
callbacks.shift()();
} });
}, 100);
}
 
// jsFooter
</script>
 
<!-- jsChart -->  
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID57954aafd009"></script>
 
<!-- divChart -->
  
<div id="TableID57954aafd009" 
  style="width: 500; height: automatic;">
</div>

None of the methods is particularly good. It seems that the assumption that a model created and optimized at an earlier time (3 months in this case) is not completely valid or useful by the time it has to be used. 
Requiring an average rank between the different methods ($ranger$, $gbm$ and $glmnet$) above 95.5%, results in the following companies:


<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Wed Jan 17 08:36:20 2018 -->


<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID57953dab6bde () {
var data = new google.visualization.DataTable();
var datajson =
[
 [
"vnr.to",
96.01916697,
93.58643568,
97.89900479,
71.32325839,
9.811697384
],
[
"nen",
96.24032436,
98.5256174,
91.92775525,
65.75746406,
7.257599249
],
[
"t.to",
96.35090306,
96.79321784,
94.47106524,
29.56137118,
-8.020416479
],
[
"ecl",
97.41983045,
98.4150387,
90.85882787,
59.6019167,
4.562771654
],
[
"chd",
98.48875783,
98.37817914,
92.77552525,
50.60818282,
1.577989645
],
[
"ari",
99.41024696,
96.05602654,
92.81238481,
77.36822705,
12.5731695
] 
];
data.addColumn('string','Stock.SYM');
data.addColumn('number','rank_ranger');
data.addColumn('number','rank_gbm');
data.addColumn('number','rank_glmnet');
data.addColumn('number','rank_actual');
data.addColumn('number','actual.win.loss');
data.addRows(datajson);
return(data);
}
 
// jsDrawChart
function drawChartTableID57953dab6bde() {
var data = gvisDataTableID57953dab6bde();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID57953dab6bde')
    );
    chart.draw(data,options);
    

}
  
 
// jsDisplayChart
(function() {
var pkgs = window.__gvisPackages = window.__gvisPackages || [];
var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
var chartid = "table";
  
// Manually see if chartid is in pkgs (not all browsers support Array.indexOf)
var i, newPackage = true;
for (i = 0; newPackage && i < pkgs.length; i++) {
if (pkgs[i] === chartid)
newPackage = false;
}
if (newPackage)
  pkgs.push(chartid);
  
// Add the drawChart function to the global list of callbacks
callbacks.push(drawChartTableID57953dab6bde);
})();
function displayChartTableID57953dab6bde() {
  var pkgs = window.__gvisPackages = window.__gvisPackages || [];
  var callbacks = window.__gvisCallbacks = window.__gvisCallbacks || [];
  window.clearTimeout(window.__gvisLoad);
  // The timeout is set to 100 because otherwise the container div we are
  // targeting might not be part of the document yet
  window.__gvisLoad = setTimeout(function() {
  var pkgCount = pkgs.length;
  google.load("visualization", "1", { packages:pkgs, callback: function() {
  if (pkgCount != pkgs.length) {
  // Race condition where another setTimeout call snuck in after us; if
  // that call added a package, we must not shift its callback
  return;
}
while (callbacks.length > 0)
callbacks.shift()();
} });
}, 100);
}
 
// jsFooter
</script>
 
<!-- jsChart -->  
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID57953dab6bde"></script>
 
<!-- divChart -->
  
<div id="TableID57953dab6bde" 
  style="width: 500; height: automatic;">
</div>

which have an average actual win loss performance percentage of 4.6%. The average performance percentage of all the companies considered during the same time period is 0.7%. 

Adding quarterly variables (but not same quarter previous year) results in an even better model performance since the average performance percentage increases to 7.5% for the best companies in all models (compared to 0.7% for all companies).

Changing the construction of the model from 2014/03/03 to 2016/03/31 and applying it to 2016/06/30, obtains an average performance percentage of 22.4% for companies with a predicted average ranking of 97%, compared to 5.4% for the average for all companies. However, when using the same model for data from 2014/06/03 to 2016/06/30 for a prediction by 2016/09/30 obtains an average actual win loss percentage of -3.4% for companies with a predicted average ranking of 99%, compared to 8.7% for the average for all companies. 

## Conclusion
This is a still a work in progress. Several improvements still need to be done before I can really trust the model:

- Test the effect of historical variables that use historial quaterly information for different time frames.  
- Improve hyper-parameter selection in current models.
- Extend to other models and methodologies.
- Add a google trend variables (stock and sector).

