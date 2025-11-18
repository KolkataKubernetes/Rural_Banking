#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name:  Pitchbook Dealcounts, Deal volume
# Current author:   Inder Majumdar
# Creation date:    November 4 2025
# Last updated:     November 4 2025
# Description: Pitchbook dealcount + volume descriptives from the NVCA monitor
#///////////////////////////////////////////////////////////////////////////////

# CONFIG --------------------------------------------------------

library(tidyverse)
library(scales)
library(readxl)
library(ggrepel)
library(maps)
library(plotly)

# set filepath
path <- "/Users/indermajumdar/Downloads"

countdir <- file.path(path, "Pitchbook_dealcount.xlsx")
voldir   <- file.path(path, "Pitchbook_dealvol.xlsx")

# Load data -----------------------------------------------------

dealcount <- read_xlsx(countdir)
dealvol   <- read_xlsx(voldir)

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

# WIDE TO LONG --------------------------------------------------

count_wide <- dealcount |>
  pivot_longer(-State, names_to = "year", values_to = "count")

vol_wide <- dealvol |>
  pivot_longer(-State, names_to = "year", values_to = "count")

rm(dealcount, dealvol)

# Descriptives: WI vs national avg over time --------------------

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

# 3) merge existing WI + nat avg with IQR
count_ts_data <- count_iqr |>
  left_join(
    count_wide |>
      filter(State != "California") |>
      group_by(year) |>
      summarise(dealcount_national = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    count_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealcount_wi = count),
    by = "year"
  ) |>
  mutate(year = as.numeric(year))

vol_ts_data <- vol_iqr |>
  left_join(
    vol_wide |>
      filter(State != "California") |>
      group_by(year) |>
      summarise(dealvol_national = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealvol_wi = count),
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
    title = "Venture Capital Dealcount: 2015 - Q3 2025",
    subtitle = "Wisconsin vs national state-level average; shaded area is IQR (excl. California)",
    x = "Year",
    y = "Dealcount",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. National average excludes California."
  ) +
  theme_im()

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
    title = "Venture Capital Committed: 2015 - Q3 2025",
    subtitle = "Wisconsin vs national state-level average; shaded area is IQR (excl. California)",
    x = "Year",
    y = "USD (million)",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. National average excludes California."
  ) +
  theme_im()

rm(vol_iqr, count_iqr)

# Descriptives: distribution over time (volume) -----------------

get_wi_vol <- function(df, yr) {
  df |>
    filter(State == "Wisconsin", year == yr) |>
    pull(count)
}

wi_2015 <- get_wi_vol(vol_wide, "2015")
wi_2021 <- get_wi_vol(vol_wide, "2021")
wi_2025 <- get_wi_vol(vol_wide, "2025")

hist_df <- vol_wide |>
  filter(year %in% c("2015", "2021", "2025"),
         State != "California") |>
  transmute(
    State,
    year = as.factor(year),
    deal_volume = count
  )

top_states <- hist_df |>
  group_by(year) |>
  slice_max(order_by = deal_volume, n = 2, with_ties = FALSE) |>
  ungroup()

p_overlay_vol <- ggplot(hist_df, aes(x = deal_volume, fill = year)) +
  geom_histogram(
    bins = 40,
    position = "identity",
    alpha = 0.35,
    color = NA
  ) +
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
    subtitle = "2015, 2021 (boom), 2025 Q3 YTD; Wisconsin shown as dashed lines",
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

# Descriptives: distribution over time (count) ------------------

wi_2015 <- get_wi_vol(count_wide, "2015")
wi_2021 <- get_wi_vol(count_wide, "2021")
wi_2025 <- get_wi_vol(count_wide, "2025")

hist_df_count <- count_wide |>
  filter(year %in% c("2015", "2021", "2025"),
         State != "California") |>
  transmute(
    State,
    year = as.factor(year),
    deal_count = count
  )

