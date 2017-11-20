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
  
  targetPath1 <- "~/Dropbox/Courses/R/StockModel-I/Downloads_2017Aug/"  # price information
  targetPath2 <- "~/Dropbox/Courses/R/StockModel-I/Downloads_2016/"   # financial information
  
  for (i in 1:dim(table)[[1]]) {
    
    #print(i)
    stock <- table[i,1]  
    
    # Loading historical stock price data into SYMB_prices
    fileName <- paste(targetPath1, stock, "-prices.RData", sep="")
    try(load(file = fileName))
    # Loading stock financial info into FinStock
    fileName <- paste(targetPath2, stock, "-FinStock.RData", sep="")
    try(load(file = fileName))
    
    # Checking the dates are right and they exist
    if ( length(SYMB_prices[histo.date.model,])==1 ) {
      
      # Income statement
      FinIS <- viewFin(FinStock, period = 'Q', "IS")
      # Balance sheet
      FinBS <- viewFin(FinStock, period = 'Q', "BS")
      # Cash flow
      FinCF <- viewFin(FinStock, period = 'Q', "CF")
      
      # Finding if stock info at end.date.model (year and month) exists
      numCol <- return.numCol(FinIS, FinBS, histo.date.model)
      numIS <- numCol[[1]]
      numBS <- numCol[[2]]
      
      # Checking that there is enough historical information at time histo.date.model
      if ( numIS != 0 & numBS != 0) {
        
        # Stock price at histo.date.model 
        price <- as.numeric(SYMB_prices[index(SYMB_prices[histo.date.model,]),1])
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
        
        table$earning.histo[i] =        (table$Ev.earning[i]/table$Ev[i])/(Ev.earning/ev)
        table$ebitda.histo[i] =         (table$Ev.ebitda[i]/table$Ev[i])/(Ev.ebitda/ev)
        table$book.histo[i] =           (table$Ev.book[i]/table$Ev[i])/(Ev.book/ev)
        table$revenue.histo[i] =        (table$Ev.revenue[i]/table$Ev[i])/(Ev.revenue/ev)
        table$cash.histo[i] =           (table$Ev.cash[i]/table$Ev[i])/(Ev.cash/ev)
        table$equity.debt.histo[i] = (table$Price.equity.debt[i]/table$Price.Model.end[i])/(Price.equity.debt/price)
        
      } else {
        print(paste(stock," does not have enough historical financial information at time histo.date.model"))
      }
    } else {
      print(paste(stock," does not have enough stock price information"))
    }
  }
  table <- na.exclude(table)  # remove stocks that do not have historical financial information
  return(table)
}