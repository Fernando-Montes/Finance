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
  table$equity.debt.histo = NA
  
  targetPath <- "~/Dropbox/Courses/R/StockModel-I/ArchiveFin/"
  
  for (i in 1:dim(table)[[1]]) {
    
    # print(i)
    stock <- table[i,1]
    # print(stock)
    
    # Loading historical stock price data into SYMB_prices
    fileName1 <- paste(targetPath, stock, "-prices.RData", sep="")
    # Loading stock financial info into Fin_Q
    fileName2 <- paste(targetPath, stock, "-Fin_Q.RData", sep="")
    if ( class(try(load(file = fileName1), silent = TRUE)) != "try-error" & 
         class(try(load(file = fileName2), silent = TRUE)) != "try-error" ) {
      
      # Closest date earlier than histo.date.model
      temp = SYMB_prices[index(SYMB_prices) < histo.date.model,]
      histo.date.mod = index(SYMB_prices[which(abs((index(temp)-histo.date.model)) == min(abs(index(temp)-histo.date.model))),])
      
      # Closest financial quarter date earlier than histo.date.model
      temp = as.Date(Fin_Q$date)[as.Date(Fin_Q$date) < histo.date.model]
      if( length(temp) != 0) { histo.date.financial = temp[which(abs((temp-histo.date.model)) == min(abs(temp-histo.date.model)))] } 
      else { histo.date.financial = as.Date("1900-01-01") }
      
      # Checking that there is enough stock price information 1 year earlier (within 5 days)
      # and that there is enough financial information 1 year earlier (within 90 days)
      if ( abs(histo.date.mod - histo.date.model) < 10 & abs(histo.date.financial - histo.date.model) < 90 ) {
        
        rownames(Fin_Q) = Fin_Q$date   # renaming rows
        histo.date.financial = as.character(histo.date.financial)    
        # Stock price at histo.date.model 
        price <- as.numeric(SYMB_prices[index(SYMB_prices[histo.date.mod,]),4])
        # Number of outstanding shares at time end.date.model
        number.shares <- ifelse(is.na(Fin_Q[histo.date.financial, "Total Common Shares Outstanding"]), 0, 
                                Fin_Q[histo.date.financial, "Total Common Shares Outstanding"])
        if (number.shares == 0 ) { 
          print(paste(stock," does not have Common Shares Outstanding information"))
          ev = NA
        } else {
          # Enterprise value
          ev <- price*number.shares
        }
        # EBITDA = (net income + interest income + income before tax - income after tax
        #           + depreciation/amortization  + unusual expense)
        ebitda <- ifelse(is.na(Fin_Q[histo.date.financial,"Net Income"]), 0,
                         Fin_Q[histo.date.financial,"Net Income"]) +
          ifelse(is.na(Fin_Q[histo.date.financial,"Interest Income(Expense), Net Non-Operating"]), 0, 
                 Fin_Q[histo.date.financial,"Interest Income(Expense), Net Non-Operating"]) +
          ifelse(is.na(Fin_Q[histo.date.financial,"Income Before Tax"]), 0, 
                 Fin_Q[histo.date.financial,"Income Before Tax"]) -
          ifelse(is.na(Fin_Q[histo.date.financial,"Income After Tax"]), 0, 
                 Fin_Q[histo.date.financial,"Income After Tax"]) +
          ifelse(is.na(Fin_Q[histo.date.financial,"Depreciation/Amortization"]), 0,
                 Fin_Q[histo.date.financial,"Depreciation/Amortization"]) +
          ifelse(is.na(Fin_Q[histo.date.financial,"Unusual Expense (Income)"]), 0,
                 Fin_Q[histo.date.financial,"Unusual Expense (Income)"])
        
        # Ev/earning = price/diluted normalized EPS 
        Ev.earning <- ifelse(Fin_Q[histo.date.financial,"Diluted Normalized EPS"] != 0, 
                             price/Fin_Q[histo.date.financial,"Diluted Normalized EPS"], NA)
        # Ev/ebitda = EV/(net income + interest income + income before tax - income after tax
        #                + depreciation/amortization + unusual expense)
        Ev.ebitda <- ifelse(ebitda != 0, ev/ebitda, NA)
        # Ev/book = EV/total equity 
        Ev.book <- ifelse(Fin_Q[histo.date.financial,"Total Equity"] != 0, 
                          ev/Fin_Q[histo.date.financial,"Total Equity"], NA)
        # Ev/revenue = EV/Total Revenue 
        Ev.revenue <- ifelse(Fin_Q[histo.date.financial,"Total Revenue"] != 0, 
                             ev/Fin_Q[histo.date.financial,"Total Revenue"], NA)
        # Ev/cash = EV/Cash and Short Term Investments 
        Ev.cash <- ifelse(Fin_Q[histo.date.financial,"Cash and Short Term Investments"] != 0, 
                          ev/Fin_Q[histo.date.financial,"Cash and Short Term Investments"], NA)
        # Price.equity.debt = price/Total Equity/Total Debt
        Price.equity.debt <- ifelse(Fin_Q[histo.date.financial,"Total Debt"] != 0 & Fin_Q[histo.date.financial,"Total Equity"] != 0, 
                                    price*Fin_Q[histo.date.financial,"Total Debt"]/Fin_Q[histo.date.financial,"Total Equity"], NA)
        
        table$earning.histo[i] =        (table$Ev.earning[i]/table$Ev[i])/(Ev.earning/ev)
        table$ebitda.histo[i] =         (table$Ev.ebitda[i]/table$Ev[i])/(Ev.ebitda/ev)
        table$book.histo[i] =           (table$Ev.book[i]/table$Ev[i])/(Ev.book/ev)
        table$revenue.histo[i] =        (table$Ev.revenue[i]/table$Ev[i])/(Ev.revenue/ev)
        table$cash.histo[i] =           (table$Ev.cash[i]/table$Ev[i])/(Ev.cash/ev)
        table$equity.debt.histo[i] = (table$Price.equity.debt[i]/table$Price.Model.end[i])/(Price.equity.debt/price)
        
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