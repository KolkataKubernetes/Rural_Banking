#///////////////////////////////////////////////////////////////////////////////
#----         Figure 2b: VC Capital Committed (BFS-normalized)            ----
# File name:  1_2_2b_vc_dealvol_fig2.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-02-03
# Purpose:    Plot venture capital deal volume per BFS applications.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

output_dir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_02_03"
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

vol_ts_data <- readRDS(file.path("2_processed_data", "vol_ts_data.rds"))

bfs <- readRDS(file.path("2_processed_data", "BFS_county.rds")) |>
  mutate(
    state_fips = stringr::str_pad(as.character(state_fips), width = 2, pad = "0")
  )

avg_label <- "2015–2024 total"

avg_data <- vol_ts_data |>
  filter(year >= 2015, year <= 2024) |>
  summarise(
    dealvol_national = sum(dealvol_national, na.rm = TRUE),
    dealvol_national_nonoutlier = sum(dealvol_national_nonoutlier, na.rm = TRUE),
    dealvol_midwest = sum(dealvol_midwest, na.rm = TRUE),
    dealvol_wi = sum(dealvol_wi, na.rm = TRUE)
  ) |>
  pivot_longer(
    cols = c(
      dealvol_national,
      dealvol_national_nonoutlier,
      dealvol_midwest,
      dealvol_wi
    ),
    names_to = "series",
    values_to = "dealvol"
  ) |>
  mutate(
    series = recode(series,
                    dealvol_national = "National",
                    dealvol_national_nonoutlier = "National (excl. CA, MA, NY)",
                    dealvol_midwest = "Midwest (excl. WI)",
                    dealvol_wi = "Wisconsin"
    ),
    series = factor(
      series,
      levels = c(
        "National",
        "National (excl. CA, MA, NY)",
        "Midwest (excl. WI)",
        "Wisconsin"
      )
    )
  )

midwest_excl_wi <- c("27", "19", "17", "26", "18")
big3            <- c("06", "25", "36")
wi_fips         <- "55"

bfs_by_state <- bfs |>
  filter(year >= 2015, year <= 2024) |>
  group_by(state_fips) |>
  summarise(sum_apps = sum(business_app, na.rm = TRUE), .groups = "drop")

summarise_group <- function(df, states, label) {
  df |>
    filter(state_fips %in% states) |>
    summarise(sum_apps = sum(sum_apps, na.rm = TRUE), .groups = "drop") |>
    mutate(series = label)
}

all_states <- sort(unique(bfs_by_state$state_fips))

bfs_groups <- bind_rows(
  summarise_group(bfs_by_state, all_states, "National"),
  summarise_group(bfs_by_state, setdiff(all_states, big3), "National (excl. CA, MA, NY)"),
  summarise_group(bfs_by_state, midwest_excl_wi, "Midwest (excl. WI)"),
  summarise_group(bfs_by_state, wi_fips, "Wisconsin")
)

avg_data <- avg_data |>
  left_join(bfs_groups, by = "series") |>
  mutate(
    per_thousand_apps = dealvol / (sum_apps / 1000),
    series = factor(
      series,
      levels = c(
        "National",
        "National (excl. CA, MA, NY)",
        "Midwest (excl. WI)",
        "Wisconsin"
      )
    )
  )

# -----------------------------
# 2) Plot
# -----------------------------

avg_data |>
  ggplot(aes(x = avg_label, y = per_thousand_apps, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(label = scales::label_comma()(per_thousand_apps)),
    position = position_dodge(width = 0.75),
    vjust = -0.4,
    size = 3
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest (excl. WI)" = "blue",
      "National (excl. CA, MA, NY)" = "grey60",
      "National" = "black"
    ),
    breaks = c(
      "National",
      "National (excl. CA, MA, NY)",
      "Midwest (excl. WI)",
      "Wisconsin"
    )
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Capital Committed: Wisconsin vs National Average",
    subtitle = "2015–2024 total",
    x        = NULL,
    y        = "USD (Millions) per 1,000 business applications",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q4 2025. Denominator: BFS business applications summed 2015–2024. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealvol_bfs

save_fig(
  p = vc_dealvol_bfs,
  filename = file.path(output_dir, "2b_2_vc_capcommitted.jpeg"),
  w = 16.5,
  h = 5.5
)