top_states_count <- hist_df_count |>
  group_by(year) |>
  slice_max(order_by = deal_count, n = 2, with_ties = FALSE) |>
  ungroup()

p_overlay_count <- ggplot(hist_df_count, aes(x = deal_count, fill = year)) +
  geom_histogram(
    bins = 40,
    position = "identity",
    alpha = 0.35,
    color = NA
  ) +
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
    subtitle = "2015, 2021 (boom), 2025 Q3 YTD; Wisconsin shown as dashed lines",
    x = "Number of deals",
    y = "Number of states",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California excluded."
  ) +
  geom_text_repel(
    data = top_states_count,
    aes(x = deal_count, y = 0, label = State, color = year),
    nudge_y = 3,
    direction = "y",
    segment.size = 0.2,
    segment.color = "grey60",
    size = 3.2,
    show.legend = FALSE
  ) +
  theme_im()

rm(top_states, top_states_count)

# ECDF of total VC volume ---------------------------------------

data_ecdf <- vol_wide |>
  filter(State != "California") |>
  group_by(State) |>
  summarise(capital_committed = sum(count, na.rm = TRUE), .groups = "drop") |>
  mutate(capital_billion = capital_committed / 1e3)

wi_total <- data_ecdf |>
  filter(State == "Wisconsin") |>
  pull(capital_billion)

ecdf_vol <- ggplot(data_ecdf, aes(x = capital_billion)) +
  stat_ecdf(linewidth = 0.9, color = "#2166ac") +
  geom_vline(xintercept = wi_total, color = "#b2182b", linetype = "dashed", linewidth = 0.8) +
  scale_x_continuous(labels = label_number(scale = 1, suffix = "B")) +
  scale_y_continuous(labels = label_percent(accuracy = 1)) +
  labs(
    title = "Cumulative distribution of VC capital committed by state, 2015–2024",
    subtitle = "Each point is a state's total VC received; Wisconsin shown as dashed line",
    x = "Total VC capital committed (billion USD)",
    y = "Cumulative share of states",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California excluded."
  ) +
  theme_im()

rm(data_ecdf)

# Map: change 2015 -> 2024 --------------------------------------

vol_change <- vol_wide |>
  filter(year %in% c("2015", "2024")) |>
  pivot_wider(names_from = year, values_from = count) |>
  mutate(
    abs_change = `2024` - `2015`,
    percent_change = if_else(
      is.na(`2015`) | `2015` == 0,
      NA_real_,
      (`2024` - `2015`) / `2015`
    )
  ) |>
  filter(State != "West Virginia")   # outlier

map_df <- map_data("state") |>
  mutate(State = str_to_title(region))

map_change <- map_df |>
  left_join(vol_change, by = "State")

