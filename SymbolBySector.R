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
  pass <- file(paste(targetPatS, "clientID.pem", sep = ""),"r")
  key <- readLines(pass, n=1)
  close(pass)
  for (i in 1:length(listStocks)) {
    print( paste("i = ", i, " stock: ", listStocks[i], sep = "") )
    if (class(try( tmp <- obtainStockInfo(listStocks[i], key), silent = TRUE)) != "try-error") {
      stockInfoAll[nrow(stockInfoAll) + 1, ] = tmp
    }
  }
  return(stockInfoAll)
}

# Returns ameritrade keys
ameritradeKeys <- function() {
  pass <- file(paste(targetPatS, "clientID.pem", sep = ""),"r")
  clientID <- readLines(pass, n=1) 
  close(pass)
  pass <- file(paste(targetPatS, "refreshToken.pem", sep = ""),"r")
  refreshToken <- readLines(pass, n=1)
  close(pass)
  data = list("grant_type" = "refresh_token", 'refresh_token' = refreshToken, 
              "access_type" = "", 'code' = '', 'client_id' = clientID, 'redirect_uri' = '') 
  request <- httr::POST( 'https://api.tdameritrade.com/v1/oauth2/token',
                      httr::add_headers( "Content-Type" = "application/x-www-form-urlencoded"), 
                      body = data, encode = "form" );
  token <- paste("Bearer", httr::content(request)$access_token)  
  return(list(clientID, token))
}

# Given stock symbol returns dataframe with candle stick info of the price
ameritradePriceInfo <- function(stock, clientID, token) {
  periodType = 'year'
  period = 10
  url = paste('https://api.tdameritrade.com/v1/marketdata/', stock, '/pricehistory?apikey=', clientID,
              '&periodType=', periodType, '&period=', period, '&frequencyType=daily&frequency=1', sep="") 
  req <- httr::GET(url, httr::add_headers(Authorization = token))
  #print(req)
  json <- httr::content(req, as = "text")
  tmp = fromJSON(json)$candles
  #print(tmp)
  framedates = as.Date(as.POSIXct(tmp[,6]/1000, origin = "1970-01-01", tz = 'UTC'), format = "%m-%d-%Y")
  SYMB_prices = zoo(tmp[,1:4], order.by = framedates)
  colnames(SYMB_prices) = c("Open", "High", "Low", "Close")
  return(SYMB_prices)
}



