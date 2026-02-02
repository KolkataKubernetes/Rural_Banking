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
  library(jsonlite)
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
    state_abbr = stringr::str_extract(name_co, "[A-Z]{2}$"),
    state_fips = stringr::str_pad(as.character(geoid_co), 5, pad = "0") |>
      substr(1, 2)
  )

top3_states <- county_props |>
  group_by(state_abbr) |>
  summarise(total_amount = sum(total_amount_raised, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(total_amount)) |>
  slice_head(n = 3) |>
  pull(state_abbr)

top3_label <- paste0("Top 3 (", paste(top3_states, collapse = ", "), ")")

state_force <- readr::read_csv(
  file.path("0_inputs", "CORI", "fips_participation.csv"),
  show_col_types = FALSE
) |>
  mutate(FIPS = stringr::str_pad(as.character(FIPS), width = 2, pad = "0")) |>
  filter(year >= 2010) |>
  group_by(FIPS) |>
  summarise(total_force = sum(Force, na.rm = TRUE), .groups = "drop")

formd_yearly_averages <- county_props |>
  group_by(state_abbr, state_fips) |>
  summarise(total_amount = sum(total_amount_raised, na.rm = TRUE), .groups = "drop") |>
  left_join(state_force, by = c("state_fips" = "FIPS")) |>
  mutate(
    per_million = total_amount / (total_force / 1000000)
  ) |>
  mutate(
    grp = case_when(
      state_abbr %in% top3_states ~ top3_label,
      state_abbr == "WI" ~ "WI",
      TRUE ~ "All other states"
    )
  ) |>
  group_by(grp) |>
  summarise(mean_amount = sum(per_million, na.rm = TRUE), .groups = "drop")

# -----------------------------
# 2) Plot
# -----------------------------

formd_yearly_averages |>
  ggplot(aes(x = "", y = mean_amount, fill = grp)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_manual(
    values = c(
      top3_label = "grey60",
      "WI" = "#c5050c",
      "All other states" = "blue"
    ),
    name = NULL
  ) +
  labs(
    title    = "Form D filing amounts",
    subtitle = "Since 2010; per 1,000,000 workers (CORI interactive map)",
    x        = NULL,
    y        = NULL,
    caption  = "Source: CORI Form D interactive map (since 2010). Values are per 1,000,000 workers; 2025 updates may not be reflected."
  ) +
  theme_im() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    legend.position = "bottom"
  ) -> x

save_fig(
  p        = x,
  filename = file.path(output_dir, "15_formD_yearly_averages.jpeg"),
  w        = 16.5,
  h        = 5.5
)
