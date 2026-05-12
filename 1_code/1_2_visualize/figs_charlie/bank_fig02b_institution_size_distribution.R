#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig02b_institution_size_distribution.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 2b. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig02b_institution_size_distribution.py
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
  "bank_fig02b_institution_size_distribution.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

sod_2024 <- load_fdic_sod(2024) |>
  filter(STALPBR == "WI")

hq_counts <- sod_2024 |>
  count(CERT, name = "branches")

bucket_levels <- c("1", "2-5", "6-10", "11-20", "21-50", "50+")

fig02b_data <- hq_counts |>
  mutate(
    bucket = cut(
      branches,
      breaks = c(0, 2, 6, 11, 21, 51, 300),
      labels = bucket_levels,
      right = FALSE
    )
  ) |>
  count(bucket, name = "n_institutions") |>
  complete(bucket = factor(bucket_levels, levels = bucket_levels),
           fill = list(n_institutions = 0))

stats_text <- glue::glue(
  "Mean: {round(mean(hq_counts$branches), 1)}  |  Median: {round(median(hq_counts$branches), 0)}  |  Total: {nrow(hq_counts)}"
)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig02b_plot <- ggplot(fig02b_data, aes(x = bucket, y = n_institutions)) +
  geom_col(fill = "#2E75B6", width = 0.7) +
  geom_text(aes(label = n_institutions), vjust = -0.35, size = 3.2) +
  annotate(
    "label",
    x = 6,
    y = max(fig02b_data$n_institutions) * 0.92,
    label = stats_text,
    hjust = 1,
    size = 3,
    fill = "white",
    color = "black"
  ) +
  labs(
    title = "Figure 2b: Wisconsin Banking Institutions by Number of Branches (2024)",
    x = "Number of Branches",
    y = "Number of Institutions",
    caption = "Data: FDIC Summary of Deposits"
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig02b_plot, output_file, width = 9, height = 5)
