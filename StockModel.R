# ----------------------------------------------------------
# StockModel.R is the main file
# It uses PrepareTable.R to construct tables with stock information
# It uses PrepareStockModel.R to construct stock model (and indirectly StockInfo.R)
# It uses saved info that has been previously created by running Download.R
# ----------------------------------------------------------

# Finance packages available in R:
# https://cran.r-project.org/web/views/Finance.html

# Load relevant packages
library(quantmod)
library(PerformanceAnalytics)
library(zoo)
library(tseries)
library(ggplot2)
library(caret)
library(forecast)  # Holt-Winters and Arima forecasting method
# Parallel computing
library(doParallel)
registerDoParallel(cores=4)

# Sourcing prepare.table function
source('~/Dropbox/Courses/R/Finance/PrepareTable.R')
# Sourcing prepare.table.sector function
source('~/Dropbox/Courses/R/Finance/PrepareTableSector.R')
# Sourcing prepare.model function
source('~/Dropbox/Courses/R/Finance/PrepareStockModel.R')

# Load data frame with Sector.Name, Sector.Num, Industry.Name, Industry.Num into listAll
load(file = "~/Dropbox/Courses/R/Finance/Downloads/SectorIndustryInfo.RData")
# Load stock, sector and industry information into StockInfo
load(file = "~/Dropbox/Courses/R/Finance/Downloads/StockInfo.RData")

# -----------------------------------------------------------------
# Creating stock model --------------------------------------------
# -----------------------------------------------------------------

# The model will be trained up to end.date.model. This date is currently set by earliest financial
# quaterly data from google financial
end.date.model <- as.Date("2015/06/30")   # Final date the model is prepared -- should be end of month
ini.date.model <- as.Date("2013/06/03")   # Initial date the model is prepared
apply.date.model <- as.Date("2016/09/30") # Date the model is designed to predict win/loss performance -- should be end of month

# Prepare table with stock info
table <- prepare.table(stockInfo, end.date.model, ini.date.model, apply.date.model)
# Removing stocks that may have problems
table.mod <- table[table$Price.Model.end > 0.01 & table$Price.Min > 0.01,]
# Adding to table valuations compared to peers
table.mod <- prepare.table.sector(table.mod) 

# Creating stock model
modelResult <- prepare.model(table.mod)
my_model <- modelResult[[1]]
my_train <- modelResult[[2]] 
my_val <- modelResult[[3]]

# Comparing models
resampleHist(my_model)
my_model_ranger <- my_model
my_model_gbm <- my_model
model_list <- list(ranger = my_model_ranger, gbm = my_model_gbm)
resamples <- resamples(model_list)
summary(resamples)
xyplot(resamples)

# Understanding the data model was created with
ggplot(table, aes(x=Price.earning, y=actual.win.loss)) + geom_point(alpha = 0.1) + geom_smooth() + xlim(c(-250, 250))
ggplot(table, aes(x=Price.book, y=actual.win.loss)) + geom_point(alpha = 0.1) + geom_smooth() + xlim(c(-10, 10))
ggplot(table, aes(x=Ev.ebitda, y=actual.win.loss)) + geom_point(alpha = 0.1) + geom_smooth() + xlim(c(-100, 100))
ggplot(table, aes(x=Price.Model.end.low.ratio, y=actual.win.loss)) + geom_point(alpha = 0.1) + 
  geom_smooth() + xlim(c(0, 10))
ggplot(table, aes(x=Price.Model.end.high.ratio, y=actual.win.loss)) + geom_point(alpha = 0.1) + 
  geom_smooth() + xlim(c(0, 1))
ggplot(table, aes(x=predicted.win.loss, y=actual.win.loss)) + geom_point(alpha = 0.1) +
  geom_smooth() + xlim(c(-100, 100))

# Displaying model train results ------
my_train_res <- my_train
my_prediction_train <- predict(my_model, my_train)
my_train_res$model_pred <- my_prediction_train
# Calculating RMSE
sqrt(mean( (my_train_res$model_pred-my_train_res$actual.win.loss)^2 ))
p <- ggplot(my_train_res,
            aes(x=model_pred, y=actual.win.loss)) + xlim(c(-50, 100)) + ylim(c(-150, 301))
my_train_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='Train data') + coord_fixed(ratio=0.3)
# Displaying model validation results ------
my_val_res <- my_val
my_prediction_val <- predict(my_model, my_val)
my_val_res$model_pred <- my_prediction_val
# Calculating RMSE
sqrt(mean( (my_val_res$model_pred-my_val_res$actual.win.loss)^2 ))
p <- ggplot(my_val_res,
            aes(x=model_pred, y=actual.win.loss)) + xlim(c(-50, 100)) + ylim(c(-150, 301))
my_val_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='Validation data') + coord_fixed(ratio=0.3)

# Define grid layout to locate plots and print each graph
require(gridExtra)
png(file.path(path = "~/Dropbox/Courses/R/Finance/Figures/" , filename = "ranger_model2.png"), height = 450, width = 800)
grid_plot <- grid.arrange(my_train_plot, my_val_plot, ncol=2)
dev.off()

# Print top results
head(my_val_res[order(-my_val_res$model_pred),], 10)
res_val <- my_val_res[order(-my_val_res$model_pred),]
save(res_val, file = "~/Dropbox/Courses/R/Finance/Figures/Res_val.Rda")

# Important variables in the final model
plot(varImp(my_model))   # or
imp_par <- summary(my_model$finalModel)
save(imp_par, file = "~/Dropbox/Courses/R/Finance/Figures/imp_par2.Rda")

# ----------------------------------------------------------------
# Using the stock model -------------------------------------------
# -----------------------------------------------------------------

# The model will be trained up to end.date.model. This date is currently set by earliest financial
# quaterly data from google financial
end.date.model.new <- as.Date("2016/06/01")
ini.date.model.new <- as.Date("2015/06/01")   # Initial date the model is prepared
# Prepare table with stock info
table.new <- prepare.table(stockInfo, end.date.model.new, ini.date.model.new, apply.date.model.new)

# UPDATE!!!!!!

my_prediction.new <- predict(my_model, table.new)
table.new$model_pred <- my_prediction.new

head(table.new[order(-table.new$model_pred),], 10)