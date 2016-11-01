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

# Loading info to be used ----------------------------------------
# Load data frame with Sector.Name, Sector.Num, Industry.Name, Industry.Num into listAll
load(file = "~/Dropbox/Courses/R/Finance/Downloads/SectorIndustryInfo.RData")
# Load stock, sector and industry information into StockInfo
load(file = "~/Dropbox/Courses/R/Finance/Downloads/StockInfo.RData")

# Sourcing functions ----------------------------------------------
source('~/Dropbox/Courses/R/Finance/PrepareTable.R')
# Sourcing prepare.table.sector function
source('~/Dropbox/Courses/R/Finance/PrepareTableSector.R')
# Sourcing prepare.model function
source('~/Dropbox/Courses/R/Finance/PrepareStockModel.R')

# Creating table to be used to create model -----------------------

# The model will be trained up to end.date.model. This date is currently set by earliest financial
# quaterly data from google financial
ini.date.model <- as.Date("2014/03/03")   # Initial date the model is prepared
end.date.model <- as.Date("2016/03/31")   # Final date the model is prepared -- should be end of month
apply.date.model <- as.Date("2016/06/30") # Date the model is designed to predict win/loss performance -- should be end of month

# Prepare table with stock info
table.model <- prepare.table(stockInfo, end.date.model, ini.date.model, apply.date.model)
# Removing stocks that may have problems
table.model <- table.model[table.model$Price.Model.end > 0.01 & table.model$Price.Min > 0.01,]
# Adding to table valuations compared to peers
table.model <- prepare.table.sector(table.model) 
# Saving table.model
save(table.model, file = "~/Dropbox/Courses/R/Finance/Figures/Table-3m_2016-06-30.Rda")
load("~/Dropbox/Courses/R/Finance/Figures/Table-3m_2016-06-30.Rda") # loads table.model

# Trying things
# table.model <- table.model[table.model$Price.Category == "3",]

# Understanding the data model was created with ---------
# ggplot(table.model, aes(x=Price.earning, y=actual.win.loss)) + geom_point(alpha = 0.1) + geom_smooth() + xlim(c(-250, 250))
# ggplot(table.model, aes(x=Price.book, y=actual.win.loss)) + geom_point(alpha = 0.1) + geom_smooth() + xlim(c(-10, 10))
# ggplot(table.model, aes(x=Ev.ebitda, y=actual.win.loss)) + geom_point(alpha = 0.1) + geom_smooth() + xlim(c(-100, 100))
# ggplot(table.model, aes(x=Price.Model.end.low.ratio, y=actual.win.loss)) + geom_point(alpha = 0.1) + 
#   geom_smooth() + xlim(c(0, 10))
# ggplot(table.model, aes(x=Price.Model.end.high.ratio, y=actual.win.loss)) + geom_point(alpha = 0.1) + 
#   geom_smooth() + xlim(c(0, 1))
# ggplot(table.model, aes(x=predicted.win.loss, y=actual.win.loss)) + geom_point(alpha = 0.1) +
#   geom_smooth() + xlim(c(-100, 100))

# Dividing table into training and test data  ---------------------
set.seed(235)
inTrain <- createDataPartition(table.model$actual.win.loss, list = FALSE, p = 0.7)
my_train <- table.model[inTrain,]
my_val <- table.model[-inTrain,]

# Creating stock model with multiple methods ----------------------

model_ranger <- prepare.model(my_train, "ranger")    # Model ranger
my_val$ranger_pred <- predict(model_ranger, my_val)

model_gbm <- prepare.model(my_train, "gbm")          # Model gbm 
my_val$gbm_pred <- predict(model_gbm, my_val)

model_glmnet <- prepare.model(my_train, "glmnet")    # Model glmnet
my_val$glmnet_pred <- predict(model_glmnet, my_val)

# Creating table with rankings from the different methods
ordered_actual <-      my_val[order(my_val$actual.win.loss),]
ordered_ranger <-      my_val[order(my_val$ranger_pred),]  #Ranger
ordered_gbm    <-      my_val[order(my_val$gbm_pred),]     #GBM
ordered_glmnet <-      my_val[order(my_val$glmnet_pred),]  #GLMNET
rank.robust <- data.frame(Stock.SYM = character(0), rank_ranger = numeric(0), rank_gbm = numeric(0), rank_glmnet = numeric(0), 
                          rank_actual = numeric(0), actual.win.loss = numeric(0), stringsAsFactors=FALSE)
