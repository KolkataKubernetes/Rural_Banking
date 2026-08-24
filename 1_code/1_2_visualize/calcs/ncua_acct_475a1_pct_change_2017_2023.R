#///////////////////////////////////////////////////////////////////////////////
#----                  NCUA Commercial Lending Calculation                  ----
# File name:  ncua_acct_475a1_pct_change_2017_2023.R
# Purpose:    Sum ACCT_475A1 for Wisconsin-headquartered credit unions in
#             2017 and 2023, then calculate the percent change.
# Outputs:    Console only; this script does not write any files.
#///////////////////////////////////////////////////////////////////////////////


# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
})

years <- c(2017L, 2023L)
ncua_dir <- file.path("0_inputs", "data_charlie", "NCUA")


# -----------------------------
# 1) Calculate annual totals
# -----------------------------

acct_475a1_totals <- map_dfr(years, function(year) {
  year_dir <- file.path(ncua_dir, sprintf("call-report-data-%d-12", year))

  branches <- read_csv(
    file.path(year_dir, "Credit Union Branch Information.txt"),
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "cp1252")
  )

  financials <- read_csv(
    file.path(year_dir, "FS220L.txt"),
    show_col_types = FALSE,
    progress = FALSE,
    locale = locale(encoding = "cp1252"),
    guess_max = 50000
  )

  wi_cu_numbers <- branches |>
    filter(
      PhysicalAddressStateCode == "WI",
      MainOffice == "Yes"
    ) |>
    distinct(CU_NUMBER) |>
    pull(CU_NUMBER)

  financials |>
    filter(CU_NUMBER %in% wi_cu_numbers) |>
    summarise(
      year = year,
      acct_475a1_total = sum(as.numeric(ACCT_475A1), na.rm = TRUE)
    )
}) |>
  arrange(year)


# -----------------------------
# 2) Calculate and print percent change
# -----------------------------

acct_475a1_2017 <- acct_475a1_totals |>
  filter(year == 2017L) |>
  pull(acct_475a1_total)

acct_475a1_2023 <- acct_475a1_totals |>
  filter(year == 2023L) |>
  pull(acct_475a1_total)

percent_change <-
  ((acct_475a1_2023 - acct_475a1_2017) / acct_475a1_2017) * 100

print(acct_475a1_totals)
cat(sprintf("Percent change, 2017 to 2023: %.2f%%\n", percent_change))
