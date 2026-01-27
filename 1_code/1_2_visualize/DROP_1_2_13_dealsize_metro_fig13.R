#///////////////////////////////////////////////////////////////////////////////
#----     Figure 13: Form D Deal Size (Metro/Metro-Adjacent)               ----
# File name:  1_2_13_dealsize_metro_fig13.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot Form D deal size per average metro/adjacent state.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/test_figures"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# --- Minimal, clean theme
theme_im <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.caption.position = "plot",
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_line(linewidth = 0.3),
      panel.grid.major.y = element_line(linewidth = 0.3),
      legend.position = "top",
      legend.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold"),
      axis.title = element_text(face = "bold")
    )
}

# --- Helper to save with consistent spec
save_fig <- function(p, filename, w = 7, h = 4.2, dpi = 320) {
  ggsave(filename, p, width = w, height = h, dpi = dpi, bg = "white")
}

# -----------------------------
# 1) Load intermediate data
# -----------------------------

metro_all <- readRDS(file.path("2_processed_data", "metro_all.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

vc_formd_dealsize_metro <- metro_all |>
  ggplot(aes(x = factor(year), y = value, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1.0)
      )
    ),
    position = position_dodge(width = 0.75),
    vjust    = -0.6,
    size     = 3,
    na.rm    = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Form D Deal Size per Average State, Metro & Metro-Adjacent Counties",
    subtitle = "2015–2024; average incremental dollars per Form D filing in the average metro/adjacent state",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to the national metro average."
  ) +
  theme_im()

save_fig(
  p        = vc_formd_dealsize_metro,
  filename = file.path(output_dir, "13_formD_dealsize_metro.jpeg"),
  w        = 16.5,
  h        = 5.5
)
