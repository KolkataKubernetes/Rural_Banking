#///////////////////////////////////////////////////////////////////////////////
#----                    WI Descriptives Intermediates                     ----
# File name:  cu_fig_cu03_institutions_branches_time.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-05-11
# Purpose:    Replicate Charlie's credit-union figure CU-3. Reference file:
#             agent-docs/agent_context/docs/code_charlie/fig_cu03_institutions_branches_time.py
# Note:       The staged NCUA inputs are missing branch files for 2005-2009
#             and do not include `call-report-data-2015-12`. This script flags
#             those gaps explicitly and skips the missing years unless the
#             dependencies are later staged.
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
  charlie_cu_output_dir,
  "cu_fig_cu03_institutions_branches_time.jpeg"
)


# -----------------------------
# 1) Load inputs
# -----------------------------

fig_cu03_years <- c(2005:2014, 2015:2024)

fig_cu03_data <- map_dfr(fig_cu03_years, function(year) {
  branch_path <- ncua_branch_file_for_year(year)

  if (!file.exists(branch_path)) {
    message("Skipping missing NCUA branch file for year ", year, ": ", branch_path)
    return(tibble())
  }

  wi <- load_ncua_branch(year) |>
    filter(PhysicalAddressStateCode == "WI")

  tibble(
    year = year,
    institutions = n_distinct(wi$CU_NUMBER),
    branches = nrow(wi)
  )
}) |>
  arrange(year)

# Reshape to long form so ggplot can place the institution and branch bars
# side by side for each observed year.
fig_cu03_long <- fig_cu03_data |>
  pivot_longer(
    cols = c(institutions, branches),
    names_to = "series",
    values_to = "count"
  ) |>
  mutate(
    series = recode(
      series,
      institutions = "Institutions",
      branches = "Branches"
    )
  )


# -----------------------------
# 2) Construct Figure
# -----------------------------

fig_cu03_plot <- ggplot(
  fig_cu03_long,
  aes(x = factor(year), y = count, fill = series)
) +
  geom_col(
    position = position_dodge(width = 0.8),
    width = 0.72
  ) +
  scale_fill_manual(
    values = c("Institutions" = "#BF4D28", "Branches" = "#2E75B6")
  ) +
  scale_y_continuous(
    limits = c(0, 800),
    breaks = seq(0, 800, by = 100),
    name = "Count"
  ) +
  labs(
    title = "Figure CU-3: Wisconsin Credit Union Institutions and Branches",
    x = "Year",
    fill = NULL,
    caption = paste(
      "Data: NCUA Call Reports.",
      "Staged inputs are missing branch files for 2005-2009 and 2015, so those years are omitted."
    )
  ) +
  charlie_theme() +
  theme(
    legend.position = "top",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )


# -----------------------------
# 3) Save Outputs
# -----------------------------

save_charlie_fig(fig_cu03_plot, output_file, width = 10, height = 5)
