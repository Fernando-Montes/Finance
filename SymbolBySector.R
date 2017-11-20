#!/usr/bin/env Rscript
# (c) Copyright 2014 mkfs <https://github.com/mkfs>
# Yahoo Finance interface.
# Modified by Fernando Montes April 2016, August 2017

# ----------------------------------------------------------
# Additional functions needed by Download.R --------------
# Obtains stock symbols ------------------------------------
# ----------------------------------------------------------

library(RCurl)
library(XML)
library(rjson)
library(httr)

# URLs for Yahoo Finance CSV API
url.yahoo.finance.base <- 'https://biz.yahoo.com/p'
url.yahoo.finance.sector <- 'https://biz.yahoo.com/p/csv/s_conameu.csv'
url.yahoo.finance.sector.industry <- 'https://biz.yahoo.com/p/csv/'

# August 2017
# new yahoo way to access stocks within a given sector
# https://biz.yahoo.com/p/112/conameu.html
# or
# https://finance.yahoo.com/industry/agricultural_chemicals

# Helper function to safely download data using Curl.
yahoo.download.csv.as.df <- function(url, set.id=TRUE) {
  # NOTE: CSV has a NUL at the end
  csv <- rawToChar(getURLContent(url, binary=TRUE, .opts=curlOptions(followlocation = TRUE)))
  read.csv(textConnection(csv))
}

# Helper function to safely download data using Curl.
yahoo.download.as.df <- function(url, set.id=TRUE) {
  sec <- scan(file = url, what = "character", sep ="\n",  allowEscapes = TRUE)
  # sec <- sec[1:length(sec)]
  sec <- sec[1:10]
  html <- htmlParse(sec)
  #Yahoo finance changed some of its pages. Updated August 2017
  #html.names <- as.vector(xpathSApply(html, '//td/font', function(x) ifelse(is.null(xmlChildren(x)$a), NA, xmlAttrs(xmlChildren(x)$a, 'href'))))
  html.names <- as.vector(xpathSApply(html, '//td', function(x) ifelse(is.null(xmlChildren(x)$a), NA, xmlAttrs(xmlChildren(x)$a, 'href'))))
  html.names <- html.names[!is.na(html.names)]
  #Yahoo finance changed some of its pages. Updated August 2017
  html.names <- substr(html.names, (nchar(html.names)+10)/2+1, nchar(html.names))
}

# Return a dataframe of all sectors in Yahoo Finance.
yahoo.sectors <- function() {
  df <- yahoo.download.csv.as.df(url.yahoo.finance.sector)
  # sector ID is "1-indexed rank by name in the sector list"
  df$ID <- 1:nrow(df)
  return(df)
}

# Parse the list of industry IDs from the URL
#   http://biz.yahoo.com/ic/ind_index_alpha.html
# It is a mystery why Yahoo does not provide an API for this.
yahoo.industries <- function() {
  #html <- htmlParse(url.yahoo.industry.list)

  sec <- scan(file = "https://biz.yahoo.com/ic/ind_index_alpha.html", what = "character", sep ="\n",  allowEscapes = TRUE)
  sec <- sec[56:length(sec)]
  html <- htmlParse(sec)
  
  html.names <- as.vector(xpathSApply(html, "//td/a/font", xmlValue))
  html.urls <- as.vector(xpathSApply(html, "//td/a/font/../@href"))
  
  if (length(html.names) != length(html.urls)) {
    warning(paste("Got", length(html.names), "names but", 
                  length(html.urls), "URLs"))
  }
  
  html.names <- gsub("\n", " ", html.names)
  html.urls <- gsub("https://biz.yahoo.com/ic/([0-9]+).html", "\\1", html.urls)
  
  df <- data.frame(Name=character(length(html.urls)), 
                   ID=numeric(length(html.urls)), stringsAsFactors=FALSE)
  for (i in 1:length(html.urls)) {
    url = html.urls[i]
    val = suppressWarnings(as.numeric(url))
    if (! is.na(val) ) {
      df[i,'Name'] = html.names[i]
      df[i,'ID'] = val
    }
  }
  return(df)
}

# Return a dataframe of industries in a sector. If sector is NULL,
# this invokes yahoo.sector.industries.all(). Note that sector is 
# an integer ID, as provided in the dataframe returned by yahoo.sectors().
# The id.df parameter is a dataframe as returned by yahoo.industries();
# this allows the user to avoid calling yahoo.industries() repeatedly.
yahoo.sector.industries <- function( sector=NULL, id.df=NULL ) {
  if (is.null(id.df)) {
    id.df <- yahoo.industries()
  }
  
  if (is.null(sector)) {
    return(yahoo.sector.industries.all(id.df))
  }
  
  url <- paste(url.yahoo.finance.sector.industry, 
               paste(as.integer(sector), 'conameu.csv', sep=''), 
               sep='/')
  df <- yahoo.download.csv.as.df(url)
  
  # fix broken Industry names
  df[,'Industry'] <- gsub(' +', ' ', df[,'Industry'])
  
  # default ID column
  df$ID <- (sector * 100) + 1:nrow(df)
  
  # set IDs based on http://biz.yahoo.com/ic/ind_index_alpha.html
  for (i in 1:nrow(id.df)) {
    name <- id.df[i, 'Name']
    if (nrow(df[df$Industry == name,]) > 0) {
      df[df$Industry == name, 'ID'] <- id.df[i, 'ID']
    }
  }
  
  df$Sector <- sector
  return(df)
}

# Return a dataframe of all industries in all sectors.
# See yahoo.sector.industres() for more detail.
yahoo.sector.industries.all <- function(id.df=NULL) {
  sec.df <- yahoo.sectors()
  ind.df <- NULL
  for (id in sec.df$ID) {
    df <- yahoo.sector.industries(id, id.df)
    if (is.null(ind.df)) {
      ind.df <- df
    } else {
      ind.df <- rbind(ind.df, df)
    }
  }
  return(ind.df)
}

# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

# Returns data frame with Sector.Name, Sector.Num, Industry.Name, Industry.Num
list.sectors.industries <- function() {
  allinfo <- yahoo.sector.industries.all()
  df <- data.frame(Sector.Num = allinfo$Sector, 
                   Industry.Name = allinfo$Industry, 
                   Industry.Num = allinfo$ID)
  sectorsinfo <- yahoo.sectors()
  df <- cbind(Sector.Name = sectorsinfo$Sectors[df$Sector.Num], df)
  return(df)
}

# Return a dataframe of companies in the specified industry.
# Note that industry is a numeric ID as provided by the 
# dataframe returned by list.sectors.industries().
industry.All.companies <- function( industry ) {
  url <- paste(url.yahoo.finance.base, 
               paste(as.integer(industry), '/conameu.html', sep=''), 
               sep='/')
  df <- yahoo.download.as.df(url)
  df <- df[df != ""]
  return(df)
}

# Return a dataframe of companies in the specified sector.
# Note that sector is a numeric ID as provided by the 
# dataframe returned by list.sectors.industries().
sector.All.companies <- function( sector ) {
  allinfo <- list.sectors.industries()
  df <- c()
  for (i in 1:length(allinfo$Sector.Num)) {
    if (allinfo$Sector.Num[i] == sector) {
      print(i)
      df <- c(df, industry.All.companies(allinfo$Industry.Num[i]))
    }
  }
  return(df)
}
