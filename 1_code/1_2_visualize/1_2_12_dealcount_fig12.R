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
  library(jsonlite)
  library(scales)
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

formd_json <- jsonlite::fromJSON(
  file.path("0_inputs", "upstream", "formd-interactive-map", "src", "data", "formd_map.json")
)

county_props <- as_tibble(formd_json$features$properties) |>
  mutate(
    state_abbr = stringr::str_extract(name_co, "[A-Z]{2}$")
  )

participation <- readr::read_csv(
  file.path("0_inputs", "CORI", "fips_participation.csv"),
  show_col_types = FALSE
) |>
  mutate(
    FIPS = stringr::str_pad(as.character(FIPS), width = 2, pad = "0"),
    Participation = readr::parse_number(as.character(Participation)),
    Force = readr::parse_number(as.character(Force))
  )

midwest_excl_wi <- c("MN", "IA", "IL", "MI", "IN")
big3            <- c("CA", "MA", "NY")
wi_abbr         <- "WI"

avg_label <- "Since 2010"

state_totals <- county_props |>
  group_by(state_abbr) |>
  summarise(total_dealcount = sum(num_funded_entities, na.rm = TRUE), .groups = "drop")

state_population <- participation |>
  filter(year >= 2010, year <= 2024) |>
  mutate(population = Force / (Participation / 100)) |>
  group_by(FIPS) |>
  summarise(sum_population = sum(population, na.rm = TRUE), .groups = "drop")

state_fips_map <- county_props |>
  mutate(state_fips = stringr::str_pad(as.character(geoid_co), 5, pad = "0") |>
    substr(1, 2)) |>
  distinct(state_fips, state_abbr)

state_population <- state_population |>
  left_join(state_fips_map, by = c("FIPS" = "state_fips"))

summarise_group <- function(df, states, label) {
  df |>
    filter(state_abbr %in% states) |>
    summarise(total_value = sum(total_dealcount, na.rm = TRUE), .groups = "drop") |>
    mutate(series = label)
}

all_states <- sort(unique(state_totals$state_abbr))

cnt_avg <- bind_rows(
  summarise_group(state_totals, all_states, "National"),
  summarise_group(state_totals, setdiff(all_states, big3), "National (excl. CA, MA, NY)"),
  summarise_group(state_totals, midwest_excl_wi, "Midwest (excl. WI)"),
  summarise_group(state_totals, wi_abbr, "Wisconsin")
) |>
  mutate(
    avg_value = total_value,
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

population_groups <- bind_rows(
  state_population |>
    summarise(sum_population = sum(sum_population, na.rm = TRUE), .groups = "drop") |>
    mutate(series = "National"),
  state_population |>
    filter(!state_abbr %in% big3) |>
    summarise(sum_population = sum(sum_population, na.rm = TRUE), .groups = "drop") |>
    mutate(series = "National (excl. CA, MA, NY)"),
  state_population |>
    filter(state_abbr %in% midwest_excl_wi) |>
    summarise(sum_population = sum(sum_population, na.rm = TRUE), .groups = "drop") |>
    mutate(series = "Midwest (excl. WI)"),
  state_population |>
    filter(state_abbr %in% wi_abbr) |>
    summarise(sum_population = sum(sum_population, na.rm = TRUE), .groups = "drop") |>
    mutate(series = "Wisconsin")
) |>
  select(series, sum_population)

cnt_avg <- cnt_avg |>
  left_join(population_groups, by = "series") |>
  mutate(
    per_million = avg_value / (sum_population / 1000000)
  )

nat_avg <- cnt_avg |>
  filter(series == "National") |>
  summarise(nat_avg = first(per_million)) |>
  pull(nat_avg)

cnt_avg <- cnt_avg |>
  mutate(pct_of_nat = per_million / nat_avg)

# -----------------------------
# 2) Plot
# -----------------------------

vc_formd_dealcount <- ggplot(
  cnt_avg,
  aes(
    x    = avg_label,
    y    = per_million,
    fill = series
  )
) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65, color = "grey30") +
  geom_text(
    mapping = aes(
      y     = per_million,
      label = dplyr::case_when(
        series == "National" ~ NA_character_,
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
      "National"                    = "black",
      "National (excl. CA, MA, NY)" = "grey60",
      "Midwest (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Form D Deal Count",
    subtitle = "Since 2010 (year coverage may not include 2025)",
    x        = NULL,
    y        = "Form D filings per 1,000,000 residents",
    caption  = "Source: CORI Form D interactive map (since 2010). Population estimated from labor force participation (no 2025 annual data). BLS annual 2025 data were checked but not found."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

save_fig(
  p        = vc_formd_dealcount,
  filename = file.path(output_dir, "12_formD_dealcount_avg.jpeg"),
  w        = 16.5,
  h        = 5.5
)
