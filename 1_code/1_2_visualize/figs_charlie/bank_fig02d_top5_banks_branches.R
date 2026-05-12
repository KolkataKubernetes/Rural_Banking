#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig02d_top5_banks_branches.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 2d. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig02d_top5_banks_branches.py
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
  "bank_fig02d_top5_banks_branches.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

top5_branches <- load_fdic_sod(2024) |>
  filter(STALPBR == "WI") |>
  count(CERT, NAMEFULL, name = "branches") |>
  arrange(desc(branches)) |>
  slice_head(n = 5) |>
  mutate(
    label = trim_bank_name(NAMEFULL),
    label = forcats::fct_rev(factor(label, levels = label))
  )


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig02d_plot <- ggplot(top5_branches, aes(x = branches, y = label)) +
  geom_col(fill = "#2E75B6", width = 0.6) +
  geom_text(aes(label = branches), hjust = -0.1, size = 3.2) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Figure 2d: Top 5 Banks by Number of Wisconsin Branches (2024)",
    x = "Number of Branches in Wisconsin",
    y = NULL,
    caption = "Data: FDIC Summary of Deposits"
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig02d_plot, output_file, width = 9, height = 4.2)
