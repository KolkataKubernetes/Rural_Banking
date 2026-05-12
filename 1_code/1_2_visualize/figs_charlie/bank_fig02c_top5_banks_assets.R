#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  bank_fig02c_top5_banks_assets.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's banking figure 2c. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig02c_top5_banks_assets.py
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
  "bank_fig02c_top5_banks_assets.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

sod_2024 <- load_fdic_sod(2024)
wi_branches <- sod_2024 |>
  filter(STALPBR == "WI")

top5_assets <- sod_2024 |>
  filter(
    as.character(BRNUM) == "0",
    CERT %in% wi_branches$CERT,
    STALP == "WI"
  ) |>
  mutate(
    ASSET = as.numeric(ASSET),
    label = trim_bank_name(NAMEFULL),
    asset_b = ASSET / 1e6
  ) |>
  arrange(desc(ASSET)) |>
  slice_head(n = 5) |>
  mutate(label = forcats::fct_rev(factor(label, levels = label)))


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig02c_plot <- ggplot(top5_assets, aes(x = asset_b, y = label)) +
  geom_col(fill = "#2E75B6", width = 0.6) +
  geom_text(
    aes(label = paste0("$", round(asset_b, 1), "B  (", CITY, ")")),
    hjust = -0.05,
    size = 3.2
  ) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(
    title = "Figure 2c: Top 5 Wisconsin-Headquartered Banks by Total Assets (2024)",
    x = "Total Assets ($ Billions)",
    y = NULL,
    caption = "Data: FDIC Summary of Deposits"
  ) +
  charlie_theme()


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig02c_plot, output_file, width = 9, height = 4.2)
