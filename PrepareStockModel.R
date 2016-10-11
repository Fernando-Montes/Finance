# ----------------------------------------------------------
# Function to prepare stock model. Returns vector with
# model, train data and validation data
# It uses PrepareTable.R 
# ----------------------------------------------------------

# Stock info available in table
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

prepare.model <- function(table) {
  
  # Dividing table into training and test data  ---------------
  inTrain <- createDataPartition(table$actual.win.loss, list = FALSE, p = 0.7)
  my_train <- table[inTrain,]
  my_val <- table[-inTrain,]
  
  table$Price.Category <- factor(table$Price.Category, levels = levels(table$Price.Category))
  
  # Regression using generalized linear regression or gbm ------------
  my_model <- train(
    actual.win.loss ~ Price.Model.end.low.ratio + Price.Model.end.high.ratio + Price.Model.end + Assets +
      Ev.earning + Ev.ebitda + Ev.book + Ev.revenue + Ev.cash + Price.equity.debt +
      predicted.win.loss + predictedLB.win.loss + SectorIndustry.Num, 
    method ="gbm", data = my_train, train.fraction = 0.5)
  
  return(list(my_model, my_train, my_val))
  
}

