#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  cu_fig_cu10_avg_loan_size.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's credit-union figure CU-10. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig_cu10_avg_loan_size.py
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
  "cu_fig_cu10_avg_loan_size.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

fig_cu10_data <- map_dfr(2017:2024, function(year) {
  wi_cu <- wi_cu_main_offices(year)$CU_NUMBER
  wi_fs <- load_ncua_fs(year) |>
    filter(CU_NUMBER %in% wi_cu)

  total_amt <- sum(as.numeric(wi_fs$ACCT_475A1), na.rm = TRUE)
  total_num <- sum(as.numeric(wi_fs$ACCT_090A1), na.rm = TRUE)

  if (is.na(total_num) || total_num <= 0) {
    return(tibble())
  }

  tibble(
    year = year,
    avg_loan = total_amt / total_num
  )
}) |>
  arrange(year)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig_cu10_plot <- ggplot(fig_cu10_data, aes(x = factor(year), y = avg_loan)) +
  geom_col(fill = "#2E75B6", width = 0.7) +
  geom_text(
    aes(label = scales::dollar(avg_loan, accuracy = 1)),
    vjust = -0.35,
    size = 3
  ) +
  scale_y_continuous(
    labels = scales::label_dollar(),
    expand = expansion(mult = c(0, 0.12))
  ) +
  labs(
    title = "Figure CU-10: Average Commercial Loan Size",
    subtitle = "Wisconsin Credit Unions, 2017-2024",
    x = "Year",
    y = "Average Loan Size ($)",
    caption = "Data: NCUA Call Reports"
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig_cu10_plot, output_file, width = 9, height = 5)
