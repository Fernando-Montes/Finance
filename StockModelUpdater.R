# ----------------------------------------------------------
# StockModel.R is the main file
# It uses information created using updater.r 
# It uses PrepareStockModel.R to construct stock model 
# ----------------------------------------------------------

# Load relevant packages
library(quantmod)
library(zoo)
library(tseries)
library(ggplot2)
library(caret)
library(forecast)  # Holt-Winters and Arima forecasting method
# Parallel computing
library(doParallel)
registerDoParallel(cores=4)

# Loading the most recent indicator table table.model
targetPath <- "~/Dropbox/Courses/R/StockModel-I/ArchiveFin/"
date.today = Sys.Date()  
temp = list.files(targetPath, pattern = "2018*") # All the files that may contain indicator information
diffDate = 20   # Obtain the most recent date less than 20 days
for (i in 1:length(temp) ) {
  if( length(strsplit(temp[i],"")[[1]])==16 ) { # Correct filename length 
    tempDate = as.Date(substr(temp[i],1,10)) # Extract date file was created
    if (date.today - tempDate < diffDate) { # Obtain the most recent date less than 20 days
      diffDate = date.today - tempDate 
      date.file = tempDate     
    }
  }
}

# Sourcing prepare.model function
source('~/Dropbox/Courses/R/StockModel-I/PrepareStockModel.R')
# Creating stock model with multiple methods ----------------------

# Open table for today's table
fileName <- paste(targetPath, date.file, ".Rdata", sep = "") 
load(file = fileName)
table.pred = table.model

# Loop over the different models 3, 6 months
for (i in seq(1,6,1)) {
# for (i in seq(3,3,3)) {
  fileName <- paste(targetPath, date.file, "-", i, "m.Rdata", sep = "") 
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
  
  save(my_val, file = paste("~/Dropbox/Courses/R/StockModel-I/ArchiveFin/", as.character(Sys.Date()), "-", i, "m-validation.Rdata", sep = ""))
  
  # Understanding training results -----
  # # Creating table with rankings from the different methods
  # ordered_actual <-      my_val[order(my_val$actual.win.loss),]
  # ordered_ranger <-      my_val[order(my_val$ranger_pred),]  #Ranger
  # ordered_gbm    <-      my_val[order(my_val$gbm_pred),]     #GBM
  # ordered_glmnet <-      my_val[order(my_val$glmnet_pred),]  #GLMNET
  # rank.robust <- data.frame(Stock.SYM = character(0), rank_ranger = numeric(0), rank_gbm = numeric(0), rank_glmnet = numeric(0), 
  #                           rank_actual = numeric(0), actual.win.loss = numeric(0), stringsAsFactors=FALSE)
  # for (i in 1:length(ordered_ranger$Stock.SYM)) {
  #   rank.robust[i,] <- list(ordered_ranger$Stock.SYM[i],                                                                         #Name stock
  #                           100.*i/length(ordered_ranger$Stock.SYM),                                                             #Rank ranger
  #                           100.*match(ordered_ranger$Stock.SYM[i], ordered_gbm$Stock.SYM)/length(ordered_ranger$Stock.SYM),     #Rank gbm
  #                           100.*match(ordered_ranger$Stock.SYM[i], ordered_glmnet$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank glmnet 
  #                           100.*match(ordered_ranger$Stock.SYM[i], ordered_actual$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank actual
  #                           ordered_ranger$actual.win.loss[i])                                                                   #Actual win-loss
  # }
  # # rank.robust <- na.exclude(rank.robust)
  # ggplot(rank.robust, aes(x=rank_ranger, y=rank_gbm, color=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  #   labs(title='gbm vs Ranger')+ xlab("Ranger rank [%]") + ylab("gbm rank [%]") + 
  #   xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
  # ggplot(rank.robust, aes(x=rank_ranger, y=rank_glmnet, color=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  #   labs(title='glmnet vs Ranger')+ xlab("Ranger rank [%]") + ylab("glmnet rank [%]") + 
  #   xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
  # ggplot(rank.robust, aes(x=((rank_ranger+rank_gbm+rank_glmnet)/3), y=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  #   labs(title='Actual vs Average rank pred.')+ xlab("Average rank [%]") + ylab("Actual rank [%]") + 
  #   xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
  # ggplot(rank.robust, aes(x=((rank_ranger+rank_gbm)/2), y=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
  #   labs(title='Actual vs Average rank pred.')+ xlab("Average rank [%]") + ylab("Actual rank [%]") + 
  #   xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
  # 
  # # Best predictions from the different methods  
  # temp <- rank.robust[rank.robust$rank_ranger > 90 & rank.robust$rank_gbm > 87 & rank.robust$rank_glmnet > 90, ]
  # temp <- rank.robust[(rank.robust$rank_ranger + rank.robust$rank_gbm + rank.robust$rank_glmnet)/3 > 97, ]
  # save(temp, file = "~/Dropbox/Courses/R/Finance/Figures/Companies90_2015-06-30.Rda")
  # rank.robust[rank.robust$rank_ranger < 5 & rank.robust$rank_gbm < 5 & rank.robust$rank_glmnet < 5, ]
  # 
  # # Comparing RMS from the different methods
  # model_list <- list(ranger = model_ranger, gbm = model_gbm)
  # resamples <- resamples(model_list)
  # summary(resamples)
  # xyplot(resamples)
  
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
  # ggplot(my_val,
  #        aes(x=ranger_pred, y=actual.win.loss, color = Price.Model.end)) + geom_point() + scale_color_gradient(low="white", high="black") +
  #   labs(title='Actual.win.loss vs Pred.win.loss')+ xlab("Pred.win.loss") + ylab("Actual.win.loss") + 
  #   xlim(c(-30, 50)) + ylim(c(-50, 100)) + coord_fixed(ratio=0.9)  
  
  
  
  
  
  
  # Using created model to make predictions
  table.pred[, paste("ranger_pred_", i, sep="")] <- predict(model_ranger, table.pred)
  table.pred[, paste("gbm_pred_", i, sep="")] <- predict(model_gbm, table.pred)
  table.pred[, paste("glmnet_pred_", i, sep="")] <- predict(model_glmnet, table.pred)
}

