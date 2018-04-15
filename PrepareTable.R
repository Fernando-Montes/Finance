# ----------------------------------------------------------
# Function to prepare to table with stocks info. Returns table.
# It uses StockInfo.R 
# ----------------------------------------------------------

prepare.table <- function(stockInfo, end.date.model, ini.date.model, apply.date.model) {
  
  #cl <- makeCluster(4, outfile="")
  #registerDoParallel(cl)
  
  # Sourcing add.stock.to.table function
  source('~/Dropbox/Courses/R/StockModel-I/StockInfo.R') 
  
  # Creating the table with the stock info  --------------------
  ptime <- system.time({
  
  table <- foreach(i=1:length(stockInfo[,1]), .combine = rbind, .verbose = F, .errorhandling = "remove") %dopar% {
  # table <- foreach(i=7150:7202, .combine = rbind, .verbose = F, .errorhandling = "remove") %dopar% {
    table.temp <- data.frame(Stock.SYM = character(0),
                        Price.Model.apply = numeric(0),
                        Price.Min = numeric(0),
                        Price.Max = numeric(0),
                        Price.Model.end = numeric(0),
                        Price.Category = character(0),
                        Assets = numeric(0),
                        Ev = numeric(0),
                        Ev.earning = numeric(0),
                        Ev.ebitda = numeric(0),
                        Ev.book = numeric(0),
                        Ev.revenue = numeric(0),
                        Ev.cash = numeric(0),
                        EquityAssets.liability = numeric(0),
                        Price.Prediction.hw = numeric(0),
                        Price.Prediction.hwLB = numeric(0),
                        Price.Prediction.arima = numeric(0),
                        sma.200 = numeric(0),
                        sma.50 = numeric(0),
                        rsi.10 = numeric(0),
                        rsi.50 = numeric(0),
                        dvo = numeric(0),
                        SectorIndustry.Num = character(0), stringsAsFactors=FALSE
    )
    # print(i)
    table.temp[1, ]  <- add.stock.to.table(stockInfo[i,1], end.date.model, ini.date.model, apply.date.model)
    table.temp[1,23] <- stockInfo[i,3] # Adding industry number stock belongs to
    data.frame(table.temp)
  }
  
  })[3]
  print(ptime)
  table <- na.exclude(table)
  # Code to save table
  # saveRDS(table, file="~/Dropbox/Courses/R/Finance/ServicesSector.Rda")
  # Code to read it back
  # table <- readRDS(file="~/Dropbox/Courses/R/Finance/ServicesSector.Rda")
  
  table$Price.Model.end.low.ratio = as.numeric(table$Price.Model.end)/as.numeric(table$Price.Min)
  table$Price.Model.end.high.ratio = as.numeric(table$Price.Model.end)/as.numeric(table$Price.Max)
  table$actual.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Model.apply) - 100.
  table$predicted.hw.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Prediction.hw) - 100.
  table$predicted.hwLB.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Prediction.hwLB) - 100.
  table$predicted.arima.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Prediction.arima) - 100.
  table$Price.sma.200 =  100.0*as.numeric(table$Price.Model.end)/as.numeric(table$sma.200)
  table$Price.sma.50 =  100.0*as.numeric(table$Price.Model.end)/as.numeric(table$sma.50)
  table$Price.Category = as.factor(table$Price.Category)
  table$SectorIndustry.Num = as.factor(table$SectorIndustry.Num)
  #stopCluster(cl)
  return(table) 
}