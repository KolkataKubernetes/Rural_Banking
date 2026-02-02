#///////////////////////////////////////////////////////////////////////////////
#----                Figure 2: VC Capital Committed (WI vs US)            ----
# File name:  1_2_2_vc_dealvol_fig2.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Plot venture capital deal volume time series comparisons.
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

vol_ts_data <- readRDS(file.path("2_processed_data", "vol_ts_data.rds"))

participation <- readr::read_csv(
  file.path("0_inputs", "CORI", "fips_participation.csv"),
  show_col_types = FALSE
) |>
  mutate(
    FIPS = stringr::str_pad(as.character(FIPS), width = 2, pad = "0"),
    Participation = readr::parse_number(as.character(Participation)),
    Force = readr::parse_number(as.character(Force))
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

population_by_state <- participation |>
  filter(year >= 2015, year <= 2024) |>
  mutate(population = Force / (Participation / 100)) |>
  group_by(FIPS) |>
  summarise(sum_population = sum(population, na.rm = TRUE), .groups = "drop")

summarise_group <- function(df, states, label) {
  df |>
    filter(FIPS %in% states) |>
    summarise(sum_population = sum(sum_population, na.rm = TRUE), .groups = "drop") |>
    mutate(series = label)
}

all_states <- sort(unique(population_by_state$FIPS))

population_groups <- bind_rows(
  summarise_group(population_by_state, all_states, "National"),
  summarise_group(population_by_state, setdiff(all_states, big3), "National (excl. CA, MA, NY)"),
  summarise_group(population_by_state, midwest_excl_wi, "Midwest (excl. WI)"),
  summarise_group(population_by_state, wi_fips, "Wisconsin")
)

avg_data <- avg_data |>
  left_join(population_groups, by = "series") |>
  mutate(
    per_million = dealvol / (sum_population / 1000000),
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
  ggplot(aes(x = avg_label, y = per_million, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(label = scales::label_comma()(per_million)),
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
    y        = "USD (Millions) per 1M residents (BLS - noninstitutionalized)",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q4 2025. Population estimated from labor force participation (no 2025 annual data). Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealvol

save_fig(
  p = vc_dealvol,
  filename = file.path(output_dir, "2_vc_capcommitted.jpeg"),
  w = 16.5,
  h = 5.5
)
