#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig09_lending_volume_growth.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 9. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig09_lending_volume_growth.py
#///////////////////////////////////////////////////////////////////////////////


# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

# Shared helper centralizes repeated local-data parsing and save logic.
source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

output_file <- file.path(
  charlie_bank_output_dir,
  "bank_fig09_lending_volume_growth.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

cra_volume <- load_cra_wi_volume_series() |>
  left_join(load_wi_population_from_participation(2000:2023), by = "year") |>
  mutate(
    loans_u100k_idx = (loans_u100k_amt / population * 10000) /
      first(loans_u100k_amt / population * 10000) * 100,
    loans_100_250_idx = (loans_100_250_amt / population * 10000) /
      first(loans_100_250_amt / population * 10000) * 100,
    loans_250_1m_idx = (loans_250_1m_amt / population * 10000) /
      first(loans_250_1m_amt / population * 10000) * 100
  )


# -----------------------------
# 1b) Check the decline in total dollars
# -----------------------------

# This diagnostic uses nominal statewide CRA lending dollars rather than the
# population-adjusted index plotted below. It reports the change from 2000 to
# 2023 for each loan-size bucket.
figure9_total_dollar_decline <- cra_volume |>
  select(
    year,
    loans_u100k_amt,
    loans_100_250_amt,
    loans_250_1m_amt
  ) |>
  pivot_longer(
    cols = -year,
    names_to = "bucket",
    values_to = "total_dollars"
  ) |>
  mutate(
    bucket = recode(
      bucket,
      loans_u100k_amt = "Under $100K",
      loans_100_250_amt = "$100K-$250K",
      loans_250_1m_amt = "$250K-$1M"
    )
  ) |>
  group_by(bucket) |>
  summarise(
    dollars_2000 = total_dollars[year == 2000][1],
    dollars_2023 = total_dollars[year == 2023][1],
    .groups = "drop"
  ) |>
  mutate(
    nominal_decline_dollars = dollars_2000 - dollars_2023,
    nominal_decline_percent = nominal_decline_dollars / dollars_2000 * 100
  ) |>
  arrange(match(bucket, c("Under $100K", "$100K-$250K", "$250K-$1M")))

message(
  "Figure 9 nominal-dollar decline from 2000 to 2023 by loan-size bucket ",
  "(positive values indicate a decline):"
)
print(figure9_total_dollar_decline, n = Inf, width = Inf)


# -----------------------------
# 1c) Check the decline in nominal dollars per 10K residents
# -----------------------------

figure9_per_10k_dollar_decline <- cra_volume |>
  select(
    year,
    population,
    loans_u100k_amt,
    loans_100_250_amt,
    loans_250_1m_amt
  ) |>
  pivot_longer(
    cols = ends_with("_amt"),
    names_to = "bucket",
    values_to = "total_dollars"
  ) |>
  mutate(
    bucket = recode(
      bucket,
      loans_u100k_amt = "Under $100K",
      loans_100_250_amt = "$100K-$250K",
      loans_250_1m_amt = "$250K-$1M"
    ),
    dollars_per_10k = total_dollars / population * 10000
  ) |>
  group_by(bucket) |>
  summarise(
    dollars_per_10k_2000 = dollars_per_10k[year == 2000][1],
    dollars_per_10k_2023 = dollars_per_10k[year == 2023][1],
    .groups = "drop"
  ) |>
  mutate(
    nominal_decline_dollars_per_10k =
      dollars_per_10k_2000 - dollars_per_10k_2023,
    nominal_decline_percent =
      nominal_decline_dollars_per_10k / dollars_per_10k_2000 * 100
  ) |>
  arrange(match(bucket, c("Under $100K", "$100K-$250K", "$250K-$1M")))

message(
  "Figure 9 nominal-dollar-per-10K decline from 2000 to 2023 ",
  "by loan-size bucket (positive values indicate a decline):"
)
print(figure9_per_10k_dollar_decline, n = Inf, width = Inf)


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig09_plot <- ggplot(cra_volume, aes(x = year)) +
  geom_line(aes(y = loans_u100k_idx, color = "Under $100K"), linewidth = 1.1) +
  geom_point(aes(y = loans_u100k_idx, color = "Under $100K"), size = 2) +
  geom_line(aes(y = loans_100_250_idx, color = "$100K-$250K"), linewidth = 1.1) +
  geom_point(aes(y = loans_100_250_idx, color = "$100K-$250K"), shape = 15, size = 2) +
  geom_line(aes(y = loans_250_1m_idx, color = "$250K-$1M"), linewidth = 1.1) +
  geom_point(aes(y = loans_250_1m_idx, color = "$250K-$1M"), shape = 17, size = 2) +
  geom_hline(yintercept = 100, color = "gray50", linetype = "dashed") +
  scale_color_manual(
    values = c(
      "Under $100K" = "#2E75B6",
      "$100K-$250K" = "#BF4D28",
      "$250K-$1M" = "#4CAF50"
    ),
    breaks = c(
      "Under $100K",
      "$100K-$250K",
      "$250K-$1M"
    )
  ) +
  labs(
    title = "Figure 9: Small Business Lending Volume per 10K Residents",
    subtitle = "Growth Index (2000 = 100)",
    x = "Year",
    y = "Growth Index (2000 = 100)",
    color = NULL
#    caption = paste(
#      "Data: CRA aggregate files.",
#      "Deviation from Charlie's original script: annual Wisconsin population is",
#      "derived from CORI fips_participation.csv because WIPOP.csv was not staged locally.",
#      "The 2000-2004 $250K-$1M series reads staged vol_1mil values, which Charlie's",
#      "Python script misses because it references vol_1M."
#    )
  ) +
  charlie_theme() +
  theme(legend.position = "top")


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig09_plot, output_file, width = 10, height = 5)