p_map_change <- ggplot(map_change, aes(long, lat, group = group, fill = percent_change)) +
  geom_polygon(color = "grey50", linewidth = 0.25) +
  coord_fixed(1.3) +
  scale_fill_gradient2(
    low = "#b2182b",
    mid = "white",
    high = "#2166ac",
    midpoint = 0,
    labels = percent_format(accuracy = 1),
    na.value = "grey90",
    name = "Pct. change\n2015 → 2024",
    limits = c(min(map_change$percent_change, na.rm = TRUE),
               max(map_change$percent_change, na.rm = TRUE))
  ) +
  labs(
    title = "Change in VC capital committed, 2015–2024",
    subtitle = "Percent change in total VC committed, by HQ state",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. States with no 2015 value shown in grey. WV omitted."
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

# ---------------------------------------------------------------
# Regions + Sankey-style flows
# ---------------------------------------------------------------

region_midwest <- c("Iowa", "Minnesota", "Wisconsin", "Illinois", "Indiana", "Michigan", "Ohio")
region_west    <- c("California", "Washington", "Oregon")
region_east    <- c("Connecticut", "Maine", "Massachusetts", "New Hampshire", "New Jersey",
                    "New York", "Pennsylvania", "Rhode Island", "Vermont")
region_southeast <- c("Alabama", "Arkansas", "Florida", "Georgia", "Kentucky",
                      "Louisiana", "Mississippi", "North Carolina", "South Carolina",
                      "Tennessee", "Virginia", "West Virginia")

# helper to build vol_avg for a given year filter
build_vol_avg <- function(df, year_filter = NULL) {
  tmp <- df
  if (!is.null(year_filter)) {
    tmp <- tmp |> filter(year == year_filter)
  } else {
    tmp <- tmp |> filter(year != "2025")
  }
  tmp |>
    group_by(State) |>
    summarise(mean_vol = mean(count, na.rm = TRUE), .groups = "drop") |>
    mutate(
      Country = "USA",
      region = case_when(
        State %in% region_midwest   ~ "Midwest",
        State %in% region_west      ~ "West",
        State %in% region_east      ~ "East",
        State %in% region_southeast ~ "Southeast",
        TRUE                        ~ "Other"
      )
    )
}

# ----- 10-year avg sankey data
vol_avg_10yr <- build_vol_avg(vol_wide, year_filter = NULL)

usa_regions_10yr <- vol_avg_10yr |>
  group_by(region) |>
  summarise(
    Country   = "USA",
    total_vol = sum(mean_vol),
    .groups   = "drop"
  ) |>
  transmute(from = Country, to = region, value = total_vol)

regions_state_10yr <- vol_avg_10yr |>
  transmute(
    from  = region,
    to    = State,
    value = mean_vol
  ) |>
  mutate(
    to = case_when(
      from == "Southeast" & !(to %in% c("Florida", "North Carolina", "Georgia")) ~ "Rest of SE",
      from == "Midwest"   & !(to %in% c("Illinois", "Wisconsin"))               ~ "Rest of Midwest",
      from == "East"      & !(to %in% c("New York", "Massachusetts"))           ~ "Rest of East",
      TRUE ~ to
    )
  ) |>
  group_by(from, to) |>
  summarise(value = sum(value, na.rm = TRUE), .groups = "drop")

sankeydata_10yr <- bind_rows(usa_regions_10yr, regions_state_10yr) |>
  filter(from != "Other")

nodes_10yr <- data.frame(
  name = c(sankeydata_10yr$from, sankeydata_10yr$to) |> unique()
)

sankeydata_10yr$IDfrom <- match(sankeydata_10yr$from, nodes_10yr$name) - 1
sankeydata_10yr$IDto   <- match(sankeydata_10yr$to,   nodes_10yr$name) - 1

p_sankey_10yr <- plot_ly(
  type = "sankey",
  orientation = "h",
  node = list(label = nodes_10yr$name),
  link = list(
    source = sankeydata_10yr$IDfrom,
    target = sankeydata_10yr$IDto,
    value  = sankeydata_10yr$value
  )
) |>
  layout(
    title = list(
      text = "VC Flows: 10-year average (USD millions)<br><sup>USA → Region → State (collapsed)</sup>"
    )
  )

# ----- 2024 sankey data
vol_avg_2024 <- build_vol_avg(vol_wide, year_filter = "2024")

usa_regions_2024 <- vol_avg_2024 |>
  group_by(region) |>
  summarise(
    Country   = "USA",
    total_vol = sum(mean_vol),
    .groups   = "drop"
  ) |>
  transmute(from = Country, to = region, value = total_vol)

regions_state_2024 <- vol_avg_2024 |>
  transmute(
    from  = region,
    to    = State,
    value = mean_vol
  ) |>
  mutate(
    to = case_when(
      from == "Southeast" & !(to %in% c("Florida", "North Carolina", "Georgia")) ~ "Rest of SE",
      from == "Midwest"   & !(to %in% c("Illinois", "Wisconsin"))               ~ "Rest of Midwest",
      from == "East"      & !(to %in% c("New York", "Massachusetts"))           ~ "Rest of East",
      TRUE ~ to
    )
  ) |>
  group_by(from, to) |>
  summarise(value = sum(value, na.rm = TRUE), .groups = "drop")

sankeydata_2024 <- bind_rows(usa_regions_2024, regions_state_2024) |>
  filter(from != "Other")

nodes_2024 <- data.frame(
  name = c(sankeydata_2024$from, sankeydata_2024$to) |> unique()
)

sankeydata_2024$IDfrom <- match(sankeydata_2024$from, nodes_2024$name) - 1
sankeydata_2024$IDto   <- match(sankeydata_2024$to,   nodes_2024$name) - 1

p_sankey_2024 <- plot_ly(
  type = "sankey",
  orientation = "h",
  node = list(label = nodes_2024$name),
  link = list(
    source = sankeydata_2024$IDfrom,
    target = sankeydata_2024$IDto,
    value  = sankeydata_2024$value
  )
) |>
  layout(
    title = list(
      text = "VC Flows: 2024 (USD millions)<br><sup>USA → Region → State (collapsed)</sup>"
    )
  )

# HTML Widgets
library('htmlwidgets')


# you can now do:
htmlwidgets::saveWidget(p_sankey_10yr, "vc_sankey_10yr_vol.html", selfcontained = TRUE)
 htmlwidgets::saveWidget(p_sankey_2024,  "vc_sankey_2024_vol.html",  selfcontained = TRUE)
 
 rm(vol_avg_10yr, usa_regions_10yr, regions_state_10yr, sankeydata_10yr, sankeydata_2024, regions_state_2024, usa_regions_2024)
 
 # ---------------------------------------------------------------
 # Sankey for Deal Count
 # ---------------------------------------------------------------
 
 
 region_midwest <- c("Iowa", "Minnesota", "Wisconsin", "Illinois", "Indiana", "Michigan", "Ohio")
 region_west    <- c("California", "Washington", "Oregon")
 region_east    <- c("Connecticut", "Maine", "Massachusetts", "New Hampshire", "New Jersey",
                     "New York", "Pennsylvania", "Rhode Island", "Vermont")
 region_southeast <- c("Alabama", "Arkansas", "Florida", "Georgia", "Kentucky",
                       "Louisiana", "Mississippi", "North Carolina", "South Carolina",
                       "Tennessee", "Virginia", "West Virginia")
 
 # helper to build vol_avg for a given year filter
 build_vol_avg <- function(df, year_filter = NULL) {
   tmp <- df
   if (!is.null(year_filter)) {
     tmp <- tmp |> filter(year == year_filter)
   } else {
     tmp <- tmp |> filter(year != "2025")
   }
   tmp |>
     group_by(State) |>
     summarise(mean_vol = mean(count, na.rm = TRUE), .groups = "drop") |>
     mutate(
       Country = "USA",
       region = case_when(
         State %in% region_midwest   ~ "Midwest",
         State %in% region_west      ~ "West",
         State %in% region_east      ~ "East",
         State %in% region_southeast ~ "Southeast",
         TRUE                        ~ "Other"
       )
     )
 }
 
 # ----- 10-year avg sankey data
 vol_avg_10yr <- build_vol_avg(count_wide, year_filter = NULL)
 
 usa_regions_10yr <- vol_avg_10yr |>
   group_by(region) |>
   summarise(
     Country   = "USA",
     total_vol = sum(mean_vol),
     .groups   = "drop"
   ) |>
   transmute(from = Country, to = region, value = total_vol)
 
 regions_state_10yr <- vol_avg_10yr |>
   transmute(
     from  = region,
     to    = State,
     value = mean_vol
   ) |>
   mutate(
     to = case_when(
       from == "Southeast" & !(to %in% c("Florida", "North Carolina", "Georgia")) ~ "Rest of SE",
       from == "Midwest"   & !(to %in% c("Illinois", "Wisconsin"))               ~ "Rest of Midwest",
       from == "East"      & !(to %in% c("New York", "Massachusetts"))           ~ "Rest of East",
       TRUE ~ to
     )
   ) |>
   group_by(from, to) |>
   summarise(value = sum(value, na.rm = TRUE), .groups = "drop")
 
 sankeydata_10yr <- bind_rows(usa_regions_10yr, regions_state_10yr) |>
   filter(from != "Other")
 
 nodes_10yr <- data.frame(
   name = c(sankeydata_10yr$from, sankeydata_10yr$to) |> unique()
 )
 
 sankeydata_10yr$IDfrom <- match(sankeydata_10yr$from, nodes_10yr$name) - 1
 sankeydata_10yr$IDto   <- match(sankeydata_10yr$to,   nodes_10yr$name) - 1
 
 p_sankey_10yr <- plot_ly(
   type = "sankey",
   orientation = "h",
   node = list(label = nodes_10yr$name),
   link = list(
     source = sankeydata_10yr$IDfrom,
     target = sankeydata_10yr$IDto,
     value  = sankeydata_10yr$value
   )
 ) |>
   layout(
     title = list(
       text = "VC Flows: 10-year average Count <br><sup>USA → Region → State (collapsed)</sup>"
     )
   )
 
 # ----- 2024 sankey data
 vol_avg_2024 <- build_vol_avg(count_wide, year_filter = "2024")
 
 usa_regions_2024 <- vol_avg_2024 |>
   group_by(region) |>
   summarise(
     Country   = "USA",
     total_vol = sum(mean_vol),
     .groups   = "drop"
   ) |>
   transmute(from = Country, to = region, value = total_vol)
 
 regions_state_2024 <- vol_avg_2024 |>
   transmute(
     from  = region,
     to    = State,
     value = mean_vol
   ) |>
   mutate(
     to = case_when(
       from == "Southeast" & !(to %in% c("Florida", "North Carolina", "Georgia")) ~ "Rest of SE",
       from == "Midwest"   & !(to %in% c("Illinois", "Wisconsin"))               ~ "Rest of Midwest",
       from == "East"      & !(to %in% c("New York", "Massachusetts"))           ~ "Rest of East",
       TRUE ~ to
     )
   ) |>
   group_by(from, to) |>
   summarise(value = sum(value, na.rm = TRUE), .groups = "drop")
 
 sankeydata_2024 <- bind_rows(usa_regions_2024, regions_state_2024) |>
   filter(from != "Other")
 
 nodes_2024 <- data.frame(
   name = c(sankeydata_2024$from, sankeydata_2024$to) |> unique()
 )
 
 sankeydata_2024$IDfrom <- match(sankeydata_2024$from, nodes_2024$name) - 1
 sankeydata_2024$IDto   <- match(sankeydata_2024$to,   nodes_2024$name) - 1
 
 p_sankey_2024 <- plot_ly(
   type = "sankey",
   orientation = "h",
   node = list(label = nodes_2024$name),
   link = list(
     source = sankeydata_2024$IDfrom,
     target = sankeydata_2024$IDto,
     value  = sankeydata_2024$value
   )
 ) |>
   layout(
     title = list(
       text = "VC Flows: 2024 Count <br><sup>USA → Region → State (collapsed)</sup>"
     )
   )
 
 # HTML Widgets
 library('htmlwidgets')
 
 
 # you can now do:
 htmlwidgets::saveWidget(p_sankey_10yr, "vc_sankey_10yr_count.html", selfcontained = TRUE)
 htmlwidgets::saveWidget(p_sankey_2024,  "vc_sankey_2024_count.html",  selfcontained = TRUE)
 
 # ---------------------------------------------------------------
 # What percent of VC dollars does WI get? Compared to rest of WI? Compared to rest of avg?
 # ---------------------------------------------------------------
 
 ## Pie chart similar to the one below
 
 
 
 
 # ---------------------------------------------------------------
 # BDS Data: What percent of "Age 0" businesses?
 # ---------------------------------------------------------------
 
 bds_fa <- read_csv('/Users/indermajumdar/Downloads/bds2023_st_fa.csv')
 
 
 ## Each year's stats
 
 bds_fa |>
   #filter(st == 55) |>
   filter(year > 2014) |>
   filter(fage == "a) 0") |> 
   transmute(year, st, fage,firms = as.numeric(firms)) |>
   group_by(year) |>
   mutate(firms_pct = firms/sum(firms)) |>
   ungroup() |>
   arrange(year, desc(firms_pct)) -> bds_fa_yearly
 
 ## 2015-2023 total stats
 
 bds_fa |>
   #filter(st == 55) |>
   filter(year > 2014) |>
   group_by(st) |>
   summarise(firms = sum(as.numeric(firms))) |>
   mutate(firms_pct = firms/sum(firms)) -> bds_fa_total
 
 # 1. Cumulative: WI vs all other states, 2015–2023
 
 ## "“From 2015–2023, how many age-0 establishments were created in WI compared to the rest of the country?”
 bds_fa_total |>
   mutate(group = if_else(st == "56", "WI", "Other states")) |>
   group_by(group) |>
   summarise(total_firms = sum(firms, na.rm = TRUE), .groups = "drop") |>
   mutate(
     pct   = total_firms / sum(total_firms),
     label = paste0(
       group, "\n",
       scales::comma(total_firms), " (", scales::percent(pct, accuracy = 0.1), ")"
     ),
     ypos  = cumsum(pct) - 0.5 * pct
   ) |>
   ggplot(aes(x = 1, y = pct, fill = group)) +
   geom_col(width = 1, color = "white") +
   coord_polar(theta = "y") +
   scale_fill_manual(values = c("WI" = "#1b9e77", "Other states" = "grey70")) +
   geom_text(
     aes(y = ypos, label = label),
     x = 2.05,
     hjust = 0,
     color = "black",
     size = 4.2,
     lineheight = 0.9
   ) +
   xlim(0, 2.6) +
   labs(
     title = "Age-0 establishments: WI vs all other states",
     subtitle = "Cumulative counts, 2015–2023",
     fill = NULL,
     caption = "Source: U.S. Census Business Dynamics Statistics (BDS), state file. Age group: a) 0."
   ) +
   theme_void() +
   theme(
     plot.title = element_text(face = "bold", hjust = 0.5),
     plot.subtitle = element_text(hjust = 0.5)
   )
 
 # 2. Average annual mix: WI vs all other states (combined)
 
 ## “In an average year (2015–2023), how big is WI’s age-0 count relative to the rest of the country in that same average year?”
 
 bds_fa_avg |>
   mutate(group = if_else(st == "56", "WI", "Other states")) |>
   group_by(group) |>
   summarise(total_firms = sum(avg_firms, na.rm = TRUE), .groups = "drop") |>
   mutate(
     pct   = total_firms / sum(total_firms),
     label = paste0(
       group, "\n",
       scales::comma(round(total_firms)), " (", scales::percent(pct, accuracy = 0.1), ")"
     ),
     ypos  = cumsum(pct) - 0.5 * pct
   ) |>
   ggplot(aes(x = 1, y = pct, fill = group)) +
   geom_col(width = 1, color = "white") +
   coord_polar(theta = "y") +
   scale_fill_manual(values = c("WI" = "#1b9e77", "Other states" = "grey70")) +
   geom_text(
     aes(y = ypos, label = label),
     x = 2.05,
     hjust = 0,
     color = "black",
     size = 4.2,
     lineheight = 0.9
   ) +
   xlim(0, 2.6) +
   labs(
     title = "Avg. annual age-0 establishments: WI vs all other states",
     subtitle = "State-level annual averages, then summed across states, 2015–2023",
     fill = NULL,
     caption = "Source: U.S. Census BDS, state file. Each state’s 2015–2023 annual age-0 count was averaged, then WI was compared to the sum of all other states’ averages."
   ) +
   theme_void() +
   theme(
     plot.title = element_text(face = "bold", hjust = 0.5),
     plot.subtitle = element_text(hjust = 0.5)
   )
 
 # 3. WI vs the average other state
 # (state_avgs and pie_df already built above)
 
 ggplot(pie_df, aes(x = 1, y = pct, fill = group)) +
   geom_col(width = 1, color = "white") +
   coord_polar(theta = "y") +
   scale_fill_manual(values = c("WI" = "#1b9e77", "Avg. other state" = "grey70")) +
   geom_text(
     aes(y = ypos, label = label),
     x = 2.05,
     hjust = 0,
     color = "black",
     size = 4.2,
     lineheight = 0.9
   ) +
   xlim(0, 2.6) +
   labs(
     title = "Avg. annual age-0 establishments: WI vs avg. other state",
     subtitle = "2015–2023 annual averages, compared at the state level",
     fill = NULL,
     caption = "Source: U.S. Census BDS, state file. WI shown against the mean annual age-0 count of all non-WI states."
   ) +
   theme_void() +
   theme(
     plot.title = element_text(face = "bold", hjust = 0.5),
     plot.subtitle = element_text(hjust = 0.5)
   )
 
 
 library(dplyr)
 library(ggplot2)
 library(scales)
 
 # --- WI share of VC (avg annual) ---
 vc_state_avg <- vol_wide |>
   filter(year != "2025") |>
   group_by(State) |>
   summarise(vc_avg = mean(count, na.rm = TRUE), .groups = "drop")
 
 wi_vc_avg <- vc_state_avg |>
   filter(State == "Wisconsin") |>
   pull(vc_avg)
 
 us_vc_avg <- sum(vc_state_avg$vc_avg, na.rm = TRUE)
 
 wi_vc_share <- wi_vc_avg / us_vc_avg
 
 # --- WI share of age-0 firms (avg annual) ---
 bds_state_avg <- bds_fa_yearly |>
   filter(fage == "a) 0") |>
   group_by(st) |>
   summarise(age0_avg = mean(firms, na.rm = TRUE), .groups = "drop")
 
 # you’ve been treating st == "56" as WI in this file, so keep it consistent
 wi_age0_avg <- bds_state_avg |>
   filter(st == "56") |>
   pull(age0_avg)
 
 us_age0_avg <- sum(bds_state_avg$age0_avg, na.rm = TRUE)
 
 wi_age0_share <- wi_age0_avg / us_age0_avg
 
 # --- combine for plotting ---
 compare_df <- tibble(
   metric = c("VC committed (avg yr)", "Age-0 firms (avg yr)"),
   wi_share = c(wi_vc_share, wi_age0_share)
 )
 
 ggplot(compare_df, aes(x = metric, y = wi_share, fill = metric)) +
   geom_col(width = 0.55) +
   geom_text(aes(label = percent(wi_share, 0.01)),
             vjust = -0.35, size = 3.8) +
   scale_y_continuous(labels = percent_format(accuracy = 0.1), expand = expansion(mult = c(0, 0.15))) +
   scale_fill_manual(values = c("#1b9e77", "grey60")) +
   labs(
     title = "Wisconsin’s share of national activity",
     subtitle = "Average year, VC vs new (age 0) establishments",
     x = NULL,
     y = "WI share of U.S. total",
     caption = "VC: Pitchbook (state rollup). Age 0: BDS 2015–2023 (st == 56 treated as WI)."
   ) +
   theme_im() +
   theme(
     legend.position = "none",
     axis.text.x = element_text(face = "bold")
   )
 
 
 
 
 
