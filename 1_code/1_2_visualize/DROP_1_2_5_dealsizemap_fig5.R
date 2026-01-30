#///////////////////////////////////////////////////////////////////////////////
#----                Figure 5: VC Deal Size Map (2024)                    ----
# File name:  1_2_5_dealsizemap_fig5.R
# Author:     Codex (based on Inder Majumdar's workflow)
# Created:    2026-01-26
# Purpose:    Map 2024 VC deal size by state.
#///////////////////////////////////////////////////////////////////////////////

# -----------------------------
# 0) Setup and configuration
# -----------------------------

suppressPackageStartupMessages({
  library(tidyverse)
  library(maps)
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

dealsize_2024 <- readRDS(file.path("2_processed_data", "dealsize_2024.rds"))

# -----------------------------
# 2) Plot
# -----------------------------

map_df <- map_data("state") |>
  mutate(State = str_to_title(region))

map_level <- map_df |>
  left_join(dealsize_2024, by = "State")

p_map_level_dealsize <- ggplot(map_level, aes(long, lat, group = group, fill = total)) +
  geom_polygon(color = "grey50", linewidth = 0.25) +
  coord_fixed(1.3) +
  scale_fill_gradient2(
    low = "#b2182b",
    mid = "white",
    high = "#2166ac",
    midpoint = 0,
    na.value = "grey90",
    name = "2024 deal size, USD (million)",
    limits = c(min(map_level$total, na.rm = TRUE),
               max(map_level$total, na.rm = TRUE))
  ) +
  labs(
    title = "VC deal size, 2024",
    subtitle = "VC deal size, by receiver HQ state",
    caption = "Source: Pitchbook Venture Capital Monitor Q4 2025. California, New York, and Massachusetts omitted."
  ) +
  theme_im() +
  theme(
    axis.title = element_blank(),
    axis.text  = element_blank(),
    axis.ticks = element_blank(),
    legend.position = "right",
    legend.title = element_text(lineheight = 1.1)
  ) +
  guides(
    fill = guide_colorbar(
      barheight = unit(4.5, "cm"),
      barwidth  = unit(0.45, "cm")
    )
  )

save_fig(
  p = p_map_level_dealsize,
  filename = file.path(output_dir, "5_dealsize_map.jpeg")
)
