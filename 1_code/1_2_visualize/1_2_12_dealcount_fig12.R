#///////////////////////////////////////////////////////////////////////////////
#----         Figure 12: Form D Deal Count by Region and RUCC             ----
# File name:  1_2_12_dealcount_fig12.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot Form D deal counts per average state by region.
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

cnt_all <- readRDS(file.path("2_processed_data", "cnt_all.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

cnt_label_df <- cnt_all |>
  group_by(year, year_idx, series, x_pos, pct_of_nat) |>
  summarise(total_value = sum(value, na.rm = TRUE), .groups = "drop")

cnt_x_breaks <- unique(cnt_all$year_idx)
cnt_x_labels <- as.character(sort(unique(cnt_all$year)))

vc_formd_dealcount <- ggplot(
  cnt_all,
  aes(
    x       = x_pos,
    y       = value,
    fill    = series,
    pattern = rucc_grp
  )
) +
  ggpattern::geom_col_pattern(
    color           = "grey30",
    pattern_density = 0.35,
    pattern_spacing = 0.02,
    pattern_colour  = "black"
  ) +
  geom_text(
    data = cnt_label_df,
    mapping = aes(
      x     = x_pos,
      y     = total_value,
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1)
      ),
      group = series
    ),
    inherit.aes = FALSE,
    vjust       = -0.4,
    size        = 3,
    na.rm       = TRUE
  ) +
  scale_x_continuous(
    breaks = cnt_x_breaks,
    labels = cnt_x_labels
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
  ggpattern::scale_pattern_manual(
    values = c(
      "metro/metro-adjacent" = "none",
      "rural"                = "stripe"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Form D Deal Count per Average State, by Region and RUCC",
    subtitle = "2015–2024; bars show average number of Form D filings per state; pattern shows metro vs rural counties",
    x        = "Year",
    y        = "Average Form D filings per state",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

save_fig(
  p        = vc_formd_dealcount,
  filename = file.path(output_dir, "12_formD_dealcount_time.jpeg"),
  w        = 16.5,
  h        = 5.5
)
