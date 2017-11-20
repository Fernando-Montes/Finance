Goal
====

The goal is to predict the performance of a given stock from financial information available in the past. The model attempts to predict the performance using a fixed time horizon. The figure of merit used to predict the performance is *actual.win.loss = (stock price at prediction date - stock price by end of model date)/(stock price by end of model date)*.

Data
====

The model is built using with financial information available on the web. The final date used in the model is referred to as end.model.date (it corresponds to stock price by end of model date). It uses 2 years of historical stock price to construct the model. The price at end.model.date divided by the lowest and highest stock prices during those two years are variables of the model. Information is downloaded from [yahoo](https://finance.yahoo.com/) and [google](https://www.google.com/finance?ei=5xv9V_DjGMnKmAG_kJBg) finance. It uses packages quantmod and PerformanceAnalytics.

    # Obtaining historical stock price data
        SYMB_prices <- get.hist.quote(instrument=stock, quote="AdjClose",provider="yahoo", compression="m", retclass="zoo", quiet=TRUE)

    # Obtaining stock financial info
        FinStock <- getFinancials(stock, auto.assign = FALSE)

Almost all stocks available in yahoo finance are used in the model preparation and prediction. Downloading of available information is is based on <https://github.com/mkfs> and from functions written by [me](https://github.com/Fernando-Montes/Finance).

There are about 2750 companies that have all the information required in the model.

Companies like *brgo* have what it seems wrong information since the price is unrealistically high for a couple of days and suddenly decreases to normal values. Another example is *mspc* that has information that is different from what the yahoo website has. It there something wrong with some of these ultra cheap stocks? There are 18 companies that have a price less than 1 cent during the two years prior to the end model date (*brgo* and *mspc* among them). Those companies were not taken into account when constructing the model. **Update August 2017:** Only companies that have a stock price greater than $5 and belong to the Nasdaq or NYSE stock exchanges are included.

Code
====

The financial information is saved locally since it is time consuming to access websites every time the model is run, and because google asks for user input (captcha screen) if running the script. The main file is StockModel.R. The file names describes what each file does.

![](ReadMeStockModel_files/figure-markdown_github/unnamed-chunk-1-1.png)

Model and Results
=================

Attempts 1-10:
--------------

The model was constructed using the following variables:

<table>
<colgroup>
<col width="20%" />
<col width="79%" />
</colgroup>
<thead>
<tr class="header">
<th>Variable</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>Price.Model.end.low.ratio</td>
<td>Stock price / lowest stock price during the last 2 years</td>
</tr>
<tr class="even">
<td>Price.Model.end.high.ratio</td>
<td>Stock price / highest stock price during the last 2 years</td>
</tr>
<tr class="odd">
<td>Price.Model.end</td>
<td>Stock price</td>
</tr>
<tr class="even">
<td>Assets</td>
<td>Total assets</td>
</tr>
<tr class="odd">
<td>Ev.earning</td>
<td>Enterprise value / earnings</td>
</tr>
<tr class="even">
<td>Ev.ebitda</td>
<td>Enterprise value / EBITDA (earnings before interests, taxes, depreciation, amortization and unusual expenses)</td>
</tr>
<tr class="odd">
<td>Ev.book</td>
<td>Enterprise value / book value</td>
</tr>
<tr class="even">
<td>Ev.revenue</td>
<td>Enterprise value / revenue</td>
</tr>
<tr class="odd">
<td>Ev.cash</td>
<td>Enterprise value / cash</td>
</tr>
<tr class="even">
<td>Price.equity.debt</td>
<td>Stock price /(Total equity/ Total debt)</td>
</tr>
<tr class="odd">
<td>predicted.win.loss</td>
<td>Predicted performance using a Holt-Winters model of the stock price</td>
</tr>
<tr class="even">
<td>predictedLB.win.loss</td>
<td>Predicted lower bound performance using a Holt-Winters model of the stock price</td>
</tr>
<tr class="odd">
<td>SectorIndustry.Num</td>
<td>Sector-industry number the stock belongs to</td>
</tr>
</tbody>
</table>

The actual model construction[1]:

       my_model <- train(
        actual.win.loss ~ Price.Model.end.low.ratio + Price.Model.end.high.ratio + Price.Model.end + Assets +
          Ev.earning + Ev.ebitda + Ev.book + Ev.revenue + Ev.cash + Price.equity.debt +
          predicted.win.loss + predictedLB.win.loss + SectorIndustry.Num, 
        method ="gbm", data = my_train, train.fraction = 0.5, tuneLength = 10,  #mtry can change from 1 to tuneLength
        trControl = trainControl(method = "cv", number = 5, repeats = 10, verboseIter = TRUE)
        )

I played with varying the variables and I noticed that some variables are used incorrectly by *caret* and/or *gbm*. Using a factor that has 4 levels according to the stock price at the end model date (&lt;1, 1-10, 10-100, &gt;100) did not work. The final model was incorrectly only assigning 3 *categories* (same as levels?) and I could not make it work. Furthermore, those categories were not relevant in the final model. Therefore, I decided to use **Price.Model.end** instead.

The time horizon used in the following is 15 months in the future (from the data financial information is last available). The model was prepared with data from 2013/06/03 to 2015/06/30 for a prediction at 2016/09/30. The following results are obtained:

    my_model$results
        shrinkage interaction.depth n.minobsinnode n.trees     RMSE   Rsquared    RMSESD  RsquaredSD
    1         0.1                 1             10      50 58.57166 0.04230435 10.026998 0.042328721

Calculating the RMSE directly in the train and validation data sets result in 57.4 and 54.5 respectively. The same for method *r**a**n**g**e**r* results in 30.4 and 54.3. The RMSE results for method *g**l**m**n**e**t* are 57.3 and 50. The problem with *g**l**m**n**e**t* is that variable **SectorIndustry.Num** is the most relevant variable by a large margin. All other variables seem to be irrelevant. Is this a problem with the method or with the way the model is built? By selecting the *g**b**m* method, more variables matter. The important variables in *g**b**m* are in the following table.

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Mon Nov 20 16:07:01 2017 -->
<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID43f84a7db315 () {
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
function drawChartTableID43f84a7db315() {
var data = gvisDataTableID43f84a7db315();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID43f84a7db315')
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
callbacks.push(drawChartTableID43f84a7db315);
})();
function displayChartTableID43f84a7db315() {
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
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID43f84a7db315"></script>
<!-- divChart -->

All other variables are not relevant (rel.inf = 0). **SectorIndustry.Num** 134 and 133 are Gold and Industrial Metals & Minerals, respectively. The train data prediction compated to the actual return (in percentage) looks reasonable. Not only for the highest performers but also for the laggarts. The validation data also seems decent

![](Figures/GBM.png)

but there is a problem. These are the best 10 results in the validation data:

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Mon Nov 20 16:07:01 2017 -->
<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID43f8352b136a () {
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
function drawChartTableID43f8352b136a() {
var data = gvisDataTableID43f8352b136a();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID43f8352b136a')
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
callbacks.push(drawChartTableID43f8352b136a);
})();
function displayChartTableID43f8352b136a() {
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
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID43f8352b136a"></script>
<!-- divChart -->

All of the top results are from **SectorIndustry.Num** 134 (Gold). If industries 134 and 133 are removed from the final results (but still keeping them in the model), the model results are much worse:

![](Figures/GBM_no134-133.png)

Attempts 10-12:
---------------

Assuming the problem with the previous attempts were the chosen variables, variables were changed. Valuations valuations of a given stock compared to other companies with the same Sector-industry-number were added:

<table>
<colgroup>
<col width="20%" />
<col width="79%" />
</colgroup>
<thead>
<tr class="header">
<th>Variable</th>
<th>Meaning</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td>Ev.earning.peers</td>
<td>Enterprise value / earnings of the stock divided by its average value (stocks in the same sector-industry)</td>
</tr>
<tr class="even">
<td>Ev.ebitda.peers</td>
<td>Enterprise value / EBITDA of the stock divided by its average value (stocks in the same sector-industry)</td>
</tr>
<tr class="odd">
<td>Ev.book.peers</td>
<td>Enterprise value / book value of the stock divided by its average value (stocks in the same sector-industry)</td>
</tr>
<tr class="even">
<td>Ev.revenue.peers</td>
<td>Enterprise value / revenueof the stock divided by its average value (stocks in the same sector-industry)</td>
</tr>
<tr class="odd">
<td>Ev.cash.peers</td>
<td>Enterprise value / cash of the stock divided by its average value (stocks in the same sector-industry)</td>
</tr>
<tr class="even">
<td>Price.equity.debt.peers</td>
<td>Stock price /(Total equity/ Total debt) of the stock divided by its average value (stocks in the same sector-industry)</td>
</tr>
</tbody>
</table>

The variable **SectorIndustry.Num** was removed since the sector performance over model training period is taken into account and it is likely that that performance will not be repeated in the future.

The variables importance in a *g**b**m* model are in the following table:

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Mon Nov 20 16:07:01 2017 -->
<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID43f84b8146cb () {
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
function drawChartTableID43f84b8146cb() {
var data = gvisDataTableID43f84b8146cb();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID43f84b8146cb')
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
callbacks.push(drawChartTableID43f84b8146cb);
})();
function displayChartTableID43f84b8146cb() {
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
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID43f84b8146cb"></script>
<!-- divChart -->

Calculating the RMSE directly in the train and validation data sets result in 56.1 and 59.4 respectively. Those numbers are slightly worse than during attempts 1-10 but the results and the relative importance of the variables look better.

![](Figures/GBM_model2.png)

The random forest model *r**a**n**g**e**r* results in 26.9 and 57.6 for the RMSE in train and validation data respectively:

![](Figures/ranger_model2.png)

The linear regression model *g**l**m**n**e**t* performs badly and results in an RMSE in the validation data larger than a 100.

Attempts 12-15:
---------------

Changes from previous attempts:

-   Variables added:
    -   Simple moving average variable (over 200 days) and comparison with its peers.
    -   Simple moving average variable (over 50 days) and comparison with its peers.
    -   ARIMA forecast prediction.
    -   Relative Strength Index RSI over 10 days: it expresses the fraction of gains and losses over the past lookback periods, 100 - (100/(1 + RS)), where RS is the average gain over the average loss over the lookback window decided.
    -   Relative Strength Index RSI over 50 days.
    -   Value representing the percentage rank of the stock price between the lowest and highest stock price during the last 2 years.
-   Changed varibles calculating the stock price over the lowest (and highest) stock price during the last 2 years to a calculation that uses daily stock prices instead of monthly stock prices.
-   Corrections:
    -   Holt-Winters prediction and its lower bound with 90% confidence were calculated with a time horizon incorrectly calculated (it was 1 month too long).
    -   Stock price at end.model.date was incorrectly taken one month later. This affected all variables involving this price.

In the previous attempts and these ones too, the calculated RMEs are highly variable depending on the splitting between training and testing data. This observation is independent of the method used:

![](Figures/ranger_gbm.png)

The relative importance of the variables also changes but not as much (most of the time). This is a particular example for the *r**a**n**g**e**r* method:

![](Figures/ranger3_varImp.png)

The train data is over-fitted with the *r**a**n**g**e**r* method but the validation data modeling is not worse than using the *g**b**m* (or any other method) method. One of the main takeaways so far is that despite adding more and more variables, the effectiveness of the model, as measured by the RMS value, has not improved much from the first attempts.

Changing time horizon:
----------------------

Using a time horizon of 3 months, the results get better:

![](Figures/ranger_gbm_timeHorizon3.png)

The relative importance of the different variables also change. Enterprise value (stock price \* number of shares) variables become more relevant.

![](Figures/ranger4_varImp.png)

For the *g**b**m* method, this is what the predictions look like:

![](Figures/GBM_timeHorizon3.png)

Eliminating quaterly variables (assets, equity, etc.):
------------------------------------------------------

By leaving only stock price variables and eliminating all quaterly variables the RMS results do not change dramatically:

![](Figures/ranger_gbm_timeHorizon3_redVar.png)

For the *g**b**m* method, this is what the predictions look like:

![](Figures/GBM_timeHorizon3_redVar.png)

Robustness of the model:
------------------------

This is how the ranking of predictions compare between methods *g**b**m* and *r**a**n**g**e**r*:

![](Figures/ranger_gbm_robust_3.png)

Notice how there are some companies that have a high rank in one of the methods but not in both. There are also some companies highly ranked in both methods. The colors indicate the ranking based on actual/win losses. Notice that there are more high ranking (high gains) companies in the top right corner than in the bottom left corner. However, the correlation between model ranking and actual win/loss ranking is not great:

![](Figures/ranger_actual_robust_3.png)

The last figure should show a linear correlation if the model were perfect. As it, there is still a lot of room for improvement. Adding quaterly variables does not improve the figure much. Therefore they are removed again for the following results.

![](Figures/ranger_actual_robust_3_quaterly.png)

The correlation between results using *g**l**m**n**e**t* and *r**a**n**g**e**r* is not as clean, but that could actually be better since companies with high rankings in both methods also seem to have good rankings in the actual win/loss ranking.

![](Figures/ranger_glmnet_robust_3.png)

I also tested the robustness of using the *r**a**n**g**e**r* method using different train data. The resulting graph is very similar to the one comparing different methods.

Requiring a rank in methods *r**a**n**g**e**r*, *g**b**m* and *g**l**m**n**e**t* above 90%, the following companies are the ones recommended by the model (prepared with data from 2013/06/03 to 2015/06/30 for a prediction at 2015/09/30):

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Mon Nov 20 16:07:01 2017 -->
<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID43f8504fb3f4 () {
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
function drawChartTableID43f8504fb3f4() {
var data = gvisDataTableID43f8504fb3f4();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID43f8504fb3f4')
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
callbacks.push(drawChartTableID43f8504fb3f4);
})();
function displayChartTableID43f8504fb3f4() {
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
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID43f8504fb3f4"></script>
<!-- divChart -->

Using the same model but for data from 2013/09/03 to 2015/09/30 for a prediction at 2015/12/31 results in RMS of 34 for *r**a**n**g**e**r* and *g**b**m* methods. Method *g**l**m**n**e**t* has an outlier that makes the RMS blow up. These are the companies with the highest actual ranking and their method rankings:

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Mon Nov 20 16:07:01 2017 -->
<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID43f8927f32 () {
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
function drawChartTableID43f8927f32() {
var data = gvisDataTableID43f8927f32();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID43f8927f32')
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
callbacks.push(drawChartTableID43f8927f32);
})();
function displayChartTableID43f8927f32() {
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
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID43f8927f32"></script>
<!-- divChart -->

None of the methods is particularly good. It seems that the assumption that a model created and optimized at an earlier time (3 months in this case) is not completely valid by the time it has to be used. However some of the model is still useful. Requiring an average rank in methods *r**a**n**g**e**r*, *g**b**m* and *g**l**m**n**e**t* above 95.5%, results in companies:

<!-- Table generated in R 3.3.2 by googleVis 0.6.2 package -->
<!-- Mon Nov 20 16:07:01 2017 -->
<!-- jsHeader -->
<script type="text/javascript">
 
// jsData 
function gvisDataTableID43f816d01aff () {
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
function drawChartTableID43f816d01aff() {
var data = gvisDataTableID43f816d01aff();
var options = {};
options["allowHtml"] = true;

    var chart = new google.visualization.Table(
    document.getElementById('TableID43f816d01aff')
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
callbacks.push(drawChartTableID43f816d01aff);
})();
function displayChartTableID43f816d01aff() {
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
<script type="text/javascript" src="https://www.google.com/jsapi?callback=displayChartTableID43f816d01aff"></script>
<!-- divChart -->

which have an average actual win loss percentage of 4.6% while the average of all the companies considered is 0.7%. When adding quaterly variables the average actual win loss percentage is 7.5%.

Changing the construction of the model from 2014/03/03 to 2016/03/31 and applying it to 2016/06/30, obtains an average actual win loss percentage of 22.4% for companies with a predicted average ranking of 97%, compared to 5.4% for the average for all companies. However, when using the same model for data from 2014/06/03 to 2016/06/30 for a prediction by 2016/09/30 obtains an average actual win loss percentage of -3.4% for companies with a predicted average ranking of 99%, compared to 8.7% for the average for all companies. The model does not work!

Tried subsetting the data to specific price categories and/or assets and the model does not seem to improve. I believe the problem is not with the existing variables but with missing information not currently in the model.

To be continued ....

To do
=====

-   Add/replace variables:
    -   Add a google trend variables (stock and sector).

[1] The *g**b**m* method does not work correctly if train.fraction is not defined explicitely.