for (i in 1:length(ordered_ranger$Stock.SYM)) {
  rank.robust[i,] <- list(ordered_ranger$Stock.SYM[i],                                                                         #Name stock
                          100.*i/length(ordered_ranger$Stock.SYM),                                                             #Rank ranger
                          100.*match(ordered_ranger$Stock.SYM[i], ordered_gbm$Stock.SYM)/length(ordered_ranger$Stock.SYM),     #Rank gbm
                          100.*match(ordered_ranger$Stock.SYM[i], ordered_glmnet$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank glmnet 
                          100.*match(ordered_ranger$Stock.SYM[i], ordered_actual$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank actual
                          ordered_ranger$actual.win.loss[i])                                                                   #Actual win-loss
}
# rank.robust <- na.exclude(rank.robust)
ggplot(rank.robust, aes(x=rank_ranger, y=rank_glmnet, color=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  labs(title='glmnet vs Ranger')+ xlab("Ranger rank [%]") + ylab("glmnet rank [%]") + 
  xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
ggplot(rank.robust, aes(x=((rank_ranger+rank_gbm+rank_glmnet)/3), y=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  labs(title='Actual vs Average rank pred.')+ xlab("Average rank [%]") + ylab("Actual rank [%]") + 
  xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)

# Best predictions from the different methods  
temp <- rank.robust[rank.robust$rank_ranger > 90 & rank.robust$rank_gbm > 87 & rank.robust$rank_glmnet > 90, ]
temp <- rank.robust[(rank.robust$rank_ranger + rank.robust$rank_gbm + rank.robust$rank_glmnet)/3 > 97, ]
save(temp, file = "~/Dropbox/Courses/R/Finance/Figures/Companies90_2015-06-30.Rda")
rank.robust[rank.robust$rank_ranger < 5 & rank.robust$rank_gbm < 5 & rank.robust$rank_glmnet < 5, ]

# Comparing RMS from the different methods
model_list <- list(ranger = model_ranger, gbm = model_gbm)
resamples <- resamples(model_list)
summary(resamples)
xyplot(resamples)

# Understanding stock model ---------------------------------------

# my_model <- model_ranger # Preferred method
# 
# # Show RMS for the method
# resampleHist(my_model)
# 
# # Displaying model train results
# my_train_res <- my_train
# my_prediction_train <- predict(my_model, my_train)
# my_train_res$model_pred <- my_prediction_train
# # Calculating RMSE
# sqrt(mean( (my_train_res$model_pred-my_train_res$actual.win.loss)^2 ))
# p <- ggplot(my_train_res,
#             aes(x=model_pred, y=actual.win.loss)) + xlim(c(-50, 100)) + ylim(c(-150, 301))
# my_train_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='Train data') + coord_fixed(ratio=0.3)
# # Displaying model validation results
# my_val_res <- my_val
# my_prediction_val <- predict(my_model, my_val)
# my_val_res$model_pred <- my_prediction_val
# # Calculating RMSE
# sqrt(mean( (my_val_res$model_pred-my_val_res$actual.win.loss)^2 ))
# p <- ggplot(my_val_res,
#             aes(x=model_pred, y=actual.win.loss)) + xlim(c(-50, 100)) + ylim(c(-150, 301))
# my_val_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='Validation data') + coord_fixed(ratio=0.3)
# 
# # Define grid layout to locate plots and print each graph
# require(gridExtra)
# png(file.path(path = "~/Dropbox/Courses/R/Finance/Figures/" , filename = "GBM_timeHorizon3_redVar.png"), height = 450, width = 800)
# grid_plot <- grid.arrange(my_train_plot, my_val_plot, ncol=2)
# dev.off()
# 
# # Print top results
# head(my_val_res[order(-my_val_res$model_pred),], 10)
# res_val <- my_val_res[order(-my_val_res$model_pred),]
# save(res_val, file = "~/Dropbox/Courses/R/Finance/Figures/Res_val.Rda")
# 
# # Important variables in the final model
# plot(varImp(my_model))   # or
# imp_par <- summary(my_model$finalModel)
# save(imp_par, file = "~/Dropbox/Courses/R/Finance/Figures/imp_par2.Rda")

# # Understanding how robust the model is
# p <- ggplot(my_val_res[order(my_val_res$model_pred),],
#             aes(x=seq(1,length(my_val_res$model_pred))*100/length(my_val_res$model_pred), y=model_pred)) + xlim(c(0, 100)) + ylim(c(-100, 100))
# p + geom_point(alpha = 0.1) + labs(title='Prediction vs rank') + coord_fixed(ratio=0.3) + xlab("Rank [%]") + ylab("Win-Loss prediction [%]")

# Understanding systematics of the model
ggplot(my_val,
  aes(x=ranger_pred, y=actual.win.loss, color = Price.Model.end)) + geom_point() + scale_color_gradient(low="white", high="black") +
  labs(title='Actual.win.loss vs Pred.win.loss')+ xlab("Pred.win.loss") + ylab("Actual.win.loss") + 
  xlim(c(-30, 50)) + ylim(c(-50, 100)) + coord_fixed(ratio=0.9)  

# Using the stock model to make a recommendation -----------------

ini.date.model <- as.Date("2014/06/03")   # Initial date the model is prepared
end.date.model <- as.Date("2016/06/30")   # Final date the model is prepared -- should be end of month
apply.date.model <- as.Date("2016/09/30") # Date the model is designed to predict win/loss performance -- should be end of month

# Prepare table with stock info
table.pred <- prepare.table(stockInfo, end.date.model, ini.date.model, apply.date.model)
# Removing stocks that may have problems
table.pred <- table.pred[table.pred$Price.Model.end > 0.01 & table.pred$Price.Min > 0.01,]
# Adding to table valuations compared to peers
table.pred <- prepare.table.sector(table.pred) 
# Saving table.pred
save(table.pred, file = "~/Dropbox/Courses/R/Finance/Figures/Table-3m_2016-09-30.Rda")

# Using created model to make predictions
table.pred$ranger_pred <- predict(model_ranger, table.pred)
table.pred$gbm_pred <- predict(model_gbm, table.pred)
table.pred$glmnet_pred <- predict(model_glmnet, table.pred)

# Creating table with rankings from the different methods
ordered_actual <-      table.pred[order(table.pred$actual.win.loss),]
ordered_ranger <-      table.pred[order(table.pred$ranger_pred),]  #Ranger
ordered_gbm    <-      table.pred[order(table.pred$gbm_pred),]     #GBM
ordered_glmnet <-      table.pred[order(table.pred$glmnet_pred),]  #GLMNET
rank.pred <- data.frame(Stock.SYM = character(0), rank_ranger = numeric(0), rank_gbm = numeric(0), rank_glmnet = numeric(0), 
                          rank_actual = numeric(0), actual.win.loss = numeric(0), stringsAsFactors=FALSE)
for (i in 1:length(ordered_ranger$Stock.SYM)) {
  rank.pred[i,] <- list(ordered_ranger$Stock.SYM[i],                                                                         #Name stock
                        100.*i/length(ordered_ranger$Stock.SYM),                                                             #Rank ranger
                        100.*match(ordered_ranger$Stock.SYM[i], ordered_gbm$Stock.SYM)/length(ordered_ranger$Stock.SYM),     #Rank gbm
                        100.*match(ordered_ranger$Stock.SYM[i], ordered_glmnet$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank glmnet 
                        100.*match(ordered_ranger$Stock.SYM[i], ordered_actual$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank actual
                        ordered_ranger$actual.win.loss[i])                                                                   #Actual win-loss
}
# rank.robust <- na.exclude(rank.robust)
ggplot(rank.pred, aes(x=rank_ranger, y=rank_glmnet, color=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  labs(title='GLMNET vs Ranger')+ xlab("Ranger rank [%]") + ylab("GLMNET rank [%]") + 
  xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
ggplot(rank.pred, aes(x=((rank_ranger+rank_gbm+rank_glmnet)/3), y=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  labs(title='Actual vs Av. rank pred.')+ xlab("Average rank [%]") + ylab("Actual rank [%]") + 
  xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)

# Best predictions from the different methods  
temp <- rank.pred[rank.pred$rank_ranger > 93 & rank.pred$rank_gbm > 93 & rank.pred$rank_glmnet > 93, ]
temp <- rank.pred[(rank.pred$rank_ranger + rank.pred$rank_gbm + rank.pred$rank_glmnet)/3 > 98, ]
save(temp, file = "~/Dropbox/Courses/R/Finance/Figures/Companies95.5_2015-09-30.Rda")
rank.pred[rank.pred$rank_ranger < 5 & rank.pred$rank_gbm < 5 & rank.pred$rank_glmnet < 5, ]

# Print top results
tail(ordered_actual, 10)
temp <- tail(rank.pred[order(rank.pred$rank_actual),],10)
save(temp, file = "~/Dropbox/Courses/R/Finance/Figures/CompaniesBest_2015-09-30.Rda")

# Calculating RMSE
sqrt(mean( (table.pred$ranger_pred-table.pred$actual.win.loss)^2 )) # ranger RMS
sqrt(mean( (table.pred$gbm_pred-table.pred$actual.win.loss)^2 ))    # gbm RMS
sqrt(mean( (table.pred$glmnet_pred-table.pred$actual.win.loss)^2 )) # glmnet RMS 
# Displaying prediction vs reality
p <- ggplot(table.pred,
            aes(x=ranger_pred, y=actual.win.loss)) + xlim(c(-50, 25)) + ylim(c(-150, 301))
ranger_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='Ranger') + coord_fixed(ratio=0.3)
p <- ggplot(table.pred,
            aes(x=gbm_pred, y=actual.win.loss)) + xlim(c(-50, 25)) + ylim(c(-150, 301))
gbm_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='gbm') + coord_fixed(ratio=0.3)
p <- ggplot(table.pred,
            aes(x=glmnet_pred, y=actual.win.loss)) + xlim(c(-50, 25)) + ylim(c(-150, 301))
glmnet_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='glmnet') + coord_fixed(ratio=0.3)

# Define grid layout to locate plots and print each graph
require(gridExtra)
#png(file.path(path = "~/Dropbox/Courses/R/Finance/Figures/" , filename = "GBM_timeHorizon3_redVar.png"), height = 450, width = 800)
grid_plot <- grid.arrange(ranger_plot, gbm_plot, glmnet_plot, ncol=3)
dev.off()