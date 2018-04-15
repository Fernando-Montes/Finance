# ----------------------------------------------------------
# Function to add stock information. Returns a vector with stock's information
# It uses saved info that has been previously created by running Download.R
# ----------------------------------------------------------

# Adds stock information to a table. Info added:
# ----- EV = price*number outstanding shares
# -----
# stock symbol
# current stock price
# lowest stock price from ini.date.model to end.date.model
# highest stock price from ini.date.model to end.date.model
# stock price at end.date.model
# stock price category at end.date.model
# Total assets at end.date.model 
# Enterprise value (EV) at end.date.model 
# EV/earnings at end.date.model
# EV/EBITDA at end.date.model
# EV/book value at end.date.model
# EV/revenue at end.date.model
# EV/total cash at end.date.model
# price/(equity/debt) at end.date.model
# prediction for current stock price
# lower bound prediction for current stock price
# Simple moving 200-day-average of the stock price
# Simple moving 50-day-average of the stock price
# Relative Strength Index over the last 10 days 
# Relative Strength Index over the last 50 days 
# DVO indicator 
# industry stock belongs to

add.stock.to.table <- function(stock, end.date.model, ini.date.model, apply.date.model) {
  
  targetPath <- "~/Dropbox/Courses/R/StockModel-I/ArchiveFin/"
  
  # Loading historical stock price data into SYMB_prices
  fileName1 <- paste(targetPath, stock, "-prices.RData", sep="")
  # Selecting only financial data of the stock
  Fin_Q = indicatorTable[indicatorTable$ticker == stock,]
  
  if ( class(try(load(file = fileName1), silent = TRUE)) != "try-error" &
       dim(Fin_Q)[1] != 0 ) {
    
    # Closest date earlier than end.date.model
    temp = SYMB_prices[index(SYMB_prices) < end.date.model,]
    end.date.mod = index(SYMB_prices[which(abs((index(temp)-end.date.model)) == min(abs(index(temp)-end.date.model))),])
    
    # Closest date earlier than ini.date.model
    temp = SYMB_prices[index(SYMB_prices) < ini.date.model,]
    ini.date.mod = index(SYMB_prices[which(abs((index(temp)-ini.date.model)) == min(abs(index(temp)-ini.date.model))),])
    
    # Closest date to apply.date.model
    apply.date.mod = index(SYMB_prices[which(abs((index(SYMB_prices)-apply.date.model)) == min(abs(index(SYMB_prices)-apply.date.model))),])
    
    # Closest financial quarter date earlier than end.date.model
    temp = as.Date(Fin_Q$calendardate)[as.Date(Fin_Q$calendardate) < end.date.model]
    end.date.financial = temp[which(abs((temp-end.date.model)) == min(abs(temp-end.date.model)))]

    # Checking that there is enough stock price information between times ini.date.model and end.date.model (within 5 days)
    # and that there is enough financial information at time close to end.date.model (within 90 days)    
    if ( abs(end.date.mod - end.date.model) < 10 & abs(ini.date.mod - ini.date.model) < 5 &
         abs(end.date.financial - end.date.model) < 95 ) {
      
      rownames(Fin_Q) = Fin_Q$calendardate   # renaming rows
      end.date.financial = as.character(end.date.financial)
      # Stock price at end.date.model 
      price <- as.numeric(SYMB_prices[index(SYMB_prices[end.date.mod,]),4])
      # Number of outstanding shares at time end.date.model
      number.shares <- ifelse(is.na(Fin_Q[end.date.financial, "shareswa"]),0,
                              Fin_Q[end.date.financial, "shareswa"])
      if (number.shares == 0 ) { 
        print(paste(stock," does not have Common Shares Outstanding information"))
        return(NA) 
      }
      # Enterprise value
      ev <- price*number.shares 
      # EBITDA = (net income + interest income + income before tax - income after tax + depreciation/amortization + unusual expense)
      ebitda <- ifelse(is.na(Fin_Q[end.date.financial, "ebitda"]), 0, 
                       Fin_Q[end.date.financial, "ebitda"]) 
      
      # The following information is at end.date.model ---------
      # lowest stock price from end.date.model-months.min to end.date.model 
      Price.Min <- min( SYMB_prices[ which(index(SYMB_prices) == index(SYMB_prices[ini.date.mod,])):
                                       which(index(SYMB_prices) == index(SYMB_prices[end.date.mod,])) ] )  
      # highest stock price from end.date.model-months.min to end.date.model
      Price.Max <- max( SYMB_prices[ which(index(SYMB_prices) == index(SYMB_prices[ini.date.mod,])):
                                       which(index(SYMB_prices) == index(SYMB_prices[end.date.mod,])) ] )    
      # stock price category at end.date.model
      Price.Category <- ifelse(price<1., "1", ifelse(price<10., "2", ifelse(price<100., "3", "4")))
      # Total assets at end.date.model 
      Assets <- Fin_Q[end.date.financial, "assets"]
      # Ev/earning = price/EPS 
      Ev.earning <- ifelse(Fin_Q[end.date.financial, "eps"] != 0, 
                           price/Fin_Q[end.date.financial, "eps"], NA)
      # Ev/ebitda = EV/(net income + interest income + income before tax - income after tax + depreciation/amortization + unusual expense)
      Ev.ebitda <- ifelse(ebitda != 0, ev/ebitda, NA)
      # Ev/book = price/Book value per share 
      Ev.book <- ifelse(Fin_Q[end.date.financial, "bvps"] != 0, 
                        price/Fin_Q[end.date.financial, "bvps"], NA)
      # Ev/revenue = EV/Total Revenue  
      Ev.revenue <- ifelse(Fin_Q[end.date.financial, "revenue"] != 0, 
                           ev/Fin_Q[end.date.financial, "revenue"], NA)
      # Ev/cash = EV/Cash and Equivalents
      Ev.cash <- ifelse( Fin_Q[end.date.financial, "cashneq"] != 0, 
                         ev/Fin_Q[end.date.financial, "cashneq"], NA )
      # EquityAssets.liability = (Equity + Assets)/Liabilities
      EquityAssets.liability <- ifelse( Fin_Q[end.date.financial, "equity"] != 0 & Fin_Q[end.date.financial, "assets"] != 0 & 
                                          Fin_Q[end.date.financial, "liabilities"] != 0, 
                                   (Fin_Q[end.date.financial, "equity"]+Fin_Q[end.date.financial, "assets"])/Fin_Q[end.date.financial, "liabilities"], NA )
      SYMB_prices <- na.approx(SYMB_prices) # in case there are NA values use interpolation
      # prediction for current stock price and lower bound prediction for current stock price
      prediction.forecast <- Forecasting.ts(SYMB_prices, end.date.mod, apply.date.model)
      # Holt-Winters prediction for current stock price
      Price.Prediction.hw <- prediction.forecast[[1]]
      # Holt-Winters prediction for lower bound prediction for current stock price
      Price.Prediction.hwLB <- prediction.forecast[[2]]
      # Arima prediction for current stock price
      Price.Prediction.arima <- prediction.forecast[[3]]
      
      #plot(SYMB_prices)
      # Add a 200-day moving average using the lines command
      # lines(SMA(SYMB_prices, n = 200), col = "red")
      # Simple moving 200-day-average of the stock price
      sma.200 <- SMA(SYMB_prices$Close, n = 200)[end.date.mod]
      # Simple moving 50-day-average of the stock price
      sma.50 <- SMA(SYMB_prices$Close, n = 50)[end.date.mod]
      # Relative Strength Index over the last 10 days 
      rsi.10 <- RSI(SYMB_prices$Close, n = 10)[end.date.mod]
      # Relative Strength Index over the last 50 days 
      rsi.50 <- RSI(SYMB_prices$Close, n = 50)[end.date.mod]
      
      # DVO indicator 
      SYMB_prices_red <- SYMB_prices[ which(index(SYMB_prices) == index(SYMB_prices[ini.date.mod,])):
                                        which(index(SYMB_prices) == index(SYMB_prices[end.date.mod,])) ]
      dvo <- runPercentRank(SYMB_prices_red, n = dim(SYMB_prices_red)[1], exact.multiplier = 1)[end.date.mod] * 100
      
      if ( abs(apply.date.mod - apply.date.model) > 6 )  { # no stock information at prediction date
        price.apply.date.model = 0 # arbitrary number ----- THESE STOCKS NEED TO BE REMOVED WHEN ML MODEL IS CREATED
      } else { # stock information at prediction date
        price.apply.date.model = SYMB_prices[apply.date.mod,1] 
      } 
      
      return( list( stock,                            # stock symbol
                    price.apply.date.model,           # stock price at apply.date.model
                    Price.Min,                        # lowest stock price from end.date.model-months.min to end.date.model 
                    Price.Max,                        # highest stock price from end.date.model-months.min to end.date.model
                    price,                            # stock price at end.date.model
                    Price.Category,                   # stock price category at end.date.model
                    Assets,                           # Total assets at end.date.model 
                    ev,                               # Enterprise value at end.date.model 
                    Ev.earning,                       # EV/earnings at end.date.model
                    Ev.ebitda,                        # EV/EBITDA at end.date.model
                    Ev.book,                          # EV/book value at end.date.model
                    Ev.revenue,                       # EV/revenue at end.date.model
                    Ev.cash,                          # EV/total cash at end.date.model
                    EquityAssets.liability,           # Equity + Assets / liability at end.date.model
                    Price.Prediction.hw,              # Holt-Winters prediction for current stock price
                    Price.Prediction.hwLB,            # Holt-Winters prediction for lower bound prediction for current stock price
                    Price.Prediction.arima,           # Arima prediction for current stock price
                    sma.200,                          # Simple moving 200-day-average of the stock price
                    sma.50,                           # Simple moving 50-day-average of the stock price
                    rsi.10,                           # Relative Strength Index over the last 10 days 
                    rsi.50,                           # Relative Strength Index over the last 50 days 
                    dvo,                              # DVO indicator  
                    "temp"                            # Place-holder for industry stock belongs to
              )
      )
    } 
    else {
      print(paste(stock," does not have enough information at time end.date.model"))
      return(NA)
    }
  } 
  else {
    print(paste("Could not open files for ", stock))
    return(NA) 
  }
}

