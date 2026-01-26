#///////////////////////////////////////////////////////////////////////////////
#----          Figure 17: Avg Form D Amount Raised per Entity              ----
# File name:  1_2_17_fig17.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot average dollars raised per business, metro vs rural.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
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

formd_yearly_avg_raised_biz <- readRDS(file.path("2_processed_data", "formd_yearly_avg_raised_biz.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

formd_yearly_avg_raised_biz |>
  ggplot(aes(x = year, y = average_raised, color = rucc_type, group = rucc_type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  scale_x_continuous(breaks = sort(unique(formd_yearly_avg_raised_biz$year))) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_color_manual(
    values = c(
      "metro" = "blue",
      "rural" = "purple"
    ),
    name = "RUCC type"
  ) +
  labs(
    title    = "Average Form D deal size by year, metro vs rural",
    subtitle = "2015–2024; average dollars raised per business",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC."
  ) +
  theme_im() +
  theme(legend.position = "bottom") -> x

save_fig(
  p        = x,
  filename = file.path(output_dir, "17_formD_yearly_avg_raised_biz.jpeg"),
  w        = 16.5,
  h        = 5.5
)
