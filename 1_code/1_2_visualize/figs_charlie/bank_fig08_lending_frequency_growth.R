#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig08_lending_frequency_growth.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 8. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig08_lending_frequency_growth.py
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
  "bank_fig08_lending_frequency_growth.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

cra_frequency <- load_cra_wi_frequency_series() |>
  left_join(load_wi_population_from_participation(2000:2023), by = "year") |>
  mutate(
    loans_u100k_idx = (loans_u100k_num / population * 10000) /
      first(loans_u100k_num / population * 10000) * 100,
    loans_100_250_idx = (loans_100_250_num / population * 10000) /
      first(loans_100_250_num / population * 10000) * 100,
    loans_250_1m_idx = (loans_250_1m_num / population * 10000) /
      first(loans_250_1m_num / population * 10000) * 100
  )


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig08_plot <- ggplot(cra_frequency, aes(x = year)) +
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
    )
  ) +
  labs(
    title = "Figure 8: Small Business Lending Frequency per 10K Residents",
    subtitle = "Growth Index (2000 = 100)",
    x = "Year",
    y = "Growth Index (2000 = 100)",
    color = NULL,
    caption = paste(
      "Data: CRA aggregate files.",
      "Deviation from Charlie's original script: annual Wisconsin population is",
      "derived from CORI fips_participation.csv because WIPOP.csv was not staged locally.",
      "The 2000-2004 $250K-$1M series reads staged num_1mil values, which Charlie's",
      "Python script misses because it references num_1M."
    )
  ) +
  charlie_theme() +
  theme(legend.position = "top")


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig08_plot, output_file, width = 10, height = 5)