# Returns stock price prediction and a lower bound price using a Holt-Winters model 
# after a number of months
Forecasting.ts <- function(SYMB_prices, end.date.model, apply.date.model) {
  
  # Converting to monthly data (end of month)
  # SYMB_prices.mon <- daily2endMonth(SYMB_prices)
  temp = SYMB_prices[endpoints(SYMB_prices, on = "months"),]
  SYMB_prices.mon = data.frame(Date = index(temp), Open = temp$Open, High = temp$High, Low = temp$Low, Close = temp$Close)
  SYMB_prices.mon = tail(SYMB_prices.mon, 36) # only forecasting based on last 36 months !!!!!!!!!!!
  
  # Find the start of the quoted prices
  start <- c(as.numeric(format(SYMB_prices.mon[1,1], format = "%Y", tz = "", usetz = FALSE)),
             as.numeric(format(SYMB_prices.mon[1,1], format = "%m", tz = "", usetz = FALSE)))
  # Find the end of the quoted prices
  end <- c(as.numeric(format(end.date.model, format = "%Y", tz = "", usetz = FALSE)),
           as.numeric(format(end.date.model, format = "%m", tz = "", usetz = FALSE)))
  SYMB.ts <- ts(SYMB_prices.mon$Close, start = start, end = end, frequency = 12)
  
  # Do the Holt-Winters model with mult season option if it can
  SYMB.hw <- if (class(try(HoltWinters(SYMB.ts, seasonal = "mult"), silent = TRUE)) != "try-error") {
    HoltWinters(SYMB.ts, seasonal = "mult")
  } else if (class(try(HoltWinters(SYMB.ts, seasonal = "add"), silent = TRUE)) != "try-error") {
    HoltWinters(SYMB.ts, seasonal = "add")
  } else {
    return(c(NA,NA))
  }
  
  # Number of time steps ahead for prediction
  n.ahead <- (length(seq(from=end.date.model, to=apply.date.model, by='month'))-1)
  # Holt-Winters prediction
  SYMB.pred.HoWin <- forecast(SYMB.hw, h=n.ahead, level = c(90), allow.multiplicative.trend = TRUE)
  # Arima prediction
  SYMB.pred.arima <- forecast(auto.arima(SYMB.ts), h=n.ahead, level = c(90))
  
  # Returns prediction and lower bound prediction
  return( list(SYMB.pred.HoWin$mean[n.ahead], SYMB.pred.HoWin$lower[n.ahead],
               SYMB.pred.arima$mean[n.ahead]) )
}

