# Help functions to download data

# Obtains list of stocks with quaterly data
obtainStockSYM <- function() {
  # Load indicatorTable
  fileName2 <- paste(targetPath, "indicatorTable.RData", sep="")
  load(file = fileName2)
  listStocks = indicatorTable[ !duplicated(indicatorTable['ticker']), 'ticker']
  return (listStocks)
}

# Obtains additional info given a stock symbol
obtainStockInfo <- function(stock, key) {
  url <- paste("https://query1.finance.yahoo.com/v10/finance/quoteSummary/", 
               stock, '?lang=en-US&region=US&modules=assetProfile&corsDomain=finance.yahoo.com', sep='')
  tmp = fromJSON(url)
  url <- paste('https://api.tdameritrade.com/v1/instruments/', stock, '?apikey=', key, sep='')
  tmpName = fromJSON(url)
  tempList = list( 'Stock.SYM' = stock, 'Sector' = tmp$quoteSummary$result$assetProfile$sector,
                   'Industry' = tmp$quoteSummary$result$assetProfile$industry, 'Website' = tmp$quoteSummary$result$assetProfile$website, 
                   'Summary' = tmp$quoteSummary$result$assetProfile$longBusinessSummary, 'Name' = tmpName$description )
  for (i in 1:length(tempList)) {
    if ( is.null(tempList[i][[1]]) == TRUE ) { tempList[i] = 'unknown' }
  }
  return ( tempList )
}

# Makes dataframe with info for all stocks
obtainStockInfoAll <- function() {
  stockInfoAll <- data.frame(Stock.SYM = character(0),
                             Sector = character(0),
                             Industry = character(0), 
                             Website = character(0),
                             Summary = character(0), 
                             Name = character(0),
                             stringsAsFactors=FALSE
  )
  listStocks = obtainStockSYM()   # Obtains list of stocks with quaterly data
  pass <- file("~/Dropbox/Courses/R/StockModel-2/clientID.pem","r")
  key <- readLines(pass,n=1)
  close(pass)
  for (i in 1:length(listStocks)) {
    print(i)
    print(listStocks[i])
    if (class(try( tmp <- obtainStockInfo(listStocks[i], key), silent = TRUE)) != "try-error") {
      stockInfoAll[nrow(stockInfoAll) + 1, ] = tmp
    }
  }
  return(stockInfoAll)
}
