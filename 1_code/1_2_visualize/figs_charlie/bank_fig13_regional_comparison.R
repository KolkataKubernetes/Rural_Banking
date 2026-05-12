#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig13_regional_comparison.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 13. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig13_regional_comparison.py
#             This script preserves Charlie's hard-coded population inputs.
#///////////////////////////////////////////////////////////////////////////////


# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
})

# Shared helper centralizes repeated local-data parsing and save logic.
source(file.path("1_code", "1_2_visualize", "figs_charlie", "_charlie_helpers.R"))

output_file_loans <- file.path(
  charlie_bank_output_dir,
  "bank_fig13a_regional_loans_per_10k.jpeg"
)
output_file_volume <- file.path(
  charlie_bank_output_dir,
  "bank_fig13b_regional_volume_per_10k.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

midwest_states <- tribble(
  ~state, ~state_fips, ~pop,
  "WI", "55", 5930405,
  "MN", "27", 5737915,
  "MI", "26", 10034113,
  "IL", "17", 12516863,
  "IA", "19", 3207004,
  "IN", "18", 6833037,
  "OH", "39", 11780017,
  "ND", "38", 783926,
  "SD", "46", 909824
)

regional_data <- load_cra_2023_state_aggregates() |>
  group_by(State_FIPS) |>
  summarise(
    loans_num = sum(Loans_U100k_Num, na.rm = TRUE),
    loans_amt = sum(Loans_U100k_Amt, na.rm = TRUE),
    .groups = "drop"
  ) |>
  inner_join(midwest_states, by = c("State_FIPS" = "state_fips")) |>
  mutate(
    loans_pc = loans_num / pop * 10000,
    vol_pc = loans_amt / pop * 10000
  )

regional_loans <- regional_data |>
  arrange(loans_pc) |>
  mutate(state = factor(state, levels = state))

regional_volume <- regional_data |>
  arrange(vol_pc) |>
  mutate(state = factor(state, levels = state))


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig13a_plot <- ggplot(regional_loans, aes(x = loans_pc, y = state, fill = state == "WI")) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_text(aes(label = round(loans_pc, 0)), hjust = -0.1, size = 3.2) +
  scale_fill_manual(values = c("TRUE" = "#BF4D28", "FALSE" = "#2E75B6")) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Figure 13a: Small Business Loans per 10K Residents",
    subtitle = "Midwest Comparison, 2023",
    x = "Under-$100K Loans per 10,000 Residents",
    y = NULL,
    caption = "Data: CRA aggregate files and Charlie's hard-coded state populations"
  ) +
  charlie_theme()

fig13b_plot <- ggplot(regional_volume, aes(x = vol_pc, y = state, fill = state == "WI")) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_text(
    aes(label = scales::dollar(vol_pc, accuracy = 1)),
    hjust = -0.1,
    size = 3.2
  ) +
  scale_fill_manual(values = c("TRUE" = "#BF4D28", "FALSE" = "#2E75B6")) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Figure 13b: Small Business Lending Volume per 10K Residents",
    subtitle = "Midwest Comparison, 2023",
    x = "Under-$100K Loan Volume per 10,000 Residents ($)",
    y = NULL,
    caption = "Data: CRA aggregate files and Charlie's hard-coded state populations"
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig13a_plot, output_file_loans, width = 9, height = 5)
save_charlie_fig(fig13b_plot, output_file_volume, width = 9, height = 5)
