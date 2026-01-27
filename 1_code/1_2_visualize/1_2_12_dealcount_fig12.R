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

formd_complete <- readRDS(file.path("2_processed_data", "formd_complete.rds"))

midwest_excl_wi <- c("27", "19", "17", "26", "18")
big3            <- c("06", "25", "36")
wi_fips         <- "55"

avg_label <- "2016–2025 total"

state_year <- formd_complete |>
  filter(year >= 2016, year <= 2025) |>
  group_by(year, st) |>
  summarise(dealcount = sum(dealcount, na.rm = TRUE), .groups = "drop")

state_totals <- state_year |>
  group_by(st) |>
  summarise(total_dealcount = sum(dealcount, na.rm = TRUE), .groups = "drop")

summarise_group <- function(df, states, label) {
  df |>
    filter(st %in% states) |>
    summarise(avg_value = mean(total_dealcount, na.rm = TRUE), .groups = "drop") |>
    mutate(series = label)
}

all_states <- sort(unique(state_totals$st))

cnt_avg <- bind_rows(
  summarise_group(state_totals, all_states, "National avg."),
  summarise_group(state_totals, setdiff(all_states, big3), "National avg. (excl. CA, MA, NY)"),
  summarise_group(state_totals, midwest_excl_wi, "Midwest avg. (excl. WI)"),
  summarise_group(state_totals, wi_fips, "Wisconsin")
) |>
  mutate(
    series = factor(
      series,
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  )

nat_avg <- cnt_avg |>
  filter(series == "National avg.") |>
  summarise(nat_avg = first(avg_value)) |>
  pull(nat_avg)

cnt_avg <- cnt_avg |>
  mutate(pct_of_nat = avg_value / nat_avg)

# -----------------------------
# 2) Plot
# -----------------------------

vc_formd_dealcount <- ggplot(
  cnt_avg,
  aes(
    x    = avg_label,
    y    = avg_value,
    fill = series
  )
) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65, color = "grey30") +
  geom_text(
    mapping = aes(
      y     = avg_value,
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1)
      ),
      group = series
    ),
    position = position_dodge(width = 0.75),
    vjust = -0.4,
    size = 3,
    na.rm = TRUE
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
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Form D Deal Count per Average State",
    subtitle = "2016–2025 total",
    x        = NULL,
    y        = "Average Form D filings per state",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

save_fig(
  p        = vc_formd_dealcount,
  filename = file.path(output_dir, "12_formD_dealcount_avg.jpeg"),
  w        = 16.5,
  h        = 5.5
)
