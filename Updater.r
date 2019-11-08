#!/usr/local/bin/Rscript

# usage: ./Updater.r -v 1 -s 1 -i 1 -p 1 -t 1 -m 1

# options:
# -v verbose
# -s update stocks within an industry
# -p update prices
# -i update indicators
# -t update table
# -m update model predictions

suppressPackageStartupMessages(require(optparse)) # don't say "Loading required package: optparse"

option_list = list(
  make_option(c("-v", "--verbose"), action="store", default=0, type='numeric',
              help="Set -v 1 so it uses verbose"),
  make_option(c("-s", "--stock"), action="store", default=0, type='numeric',
              help="Set -s 1 to update list of stocks to be used"),
  make_option(c("-i", "--indicator"), action="store", default=0, type='numeric',
              help="Set -i 1 to update indicators"),
  make_option(c("-p", "--prices"), action="store", default=0, type='numeric',
              help="Set -p 1 to update stock prices"),
  make_option(c("-t", "--table"), action="store", default=0, type='numeric',
              help="Set -t 1 to update indicator/price table"),
  make_option(c("-m", "--model"), action="store", default=0, type='numeric',
              help="Set -m 1 to update model table")
)
opt = parse_args(OptionParser(option_list=option_list))

verbose = opt$verbose             # -v
update.Stocks = opt$stock         # -s   
update.Indicators = opt$indicator # -i
update.Prices = opt$prices        # -p
update.Table = opt$table          # -t
update.Model = opt$model          # -m

# Loading libraries
suppressPackageStartupMessages(library(quantmod))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tseries))
suppressPackageStartupMessages(library(zoo))
suppressPackageStartupMessages(library(forecast))
suppressPackageStartupMessages(library(doParallel))
suppressPackageStartupMessages(library(TTR))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(caret))
suppressPackageStartupMessages(library(gbm))
suppressPackageStartupMessages(library(Quandl))
suppressPackageStartupMessages(library(jsonlite))

registerDoParallel(cores = 4)

targetPath = "~/Dropbox/Courses/R/StockModel-2/ArchiveFin/"

# Updating indicators
if (update.Indicators == 1) { # Update indicators
  pass <- file("~/Dropbox/Courses/R/StockModel-2/QuandlPass","r")
  quandl_key <- readLines(pass,n=1)
  close(pass)
  Quandl.api_key(quandl_key)
  indicatorTable <- Quandl.datatable("SHARADAR/SF1", paginate = TRUE, dimension = "ARQ")
  fileName <- paste(targetPath, "indicatorTable.RData", sep="")
  save(indicatorTable, file = fileName)
}

# Updating list of stocks
if (update.Stocks == 1) {
  # Loading additional functions
  source('~/Dropbox/Courses/R/StockModel-2/SymbolBySector.R')
  stockInfoAll = obtainStockInfoAll()
  fileName <- "~/Dropbox/Courses/R/StockModel-2/ArchiveFin/StockInfoAll.RData"
  save(stockInfoAll, file = fileName)
} else{
  # Loading list of stocks into stockInfoAll 
  fileName <- paste(targetPath, "StockInfoAll.RData", sep="")
  load(file = fileName)
}

# Updating prices
prices.updated = 0
if (update.Prices == 1) { 
  # Creating a table with the stock info that has price information only  --------------------
  stockInfo <- data.frame(Stock.SYM = character(0),
                          Sector = character(0),
                          Industry = character(0), 
                          Website = character(0),
                          Summary = character(0), 
                          Name = character(0),
                          stringsAsFactors=FALSE
  )
  # Loop over all stocks
  noStocks = dim(stockInfoAll)[1]
  sample.stockInfoAll = sample_n(stockInfoAll, noStocks)  # Randomly sample stocks to be updated
  for (i in 1:noStocks) {
    # for (i in 1:10) {
    stock = sample.stockInfoAll[i,"Stock.SYM"]
    if (verbose == 1) print( paste("Stock ", stock, " , loop step ", i, " out of ", noStocks)  )
    if ( class( try( SYMB_prices <- get.hist.quote(instrument=stock, quote=c("Open", "High", "Low", "Close"), provider="yahoo", compression="d", retclass="zoo", quiet=TRUE), 
                     silent = TRUE) ) != "try-error" ) {
      prices.updated = prices.updated + 1
      if ( dim(SYMB_prices)[1]>10 ) {
        # Code to write info
        fileName <- paste(targetPath, stock, "-prices.RData", sep="")
        save(SYMB_prices, file = fileName)
        stockInfo = rbind(stockInfo, sample.stockInfoAll[i,])
      }
    }
  }
  fileName <- paste(targetPath, "StockInfo.RData", sep="")
  save(stockInfo, file = fileName)
}

# TEMP ------------------------------
# Replace Sys.Date() with sysDate

