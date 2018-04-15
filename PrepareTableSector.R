# ----------------------------------------------------------
# Function to prepare to table with stocks info. Returns modified table.
# Add variables (columns) with valuations of a given stock compared
# to other companies with the same Sector-industry-number.
# ----------------------------------------------------------

# Valuations to return compared to sector average
# EV/earnings at end.date.model
# EV/EBITDA at end.date.model
# EV/book value at end.date.model
# EV/revenue at end.date.model
# EV/total cash at end.date.model
# price/(equity/debt) at end.date.model

prepare.table.sector <- function(table) {
  
  # Adding columns to table and initializing to zero
  table$Ev.earning.peers =        as.numeric(table$Ev.earning*0.)
  table$Ev.ebitda.peers =         as.numeric(table$Ev.earning.peers)
  table$Ev.book.peers =           as.numeric(table$Ev.earning.peers)
  table$Ev.revenue.peers =        as.numeric(table$Ev.earning.peers)
  table$Ev.cash.peers =           as.numeric(table$Ev.earning.peers)
  table$EquityAssets.liability.peers = as.numeric(table$Ev.earning.peers)
  table$Price.sma.200.peers =     as.numeric(table$Ev.earning.peers)
  table$Price.sma.50.peers =      as.numeric(table$Ev.earning.peers)
    
  # Loop over table
  for (i in 1:dim(table)[[1]]) {
    
    # Filling table with valuations divided by mean
    table[i,"Ev.earning.peers"] <- table[i,"Ev.earning"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Ev.earning)
    table[i,"Ev.ebitda.peers"] <- table[i,"Ev.ebitda"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Ev.ebitda)
    table[i,"Ev.book.peers"] <- table[i,"Ev.book"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Ev.book)
    table[i,"Ev.revenue.peers"] <- table[i,"Ev.revenue"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Ev.revenue)
    table[i,"Ev.cash.peers"] <- table[i,"Ev.cash"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Ev.cash)
    table[i,"EquityAssets.liability.peers"] <- table[i,"EquityAssets.liability"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$EquityAssets.liability)
    table[i,"Price.sma.200.peers"] <- table[i,"Price.sma.200"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Price.sma.200)
    table[i,"Price.sma.50.peers"] <- table[i,"Price.sma.50"]/mean(table[table$SectorIndustry.Num == table[i, "SectorIndustry.Num"],]$Price.sma.50)
    
  }
  table <- na.exclude(table)
  return(table)  
}