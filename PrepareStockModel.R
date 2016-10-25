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
  gbmGrid <- expand.grid(.interaction.depth = (1:5) * 2, .n.trees = (1:10)*20, .shrinkage = .1, .n.minobsinnode = (5:15) )
  my_model <- train(
    actual.win.loss ~ Price.Model.end.low.ratio + Price.Model.end.high.ratio + Price.Model.end + Assets +
      Ev.earning + Ev.ebitda + Ev.book + Ev.revenue + Ev.cash + Price.equity.debt +
      predicted.hw.win.loss + predicted.hwLB.win.loss + predicted.arima.win.loss + 
      Price.sma.200 + Price.sma.50 + rsi.10 + rsi.50 + dvo +
      Ev.earning.peers + Ev.ebitda.peers + Ev.book.peers + Ev.revenue.peers + Ev.cash.peers + Price.equity.debt.peers + 
      Price.sma.200.peers + Price.sma.50.peers, 
    method ="gbm", data = my_train, bag.fraction = 0.5, tuneGrid = gbmGrid,
    #method ="ranger", data = my_train, tuneLength = 10, importance = 'impurity',  #mtry can change from 1 to tuneLength
    #method ="glmnet", data = my_train, tuneGrid = expand.grid(alpha = seq(0, 1, length = 10), lambda = seq(0.0001, 1, length = 20)), preProcess = c("center", "scale"),
    trControl = trainControl(method = "cv", number = 10, repeats = 50, verboseIter = TRUE, allowParallel = TRUE)
    )
  
  return(list(my_model, my_train, my_val))
  
}

