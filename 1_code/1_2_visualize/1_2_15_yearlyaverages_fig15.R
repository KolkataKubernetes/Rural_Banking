#///////////////////////////////////////////////////////////////////////////////
#----              Figure 15: Form D Yearly Averages                       ----
# File name:  1_2_15_yearlyaverages_fig15.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot yearly average Form D filing amounts by group.
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

formd_yearly_averages <- readRDS(file.path("2_processed_data", "formd_yearly_averages.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

formd_yearly_averages |>
  ggplot(aes(x = mean_amount, y = grp, fill = rucc_type)) +
  geom_col(position = position_dodge(width = 0.8)) +
  scale_x_continuous(labels = scales::label_comma()) +
  scale_fill_manual(
    values = c(
      "metro" = "blue",
      "rural" = "purple"
    ),
    name = "RUCC type"
  ) +
  labs(
    title    = "Form D filing amounts, yearly averages",
    subtitle = "2015–2024; average incremental dollars per Form D filing",
    x        = "Amount Raised (USD)",
    y        = "",
    caption  = "Source: SEC Form D; USDA RUCC. Values calculated by averaging across years for each group."
  ) +
  theme_im() +
  theme(legend.position = "bottom") -> x

save_fig(
  p        = x,
  filename = file.path(output_dir, "15_formD_yearly_averages.jpeg"),
  w        = 16.5,
  h        = 5.5
)
