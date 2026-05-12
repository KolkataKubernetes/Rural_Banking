#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  cu_fig_cu11_per_capita_lending.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's credit-union figure CU-11. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig_cu11_per_capita_lending.py
#             This script preserves Charlie's hard-coded Wisconsin population
#             values during the first-pass replication.
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
  "cu_fig_cu11_per_capita_lending.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

wi_population <- c(
  `2017` = 5793147,
  `2018` = 5809319,
  `2019` = 5824581,
  `2020` = 5897375,
  `2021` = 5881608,
  `2022` = 5903975,
  `2023` = 5930405,
  `2024` = 5960975
)

fig_cu11_data <- map_dfr(2017:2024, function(year) {
  wi_cu <- wi_cu_main_offices(year)$CU_NUMBER
  wi_fs <- load_ncua_fs(year) |>
    filter(CU_NUMBER %in% wi_cu)

  total_amt <- sum(as.numeric(wi_fs$ACCT_475A1), na.rm = TRUE)
  total_num <- sum(as.numeric(wi_fs$ACCT_090A1), na.rm = TRUE)
  pop <- wi_population[as.character(year)]

  tibble(
    year = year,
    per_cap_amt = total_amt / pop,
    per_10k_num = 10000 * total_num / pop
  )
}) |>
  arrange(year)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig_cu11_plot <- ggplot(fig_cu11_data, aes(x = factor(year))) +
  geom_col(aes(y = per_cap_amt), fill = "#2E75B6", alpha = 0.7) +
  geom_line(
    aes(y = per_10k_num * max(per_cap_amt) / max(per_10k_num), group = 1),
    color = "#BF4D28",
    linewidth = 1.1
  ) +
  geom_point(
    aes(y = per_10k_num * max(per_cap_amt) / max(per_10k_num)),
    color = "#BF4D28",
    size = 2
  ) +
  scale_y_continuous(
    name = "Loan Amount per Capita ($)",
    labels = scales::label_dollar(),
    sec.axis = sec_axis(
      ~ . * max(fig_cu11_data$per_10k_num) / max(fig_cu11_data$per_cap_amt),
      name = "Originations per 10,000 Residents"
    )
  ) +
  labs(
    title = "Figure CU-11: Per Capita Commercial Lending by Wisconsin Credit Unions",
    x = "Year",
    caption = "Data: NCUA Call Reports and Charlie's hard-coded Wisconsin population values"
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig_cu11_plot, output_file, width = 9, height = 5)