save(table.pred, file = paste("~/Dropbox/Courses/R/StockModel-I/ArchiveFin/", as.character(Sys.Date()), "-pred.Rdata", sep = ""))

# Understading results ----
# # Creating table with rankings from the different methods
# ordered_actual <-      table.pred[order(table.pred$actual.win.loss),]
# ordered_ranger <-      table.pred[order(table.pred$ranger_pred),]  #Ranger
# ordered_gbm    <-      table.pred[order(table.pred$gbm_pred),]     #GBM
# ordered_glmnet <-      table.pred[order(table.pred$glmnet_pred),]  #GLMNET
# rank.pred <- data.frame(Stock.SYM = character(0), rank_ranger = numeric(0), rank_gbm = numeric(0), rank_glmnet = numeric(0), 
#                           rank_actual = numeric(0), actual.win.loss = numeric(0), stringsAsFactors=FALSE)
# for (i in 1:length(ordered_ranger$Stock.SYM)) {
#   rank.pred[i,] <- list(ordered_ranger$Stock.SYM[i],                                                                         #Name stock
#                         100.*i/length(ordered_ranger$Stock.SYM),                                                             #Rank ranger
#                         100.*match(ordered_ranger$Stock.SYM[i], ordered_gbm$Stock.SYM)/length(ordered_ranger$Stock.SYM),     #Rank gbm
#                         100.*match(ordered_ranger$Stock.SYM[i], ordered_glmnet$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank glmnet 
#                         100.*match(ordered_ranger$Stock.SYM[i], ordered_actual$Stock.SYM)/length(ordered_ranger$Stock.SYM),  #Rank actual
#                         ordered_ranger$actual.win.loss[i])                                                                   #Actual win-loss
# }
# # rank.robust <- na.exclude(rank.robust)
# # ggplot(rank.pred, aes(x=rank_ranger, y=rank_glmnet, color=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
# #   labs(title='GLMNET vs Ranger')+ xlab("Ranger rank [%]") + ylab("GLMNET rank [%]") + 
# #   xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
# # ggplot(rank.pred, aes(x=((rank_ranger+rank_gbm+rank_glmnet)/3), y=rank_actual)) + scale_color_gradient(low="white", high="black") + geom_point() + 
# #   labs(title='Actual vs Av. rank pred.')+ xlab("Average rank [%]") + ylab("Actual rank [%]") + 
# #   xlim(c(0, 100)) + ylim(c(0, 100)) + coord_fixed(ratio=1.3)
# 
# # Best predictions from the different methods  
# temp <- rank.pred[rank.pred$rank_ranger > 93 & rank.pred$rank_gbm > 93 & rank.pred$rank_glmnet > 93, ]
# temp <- rank.pred[(rank.pred$rank_ranger + rank.pred$rank_gbm + rank.pred$rank_glmnet)/3 > 95, ]
# save(temp, file = "~/Dropbox/Courses/R/Finance/Figures/Companies95.5_2015-09-30.Rda")
# rank.pred[rank.pred$rank_ranger < 5 & rank.pred$rank_gbm < 5 & rank.pred$rank_glmnet < 5, ]
# 
# # Print top results
# tail(ordered_actual, 10)
# temp <- tail(rank.pred[order(rank.pred$rank_actual),],10)
# save(temp, file = "~/Dropbox/Courses/R/Finance/Figures/CompaniesBest_2015-09-30.Rda")
# 
# # Calculating RMSE
# sqrt(mean( (table.pred$ranger_pred-table.pred$actual.win.loss)^2 )) # ranger RMS
# sqrt(mean( (table.pred$gbm_pred-table.pred$actual.win.loss)^2 ))    # gbm RMS
# sqrt(mean( (table.pred$glmnet_pred-table.pred$actual.win.loss)^2 )) # glmnet RMS 
# # Displaying prediction vs reality
# p <- ggplot(table.pred,
#             aes(x=ranger_pred, y=actual.win.loss)) + xlim(c(-50, 25)) + ylim(c(-150, 301))
# ranger_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='Ranger') + coord_fixed(ratio=0.3)
# p <- ggplot(table.pred,
#             aes(x=gbm_pred, y=actual.win.loss)) + xlim(c(-50, 25)) + ylim(c(-150, 301))
# gbm_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='gbm') + coord_fixed(ratio=0.3)
# p <- ggplot(table.pred,
#             aes(x=glmnet_pred, y=actual.win.loss)) + xlim(c(-50, 25)) + ylim(c(-150, 301))
# glmnet_plot <- p + geom_point(alpha = 0.1) + geom_smooth() + labs(title='glmnet') + coord_fixed(ratio=0.3)

