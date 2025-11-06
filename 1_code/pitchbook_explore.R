#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name:  Pitchbook Dealcounts, Deal volume
# Previous author:  -
# Current author:   Inder Majumdar
# Creation date:    November 4 2025
# Last updated: November 4 2025
# Description: Pitchbook dealcount + volume descriptives from the NVCA monitor summary.
#///////////////////////////////////////////////////////////////////////////////

# CONFIG --------------------------------------------------------

#Load packages

library('tidyverse')
library(scales)
#set filepath
path = '/Users/indermajumdar/Downloads'

countdir = paste(path, 'Pitchbook_dealcount.xlsx', sep = "/")

voldir = paste(path, 'Pitchbook_dealvol.xlsx', sep = "/")

#Load data

dealcount <- readxl::read_xlsx(countdir)

dealvol <- readxl::read_xlsx(voldir)

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

# WIDE TO LONG  --------------------------------------------------------

count_wide <- gather(dealcount, "year", "count", -State)

vol_wide <- gather(dealvol, "year", "count", -State)

rm(dealcount, dealvol)

# Descriptives:  How does WI compare to national average over time?  --------------------------------------------------------


# 1) dealcount IQR by year (exclude CA)
count_iqr <- count_wide |>
  filter(State != "California") |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# 2) dealvol IQR by year (exclude CA)
vol_iqr <- vol_wide |>
  filter(State != "California") |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# 3) merge your existing WI + nat avg with IQR