for (sysDate in seq(as.Date("2019-11-07"), as.Date("2019-11-07"), by="days")) {
  sysDate = as.Date(sysDate)

# Updating table
if (update.Table == 1) {  

  # Loop over 1...6 months ago
  for (i in c(5,10,30)) {
    
    # Load indicatorTable
    fileName2 <- paste(targetPath, "indicatorTable.RData", sep="")
    load(file = fileName2)
    
    # Table today ----- 
    end.date.model = sysDate                        # Today
    ini.date.model = end.date.model %m-% months(6)     # 6 months before to start modeling
    histo.date.model = end.date.model - years(1)       # Model is compared to historical info (1 year earlier)
    apply.date.model = end.date.model + days(i)   # months ahead
    # Prepare table with stock info
    source('~/Dropbox/Courses/R/StockModel-2/PrepareTable.R')          # source prepare table
    table.model <- prepare.table(stockInfoAll, end.date.model, ini.date.model, apply.date.model)
    # Removing stocks that may have problems
    table.model <- table.model[table.model$Price.Model.end > 0.01 & table.model$Price.Min > 0.01,]
    # Adding to table valuations compared to peers
    source('~/Dropbox/Courses/R/StockModel-2/PrepareTableSector.R')    # source prepare.table.sector function
    table.model <- prepare.table.sector(table.model) 
    # Adding historical financial status comparison
    source('~/Dropbox/Courses/R/StockModel-2/StockInfoHistorical.R')   # source add.histo.to.table function
    table.model <- add.histo.to.table(table.model, histo.date.model)
    # Saving table.model
    save(table.model, file = paste(targetPath, as.character(sysDate), "+", i, "d.Rdata", sep = ""))
    
    end.date.model = sysDate - days(i)              # model run today - i months
    ini.date.model = end.date.model %m-% months(6)     # 6 months before to start modeling
    histo.date.model = end.date.model - years(1)       # Model is compared to historical info (1 year earlier)
    apply.date.model = sysDate                      # Today
    # Prepare table with stock info
    table.model <- prepare.table(stockInfoAll, end.date.model, ini.date.model, apply.date.model)
    # Removing stocks that may have problems
    table.model <- table.model[table.model$Price.Model.end > 0.01 & table.model$Price.Min > 0.01 & table.model$actual.win.loss != -100,]
    # Adding to table valuations compared to peers
    table.model <- prepare.table.sector(table.model) 
    # Adding historical financial status comparison
    table.model <- add.histo.to.table(table.model, histo.date.model)
    # Saving table.model
    save(table.model, file = paste(targetPath, as.character(sysDate), "-", i, "d.Rdata", sep = ""))
  }
}

# Updating model
if (update.Model == 1) {  
  # Loading the most recent indicator table table.model
  targetPath <- "~/Dropbox/Courses/R/StockModel-2/ArchiveFin/"
  date.today = sysDate  
  temp = list.files(targetPath, pattern = "2019-*") # All the files that may contain indicator information
  diffDate = 20   # Obtain the most recent date less than 20 days
  for (i in 1:length(temp) ) {
    if( length(strsplit(temp[i],"")[[1]])==19 ) { # Correct filename length 
      tempDate = as.Date(substr(temp[i],1,10)) # Extract date file was created
      if (date.today - tempDate < diffDate & date.today - tempDate >= 0) { # Obtain the most recent date less than 20 days
        diffDate = date.today - tempDate 
        date.file = tempDate     
      }
    }
  }
  
  # Sourcing prepare.model function
  source('~/Dropbox/Courses/R/StockModel-2/PrepareStockModel.R')
  # Creating stock model with multiple methods ----------------------
  
  # Loop over the different models 5, 10, 30 days
  for (i in c(5,10,30)) {

    # Open table for today's table
    fileName <- paste(targetPath, date.file, "+", i, "d.Rdata", sep = "") 
    load(file = fileName)
    table.pred = table.model
    
    fileName <- paste(targetPath, date.file, "-", i, "d.Rdata", sep = "") 
    load(file = fileName)
    
    # Dividing table into training and test data  ---------------------
    set.seed(235)
    inTrain <- createDataPartition(table.model$actual.win.loss, list = FALSE, p = 0.7)
    my_train <- table.model[inTrain,]
    my_val <- table.model[-inTrain,]
    model_ranger <- prepare.model(my_train, "ranger")    # Model ranger
    my_val$ranger_pred <- predict(model_ranger, my_val)
    model_gbm <- prepare.model(my_train, "gbm")          # Model gbm 
    my_val$gbm_pred <- predict(model_gbm, my_val)
    model_glmnet <- prepare.model(my_train, "glmnet")    # Model glmnet
    my_val$glmnet_pred <- predict(model_glmnet, my_val)
    save(my_val, file = paste(targetPath, date.file, "-", i, "d-validation.Rdata", sep = ""))
    variableImportance = list(varImp(model_ranger), varImp(model_gbm), varImp(model_glmnet))
    save(variableImportance, file = paste(targetPath, date.file, "-", i, "d-varImp.Rdata", sep = ""))
    
    # Using created model to make predictions
    table.pred[, paste("ranger_pred_", i, sep="")] <- predict(model_ranger, table.pred)
    table.pred[, paste("gbm_pred_", i, sep="")] <- predict(model_gbm, table.pred)
    table.pred[, paste("glmnet_pred_", i, sep="")] <- predict(model_glmnet, table.pred)
    save(table.pred, file = paste(targetPath, date.file, "+", i, "d-pred.Rdata", sep = ""))
  }
  
}
} # TEMP --------------
  
if (verbose == 1) {
  print( paste( "dim(stockInfoAll) ", dim(stockInfoAll) )  )
  print( paste( "Prices updated = ", prices.updated )  )
  if (update.Table == 1) { print( paste( "Table items  = ", dim(table.model)[1] )  ) }
  else { print("no table created") }
}
