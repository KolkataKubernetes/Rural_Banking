#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name:  4A Data Ingest
# Previous author:  -
# Current author:   Inder Majumdar
# Creation date:    October 25 2025
# Last updated: November 17 2025
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
# 1.a) PULLING DATA FROM THE API
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
# 1.b) LOADING EXCEL DEPENDENCIES
##################################

zip_county_crosswalk <- readxl::read_excel('/Volumes/aae/users/imajumdar/Rural_Banking/0_data/CORI/HUD_crosswalks/ZIP_COUNTY_122020.xlsx')

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
# 2) Data merge: HUD Zip - County Crosswalk (Outcome: FIPS Code)
##################################

# NOTE TO SELF - FOR NOW, I'M ONLY PULLING 2020 DATA - SO I WILL PULL THE 2020 Q4 DATA. FOR THE ENTIRE PULL, FOLLOW 
# THE 2014 AND 2021 RULES THAT CORI FOLLOWS. OR BETTER YET, DO A YEAR-WISE MATCH.

# 0) Prepare HUD crosswalk for CORI logic

zip_county_crosswalk |>
  group_by(ZIP) |>
  filter(BUS_RATIO == max(BUS_RATIO)) |> # Rule 1: Majority of business rule
  filter(TOT_RATIO == max(TOT_RATIO)) -> x # Rule 2, after rule 1: Majority of total 

# 1) Normalize issuer ZIP and classify patterns

issuers |> 
  mutate(
    zip_raw = zipcode, 
    zip5 = stringr::str_extract(zipcode, "\\d{5}"), #first five digits using regex
    zip_class = dplyr::case_when(
      str_detect(zipcode, "^\\d{5}-\\d{4}$") ~ "US_ZIP + 4",
      str_detect(zipcode, "^\\d{5}$") ~ "US_ZIP5",
      # Canadian Zips: A1A, 1A1
      str_detect(str_to_upper(zipcode),
                 "^[A-Z]\\d[A-Z][ -]?\\d[A-Z]\\d$")     ~ "CAN_postal",
      TRUE ~ "Other_or_foreign"
      )  
    ) -> issuers

# Complete the join

issuers |>
  left_join(x, by = c("zip5" = "ZIP")) -> issuers_match

rm(x)

# Two issues here. First: let's categorize the NA mismatches.


# --------------------- # N.A. Analysis ---------------------

# How many are unmatched, overall?
sum(is.na(issuers_match$COUNTY))

# What are the types of mismatches?
issuers_match |>
  filter(is.na(COUNTY)) |>
  group_by(zip_class) |>
  summarise(n = n()) ## The good thing is that most of these are foreign Zip codes. Let's move on for now.


##################################
# 3) Smallest year of incorporation 
##################################

issuers_match |>
  group_by(cik, entityname) |>
  mutate(
    minyear_value = suppressWarnings(min(yearofinc_value_entered, na.rm = TRUE)), #min val excluding NA. Suprressing warnings since nonfinite issues handled below
    fallback = dplyr::first(na.omit(yearofinc_timespan_choice)), #get fallback text val
    #Apply CORI rule
    minyear = if_else(
      is.finite(minyear_value),
      as.character(minyear_value),
      fallback
    )
  ) |> 
  ungroup() |>
  select(-minyear_value, -fallback) -> issuers_match


##################################
# 4) join issuers_match and offerings
##################################
## It looks like industry group type is attached to offerings, not issuers.

## For now I'll join and then concatenate industry group types

issuers_match |>
  filter(is_primaryissuer_flag == 'YES') -> issuers_match_primary

issuers_offerings <- left_join(issuers_match_primary, offerings, by = c('accessionnumber', 'year', 'quarter'))

##################################
# 5) Collapse Industry Specification
##################################

# Ask about this later... Do I use CIK number?


##################################
# 6) Correct totalamountsold: Wrangling biz id, funding round
##################################

summary(issuers_offerings$totalamountsold)

issuers_offerings |>
  mutate(cik = as.character(cik)) -> issuers_offerings

  class(issuers_offerings$accessionnumber)
  
issuers_offerings |>
  mutate(biz_id = case_when(
    substr(accessionnumber,1,10) == cik ~ cik,
    TRUE                               ~ paste0(as.character(cik), "_", substr(accessionnumber,1,10))
                           )) -> issuers_offerings
  
  
# Create funding round

issuers_offerings <- issuers_offerings %>%
  group_by(
    biz_id,
    sale_date,
    isequitytype,
    isdebttype,
    ispooledinvestmentfundtype,
    isbusinesscombinationtrans
  ) %>%
  # one row per (biz_id, combo) to rank
  mutate(.round_key = dplyr::cur_group_id()) %>%
  ungroup() %>%
  group_by(biz_id) %>%
  mutate(
    funding_round_id = dplyr::dense_rank(.round_key)
  ) %>%
  ungroup() %>%
  select(-.round_key)



sort(table(issuers_offerings$funding_round_id), decreasing = TRUE)

issuers_offerings |> 
  filter(biz_id == "1557354_0000897069", funding_round_id == 1)
  
issuers_offerings |>
  group_by(biz_id) |>
  summarise(n_rounds = n_distinct(funding_round_id)) |>
  arrange(desc(n_rounds)) |>
  filter(n_rounds == 3)

issuers_offerings |>
  filter(biz_id == '1045390_0001441557') -> example


##################################
# 7) Correct totalamountsold: Calculating Increments
##################################
issuers_offerings <- issuers_offerings %>%
  group_by(biz_id) %>%
  arrange(accessionnumber, .by_group = TRUE) %>%
  mutate(
    incremental_amount = totalamountsold - lag(totalamountsold),
    incremental_amount = if_else(
      is.na(incremental_amount),     # first filing in each round
      totalamountsold,               # take the whole value
      incremental_amount             # the diff
    )
  ) %>%
  ungroup()

issuers_offerings |>
  filter(biz_id == '1045390_0001441557') -> example

issuers_offerings %>%
  group_by(biz_id, funding_round_id) %>%
  summarise(
    filings   = n(),
    total     = max(totalamountsold, na.rm = TRUE),
    incr_sum  = sum(incremental_amount, na.rm = TRUE),
    difference = total - incr_sum
  ) %>%
  arrange(desc(abs(difference)))