count_ts_data <- count_iqr |>
  left_join(
    count_wide |>
      group_by(year) |>
      filter(State != "California") |>
      summarise(dealcount_national = mean(count), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    count_wide |>
      filter(State == "Wisconsin") |>
      reframe(year, dealcount_wi = count),
    by = "year"
  ) |>
  mutate(year = as.numeric(year))

vol_ts_data <- vol_iqr |>
  left_join(
    vol_wide |>
      group_by(year) |>
      filter(State != "California") |>
      summarise(dealvol_national = mean(count), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(State == "Wisconsin") |>
      reframe(year, dealvol_wi = count),
    by = "year"
  ) |>
  mutate(year = as.numeric(year))

# 4) plot: COUNT with IQR ribbon
count_ts <- ggplot(count_ts_data, aes(x = year)) +
  geom_ribbon(aes(ymin = p25, ymax = p75),
              fill = "grey70", alpha = 0.25) +
  geom_line(aes(y = dealcount_national, linetype = "Nat. Avg."), linewidth = 0.9) +
  geom_line(aes(y = dealcount_wi, linetype = "Wisc."), linewidth = 0.9) +
  scale_linetype_manual(values = c("Wisc." = "solid", "Nat. Avg." = "dashed"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Venture Capital Dealcount: Count per year, 2015 - Q3 2025",
    subtitle = "Wisconsin vs national state-level average; shaded area is IQR (excl. California)",
    x = "Year",
    y = "Dealcount",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. National average excludes California."
  ) +
  theme_im()
count_ts

# 5) plot: VOLUME with IQR ribbon
vol_ts <- ggplot(vol_ts_data, aes(x = year)) +
  geom_ribbon(aes(ymin = p25, ymax = p75),
              fill = "grey70", alpha = 0.25) +
  geom_line(aes(y = dealvol_national, linetype = "Nat. Avg."), linewidth = 0.9) +
  geom_line(aes(y = dealvol_wi, linetype = "Wisc."), linewidth = 0.9) +
  scale_linetype_manual(values = c("Wisc." = "solid", "Nat. Avg." = "dashed"), name = NULL) +
  scale_x_continuous(breaks = pretty_breaks()) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Venture Capital Committed: USD (millions) per year, 2015 - Q3 2025",
    subtitle = "Wisconsin vs national state-level average; shaded area is IQR (excl. California)",
    x = "Year",
    y = "USD (million)",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. National average excludes California."
  ) +
  theme_im()
vol_ts

# Descriptives:  How has the distribution of Dealflow changed over time? Where does WI sit on that distribution?  --------------------------------------------------------

# helper to get WI value for a given year
get_wi_vol <- function(df, yr) {
  df |>
    filter(State == "Wisconsin", year == yr) |>
    pull(count)
}


# 1) get WI values for each year
wi_2015 <- get_wi_vol(vol_wide, 2015)
wi_2021 <- get_wi_vol(vol_wide, 2021)
wi_2025 <- get_wi_vol(vol_wide, 2025)

# 2) build one df with 3 years, excluding CA
hist_df <- vol_wide |>
  filter(year %in% c(2015, 2021, 2025),
         State != "California") |>
  transmute(
    State,
    year = as.factor(year),
    deal_volume = count
  )

# Identify top 2 states (by deal volume) across all selected years
library(ggrepel)

top_states <- hist_df |>
  group_by(year) |>
  slice_max(order_by = deal_volume, n = 2, with_ties = FALSE) |>
  ungroup()

# 3) plot
p_overlay <- ggplot(hist_df, aes(x = deal_volume, fill = year)) +
  geom_histogram(
    bins = 40,
    position = "identity",
    alpha = 0.35,
    color = NA
  ) +
  # WI lines
  geom_vline(xintercept = wi_2015, linetype = "dashed", linewidth = 0.55, color = "#1b9e77") +
  geom_vline(xintercept = wi_2021, linetype = "dashed", linewidth = 0.55, color = "#d95f02") +
  geom_vline(xintercept = wi_2025, linetype = "dashed", linewidth = 0.55, color = "#7570b3") +
  scale_fill_manual(
    values = c("2015" = "#1b9e77", "2021" = "#d95f02", "2025" = "#7570b3"),
    name = "Year"
  ) +
  scale_x_continuous(labels = label_comma()) +
  labs(
    title = "Distribution of VC capital committed across states, selected years",
    subtitle = "Overlay of 2015, 2021 (VC boom), and 2025 Q3 YTD; Wisconsin shown as dashed lines",
    x = "USD (millions)",
    y = "Number of states",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California excluded."
  ) +
  geom_text_repel(
    data = top_states,
    aes(x = deal_volume, y = 0, label = State, color = year),
    nudge_y = 3,
    direction = "y",
    segment.size = 0.2,
    segment.color = "grey60",
    size = 3.2,
    show.legend = FALSE
  ) +
  theme_im()

p_overlay

# Descriptives:  How has the distribution of Deal Count changed over time? Where does WI sit on that distribution?  --------------------------------------------------------


# 1) get WI values for each year
wi_2015 <- get_wi_vol(count_wide, 2015)
wi_2021 <- get_wi_vol(count_wide, 2021)
wi_2025 <- get_wi_vol(count_wide, 2025)

# 2) build one df with 3 years, excluding CA
hist_df <- count_wide |>
  filter(year %in% c(2015, 2021, 2025),
         State != "California") |>
  transmute(
    State,
    year = as.factor(year),
    deal_count = count
  )

# Identify top 2 states (by deal volume) across all selected years
library(ggrepel)

top_states <- hist_df |>
  group_by(year) |>
  slice_max(order_by = deal_count, n = 2, with_ties = FALSE) |>
  ungroup()

# 3) plot
p_overlay <- ggplot(hist_df, aes(x = deal_count, fill = year)) +
  geom_histogram(
    bins = 40,
    position = "identity",
    alpha = 0.35,
    color = NA
  ) +
  # WI lines
  geom_vline(xintercept = wi_2015, linetype = "dashed", linewidth = 0.55, color = "#1b9e77") +
  geom_vline(xintercept = wi_2021, linetype = "dashed", linewidth = 0.55, color = "#d95f02") +
  geom_vline(xintercept = wi_2025, linetype = "dashed", linewidth = 0.55, color = "#7570b3") +
  scale_fill_manual(
    values = c("2015" = "#1b9e77", "2021" = "#d95f02", "2025" = "#7570b3"),
    name = "Year"
  ) +
  scale_x_continuous(labels = label_comma()) +
  labs(
    title = "Distribution of deal count across states, selected years",
    subtitle = "Overlay of 2015, 2021 (VC boom), and 2025 Q3 YTD; Wisconsin shown as dashed lines",
    x = "Number of deals",
    y = "Number of states",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California excluded."
  ) +
  geom_text_repel(
    data = top_states,
    aes(x = deal_count, y = 0, label = State, color = year),
    nudge_y = 3,
    direction = "y",
    segment.size = 0.2,
    segment.color = "grey60",
    size = 3.2,
    show.legend = FALSE
  ) +
  theme_im()

p_overlay


# Descriptives:  Over the last 10 years, where does Wisconsin rank in total dealflow? (ECDF)  --------------------------------------------------------

# ==========================
#  ECDF of total VC volume
# ==========================

# 1) Summarize total deal volume per state
data_ecdf <- vol_wide |>
  filter(State != "California") |>
  group_by(State) |>
  summarise(capital_committed = sum(count, na.rm = TRUE), .groups = "drop") |>
  # Convert to billions for readability
  mutate(capital_billion = capital_committed / 1e3)

# 2) Extract Wisconsin's total
wi_total <- data_ecdf |>
  filter(State == "Wisconsin") |>
  pull(capital_billion)

# 3) Plot ECDF with Wisconsin marker
ecdf_vol <- ggplot(data_ecdf, aes(x = capital_billion)) +
  stat_ecdf(linewidth = 0.9, color = "#2166ac") +
  geom_vline(xintercept = wi_total, color = "#b2182b", linetype = "dashed", linewidth = 0.8) +
  scale_x_continuous(labels = label_number(scale = 1, suffix = "B")) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Cumulative distribution of VC capital committed by state, 2015–2024",
    subtitle = "Each point represents a state's total venture capital received over the 10-year period. Wisconsin shown as dashed line",
    x = "Total VC capital committed (billion USD)",
    y = "Cumulative share of states",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California excluded."
  ) +
  theme_im()

ecdf_vol

#  Descriptives: Map of total change over 10 year period?  --------------------------------------------------------

# 1) compute change 2015 -> 2024 by state
vol_change <- vol_wide |>
  # year is character after gather(), so filter as character
  dplyr::filter(year %in% c("2015", "2024")) |>
  tidyr::spread(year, count) |>
  # some states may have 0 or NA in 2015; handle that
  dplyr::mutate(
    abs_change = `2024` - `2015`,
    percent_change = dplyr::if_else(
      is.na(`2015`) | `2015` == 0,
      NA_real_,
      (`2024` - `2015`) / `2015`
    )
  ) |>
  filter(State != "West Virginia") # outlier

# 2) get map data and harmonize names
map_df <- map_data("state") |>
  dplyr::mutate(State = stringr::str_to_title(region))  # "new york" -> "New York"

# 3) join map to change data
map_change <- map_df |>
  dplyr::left_join(vol_change, by = "State")

# 4) plot

p_map_change <- ggplot(map_change, aes(long, lat, group = group, fill = percent_change)) +
  geom_polygon(color = "grey50", linewidth = 0.25) +
  coord_fixed(1.3) +
  scale_fill_gradient2(
    low = "#b2182b",
    mid = "white",
    high = "#2166ac",
    midpoint = 0,
    labels = scales::percent_format(accuracy = 1),
    na.value = "grey90",
    name = "Pct. change\n2015 → 2024",
    # this helps a bit but we’ll override with guides()
    limits = c(min(map_change$percent_change, na.rm = TRUE),
               max(map_change$percent_change, na.rm = TRUE))
  ) +
  labs(
    title = "Change in VC capital committed, 2015–2024",
    subtitle = "Percent change in total VC capital committed, by HQ state",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. States with no 2015 value shown in grey. Omitted West Virginia (% change outlier)."
  ) +
  theme_im() +
  theme(
    axis.title = element_blank(),
    axis.text = element_blank(),
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

p_map_change

