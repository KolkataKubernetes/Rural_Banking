#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  cu_fig_cu06_commercial_pct_assets.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's credit-union figure CU-6. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig_cu06_commercial_pct_assets.py
#///////////////////////////////////////////////////////////////////////////////


# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

# Shared helper centralizes repeated local-data parsing and save logic.
source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

output_file <- file.path(
  charlie_cu_output_dir,
  "cu_fig_cu06_commercial_pct_assets.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

# This figure needs two NCUA financial layouts:
# - fs220.txt supplies ACCT_010 (true total assets) across the staged years.
# - FS220L/fs220L supplies the post-2017 outstanding commercial-loan balance.
load_ncua_csv_candidate <- function(year, candidates) {
  data_dir <- ncua_branch_dir_for_year(year)
  path <- purrr::detect(
    file.path(data_dir, candidates),
    file.exists
  )

  if (is.null(path)) {
    stop(
      "Missing expected NCUA file for year ", year,
      ". Looked for: ", paste(candidates, collapse = ", ")
    )
  }

  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    locale = readr::locale(encoding = "cp1252"),
    guess_max = 50000
  )
}

fig_cu06_data <- map_dfr(2010:2024, function(year) {
  branch_path <- ncua_branch_file_for_year(year)

  if (!file.exists(branch_path)) {
    message("Skipping missing NCUA branch file for year ", year, ": ", branch_path)
    return(tibble())
  }

  main_offices <- load_ncua_branch(year) |>
    filter(MainOffice == "Yes")

  wi_cu <- main_offices |>
    filter(PhysicalAddressStateCode == "WI") |>
    pull(CU_NUMBER)

  us_ex_wi_cu <- main_offices |>
    filter(PhysicalAddressStateCode != "WI") |>
    pull(CU_NUMBER)

  # fs220.txt contains ACCT_010, which is the true total-assets denominator.
  fs_core <- load_ncua_csv_candidate(year, c("fs220.txt", "FS220.txt"))

  pct_for_group <- function(cu_numbers) {
    group_fs_core <- fs_core |>
      filter(CU_NUMBER %in% cu_numbers)

    total_assets <- sum(as.numeric(group_fs_core$ACCT_010), na.rm = TRUE)

    if (year <= 2016) {
      # Pre-2017, ACCT_400 is the staged outstanding business-loan balance.
      total_commercial <- sum(as.numeric(group_fs_core$ACCT_400), na.rm = TRUE)
    } else {
      # Post-2017, the staged commercial-loan-outstanding measure lives in
      # FS220L under ACCT_400T1. This is the concept that aligns with the
      # expected "commercial lending as a share of assets" series.
      group_fs_loan <- fs_loan |>
        filter(CU_NUMBER %in% cu_numbers)

      total_commercial <- sum(as.numeric(group_fs_loan$ACCT_400T1), na.rm = TRUE)
    }

    if (is.na(total_assets) || total_assets <= 0) {
      return(NA_real_)
    }

    (total_commercial / total_assets) * 100
  }

  if (year <= 2016) {
    fs_loan <- NULL
  } else {
    fs_loan <- load_ncua_csv_candidate(year, c("FS220L.txt", "fs220L.txt"))
  }

  tibble(
    year = year,
    wi_pct_assets = pct_for_group(wi_cu),
    us_ex_wi_pct_assets = pct_for_group(us_ex_wi_cu)
  )
}) |>
  arrange(year)

# Plot in long form so Wisconsin and national-excluding-Wisconsin appear as
# directly comparable lines on the same axes.
fig_cu06_long <- fig_cu06_data |>
  pivot_longer(
    cols = c(wi_pct_assets, us_ex_wi_pct_assets),
    names_to = "series",
    values_to = "pct_assets"
  ) |>
  mutate(
    series = recode(
      series,
      wi_pct_assets = "Wisconsin",
      us_ex_wi_pct_assets = "U.S. Excluding WI"
    )
  )


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig_cu06_plot <- ggplot(
  fig_cu06_long,
  aes(x = year, y = pct_assets, color = series)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = fig_cu06_data$year) +
  scale_y_continuous(
    limits = c(0, 15),
    breaks = seq(0, 15, by = 2.5),
    labels = function(x) paste0(x, "%")
  ) +
  scale_color_manual(
    values = c(
      "Wisconsin" = "#2E75B6",
      "U.S. Excluding WI" = "#BF4D28"
    )
  ) +
  labs(
    title = "Figure CU-6: Commercial Lending as % of Total Assets",
    subtitle = "Wisconsin Credit Unions, 2010-2024",
    x = "Year",
    y = "Commercial Loans as % of Total Assets",
    color = NULL,
    caption = paste(
      "Data: NCUA Call Reports.",
      "Staged inputs are missing the 2015 NCUA branch/call-report directory, so 2015 is omitted.",
      "Deviation from Charlie's staged Python: this implementation uses ACCT_010",
      "as total assets and outstanding business-loan balances (ACCT_400 pre-2017,",
      "ACCT_400T1 post-2017) to align with the intended metric.",
      "The comparison line sums all non-Wisconsin main-office credit unions."
    )
  ) +
  charlie_theme() +
  theme(legend.position = "top")


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig_cu06_plot, output_file, width = 9, height = 5)
