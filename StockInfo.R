# ----------------------------------------------------------
# Function to add stock information. Returns a vector with stock's information
# It uses saved info that has been previously created by running Download.R
# ----------------------------------------------------------

# Adds stock information to a table. Info added:
# ----- EV = price*number outstanding shares
# -----
# stock symbol
# current stock price
# lowest stock price from end.date.model-months.min to end.date.model 
# highest stock price from end.date.model-months.min to end.date.model
# stock price at end.date.model
# stock price category at end.date.model
# Total assets at end.date.model 
# EV/earnings at end.date.model
# EV/EBITDA at end.date.model
# EV/book value at end.date.model
# EV/revenue at end.date.model
# EV/total cash at end.date.model
# price/(equity/debt) at end.date.model
# prediction for current stock price
# lower bound prediction for current stock price
# industry stock belongs to

add.stock.to.table <- function(stock, end.date.model, months.min) {
  
  targetPath <- "~/Dropbox/Courses/R/Finance/Downloads/"
  
  # Loading historical stock price data into SYMB_prices
  fileName <- paste(targetPath, stock, "-prices.RData", sep="")
  load(file = fileName)
  
  # Loading stock financial info into FinStock
  fileName <- paste(targetPath, stock, "-FinStock.RData", sep="")
  load(file = fileName)
  
  # Checking that there is enough stock price historical information
  if (length(SYMB_prices)-length(seq(to=Sys.Date(), from=end.date.model, by='month')) - months.min + 1 > 1) {
    
    # Income statement
    FinIS <- viewFin(FinStock, period = 'Q', "IS")
    # Balance sheet
    FinBS <- viewFin(FinStock, period = 'Q', "BS")
    # Cash flow
    FinCF <- viewFin(FinStock, period = 'Q', "CF")
    
    # Finding if stock info at end.date.model (year and month) exists
    numCol <- return.numCol(FinIS, FinBS, end.date.model)
    numIS <- numCol[[1]]
    numBS <- numCol[[2]]
    
    # Checking that there is enough historical information at time end.date.model
    if ( numIS != 0 & numBS != 0) {
      
      # Stock price at end.date.model --- taking to be the first day of the next month
      price <- SYMB_prices[length(SYMB_prices)-length(seq(to=Sys.Date(), from=end.date.model, by='month'))+2]
      # Number of outstanding shares at time end.date.model
      number.shares <- ifelse(is.na(FinBS["Total Common Shares Outstanding",numBS]),0,FinBS["Total Common Shares Outstanding",numBS])
      if (number.shares == 0 ) { 
        print(paste(stock," does not have Common Shares Outstanding information"))
        return(NA) 
      }
      # Enterprise value
      ev <- price*number.shares 
      # EBITDA = (net income FinIS + interest income FinIS + income before tax FinIS - income after tax FinIS 
      #           + depreciation/amortization FinIS + unusual expense FinIS)
      ebitda <- ifelse(is.na(FinIS["Net Income",numIS]),0,FinIS["Net Income",numIS]) +
        ifelse(is.na(FinIS["Interest Income(Expense), Net Non-Operating",numIS]),0,FinIS["Interest Income(Expense), Net Non-Operating",numIS])+
        ifelse(is.na(FinIS["Income Before Tax",numIS]),0,FinIS["Income Before Tax",numIS])-
        ifelse(is.na(FinIS["Income After Tax",numIS]),0,FinIS["Income After Tax",numIS])+
        ifelse(is.na(FinIS["Depreciation/Amortization",numIS]),0,FinIS["Depreciation/Amortization",numIS])+
        ifelse(is.na(FinIS["Unusual Expense (Income)",numIS]),0,FinIS["Unusual Expense (Income)",numIS])
      
      # The following information is at end.date.model ---------
      # lowest stock price from end.date.model-months.min to end.date.model 
      Price.Min <- min(SYMB_prices[(length(SYMB_prices)-length(seq(to=Sys.Date(), from=end.date.model, by='month'))+1 - months.min):
                                   (length(SYMB_prices)-length(seq(to=Sys.Date(), from=end.date.model, by='month'))+2)])  
      # highest stock price from end.date.model-months.min to end.date.model
      Price.Max <- max(SYMB_prices[(length(SYMB_prices)-length(seq(to=Sys.Date(), from=end.date.model, by='month'))+1 - months.min):
                                   (length(SYMB_prices)-length(seq(to=Sys.Date(), from=end.date.model, by='month'))+2)])  
      # stock price category at end.date.model
      Price.Category <- ifelse(price<1., "1", ifelse(price<10., "2", ifelse(price<100., "3", "4")))
      # Total assets at end.date.model 
      Assets <- FinBS["Total Assets",numBS]
      # Ev/earning = price/diluted normalized EPS (FinIS) 
      Ev.earning <- ifelse(FinIS["Diluted Normalized EPS",numIS] != 0, price/FinIS["Diluted Normalized EPS",numIS], NA)
      # Ev/ebitda = EV/(net income FinIS + interest income FinIS + income before tax FinIS - income after tax FinIS 
      #                + depreciation/amortization FinIS + unusual expense FinIS)
      Ev.ebitda <- ifelse(ebitda != 0, ev/ebitda, NA)
      # Ev/book = EV/total equity (FinBS) 
      Ev.book <- ifelse(FinBS["Total Equity",numBS] != 0, ev/FinBS["Total Equity",numBS], NA)
      # Ev/revenue = EV/Total Revenue (FinIS) 
      Ev.revenue <- ifelse(FinIS["Total Revenue",numIS] != 0, ev/FinIS["Total Revenue",numIS], NA)
      # Ev/cash = EV/Cash and Short Term Investments (FinBS) 
      Ev.cash <- ifelse(FinBS["Cash and Short Term Investments",numBS] != 0, ev/FinBS["Cash and Short Term Investments",numBS], NA)
      # Price.equity.debt = price/Total Equity (FinBS)/Total Debt (Fin BS)
      Price.equity.debt <- ifelse(FinBS["Total Debt",numBS] != 0 & FinBS["Total Equity",numBS] != 0, 
                                  price*FinBS["Total Debt",numBS]/FinBS["Total Equity",numBS], NA)
      # prediction for current stock price and lower bound prediction for current stock price
      HoltWinters <- Prediction.HoltWinters(SYMB_prices, 
                             c(as.numeric(format(end.date.model, format = "%Y")), as.numeric(format(end.date.model, format = "%m"))), 
                             length(seq(to=Sys.Date(), from=end.date.model, by='month')))
      # prediction for current stock price
      Price.Prediction <- HoltWinters[[1]]
      # prediction for lower bound prediction for current stock price
      Price.Prediction.LB <- HoltWinters[[2]]
  
      return( list(stock,                            # stock symbol
                   SYMB_prices[length(SYMB_prices)], # current stock price
                   Price.Min,                        # lowest stock price from end.date.model-months.min to end.date.model 
                   Price.Max,                        # highest stock price from end.date.model-months.min to end.date.model
                   price,                            # stock price at end.date.model
                   Price.Category,                   # stock price category at end.date.model
                   Assets,                           # Total assets at end.date.model 
                   Ev.earning,                       # EV/earnings at end.date.model
                   Ev.ebitda,                        # EV/EBITDA at end.date.model
                   Ev.book,                          # EV/book value at end.date.model
                   Ev.revenue,                       # EV/revenue at end.date.model
                   Ev.cash,                          # EV/total cash at end.date.model
                   Price.equity.debt,                # price/(debt/equity) at end.date.model
                   Price.Prediction,                 # prediction for current stock price
                   Price.Prediction.LB,              # prediction for lower bound prediction for current stock price
                   "temp"                            #Place-holder for industry stock belongs to
                  )
      )
    } else {
      print(paste(stock," does not have enough historical information at time end.date.model"))
      return(NA)
    }
  } else {
    print(paste(stock," does not have enough stock price historical information"))
    return(NA)
  }

}

