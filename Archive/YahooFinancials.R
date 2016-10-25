# Yahoo financial API
# https://query2.finance.yahoo.com/v10/finance/quoteSummary/STOCK_SYMBOL?modules=MODULE_NAME

# Not being used since yahoo data lacks number of shares outstanding!!!!!

# Possible modules
# assetProfile
# financialData
# defaultKeyStatistics
# calendarEvents
# incomeStatementHistory
# cashflowStatementHistory
# balanceSheetHistory

stock <-c("MSFT")
IS <- yahoo.financials(stock, "incomeStatementHistory")
netIncomeApplicableToCommonShares <- IS$quoteSummary$result[[1]]$incomeStatementHistory$incomeStatementHistory[[3]]$netIncomeApplicableToCommonShares$raw
BS <- yahoo.financials(stock, "balanceSheetHistory")
bookValue <- BS$quoteSummary$result[[1]]$balanceSheetHistory$balanceSheetStatements[[3]]$netTangibleAssets$raw
CF <- yahoo.financials(stock, "cashflowStatementHistory")



yahoo.financials <- function(stock, module) {
  # Load relevant packages
  library(rjson)
    # URLs for Yahoo Finance CSV API
  url.yahoo.finance.base <- 'https://query2.finance.yahoo.com/v10/finance/quoteSummary/'
  url <- paste(url.yahoo.finance.base, stock, '?modules=', module, sep='')
  json_data <- fromJSON(paste(readLines(url), collapse=""))
  return(json_data)
}
