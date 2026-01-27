#///////////////////////////////////////////////////////////////////////////////
#----                  Figure 1: VC Deal Count (WI vs US)                 ----
# File name:  1_2_1_vc_dealcount_fig1.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot venture capital deal count time series comparisons.
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

count_ts_data <- readRDS(file.path("2_processed_data", "count_ts_data.rds"))

avg_label <- "2015–2025 average"
avg_data <- count_ts_data |>
  filter(year >= 2015, year <= 2025) |>
  summarise(
    dealcount_national = mean(dealcount_national, na.rm = TRUE),
    dealcount_national_nonoutlier = mean(dealcount_national_nonoutlier, na.rm = TRUE),
    dealcount_midwest = mean(dealcount_midwest, na.rm = TRUE),
    dealcount_wi = mean(dealcount_wi, na.rm = TRUE)
  ) |>
  pivot_longer(
    cols = c(
      dealcount_national,
      dealcount_national_nonoutlier,
      dealcount_midwest,
      dealcount_wi
    ),
    names_to = "series",
    values_to = "dealcount"
  ) |>
  mutate(
    series = recode(series,
                    dealcount_national = "National avg.",
                    dealcount_national_nonoutlier = "National avg. (excl. CA, MA, NY)",
                    dealcount_wi = "Wisconsin",
                    dealcount_midwest = "Midwest avg. (excl. WI)"
    ),
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

nat_avg <- avg_data |>
  filter(series == "National avg.") |>
  summarise(nat_avg = first(dealcount)) |>
  pull(nat_avg)

avg_data <- avg_data |>
  mutate(pct_of_nat = dealcount / nat_avg)

# -----------------------------
# 2) Plot
# -----------------------------

avg_data |>
  ggplot(aes(x = avg_label, y = dealcount, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        TRUE ~ NA_character_
      )),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest avg. (excl. WI)" = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg." = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Deal Count: Wisconsin vs National Average",
    subtitle = "2015–2025 average",
    x        = NULL,
    y        = "Number of deals",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q3 2025. Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealcount

save_fig(
  p = vc_dealcount,
  filename = file.path(output_dir, "1_vc_dealcount.jpeg"),
  w = 16.5,
  h = 5.5
)
