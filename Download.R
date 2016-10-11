# ----------------------------------------------------------
# Program to download financial info from google and yahoo 
# and save it to disk to be accessed later 
# It uses SymbolBySector.R 
# ----------------------------------------------------------

# Load relevant packages
library(tseries)
library(quantmod)

targetPath <- "~/Dropbox/Courses/R/Finance/Downloads/"

# Loading additional functions
source('~/Dropbox/Courses/R/Finance/SymbolBySector.R')

# ----------- Relevant functions ----------------
# Returns data frame with Sector.Name, Sector.Num, Industry.Name, Industry.Num
listAll <- list.sectors.industries()

# Saving all the sector-industry information
fileName <- paste(targetPath, "SectorIndustryInfo.RData", sep="")
save(listAll, file = fileName)

# --------
# Return a dataframe of companies in the specified sector. Note that sector is a numeric ID 
# as provided by the dataframe returned by list.sectors.industries().
# sector.All.companies(sector num)
# --------
# Return a dataframe of companies in the specified industry. Note that industry is a numeric ID 
# as provided by the  dataframe returned by list.sectors.industries().
# industry.All.companies(industry num)

# Creating a table with the stock info  --------------------
stockInfo <- data.frame(Stock.SYM = character(0),
                    Sector.Num = numeric(0),
                    Industry.Num = numeric(0), stringsAsFactors=FALSE
)

# ---------------------------------------------------------------------------
# Creating data frame with all stock symbols, sector and industry numbers
# ---------------------------------------------------------------------------
stockInfoAll <- stockInfo
for (j in 1:length(listAll[,1])) {
  # Selecting stocks of this sector-industry
  stock <- industry.All.companies(listAll[j,4])
  if (length(stock) > 0) {
    for (i in 1:length(stock)) {
      stockInfoAll[nrow(stockInfoAll) + 1, ] <- c(stock[i], listAll[j,2], listAll[j,4])
    }
  }
}
# Deleting duplicated rows
stockInfoAll <- stockInfoAll[!duplicated(stockInfoAll), ]

# Saving data frame with all stock symbols, sector and industry numbers
fileName <- paste(targetPath, "StockInfoAll.RData", sep="")
save(stockInfoAll, file = fileName)

# ---------------------------------------------------------------------------
# Creating data frame with stock symbols, sector and industry numbers that have information 
# ---------------------------------------------------------------------------
fileName <- paste(targetPath, "StockInfoAll.RData", sep="")
load(file = fileName)

for (i in 1:length(stockInfoAll[,1])) {
#for (i in 1:length(missing[,1])) {
    
  print(i)
  stock <- stockInfoAll[i,1]
  
  # if there is information online from both yahoo and google
  if ( class(try(get.hist.quote(instrument=stock, quote="AdjClose", provider="yahoo", compression="m", retclass="zoo", quiet=TRUE), silent = TRUE)) != "try-error" &
       class(try(getFinancials(stock, auto.assign = FALSE), silent = TRUE)) != "try-error" ) {
    
    # Obtaining historical stock price data
    SYMB_prices <- get.hist.quote(instrument=stock, quote="AdjClose",provider="yahoo", compression="m", retclass="zoo", quiet=TRUE)
    # Code to write info
    fileName <- paste(targetPath, stock, "-prices.RData", sep="")
    save(SYMB_prices, file = fileName)
    
    # Obtaining stock financial info
    FinStock <- getFinancials(stock, auto.assign = FALSE)
    # Code to write info
    fileName <- paste(targetPath, stock, "-FinStock.RData", sep="")
    save(FinStock, file = fileName)
    
    stockInfo[nrow(stockInfo) + 1, ] <- c(stock, stockInfoAll[i,2], stockInfoAll[i,3])
  }
}  

# Deleting duplicated rows
stockInfo <- stockInfo[!duplicated(stockInfo), ]
# Saving data frame with stock symbols, sector and industry numbers that have information 
fileName <- paste(targetPath, "StockInfo.RData", sep="")
save(stockInfo, file = fileName)


# -----------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------- 
# Dataframe to make sure companies do not have info  
missing <- rbind(stockInfoAll, stockInfo)
missing <- missing[!duplicated(missing) & !duplicated(missing, fromLast = TRUE), ]
  
# -----------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------
# Code to check if google is back to normal (after captcha message)
stock <- stockInfoAll[1,1]
getFinancials(stock, auto.assign = FALSE)
tryCatch( getFinancials(stock, auto.assign = FALSE),  error = function(err) {
  if(err$message == "cannot open the connection") { print("503 Service Unavailable")
    stop("Google captcha") } })
# Code to check in which number to continue
stockInfoAll[stockInfoAll[,1] == stockInfo[length(stockInfo[,1]),1],]

# -----------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------
# Code to read info back
fileName <- paste(targetPath, stock, "-prices.RData", sep="")
fileName <- paste(targetPath, stock, "-FinStock.RData", sep="")
fileName <- paste(targetPath, "StockInfoAll.RData", sep="")
load(file = fileName)