# Returns stock price prediction and a lower bound price using a Holt-Winters model 
# after a number of months
Prediction.HoltWinters <- function(SYMB_prices, end.date.model, months.ahead) {
  # Find the start of the quoted prices
  start <- c(as.numeric(format(index(SYMB_prices)[1], format = "%Y", tz = "", usetz = FALSE)),
             as.numeric(format(index(SYMB_prices)[1], format = "%m", tz = "", usetz = FALSE)))
  
  SYMB.ts <- ts(SYMB_prices, start = start, end = end.date.model, freq=12)
  # Do the Holt-Winters model with mult season option if it can
  SYMB.hw <- if (class(try(HoltWinters(SYMB.ts, seasonal = "mult"), silent = TRUE)) != "try-error") {
    HoltWinters(SYMB.ts, seasonal = "mult")
  } else if (class(try(HoltWinters(SYMB.ts, seasonal = "add"), silent = TRUE)) != "try-error") {
    HoltWinters(SYMB.ts, seasonal = "add")
  } else {
    return(c(NA,NA))
  }
  SYMB.predict <- predict(SYMB.hw, n.ahead = months.ahead, level = 0.9, prediction.interval = TRUE)
  # Returns prediction and lower bound prediction
  return( list(SYMB.predict[length(SYMB.predict[,1])], SYMB.predict[length(SYMB.predict)]) )
}

