library(gtrendsR)

usr <- ".."
psw <- ".."
gconnect(usr, psw) 
lang_trend <- gtrends(c("Canlan Ice Sports"), start_date = "2015-06-01", end_date = "2016-08-01")
plot(lang_trend)