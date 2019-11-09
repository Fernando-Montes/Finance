# ----------------------------------------------------------
# Function to add historical stock information. Returns modified table.
# Add variables (columns) with valuations of a given stock compared
# to performance at histo.date.model (should be a year earlier than end.date.model)
# ----------------------------------------------------------

# Adds historical stock information to a table. Info added:
# ----- EV = price*number outstanding shares
# -----
# Total assets at histo.date.model 
# EV/earnings at end.date.model / EV/earnings at histo.date.model
# EV/EBITDA at end.date.model / EV/EBITDA at histo.date.model
# EV/book value at end.date.model / EV/book value at histo.date.model
# EV/revenue at end.date.model  / EV/revenue at histo.date.model
# EV/total cash at end.date.model  / EV/total cash at histo.date.model
# price/(equity/debt) at end.date.model / price/(equity/debt) at histo.date.model

add.histo.to.table <- function(table, histo.date.model) {
  
  # Adding columns to table and initializing to zero
  table$earning.histo =     NA
  table$ebitda.histo =      NA
  table$book.histo =        NA
  table$revenue.histo =     NA
  table$cash.histo =        NA
  table$equityAssets.liability.histo = NA
  
  for (i in 1:dim(table)[[1]]) {
    
    #print(i)
    stock <- table[i,1]
    #print(stock)
    
    # Loading historical stock price data into SYMB_prices
    fileName1 <- paste(targetPath, stock, "-prices.RData", sep="")
    # Selecting only financial data of the stock
    Fin_Q = indicatorTable[indicatorTable$ticker == stock,]
    
    if ( class(try(load(file = fileName1), silent = TRUE)) != "try-error" &
         dim(Fin_Q)[1] != 0 & index(SYMB_prices)[1] < histo.date.model ) {
      
      # Closest date earlier than histo.date.model
      temp = SYMB_prices[index(SYMB_prices) < histo.date.model,]
      histo.date.mod = index(SYMB_prices[which(abs((index(temp)-histo.date.model)) == min(abs(index(temp)-histo.date.model))),])
      
      # Closest financial quarter date earlier than histo.date.model
      temp = as.Date(Fin_Q$calendardate)[as.Date(Fin_Q$calendardate) < histo.date.model]
      if( length(temp) != 0) { histo.date.financial = temp[which(abs((temp-histo.date.model)) == min(abs(temp-histo.date.model)))] } 
      else { histo.date.financial = as.Date("1900-01-01") }
      
      # Checking that there is enough stock price information 1 year earlier (within 5 days)
      # and that there is enough financial information 1 year earlier (within 90 days)
      if ( abs(histo.date.mod - histo.date.model) < 10 & abs(histo.date.financial - histo.date.model) < 95 ) {
        
        rownames(Fin_Q) = Fin_Q$calendardate   # renaming rows
        histo.date.financial = as.character(histo.date.financial)    
        # Stock price at histo.date.model 
        price <- as.numeric(SYMB_prices[index(SYMB_prices[histo.date.mod,]),4])
        # Number of outstanding shares at time end.date.model
        number.shares <- ifelse(is.na(Fin_Q[histo.date.financial, "shareswa"]), 0, 
                                Fin_Q[histo.date.financial, "shareswa"])
        if (number.shares == 0 ) { 
          print(paste(stock," does not have Common Shares Outstanding information"))
          ev = NA
        } else {
          # Enterprise value
          ev <- price*number.shares
        }
        # EBITDA = (net income + interest income + income before tax - income after tax
        #           + depreciation/amortization  + unusual expense)
        ebitda <-ifelse(is.na(Fin_Q[histo.date.financial, "ebitda"]), 0, 
                        Fin_Q[histo.date.financial, "ebitda"])
        
        # Ev/earning = price/EPS 
        Ev.earning <- ifelse(Fin_Q[histo.date.financial, "eps"] != 0, 
                             price/Fin_Q[histo.date.financial, "eps"], NA)
        # Ev/ebitda = EV/(net income + interest income + income before tax - income after tax + depreciation/amortization + unusual expense)
        Ev.ebitda <- ifelse(ebitda != 0, ev/ebitda, NA)
        # Ev/book = price/Book value per share 
        Ev.book <- ifelse(Fin_Q[histo.date.financial, "bvps"] != 0, 
                          price/Fin_Q[histo.date.financial, "bvps"], NA)
        # Ev/revenue = EV/Total Revenue  
        Ev.revenue <- ifelse(Fin_Q[histo.date.financial, "revenue"] != 0, 
                             ev/Fin_Q[histo.date.financial, "revenue"], NA)
        # Ev/cash = EV/Cash and Equivalents
        Ev.cash <- ifelse( Fin_Q[histo.date.financial, "cashneq"] != 0, 
                           ev/Fin_Q[histo.date.financial, "cashneq"], NA )
        # EquityAssets.liability = (Equity + Assets)/Liabilities
        EquityAssets.liability <- ifelse( Fin_Q[histo.date.financial, "equity"] != 0 & Fin_Q[histo.date.financial, "assets"] != 0 & 
                                            Fin_Q[histo.date.financial, "liabilities"] != 0, 
                                          (Fin_Q[histo.date.financial, "equity"]+Fin_Q[histo.date.financial, "assets"])/Fin_Q[histo.date.financial, "liabilities"], NA )
        
        table$earning.histo[i] =        (table$Ev.earning[i]/table$Ev[i])/(Ev.earning/ev)
        table$ebitda.histo[i] =         (table$Ev.ebitda[i]/table$Ev[i])/(Ev.ebitda/ev)
        table$book.histo[i] =           (table$Ev.book[i]/table$Ev[i])/(Ev.book/ev)
        table$revenue.histo[i] =        (table$Ev.revenue[i]/table$Ev[i])/(Ev.revenue/ev)
        table$cash.histo[i] =           (table$Ev.cash[i]/table$Ev[i])/(Ev.cash/ev)
        table$equityAssets.liability.histo[i] = (table$EquityAssets.liability[i])/(EquityAssets.liability)
        
      } else {
        print(paste(stock," does not have enough information at time histo.date.model"))
      }
    } else {
      print(paste("Could not open files for ", stock))
    }
  }
  table <- na.exclude(table)  # remove stocks that do not have historical financial information
  return(table)
}