# To run it:
# plot.Prediction(stock, c(as.numeric(format(end.date.model, format = "%Y")), as.numeric(format(end.date.model, format = "%m"))), 
#                        length(seq(to=Sys.Date(), from=end.date.model, by='month')))
plot.Prediction <- function(stock, end.date.model, months.ahead) {
  # Obtaining historical data
  SYMB_prices <- get.hist.quote(instrument=stock, 
                                quote="AdjClose",provider="yahoo", 
                                compression="m", retclass="zoo", quiet=TRUE)
  
  # Find the start of the quoted prices
  start <- c(as.numeric(format(index(SYMB_prices)[1], format = "%Y", tz = "", usetz = FALSE)),
             as.numeric(format(index(SYMB_prices)[1], format = "%m", tz = "", usetz = FALSE)))
  
  SYMB.ts <- ts(SYMB_prices, start = start, end = end.date.model, freq=12)
  #plot(SYMB.ts, xlab= "Time (months)", ylab = "Price")
  # Do the Holt-Winters model with mult season option if it can
  SYMB.hw <- if (class(try(HoltWinters(SYMB.ts, seasonal = "mult"), silent = TRUE)) != "try-error") {
    HoltWinters(SYMB.ts, seasonal = "mult")
  } else {
    HoltWinters(SYMB.ts, seasonal = "add")
  }
  #SYMB.hw 
  #SYMB.hw$coef 
  #SYMB.hw$SSE
  #plot (SYMB.hw$fitted)
  #plot (SYMB.hw)
  
  # Prediction into the future !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SYMB.predict <- predict(SYMB.hw, n.ahead = months.ahead, level = 0.9, prediction.interval = TRUE)
  SYMB.ts <- ts(SYMB_prices, start = start, freq=12)
  ts.plot(SYMB.ts, as.ts(SYMB.hw$fitted[,1]), SYMB.predict, lty = c(1,2,3,3,3)
          , xlab= "Time (months)", ylab = paste("Price", stock))
}

