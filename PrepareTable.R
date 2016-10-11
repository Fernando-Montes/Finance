# ----------------------------------------------------------
# Function to prepare to table with stocks info. Returns table.
# It uses StockInfo.R 
# ----------------------------------------------------------

prepare.table <- function(stockInfo, end.date.model, months.min) {
  
  # Sourcing add.stock.to.table function
  source('~/Dropbox/Courses/R/Finance/StockInfo.R') 
  
  # Creating the table with the stock info  --------------------
  # EV = price * number outstanding shares
  table <- data.frame(Stock.SYM = character(0),
                      Price.Current = numeric(0),
                      Price.Min = numeric(0),
                      Price.Max = numeric(0),
                      Price.Model.end = numeric(0),
                      Price.Category = character(0),
                      Assets = numeric(0),
                      Ev.earning = numeric(0),
                      Ev.ebitda = numeric(0),
                      Ev.book = numeric(0),
                      Ev.revenue = numeric(0),
                      Ev.cash = numeric(0),
                      Price.equity.debt = numeric(0),
                      Price.Prediction = numeric(0),
                      Price.Prediction.LB = numeric(0),
                      SectorIndustry.Num = character(0), stringsAsFactors=FALSE
  )
  
  # Loop over all the stocks that have been previously saved
  for (i in 1:length(stockInfo[,1])) {
    print(i)
    table[nrow(table) + 1, ] <- add.stock.to.table(stockInfo[i,1], end.date.model, months.min)
    table[nrow(table), 16] <- stockInfo[i,3] # Adding industry number stock belongs to
  }
  
  table <- na.exclude(table)
  # Code to save table
  # saveRDS(table, file="~/Dropbox/Courses/R/Finance/ServicesSector.Rda")
  # Code to read it back
  # table <- readRDS(file="~/Dropbox/Courses/R/Finance/ServicesSector.Rda")
  
  table$Price.Model.end.low.ratio = as.numeric(table$Price.Model.end)/as.numeric(table$Price.Min)
  table$Price.Model.end.high.ratio = as.numeric(table$Price.Model.end)/as.numeric(table$Price.Max)
  table$actual.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Current) - 100.
  table$predicted.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Prediction) - 100.
  table$predictedLB.win.loss = 100.0/as.numeric(table$Price.Model.end)*as.numeric(table$Price.Prediction.LB) - 100.
  table$Price.Category = as.factor(table$Price.Category)
  table$SectorIndustry.Num = as.factor(table$SectorIndustry.Num)
  
  return(table) 
}