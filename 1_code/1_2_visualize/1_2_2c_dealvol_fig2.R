#///////////////////////////////////////////////////////////////////////////////
#----     Figure 2c: VC Capital Committed (State-level, single year)     ----
# File name:  1_2_2c_dealvol_fig2.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-02-03
# Purpose:    Plot venture capital deal volume per 1M residents
#             for the most recent year with numerator+denominator data.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
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
      legend.position = "none",
      plot.title = element_text(face = "bold"),
      axis.title = element_text(face = "bold")
    )
}

# --- Helper to save with consistent spec
save_fig <- function(p, filename, w = 9.5, h = 10, dpi = 320) {
  ggsave(filename, p, width = w, height = h, dpi = dpi, bg = "white")
}

# -----------------------------
# 1) Load inputs
# -----------------------------

dealvol_raw <- readxl::read_xlsx(
  file.path("0_inputs", "Pitchbook", "Pitchbook_dealvol.xlsx")
)

participation <- readr::read_csv(
  file.path("0_inputs", "CORI", "fips_participation.csv"),
  show_col_types = FALSE
)

state_fips <- readr::read_csv(
  file.path("0_inputs", "state_fips.csv"),
  show_col_types = FALSE
)

# -----------------------------
# 2) Determine most recent common year
# -----------------------------

dealvol_years <- names(dealvol_raw)[-1] |> as.integer()
participation_years <- participation$year |> as.integer()

year_use <- intersect(dealvol_years, participation_years) |>
  max(na.rm = TRUE)

if (!is.finite(year_use)) {
  stop("No common year found between Pitchbook deal volume and participation data.")
}

# -----------------------------
# 3) Build state-level normalization
# -----------------------------

state_lookup <- state_fips |>
  filter(FIPS_CODE != "11") |>
  transmute(
    state_fips = stringr::str_pad(as.character(FIPS_CODE), width = 2, pad = "0"),
    state_name = stringr::str_to_title(tolower(STATE_NAME)),
    state_name_key = tolower(STATE_NAME)
  )

dealvol_state <- dealvol_raw |>
  pivot_longer(-State, names_to = "year", values_to = "dealvol") |>
  mutate(
    year = as.integer(year),
    state_name_key = tolower(State)
  ) |>
  filter(year == year_use)

population_state <- participation |>
  mutate(
    FIPS = stringr::str_pad(as.character(FIPS), width = 2, pad = "0"),
    Participation = readr::parse_number(as.character(Participation)),
    Force = readr::parse_number(as.character(Force)),
    year = as.integer(year)
  ) |>
  filter(year == year_use) |>
  transmute(
    state_fips = FIPS,
    population = Force / (Participation / 100)
  )

state_data <- dealvol_state |>
  left_join(state_lookup, by = "state_name_key") |>
  left_join(population_state, by = "state_fips") |>
  filter(!is.na(state_fips)) |>
  mutate(
    per_million = dealvol / (population / 1000000)
  ) |>
  arrange(desc(per_million))

# -----------------------------
# 4) Plot
# -----------------------------

subtitle_text <- paste0("Year used: ", year_use)

state_data |>
  ggplot(aes(x = reorder(state_name, per_million), y = per_million)) +
  geom_col(fill = "#1f4e79") +
  geom_text(
    aes(label = scales::label_comma()(per_million)),
    hjust = -0.05,
    size = 2.6
  ) +
  coord_flip() +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title = "Venture Capital Capital Committed per 1M Residents",
    subtitle = subtitle_text,
    x = NULL,
    y = "USD (Millions) per 1M residents (BLS - noninstitutionalized)",
    caption = "Source: Pitchbook Venture Capital Monitor Q4 2025. Population estimated from labor force participation."
  ) +
  theme_im() -> vc_dealvol_states

save_fig(
  p = vc_dealvol_states,
  filename = file.path(output_dir, "2c_vc_capcommitted_states.jpeg")
)

message("Year used for normalization: ", year_use)