# Returns column number of FinIS and FinBS that has the same date as end.date.model
return.numCol <- function(FinIS, FinBS, end.date.model) {

  numIS <- 0
  if ( class(try(FinIS["Diluted Normalized EPS",1], TRUE)) != "try-error" ) { 
    if ( as.numeric(format(as.Date(colnames(FinIS)[1]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinIS)[1]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numIS <- 1
    }
  } 
  if ( class(try(FinIS["Diluted Normalized EPS",2], TRUE)) != "try-error" & numIS == 0 ) { 
    if ( as.numeric(format(as.Date(colnames(FinIS)[2]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinIS)[2]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numIS <- 2
    }
  } 
  if ( class(try(FinIS["Diluted Normalized EPS",3], TRUE)) != "try-error" & numIS == 0) { 
    if ( as.numeric(format(as.Date(colnames(FinIS)[3]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinIS)[3]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numIS <- 3
    }
  } 
  if ( class(try(FinIS["Diluted Normalized EPS",4], TRUE)) != "try-error" & numIS == 0) { 
    if ( as.numeric(format(as.Date(colnames(FinIS)[4]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinIS)[4]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numIS <- 4
    }
  } 
  if ( class(try(FinIS["Diluted Normalized EPS",5], TRUE)) != "try-error" & numIS == 0) { 
    if ( as.numeric(format(as.Date(colnames(FinIS)[5]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinIS)[5]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numIS <- 5
    }
  }
  
  numBS <- 0
  if ( class(try(FinBS["Total Equity",1], TRUE)) != "try-error" ) { 
    if ( as.numeric(format(as.Date(colnames(FinBS)[1]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinBS)[1]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numBS <- 1
    }
  } 
  if ( class(try(FinBS["Total Equity",2], TRUE)) != "try-error" & numBS == 0 ) { 
    if ( as.numeric(format(as.Date(colnames(FinBS)[2]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinBS)[2]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numBS <- 2
    }
  } 
  if ( class(try(FinBS["Total Equity",3], TRUE)) != "try-error" & numBS == 0 ) { 
    if ( as.numeric(format(as.Date(colnames(FinBS)[3]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinBS)[3]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numBS <- 3
    }
  } 
  if ( class(try(FinBS["Total Equity",4], TRUE)) != "try-error" & numBS == 0 ) { 
    if ( as.numeric(format(as.Date(colnames(FinBS)[4]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinBS)[4]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numBS <- 4
    }
  } 
  if ( class(try(FinBS["Total Equity",5], TRUE)) != "try-error" & numBS == 0 ) { 
    if ( as.numeric(format(as.Date(colnames(FinBS)[5]), format = "%Y")) == as.numeric(format(end.date.model, format = "%Y")) &
         as.numeric(format(as.Date(colnames(FinBS)[5]), format = "%m")) == as.numeric(format(end.date.model, format = "%m")) ) { 
      numBS <- 5
    }
  }
  
  return(list(numIS, numBS))
}



# ADDITIONAL NOT CURRENTLY USED  
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Places to obtain financial data

# Interesting site
# http://finance-r.com/

# http://www.wikinvest.com/stock/Microsoft_(MSFT)/Data/Income_Statement
# fernandoamontes@gmail.com
# oabecobacd
# iugilbuiwgwwew4

# https://www.estimize.com
#fernandoamontes@gmail.com
#sxashsbkhjflkurt3

# http://www.valueuncovered.com/stock-research-10-year-historical-financial-statements
# https://www.quora.com/Which-web-site-gives-the-previous-10-years-earnings-of-a-public-company
# http://ycharts.com/financials/AAPL/income_statement/annual

# http://financials.morningstar.com/ratios/r.html?t=QAN&region=aus&culture=en-US
# http://financials.morningstar.com/valuation/price-ratio.html?t=00670&region=hkg&culture=en-US
# http://financials.morningstar.com/ajax/exportKR2CSV.html?&t=GOOG

# Yahoo API
# http://stackoverflow.com/questions/38567661/how-to-get-key-statistics-for-yahoo-finance-web-search-api

# Obtaining information from
# http://financials.morningstar.com/ratios/r.html?t=QAN&region=aus&culture=en-US

# TenYearSummary <- read.csv2(paste0("http://financials.morningstar.com/ratios/r.html?t=", 
#                                    stock, "&region=usa&culture=en-US")) 
# test <- readHTMLTable(paste0("http://financials.morningstar.com/ratios/r.html?t=", 
#                              stock, "&region=usa&culture=en-US"))
# 
# TenYearSummary <- read.csv2(paste0("http://financials.morningstar.com//ajax/exportKR2CSV.html?&t=", 
#                                    stock)) 
# write.csv(TenYearSummary, paste0("/Users/fernandomontes/Dropbox/Courses/R/Finance/Financials/",stock), row.names=T)