# Function to plot prediction -- just to check
plot.Prediction <- function(stock, end.date.model, apply.date.model) {
  # Obtaining historical data
  SYMB_prices <- get.hist.quote(instrument=stock, 
                                quote="Close",provider="yahoo", 
                                compression="m", retclass="zoo", quiet=TRUE)
  
  # Find the start of the quoted prices
  start <- c(as.numeric(format(index(SYMB_prices)[1], format = "%Y", tz = "", usetz = FALSE)),
             as.numeric(format(index(SYMB_prices)[1], format = "%m", tz = "", usetz = FALSE)))
  # Find the end of the quoted prices
  end <- c(as.numeric(format(end.date.model, format = "%Y", tz = "", usetz = FALSE)),
           as.numeric(format(end.date.model, format = "%m", tz = "", usetz = FALSE)))
  
  SYMB.ts <- ts(SYMB_prices, start = start, end = end, freq=12)
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
  SYMB.predict <- predict(SYMB.hw, n.ahead = (length(seq(from=end.date.model, to=apply.date.model, by='month'))-1),
                          level = 0.9, prediction.interval = TRUE)
  SYMB.ts <- ts(SYMB_prices, start = start, freq=12)
  ts.plot(SYMB.ts, as.ts(SYMB.hw$fitted[,1]), SYMB.predict, lty = c(1,2,3,3,3)
          , xlab= "Time (months)", ylab = paste("Price", stock))
}

# Obsolete!!!!!!!! -----
# Function that takes a time series with daily data and returns a data frame including the last day of every month data
daily2endMonth <- function(daily.series) {
  
  # Data frame with date and numeric fields
  month.series <- data.frame(Date = numeric(0), Close = numeric(0))
  i <- 1
  while(i <= length(daily.series)) {
    # Obtaining for 1 month by subsetting
    month.data <- daily.series[as.numeric(format(index(daily.series[i]), format = "%Y")) == as.numeric(format(index(daily.series), format = "%Y"))
                             & as.numeric(format(index(daily.series[i]), format = "%m")) == as.numeric(format(index(daily.series), format = "%m")),]
    # Only add the last day of the month
    month.series[nrow(month.series) + 1, 2] <- tail(month.data,1)
    month.series[nrow(month.series), 1] <- index(tail(month.data,1))
    
    i <- i + length(month.data)
  }
  month.series$Date <- as.Date(month.series$Date)
  return(month.series)
}

