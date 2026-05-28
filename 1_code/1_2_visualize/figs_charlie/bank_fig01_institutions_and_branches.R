#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig01_institutions_and_branches.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 1. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig01_institutions_and_branches.py
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
  "bank_fig01_institutions_and_branches.jpeg"
)

figreport_output_file <- file.path(
  charlie_bank_output_dir,
  "bank_fig01_institutions_and_branches_figreport.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

fig01_data <- map_dfr(fdic_available_years(), function(year) {
  wi <- load_fdic_sod(year) |>
    filter(STALPBR == "WI")

  tibble(
    year = year,
    n_institutions = n_distinct(wi$CERT),
    n_branches = nrow(wi)
  )
}) |>
  arrange(year)

# The report's embedded Figure 1 uses the commercial-bank subset only.
# In the staged SOD files, that aligns with BKCLASS values NM, N, and SM.
fig01_figreport_data <- map_dfr(fdic_available_years(), function(year) {
  wi_commercial <- load_fdic_sod(year) |>
    filter(
      STALPBR == "WI",
      BKCLASS %in% c("NM", "N", "SM")
    )

  tibble(
    year = year,
    n_institutions = n_distinct(wi_commercial$CERT),
    n_branches = nrow(wi_commercial)
  )
}) |>
  arrange(year)

fig01_long <- fig01_data |>
  transmute(
    year,
    Institutions = n_institutions,
    Branches = n_branches
  ) |>
  pivot_longer(
    cols = c(Institutions, Branches),
    names_to = "series",
    values_to = "value"
  ) |>
  mutate(
    series = factor(series, levels = c("Institutions", "Branches"))
  )

fig01_figreport_long <- fig01_figreport_data |>
  transmute(
    year,
    Institutions = n_institutions,
    Branches = n_branches
  ) |>
  pivot_longer(
    cols = c(Institutions, Branches),
    names_to = "series",
    values_to = "value"
  ) |>
  mutate(
    series = factor(series, levels = c("Institutions", "Branches"))
  )


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig01_plot <- ggplot(fig01_long, aes(x = year, y = value, color = series, shape = series)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.4) +
  scale_color_manual(
    values = c("Institutions" = "#BF4D28", "Branches" = "#2E75B6")
  ) +
  scale_shape_manual(
    values = c("Institutions" = 16, "Branches" = 15)
  ) +
  scale_x_continuous(
    breaks = seq(min(fig01_data$year), max(fig01_data$year), by = 2)
  ) +
  scale_y_continuous(
    limits = c(0, 2500),
    breaks = seq(0, 2500, by = 250)
  ) +
  labs(
    title = "Figure 1: Wisconsin Banking Institutions and Branches (2000-2024)",
    x = "Year",
    y = "Count",
    color = NULL,
    shape = NULL,
    caption = "Data: FDIC Summary of Deposits"
  ) +
  charlie_theme() +
  theme(
    legend.position = "right",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

fig01_figreport_plot <- ggplot(
  fig01_figreport_long,
  aes(x = year, y = value, color = series, shape = series)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.4) +
  scale_color_manual(
    values = c("Institutions" = "#BF4D28", "Branches" = "#2E75B6")
  ) +
  scale_shape_manual(
    values = c("Institutions" = 16, "Branches" = 15)
  ) +
  scale_x_continuous(
    breaks = seq(min(fig01_figreport_data$year), max(fig01_figreport_data$year), by = 2)
  ) +
  scale_y_continuous(
    limits = c(0, 2500),
    breaks = seq(0, 2500, by = 250)
  ) +
  labs(
    title = "Figure 1: Commercial Bank Institutions & Branches in Wisconsin (All Loans)",
    x = "Year",
    y = "Count",
    color = NULL,
    shape = NULL,
    caption = "Data: FDIC Summary of Deposits"
  ) +
  charlie_theme() +
  theme(
    legend.position = "right",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig01_plot, output_file, width = 10, height = 5)
save_charlie_fig(fig01_figreport_plot, figreport_output_file, width = 10, height = 5)
