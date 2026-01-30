#///////////////////////////////////////////////////////////////////////////////
#----       Figure 7: Age 0 Business Births per Labor Force               ----
# File name:  1_2_7_newfirms_laborforce_fig7.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot age-0 business births normalized by labor force.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2"
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

grp_all_lf <- readRDS(file.path("2_processed_data", "grp_all_lf.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

grp_all_lf |>
  select(year, firmcount, group, pct_of_nat) |>
  mutate(
    series = factor(
      group,
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  ) |>
  ggplot(aes(x = factor(year), y = firmcount, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        TRUE ~ NA_character_
      )
    ),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin"                  = "#c5050c",
      "Midwest avg. (excl. WI)"    = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg."              = "black"
    )
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Business Age 0 Births Per 100,000 labor force participants",
    subtitle = "2015–2024",
    x        = "Year",
    y        = "Average Firms per Labor Force Participant",
    fill     = NULL,
    caption  = "Source: US Census BDS; labor participation from CPS/LAUS. Percents above each bar refer to the percent of the normalized National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> new_firms_normalized

save_fig(
  p        = new_firms_normalized,
  filename = file.path(output_dir, "7_new_firms_barplot_normalized_lfp.jpeg"),
  w        = 16.5,
  h        = 5.5
)
