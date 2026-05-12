#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig02_branch_institution_ratio.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 2. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig02_branch_institution_ratio.py
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
  "bank_fig02_branch_institution_ratio.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

fig02_data <- map_dfr(fdic_available_years(), function(year) {
  wi <- load_fdic_sod(year) |>
    filter(STALPBR == "WI")

  branch_counts <- wi |>
    count(CERT, name = "branches")

  tibble(
    year = year,
    median = median(branch_counts$branches, na.rm = TRUE),
    mean = mean(branch_counts$branches, na.rm = TRUE)
  )
}) |>
  arrange(year)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig02_plot <- ggplot(fig02_data, aes(x = year)) +
  geom_line(aes(y = median, color = "Median"), linewidth = 1.1) +
  geom_point(aes(y = median, color = "Median"), size = 2) +
  geom_line(
    aes(y = mean, color = "Mean"),
    linewidth = 1.1,
    linetype = "dashed"
  ) +
  geom_point(aes(y = mean, color = "Mean"), shape = 15, size = 2) +
  scale_color_manual(
    values = c("Median" = "#2E75B6", "Mean" = "#BF4D28")
  ) +
  scale_x_continuous(
    breaks = seq(min(fig02_data$year), max(fig02_data$year), by = 2)
  ) +
  labs(
    title = "Figure 2: Median and Mean Branches per Banking Institution (2000-2024)",
    x = "Year",
    y = "Branches per Institution",
    color = NULL,
    caption = "Data: FDIC Summary of Deposits"
  ) +
  charlie_theme() +
  theme(
    legend.position = "top",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig02_plot, output_file, width = 10, height = 5)
