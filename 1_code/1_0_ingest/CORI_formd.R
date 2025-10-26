#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name:  4A Data Ingest
# Previous author:  -
# Current author:   Inder Majumdar
# Creation date:    October 25 2025
# Last updated: October 26 2025
# Description: 4A Data Ingest with Matching between Issuers and Offerings
# API Information: https://github.com/matthewjrogers/dform, https://github.com/ruralinnovation/formd-interactive-map
# Change log:
## 10/25/25: Started file.
## 10/26/25: Drafted matching logic.
#///////////////////////////////////////////////////////////////////////////////

# This is my first time using an R Package directly from Github. Won't need to run the code from 
# below every time, but I'm keeping the code below for instruction.

# Install dependencies for devtools - htmltab has been archived out of CRAN, so need a manual install

install.packages('devtools')
library('devtools')

install.packages("remotes")

# prerequisites that htmltab/parse stack often needs
install.packages(c("XML","xml2","curl","selectr","rvest"))

# htmltab (fork that’s maintained)
remotes::install_github("htmltab/htmltab")

install_github("matthewjrogers/dform")


##################################
# 1) PULLING DATA FROM THE API
##################################
library('dform') #CORI API Should work after using Devtools/Manual htmltab install above

# choose one of these depending on what dform uses under the hood. Need this for the SEC to know who I am

# If it uses httr:
library(httr)
set_config(user_agent("UW–Madison AAE (imajumdar@wisc.edu)"))

# If it uses base/curl download.file:
options(HTTPUserAgent = "UW–Madison AAE (imajumdar@wisc.edu)")

dfm <- dForm$new()

data <- dfm$load_data(2020, quarter = c(1:4), remove_duplicates = TRUE, use_cache = TRUE)

##################################
# 2) Data merge: Preliminaries
##################################
library('tidyverse')

# 2.1: Pull offerings and data 

offerings <- data$offerings

issuers <- data$issuers

# 2.2: Strip Punctuation and Whitespace from entity, city name

issuers |> 
  mutate(entityname = stringr::str_replace_all(entityname, "[[:punct:]]", ""), city = stringr::str_replace_all(city, "[[:punct:]]", "")) |> #Replace punctuation - Regex
  mutate(entityname = stringr::str_squish(entityname), city = stringr::str_squish(city)) |> # Remove whitespace, and limit internal whitespace to a single space
  mutate(across(c(entityname, city), ~str_to_upper(.x))) -> issuers # Upper case everything
  

##################################
# 2) Data merge: HUD Zip - County Crosswalk
##################################





