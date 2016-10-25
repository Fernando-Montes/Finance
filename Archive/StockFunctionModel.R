library(data.table)

# WRONG: NEED TO DO A MODEL FOR EACH STOCK!!!!!!!
# BUT NOT ENOUGH DATA POINTS THEREFORE THIS APPROACH DOES NOT WORK!!!!!

prepare.Stock.function <- function(stockInfo, end.date.model, months.min) {

  targetPath <- "~/Dropbox/Courses/R/Finance/Downloads/"
  outPath = "~/Dropbox/Courses/R/Finance/Downloads/PrepareStockFunctionData.csv"
  endDate = as.Date("2016-09-01")
  
  stocksAllTable <- data.frame()
  
  # loop over time from (end.date.model-months.min) to (end.date.model-months.min)
  for (i in 1:length(stockInfo[,1])) {
  #for (i in 1:2) {
    print(i)
    # Loading historical stock price data into SYMB_prices
    fileName <- paste(targetPath, stockInfo[i,1], "-prices.RData", sep="")
    load(file = fileName)
    
    # Checking the dates are right
    if ( index(SYMB_prices[length(SYMB_prices)]) > end.date.model & length(SYMB_prices[endDate,])==1 ) {
      # Checking that there is enough stock price historical information
      if ( length(SYMB_prices) > length(seq(to=index(SYMB_prices[length(SYMB_prices)]), from=end.date.model, by='month')) + months.min - 1 ) {
        stocksAllTable <- rbind(stocksAllTable, 
                          rbind(data.frame(),
                            SYMB_prices[(length(SYMB_prices)-length(seq(to=index(SYMB_prices[length(SYMB_prices)]), from=end.date.model, by='month'))+1 - months.min):
                                        (length(SYMB_prices)-(length(seq(to=index(SYMB_prices[length(SYMB_prices)]), from=endDate, by='month'))-1))])) 
      }
    } 
  }
  
  # loop over different "data" points : from end.date.model to the date of the last stock price
  for (j in 1:length(seq(to=endDate, from=end.date.model, by='month'))) {
     x <- stocksAllTable[,j]
     y <- stocksAllTable[,j+months.min]
     
     dat = data.table(cbind(y, x))
     dat <- as.matrix(dat)
     write.table(dat, file=outPath, append=(j != 1), sep=",", row.names=FALSE, quote=FALSE)
  }
  
  dat = read.csv(outPath)
  # Preparing model
  
}