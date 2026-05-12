#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig10_avg_loan_size.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 10. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig10_avg_loan_size.py
#             This script rebuilds the missing under-$100K average-size input
#             from Charlie's figure 8 and figure 9 logic.
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
  charlie_bank_output_dir,
  "bank_fig10_avg_loan_size.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

fig10_data <- build_cra_under100k_average_size()


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig10_plot <- ggplot(fig10_data, aes(x = year, y = avg_size)) +
  geom_line(color = "#2E75B6", linewidth = 1.1) +
  geom_point(color = "#2E75B6", size = 2) +
  scale_y_continuous(labels = scales::label_dollar()) +
  labs(
    title = "Figure 10: Average Small Business Loan Size (Under $100K Category)",
    subtitle = "2000-2023",
    x = "Year",
    y = "Average Loan Size ($)",
    caption = "Data: CRA aggregate files; rebuilt locally from Charlie's figure 8 and figure 9 logic."
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig10_plot, output_file, width = 10, height = 5)
