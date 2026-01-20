#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name: WI Small Business Finance Descriptives
# Current author:   Inder Majumdar
# Creation date:    December 3 2025
# Last updated:     December 9 2025
# Description: 
#///////////////////////////////////////////////////////////////////////////////

# CONFIG --------------------------------------------------------

library(tidyverse)
library(scales)
library(readxl)
library(ggrepel)
library(maps)
library(plotly)
library(ggpattern)
library(sf)

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

# set filepath

path <- "/Users/indermajumdar/Downloads"
countdir <- file.path(path, "Pitchbook_dealcount.xlsx")
voldir   <- file.path(path, "Pitchbook_dealvol.xlsx")
formd_dir <- file.path(path, 'form_d')
ruccdir <- file.path(path, "Ruralurbancontinuumcodes2023.xlsx")

# Load Data --------------------------------------------------------

dealcount <- read_xlsx(countdir)
dealvol   <- read_xlsx(voldir)
participationdir <- read_csv('/Users/indermajumdar/Downloads/fips_participation.csv')
bds_fa <- read_csv('/Users/indermajumdar/Downloads/bds2023_st_fa.csv')
rucc <- read_excel(ruccdir)

# Load Form D Data --------------------------------------------------------
formd_data <- list.files(formd_dir, pattern = "\\.csv$", full.names = TRUE) |>
  map_dfr(read_csv) |>
  select(-1) |>
  distinct()


# --- Pitchbook Wide To Long

count_wide <- dealcount |>
  pivot_longer(-State, names_to = "year", values_to = "count")

vol_wide <- dealvol |>
  pivot_longer(-State, names_to = "year", values_to = "count")

rm(dealcount, dealvol)

dealsize_wide <- inner_join(count_wide, vol_wide |> reframe(State, year, vol = count), by = c("State", "year")) |>
  transmute(State, year, dealsize = vol/count)

# --- Pitchbook data with IQR, TS

# 1) dealcount IQR by year (exclude CA, MA, NY)
count_iqr <- count_wide |>
#  filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# 2) dealvol IQR by year (exclude CA, MA, NY)
vol_iqr <- vol_wide |>
#  filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# 3) dealsize IQR

size_iqr <- dealsize_wide |>
  # filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
  group_by(year) |>
  summarise(
    p25 = quantile(dealsize, 0.25, na.rm = TRUE),
    p50 = quantile(dealsize, 0.50, na.rm = TRUE),
    p75 = quantile(dealsize, 0.75, na.rm = TRUE),
    .groups = "drop"
  )


# --- Create TS Datasets

# Count 

count_ts_data <- count_iqr |>
  left_join( # National Average
    count_wide |>
      group_by(year) |>
      summarise(dealcount_national = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join( # Adjusted for outliers
    count_wide |>
      filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
      group_by(year) |>
      summarise(dealcount_national_nonoutlier = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join( # Midwest excl. WI, *average state*
    count_wide |>
      filter(State %in% c("Minnesota", "Iowa", "Illinois", "Michigan", "Indiana")) |>
      group_by(year) |>
      summarise(dealcount_midwest = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join( # Wisco only
    count_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealcount_wi = count),
    by = "year"
  ) |>
  mutate(
    year          = as.numeric(year),
    nonoutlier_pct = dealcount_national_nonoutlier / dealcount_national,
    midwest_pct    = dealcount_midwest / dealcount_national,
    wi_pct         = dealcount_wi / dealcount_national
  )

# Vol

vol_ts_data <- vol_iqr |>
  left_join( # National Average
    vol_wide |>
      group_by(year) |>
      summarise(dealvol_national = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
      group_by(year) |>
      summarise(dealvol_national_nonoutlier = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(State %in% c('Minnesota','Iowa', 'Illinois', 'Michigan', 'Indiana')) |>
      group_by(year) |>
      summarise(dealvol_midwest = mean(count, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    vol_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealvol_wi = count),
    by = "year"
  ) |>
  mutate(year = as.numeric(year)) |> 
  mutate(nonoutlier_pct = dealvol_national_nonoutlier/dealvol_national,
         wi_pct = dealvol_wi/dealvol_national,
         midwest_pct = dealvol_midwest/dealvol_national) # Add WI percent

# Dealsize

dealsize_ts_data <- size_iqr |>
  left_join( # National Average
  dealsize_wide |>
      group_by(year) |>
      summarise(dealsize_national = mean(dealsize, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    dealsize_wide |>
      filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
      group_by(year) |>
      summarise(dealsize_national_nonoutlier = mean(dealsize, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    dealsize_wide |>
      filter(State %in% c('Minnesota','Iowa', 'Illinois', 'Michigan', 'Indiana')) |>
      group_by(year) |>
      summarise(dealsize_midwest = mean(dealsize, na.rm = TRUE), .groups = "drop"),
    by = "year"
  ) |>
  left_join(
    dealsize_wide |>
      filter(State == "Wisconsin") |>
      transmute(year, dealsize_wi = dealsize),
    by = "year"
  ) |>
  mutate(year = as.numeric(year)) |> 
  mutate(nonoutlier_pct = dealsize_national_nonoutlier/dealsize_national,
         wi_pct = dealsize_wi/dealsize_national,
         midwest_pct = dealsize_midwest/dealsize_national) # Add WI percent

# Barplots: Dealcount and Capital Committed  --------------------------------------------------

# --- Dealcount over time

count_ts_data |>
  select(year, dealcount_national, dealcount_wi, dealcount_national_nonoutlier, dealcount_midwest,
         wi_pct, nonoutlier_pct, midwest_pct) |>
  pivot_longer(
    cols = c(dealcount_national, dealcount_national_nonoutlier, dealcount_wi, dealcount_midwest),
    names_to = "series",
    values_to = "dealcount"
  ) |>
  mutate(
    series = recode(series,
                    dealcount_national = "National avg.",
                    dealcount_national_nonoutlier = "National avg. (excl. CA, MA, NY)",
                    dealcount_wi = "Wisconsin",
                    dealcount_midwest = "Midwest avg. (excl. WI)"
    )) |> 
  mutate(
    series = factor(
      series, 
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  ) |>
  ggplot(aes(x = factor(year), y = dealcount, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  # ONE text layer, all series; only label WI + non-outlier
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(wi_pct, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(nonoutlier_pct, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(midwest_pct, accuracy = 1.0),
        TRUE ~ NA_character_ # no label for plain national avg.
      )),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest avg. (excl. WI)" = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg." = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Deal Count: Wisconsin vs National Average",
    subtitle = "2015–2024",
    x        = "Year",
    y        = "Number of deals",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q3 2025. Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealcount

save_fig(p = vc_dealcount, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/1_vc_dealcount.jpeg', w = 16.5, h = 5.5)

# --- Deal Volume over time

vol_ts_data |>
  select(year, dealvol_national, dealvol_wi, dealvol_national_nonoutlier, dealvol_midwest,
         wi_pct, nonoutlier_pct, midwest_pct) |>
  pivot_longer(
    cols = c(dealvol_national, dealvol_national_nonoutlier, dealvol_wi, dealvol_midwest),
    names_to = "series",
    values_to = "dealvol"
  ) |>
  mutate(
    series = recode(series,
                    dealvol_national = "National avg.",
                    dealvol_national_nonoutlier = "National avg. (excl. CA, MA, NY)",
                    dealvol_midwest = "Midwest avg. (excl. WI)",
                    dealvol_wi = "Wisconsin"
    )) |> 
  mutate(
    series = factor(
      series, 
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  ) |>
  ggplot(aes(x = factor(year), y = dealvol, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  # ONE text layer, all series; only label WI + non-outlier
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(wi_pct, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(midwest_pct, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(nonoutlier_pct, accuracy = 1.0),
        TRUE ~ NA_character_ # no label for plain national avg.
      )),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest avg. (excl. WI)" = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg." = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Capital Committed: Wisconsin vs National Average",
    subtitle = "2015–2024",
    x        = "Year",
    y        = "USD (Millions)",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q3 2025. Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealvol

save_fig(p = vc_dealvol, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/2_vc_capcommitted.jpeg', w = 16.5, h = 5.5)


# --- Deal Size

dealsize_ts_data |>
  select(year, dealsize_national, dealsize_wi, dealsize_national_nonoutlier, dealsize_midwest,
         wi_pct, nonoutlier_pct, midwest_pct) |>
  pivot_longer(
    cols = c(dealsize_national, dealsize_national_nonoutlier, dealsize_wi, dealsize_midwest),
    names_to = "series",
    values_to = "dealsize"
  ) |>
  mutate(
    series = recode(series,
                    dealsize_national = "National avg.",
                    dealsize_midwest = "Midwest avg. (excl. WI)",
                    dealsize_national_nonoutlier = "National avg. (excl. CA, MA, NY)",
                    dealsize_wi = "Wisconsin"
    )) |>
  mutate(
    series = factor(
      series, 
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  ) |>
  ggplot(aes(x = factor(year), y = dealsize, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  # ONE text layer, all series; only label WI + non-outlier
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(wi_pct, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(midwest_pct, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(nonoutlier_pct, accuracy = 1.0),
        TRUE ~ NA_character_ # no label for plain national avg.
      )),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest avg. (excl. WI)" = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg." = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Venture Capital Deal Size: Wisconsin vs National Average",
    subtitle = "2015–2024",
    x        = "Year",
    y        = "USD (Millions)",
    fill     = NULL,
    caption  = "Source: Pitchbook Venture Capital Monitor Q3 2025. Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> vc_dealsize

save_fig(p = vc_dealsize, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/3_vc_dealsize.jpeg', w = 16.5, h = 5.5)


# Map: 2024 levels  --------------------------------------------------

# --- Volume

vol_2024 <- vol_wide |>
  filter(year %in% c("2024")) |>
  filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
  pivot_wider(names_from = year, values_from = count) |>
  rename(total = '2024')


map_df <- map_data("state") |>
  mutate(State = str_to_title(region)) 
  

map_level <- map_df |>
  left_join(vol_2024, by = "State")

p_map_level_capcommit <- ggplot(map_level, aes(long, lat, group = group, fill = total)) +
  geom_polygon(color = "grey50", linewidth = 0.25) +
  coord_fixed(1.3) +
  scale_fill_gradient2(
    low = "#b2182b",
    mid = "white",
    high = "#2166ac",
    midpoint = 0,
    na.value = "grey90",
    name = "2024 deal volumes, USD (million)",
    limits = c(min(map_level$total, na.rm = TRUE),
               max(map_level$total, na.rm = TRUE))
  ) +
  labs(
    title = "VC capital committed, 2024",
    subtitle = "VC capital committed, by receiver HQ state",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California, New York, and Massachusetts omitted."
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

p_map_level_capcommit

save_fig(p = p_map_level_capcommit, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/4_cap_committed_map.jpeg')

# --- Deal Size

dealsize_wide |>
  filter(year == 2024) |>
  arrange(desc(dealsize))

dealsize_2024 <- dealsize_wide |>
  filter(year %in% c("2024")) |>
  pivot_wider(names_from = year, values_from = dealsize) |>
  rename(total = '2024')


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
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California, New York, and Massachusetts omitted."
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

p_map_level_dealsize

save_fig(p = p_map_level_dealsize, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/5_dealsize_map.jpeg')

#What's happening in West Virginia?

count_wide |>
  filter(year == 2024, State == "West Virginia")

vol_wide |>
  filter(year == 2024, State == "West Virginia")

# Age 0 Businesses  --------------------------------------------------

# Define state sets
midwest_excl_wi <- c("27", "19", "17", "26", "18")  # MN, IA, IL, MI, IN
big3            <- c("06", "25", "36")              # CA, MA, NY
wi_fips         <- "55"

# Base data: all states, firm age 0, post-2014
base <- bds_fa |>
  filter(year > 2014,
         fage == "a) 0") |>
  transmute(year, st, firms = as.numeric(firms))

## 1) National average (ALL states, incl. Midwest)
grp_nat <- base |>
  group_by(year) |>
  summarise(
    firmcount = mean(firms, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(group = "National avg.")

## 2) National avg EXCEPT CA, MA, NY
grp_nat_excl_big3 <- base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(
    firmcount = mean(firms, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

## 3) Midwest EXCEPT WI (MN, IA, IL, MI, IN)
grp_midwest <- base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(
    firmcount = mean(firms, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(group = "Midwest avg. (excl. WI)")

## 4) WI only
grp_wi <- base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(
    firmcount = mean(firms, na.rm = TRUE),  # effectively just firms, but keeps pattern
    .groups = "drop"
  ) |>
  mutate(group = "Wisconsin")

grp_all <- bind_rows(grp_nat, grp_nat_excl_big3, grp_midwest, grp_wi)

grp_all <- grp_all |>
  left_join(
    grp_nat |> select(nat_avg = firmcount, year),
    by = "year"
  ) |>
  mutate(pct_of_nat = firmcount / nat_avg)

rm(grp_midwest, grp_nat, grp_nat_excl_big3, grp_wi)

# --- Make barplot

grp_all |>
  select(year, firmcount, group, pct_of_nat) |>
  mutate(
    series = factor(
      group, 
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  ) |>
  ggplot(aes(x = factor(year), y = firmcount, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  # ONE text layer, all series; only label WI + non-outlier
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "Wisconsin" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "Midwest avg. (excl. WI)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
        TRUE ~ NA_character_ # no label for plain national avg.
      )),
    position = position_dodge(width = 0.75),
    vjust = -0.6,
    size = 3,
    na.rm = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "Wisconsin" = "#c5050c",
      "Midwest avg. (excl. WI)" = "blue",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "National avg." = "black"
    )) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Business Age 0 Births",
    subtitle = "2015–2024",
    x        = "Year",
    y        = "Average Firms",
    fill     = NULL,
    caption  = "Source: US Census Business Dynamics Statistics (BDS). Percents above each bar refer to the percent of National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
  ) +
  theme_im() -> new_firms_base


  save_fig(p = new_firms_base, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/6_new_firms_base.jpeg', w = 16.5, h = 5.5)

  #-----------------------------
  # Age 0 Businesses, normalized by labor force
  #-----------------------------
  
  # State sets (same as before)
  midwest_excl_wi <- c("27", "19", "17", "26", "18")  # MN, IA, IL, MI, IN
  big3            <- c("06", "25", "36")              # CA, MA, NY
  wi_fips         <- "55"
  
  # Base data: all states, firm age 0, post-2014, normalized by labor force
  base_lf <- bds_fa |>
    filter(year > 2014,
           fage == "a) 0") |>
    left_join(participationdir, by = c("year", "st" = "FIPS")) |>
    transmute(
      year,
      st,
      # firms per unit of labor force (whatever scale Force is in)
      firms_norm = as.numeric(firms) / (Force/100000)
    )
  
  ## 1) National average (ALL states, incl. Midwest) - normalized
  grp_nat_lf <- base_lf |>
    group_by(year) |>
    summarise(
      firmcount = mean(firms_norm, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(group = "National avg.")
  
  ## 2) National avg EXCEPT CA, MA, NY - normalized
  grp_nat_excl_big3_lf <- base_lf |>
    filter(!st %in% big3) |>
    group_by(year) |>
    summarise(
      firmcount = mean(firms_norm, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(group = "National avg. (excl. CA, MA, NY)")
  
  ## 3) Midwest EXCEPT WI (MN, IA, IL, MI, IN) - normalized
  grp_midwest_lf <- base_lf |>
    filter(st %in% midwest_excl_wi) |>
    group_by(year) |>
    summarise(
      firmcount = mean(firms_norm, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(group = "Midwest avg. (excl. WI)")
  
  ## 4) WI only - normalized
  grp_wi_lf <- base_lf |>
    filter(st == wi_fips) |>
    group_by(year) |>
    summarise(
      firmcount = mean(firms_norm, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(group = "Wisconsin")
  
  # Combine and compute % of national avg (normalized)
  grp_all_lf <- bind_rows(grp_nat_lf, grp_nat_excl_big3_lf, grp_midwest_lf, grp_wi_lf) |>
    left_join(
      grp_nat_lf |> select(year, nat_avg = firmcount),
      by = "year"
    ) |>
    mutate(pct_of_nat = firmcount / nat_avg)
  
  rm(grp_nat_lf, grp_nat_excl_big3_lf, grp_midwest_lf, grp_wi_lf)
  
  # --- Make normalized barplot (same structure as new_firms_base)
  
  grp_all_lf |>
    select(year, firmcount, group, pct_of_nat) |>
    mutate(
      series = factor(
        group,
        levels = c(
          "National avg.",
          "National avg. (excl. CA, MA, NY)",
          "Midwest avg. (excl. WI)",
          "Wisconsin"
        )
      )
    ) |>
    ggplot(aes(x = factor(year), y = firmcount, fill = series)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.65) +
    geom_text(
      aes(
        label = dplyr::case_when(
          series == "Wisconsin" ~ scales::percent(pct_of_nat, accuracy = 1.0),
          series == "Midwest avg. (excl. WI)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
          series == "National avg. (excl. CA, MA, NY)" ~ scales::percent(pct_of_nat, accuracy = 1.0),
          TRUE ~ NA_character_
        )
      ),
      position = position_dodge(width = 0.75),
      vjust = -0.6,
      size = 3,
      na.rm = TRUE
    ) +
    scale_fill_manual(
      values = c(
        "Wisconsin"                  = "#c5050c",
        "Midwest avg. (excl. WI)"    = "blue",
        "National avg. (excl. CA, MA, NY)" = "grey60",
        "National avg."              = "black"
      )
    ) +
    scale_y_continuous(labels = scales::label_comma()) +
    labs(
      title    = "Business Age 0 Births Per 100,000 labor force participants",
      subtitle = "2015–2024",
      x        = "Year",
      y        = "Average Firms per Labor Force Participant",
      fill     = NULL,
      caption  = "Source: US Census BDS; labor participation from CPS/LAUS. Percents above each bar refer to the percent of the normalized National Average. Midwest states include Minnesota, Iowa, Illinois, Indiana, and Michigan."
    ) +
    theme_im() -> new_firms_normalized
  
  save_fig(
    p        = new_firms_normalized,
    filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/7_new_firms_barplot_normalized_lfp.jpeg",
    w        = 16.5,
    h        = 5.5
  )

# Form D Visualizations: Formatting Data   --------------------------------------------------
formd_data_US <- formd_data |> 
  filter(zip_class %in% c("US_ZIP + 4", "US_ZIP5")) |>
  filter(!(stateorcountrydescription %in% c("ALBERTA, CANADA", "AMERICAN SAMOA",
                                          "ANGUILLA", "ANTIGUA AND BARBUDA", "ARGENTINA", 
                                          "ARMENIA", "AUSTRALIA", "AUSTRIA", "AZERBAIJAN", 
                                          "BAHAMAS", "BANGLADESH", "BARBADOS", "BELGIUM", "BELIZE", 
                                          "BERMUDA", "BRAZIL", "BRITISH COLUMBIA, CANADA", "BULGARIA", 
                                          "CANADA (FEDERAL LEVEL)", "CAYMAN ISLANDS", "CHILE", "CHINA", 
                                          "COLOMBIA", "COOK ISLANDS", "COSTA RICA", "CROATIA", "DENMARK", 
                                          "EGYPT", "ESTONIA", "ETHIOPIA", "FINLAND", "FRANCE", "GERMANY", 
                                          "GHANA", "GIBRALTAR", "GREECE", "GRENADA", "GUAM", "GUATEMALA", 
                                          "GUERNSEY", "HONDURAS", "HONG KONG", "INDONESIA", "IRELAND", 
                                          "ISRAEL", "ITALY", "JAMAICA", "KENYA", "KOREA, REPUBLIC OF", 
                                          "LUXEMBOURG", "MACAU", "MALAYSIA", "MARSHALL ISLANDS", "MAURITIUS",
                                          "MEXICO", "MICRONESIA, FEDERATED STATES OF", "MONACO", "MONGOLIA", "NETHERLANDS",
                                          "NETHERLANDS ANTILLES", "NIGERIA", "NEW ZEALAND", "NIGERIA", "NORTHERN MARIANA ISLANDS", 
                                          "NORWAY", "ONTARIO, CANADA", "PAKISTAN", "PANAMA", "PERU", "PUERTO RICO", "QUEBEC, CANADA", 
                                          "RUSSIAN FEDERATION", "RWANDA", "SAINT KITTS AND NEVIS", "SAINT LUCIA", "SAINT VINCENT AND THE GRENADINES", 
                                          "SERBIA", "SEYCHELLES", "SINGAPORE", "SLOVAKIA", "SPAIN", "SWEDEN", "SWITZERLAND", "TAIWAN", "TAIWAN, PROVINCE OF CHINA", 
                                          "THAILAND", "TURKEY", "UGANDA", "UKRAINE", "UNITED ARAB EMIRATES", "UNITED KINGDOM", "UNITED STATES MINOR OUTLYING ISLANDS", 
                                          "URUGUAY", "VIET NAM", "VIRGIN ISLANDS, BRITISH", "VIRGIN ISLANDS, U.S.", ""))) |>
  filter(accessionnumber != '0001584209-16-000007') |> #Filter out crazy art fund transaction
  filter(totalamountsold < 100000000) |> # Filter for now
  filter(!(stateorcountry %in% c("CA", "2Q", "MA", "NY", "PR", "X1", "I0"))) |>  #Filter out remaining junk states, MA, NY, CA
  select(entityname, cik, biz_id, stateorcountry, stateorcountrydescription, zipcode, COUNTY, entitytype, year, over100recipientflag, incremental_amount) |>
  filter(incremental_amount != 0)

# Form D Visualizations: Wisconsin map, increment volumes  --------------------------------------------------


formd_wi_county <- formd_data_US |>
  mutate(
    county_fips = str_pad(COUNTY, width = 5, side = "left", pad = "0")
  ) |>
  # keep only Wisconsin counties by FIPS prefix
  filter(substr(county_fips, 1, 2) == "55") |>
  group_by(county_fips) |>
  summarise(
    total_increment = sum(incremental_amount, na.rm = TRUE),
    n_filings       = n(),
    .groups         = "drop"
  )


options(tigris_use_cache = TRUE)

wi_counties <- tigris::counties(state = "WI", cb = TRUE, year = 2023) |> 
  st_transform(5070)   # or 4326 if you prefer lon/lat; 5070 is a nice CONUS proj


wi_map <- wi_counties |>
  mutate(county_fips = GEOID) |>
  left_join(formd_wi_county, by = "county_fips")

ggplot(wi_map) +
  geom_sf(aes(fill = total_increment), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    option = "magma",
    na.value = "grey90",
    labels = label_dollar(scale = 1, suffix = "", accuracy = 1),
    trans = "log10",   # helps if the distribution is very skewed
    name = "Total incremental\nForm D capital"
  ) +
  labs(
    title    = "Form D Capital Raised in Wisconsin by County",
    subtitle = "Total incremental amount sold, 2015-2024",
    caption  = "Source: SEC Form D (via dform); author calculations"
  ) +
  coord_sf() +
  theme_minimal(base_size = 12) -> increment_sold_cumulative

save_fig(p = increment_sold_cumulative, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/8_increment_sold_cumulative.jpeg')


# Form D Visualizations: Wisconsin map, transaction volumes  --------------------------------------------------

ggplot(wi_map) +
  geom_sf(aes(fill = n_filings), color = "white", linewidth = 0.2) +
  scale_fill_viridis_c(
    option = "plasma",
    na.value = "grey90",
    labels = label_comma(),
    name = "Number of Form D\nfilings"
  ) +
  labs(
    title    = "Form D Filing Count in Wisconsin by County",
    subtitle = "Number of filings, 2015-2014",
    caption  = "Source: SEC Form D (via dform); author calculations"
  ) +
  coord_sf() +
  theme_minimal(base_size = 12) -> total_deals_cumulative

save_fig(p = total_deals_cumulative, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/9_total_deals_cumulative.jpeg')


# Form D Visualizations: Wisconsin vs. Nat, Midwest volume avg. over time  --------------------------------------------------


#--------------------------------------------------
# 0. Compute (year, state, RUCC) Form D metrics
#--------------------------------------------------

formd_group_year <- formd_data_US |>
  mutate(
    county_fips = str_pad(COUNTY, width = 5, pad = "0"),
    st          = substr(county_fips, 1, 2)
  ) |>
  left_join(
    rucc |> mutate(RUCC_2023 = as.integer(RUCC_2023)) |> select(FIPS, RUCC_2023),
    by = c("county_fips" = "FIPS")
  ) |>
  select(year, st, incremental_amount, RUCC_2023) |>
  mutate(
    rucc_grp = case_when(
      RUCC_2023 %in% c(1,2,3,4,6,8) ~ "metro/metro-adjacent",
      TRUE                          ~ "rural"
    )
  ) |>
  group_by(year, st, rucc_grp) |>
  summarise(
    incremental_dollars = sum(incremental_amount, na.rm = TRUE),
    dealcount           = n(),
    avg_dealsize        = incremental_dollars / dealcount,
    .groups = "drop"
  ) |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  filter(!is.na(Force), Force > 0) |>
  mutate(
    adjusted_dollars = incremental_dollars / (Force/100000)
  )


#--------------------------------------------------
# 1. Build complete (year, state, RUCC) panel
#--------------------------------------------------

rucc_levels <- c("metro/metro-adjacent", "rural")

formd_base <- formd_group_year |>
  mutate(
    st       = str_pad(st, width = 2, pad = "0"),
    rucc_grp = factor(rucc_grp, levels = rucc_levels)
  ) |>
  select(year, st, rucc_grp, incremental_dollars, dealcount, adjusted_dollars)

formd_complete <- formd_base |>
  complete(
    year,
    st,
    rucc_grp = rucc_levels,
    fill = list(
      incremental_dollars = 0,
      dealcount           = 0,
      adjusted_dollars    = 0
    )
  )


#--------------------------------------------------
# 2. Define region groupings (same as your VC/BDS figures)
#--------------------------------------------------

midwest_excl_wi <- c("27", "19", "17", "26", "18")   # MN, IA, IL, MI, IN
big3            <- c("06", "25", "36")               # CA, MA, NY
wi_fips         <- "55"


#--------------------------------------------------
# 3. Construct the 4-group average-state values (Volume example)
#--------------------------------------------------

# -- 1) National avg
vol_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

# -- 2) National avg (excl. CA/MA/NY)
vol_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

# -- 3) Midwest avg (excl. WI)
vol_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

# -- 4) Wisconsin
vol_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(incremental_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

# Combine all RUCC-segmented summaries
vol_all <- bind_rows(vol_nat, vol_nat_excl, vol_midwest, vol_wi)

#--------------------------------------------------
# 4. Compute % of national average (sum over RUCC)
#--------------------------------------------------

series_levels <- c(
  "National avg.",
  "National avg. (excl. CA, MA, NY)",
  "Midwest avg. (excl. WI)",
  "Wisconsin"
)

vol_all <- vol_all |>
  mutate(
    series = factor(group, levels = series_levels)
  )

# Region totals (metro + rural) in "average-state" units
vol_totals <- vol_all |>
  group_by(year, series) |>
  summarise(
    region_total = sum(value, na.rm = TRUE),
    .groups      = "drop"
  )

# National benchmark (average state)
nat_totals <- vol_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

# Attach % of national back to RUCC-level rows
vol_all <- vol_all |>
  left_join(vol_totals, by = c("year", "series")) |>
  left_join(nat_totals,  by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

#--------------------------------------------------
# 5. Build manual x positions so we can dodge by series,
#    stack by RUCC, and keep a clean year axis
#--------------------------------------------------

# numeric index for years (1, 2, 3, ...)
years <- sort(unique(vol_all$year))
year_index <- setNames(seq_along(years), years)

vol_all <- vol_all |>
  mutate(
    year_idx   = year_index[as.character(year)],
    series_idx = as.numeric(series),
    # tweak 0.18 if you want bars closer or further apart
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

# Data for text labels: one row per (year, series)
label_df <- vol_all |>
  group_by(year, year_idx, series, x_pos, pct_of_nat) |>
  summarise(
    total_value = sum(value, na.rm = TRUE),
    .groups     = "drop"
  )

# Axis breaks at integer year positions
x_breaks <- unique(vol_all$year_idx)
x_labels <- names(year_index)[match(x_breaks, year_index)]

#--------------------------------------------------
# 6. Plot: Incremental Form D volume
#--------------------------------------------------

vc_formd_vol <- ggplot(
  vol_all,
  aes(
    x       = x_pos,
    y       = value,
    fill    = series,      # region colors
    pattern = rucc_grp     # metro vs rural as pattern
  )
) +
  ggpattern::geom_col_pattern(
    color           = "grey30",
    pattern_density = 0.35,
    pattern_spacing = 0.02,
    pattern_colour  = "black"
  ) +
  # Percent-of-national label on top of each region bar
  geom_text(
    data = label_df,
    mapping = aes(
      x     = x_pos,
      y     = total_value,
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1)
      ),
      group = series
    ),
    inherit.aes = FALSE,
    vjust       = -0.4,
    size        = 3,
    na.rm       = TRUE
  ) +
  scale_x_continuous(
    breaks = x_breaks,
    labels = x_labels
  ) +
  # --- region colors: same code as your previous items
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  # --- RUCC patterns: metro solid, rural striped
  scale_pattern_manual(
    values = c(
      "metro/metro-adjacent" = "none",
      "rural"                = "stripe"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Incremental Form D Capital per Average State, by Region and RUCC",
    subtitle = "2015–2024; bars show average state incremental dollars; shading/pattern shows metro vs rural counties",
    x        = "Year",
    y        = "Average incremental dollars per state",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

vc_formd_vol

save_fig(
  p        = vc_formd_vol,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/10_incremental_formD_time.jpeg",
  w        = 16.5,
  h        = 5.5
)

#--------------------------------------------------
# Figure 11: Incremental Form D capital per 100,000 labor force
#--------------------------------------------------

# 3A. Construct the 4-group average-state values for adjusted_dollars

adj_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

adj_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

adj_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

adj_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(adjusted_dollars, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

adj_all <- bind_rows(adj_nat, adj_nat_excl, adj_midwest, adj_wi)

# 4A. Percent of national average (sum over RUCC)

series_levels <- c(
  "National avg.",
  "National avg. (excl. CA, MA, NY)",
  "Midwest avg. (excl. WI)",
  "Wisconsin"
)

adj_all <- adj_all |>
  mutate(
    series = factor(group, levels = series_levels)
  )

adj_totals <- adj_all |>
  group_by(year, series) |>
  summarise(
    region_total = sum(value, na.rm = TRUE),
    .groups      = "drop"
  )

adj_nat_totals <- adj_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

adj_all <- adj_all |>
  left_join(adj_totals,    by = c("year", "series")) |>
  left_join(adj_nat_totals, by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

# 5A. Manual x-positions (same logic as for vol_all, but separate objects)

adj_years <- sort(unique(adj_all$year))
adj_year_index <- setNames(seq_along(adj_years), adj_years)

adj_all <- adj_all |>
  mutate(
    year_idx   = adj_year_index[as.character(year)],
    series_idx = as.numeric(series),
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

adj_label_df <- adj_all |>
  group_by(year, year_idx, series, x_pos, pct_of_nat) |>
  summarise(
    total_value = sum(value, na.rm = TRUE),
    .groups     = "drop"
  )

adj_x_breaks <- unique(adj_all$year_idx)
adj_x_labels <- names(adj_year_index)[match(adj_x_breaks, adj_year_index)]

# 6A. Plot: adjusted dollars (per 100k labor force)

vc_formd_vol_adj <- ggplot(
  adj_all,
  aes(
    x       = x_pos,
    y       = value,
    fill    = series,
    pattern = rucc_grp
  )
) +
  ggpattern::geom_col_pattern(
    color           = "grey30",
    pattern_density = 0.35,
    pattern_spacing = 0.02,
    pattern_colour  = "black"
  ) +
  geom_text(
    data = adj_label_df,
    mapping = aes(
      x     = x_pos,
      y     = total_value,
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1)
      ),
      group = series
    ),
    inherit.aes = FALSE,
    vjust       = -0.4,
    size        = 3,
    na.rm       = TRUE
  ) +
  scale_x_continuous(
    breaks = adj_x_breaks,
    labels = adj_x_labels
  ) +
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  scale_pattern_manual(
    values = c(
      "metro/metro-adjacent" = "none",
      "rural"                = "stripe"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Incremental Form D Capital per 100,000 Labor Force Participants",
    subtitle = "2015–2024; bars show average state incremental dollars per 100k labor force; pattern shows metro vs rural counties",
    x        = "Year",
    y        = "Dollars",
    caption  = "Source: SEC Form D; USDA RUCC; CPS/LAUS labor force participation. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

vc_formd_vol_adj

save_fig(
  p        = vc_formd_vol_adj,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/11_incremental_formD_per_lf_time.jpeg",
  w        = 16.5,
  h        = 5.5
)

#--------------------------------------------------
# Figure 12: Form D deal count per average state
#--------------------------------------------------

# 3B. Construct the 4-group average-state values for dealcount

cnt_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

cnt_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

cnt_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

cnt_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

cnt_all <- bind_rows(cnt_nat, cnt_nat_excl, cnt_midwest, cnt_wi)

# 4B. Percent of national average (sum over RUCC)

series_levels <- c(
  "National avg.",
  "National avg. (excl. CA, MA, NY)",
  "Midwest avg. (excl. WI)",
  "Wisconsin"
)

cnt_all <- cnt_all |>
  mutate(
    series = factor(group, levels = series_levels)
  )

cnt_totals <- cnt_all |>
  group_by(year, series) |>
  summarise(
    region_total = sum(value, na.rm = TRUE),
    .groups      = "drop"
  )

cnt_nat_totals <- cnt_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

cnt_all <- cnt_all |>
  left_join(cnt_totals,     by = c("year", "series")) |>
  left_join(cnt_nat_totals, by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

# 5B. Manual x-positions

cnt_years <- sort(unique(cnt_all$year))
cnt_year_index <- setNames(seq_along(cnt_years), cnt_years)

cnt_all <- cnt_all |>
  mutate(
    year_idx   = cnt_year_index[as.character(year)],
    series_idx = as.numeric(series),
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

cnt_label_df <- cnt_all |>
  group_by(year, year_idx, series, x_pos, pct_of_nat) |>
  summarise(
    total_value = sum(value, na.rm = TRUE),
    .groups     = "drop"
  )

cnt_x_breaks <- unique(cnt_all$year_idx)
cnt_x_labels <- names(cnt_year_index)[match(cnt_x_breaks, cnt_year_index)]

# 6B. Plot: deal count

vc_formd_dealcount <- ggplot(
  cnt_all,
  aes(
    x       = x_pos,
    y       = value,
    fill    = series,
    pattern = rucc_grp
  )
) +
  ggpattern::geom_col_pattern(
    color           = "grey30",
    pattern_density = 0.35,
    pattern_spacing = 0.02,
    pattern_colour  = "black"
  ) +
  geom_text(
    data = cnt_label_df,
    mapping = aes(
      x     = x_pos,
      y     = total_value,
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1)
      ),
      group = series
    ),
    inherit.aes = FALSE,
    vjust       = -0.4,
    size        = 3,
    na.rm       = TRUE
  ) +
  scale_x_continuous(
    breaks = cnt_x_breaks,
    labels = cnt_x_labels
  ) +
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  scale_pattern_manual(
    values = c(
      "metro/metro-adjacent" = "none",
      "rural"                = "stripe"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Form D Deal Count per Average State, by Region and RUCC",
    subtitle = "2015–2024; bars show average number of Form D filings per state; pattern shows metro vs rural counties",
    x        = "Year",
    y        = "Average Form D filings per state",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

vc_formd_dealcount

save_fig(
  p        = vc_formd_dealcount,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/12_formD_dealcount_time.jpeg",
  w        = 16.5,
  h        = 5.5
)

#--------------------------------------------------
# Figure 13: Form D deal size per average state (metro / metro-adjacent)
#--------------------------------------------------

# 13.1  State-level metro deal size
metro_base <- formd_complete |>
  filter(rucc_grp == "metro/metro-adjacent") |>
  group_by(year, st) |>
  summarise(
    incremental_dollars = sum(incremental_dollars, na.rm = TRUE),
    dealcount           = sum(dealcount,           na.rm = TRUE),
    .groups             = "drop"
  ) |>
  mutate(
    dealsize = ifelse(dealcount > 0,
                      incremental_dollars / dealcount,
                      NA_real_)
  )

# 13.2  Average-state values for the 4 regions

metro_nat <- metro_base |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "National avg.")

metro_nat_excl <- metro_base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "National avg. (excl. CA, MA, NY)")

metro_midwest <- metro_base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "Midwest avg. (excl. WI)")

metro_wi <- metro_base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "Wisconsin")

metro_all <- bind_rows(metro_nat, metro_nat_excl, metro_midwest, metro_wi)

# 13.3  Percent of national average

metro_all <- metro_all |>
  mutate(
    series = factor(
      series,
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  )

metro_nat_ref <- metro_all |>
  filter(series == "National avg.") |>
  select(year, nat_value = value)

metro_all <- metro_all |>
  left_join(metro_nat_ref, by = "year") |>
  mutate(pct_of_nat = value / nat_value)

# 13.4  Plot

vc_formd_dealsize_metro <- metro_all |>
  ggplot(aes(x = factor(year), y = value, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1.0)
      )
    ),
    position = position_dodge(width = 0.75),
    vjust    = -0.6,
    size     = 3,
    na.rm    = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Form D Deal Size per Average State, Metro & Metro-Adjacent Counties",
    subtitle = "2015–2024; average incremental dollars per Form D filing in the average metro/adjacent state",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to the national metro average."
  ) +
  theme_im()

vc_formd_dealsize_metro

save_fig(
  p        = vc_formd_dealsize_metro,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/13_formD_dealsize_metro.jpeg",
  w        = 16.5,
  h        = 5.5
)

#--------------------------------------------------
# Figure 14: Form D deal size per average state (rural)
#--------------------------------------------------

# 14.1  State-level rural deal size
rural_base <- formd_complete |>
  filter(rucc_grp == "rural") |>
  group_by(year, st) |>
  summarise(
    incremental_dollars = sum(incremental_dollars, na.rm = TRUE),
    dealcount           = sum(dealcount,           na.rm = TRUE),
    .groups             = "drop"
  ) |>
  mutate(
    dealsize = ifelse(dealcount > 0,
                      incremental_dollars / dealcount,
                      NA_real_)
  )

# 14.2  Average-state values for the 4 regions

rural_nat <- rural_base |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "National avg.")

rural_nat_excl <- rural_base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "National avg. (excl. CA, MA, NY)")

rural_midwest <- rural_base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "Midwest avg. (excl. WI)")

rural_wi <- rural_base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "Wisconsin")

rural_all <- bind_rows(rural_nat, rural_nat_excl, rural_midwest, rural_wi)

# 14.3  Percent of national average

rural_all <- rural_all |>
  mutate(
    series = factor(
      series,
      levels = c(
        "National avg.",
        "National avg. (excl. CA, MA, NY)",
        "Midwest avg. (excl. WI)",
        "Wisconsin"
      )
    )
  )

rural_nat_ref <- rural_all |>
  filter(series == "National avg.") |>
  select(year, nat_value = value)

rural_all <- rural_all |>
  left_join(rural_nat_ref, by = "year") |>
  mutate(pct_of_nat = value / nat_value)

# 14.4  Plot

vc_formd_dealsize_rural <- rural_all |>
  ggplot(aes(x = factor(year), y = value, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1.0)
      )
    ),
    position = position_dodge(width = 0.75),
    vjust    = -0.6,
    size     = 3,
    na.rm    = TRUE
  ) +
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Form D Deal Size per Average State, Rural Counties",
    subtitle = "2015–2024; average incremental dollars per Form D filing in the average rural state",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to the national rural average."
  ) +
  theme_im()

vc_formd_dealsize_rural

save_fig(
  p        = vc_formd_dealsize_rural,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/14_formD_dealsize_rural.jpeg",
  w        = 16.5,
  h        = 5.5
)

#--------------------------------------------------
# Figure 15: Form D Figure 3 from CORI
#--------------------------------------------------

# Identify top 3...
formd_data_US |>
  group_by(stateorcountry, year) |> 
  summarise(total = sum(incremental_amount)) |>
  group_by(stateorcountry) |>
  summarise(mean_amount = mean(total)) |>
  arrange(desc(mean_amount))

formd_data_US |> 
  select(year, stateorcountry, COUNTY, incremental_amount) |> 
  left_join(rucc |> select(FIPS, RUCC_2023), by = c("COUNTY" = "FIPS")) |>
  mutate(
    rucc_type = ifelse(RUCC_2023 %in% c("1", "2", "3"), "metro", "rural")
  ) |>
  group_by(year, stateorcountry, rucc_type) |> 
  summarise(total = sum(incremental_amount, na.rm = TRUE)) |> #sum of form D filings in a given year
  group_by(stateorcountry, rucc_type) |>
  summarise(average_filings = mean(total, na.rm = TRUE)) |> #avg. across years
  mutate(
    grp = case_when(
      stateorcountry %in% c("TX", "IL", "FL") ~ "Top 3 (TX, IL, FL)",
      stateorcountry == "WI" ~ "WI",
      TRUE ~ "All other states"
    )
  ) |>
  group_by(grp, rucc_type) |>
  summarise(mean_amount = mean(average_filings, na.rm = TRUE), .groups = "drop") |> #avg. across states
  ggplot(aes(x = mean_amount, y = grp, fill = rucc_type)) +
  geom_col(position = position_dodge(width = 0.8)) +
  scale_x_continuous(labels = scales::label_comma()) +
  scale_fill_manual(
    values = c(
      "metro" = "blue",
      "rural" = "purple"
    ),
    name = "RUCC type"
  ) +
  labs(
    title    = "Form D filing amounts, yearly averages",
    subtitle = "2015–2024; average incremental dollars per Form D filing",
    x        = "Amount Raised (USD)",
    y        = "",
    caption  = "Source: SEC Form D; USDA RUCC. Values calculated by averaging across years for each group."
  ) +
  theme_im() +
  theme(legend.position = "bottom") -> x


  
save_fig(
  p        = x,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/15_formD_yearly_averages.jpeg",
  w        = 16.5,
  h        = 5.5
)

rm(x)

#--------------------------------------------------
# Figure 16: Form D Figure 11 from CORI, but filing size
#--------------------------------------------------

formd_data_US |> 
  select(year, stateorcountry, COUNTY, incremental_amount) |> 
  mutate(COUNTY = stringr::str_pad(COUNTY, 5, pad = "0")) |>
  left_join(rucc |> select(FIPS, RUCC_2023), by = c("COUNTY" = "FIPS")) |>
  mutate(
    rucc_type = ifelse(RUCC_2023 %in% c("1", "2", "3"), "metro", "rural")
  ) |>
  group_by(year, rucc_type) |> 
  summarise(average_filings = mean(incremental_amount, na.rm = TRUE),
            .groups = "drop") |>
  ggplot(aes(x = year, y = average_filings, color = rucc_type)) + 
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_color_manual(
    values = c(
      "metro" = "blue",
      "rural" = "purple"
    ),
    name = "RUCC type"
  ) +
  labs(
    title    = "Average Form D deal size by year, metro vs rural",
    subtitle = "2015–2024; mean incremental dollars per Form D filing",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC."
  ) +
  theme_im() +
  theme(legend.position = "bottom") -> x 


save_fig(
  p        = x,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/16_formD_yearly_avg_filing.jpeg",
  w        = 16.5,
  h        = 5.5
)

rm(x)

#--------------------------------------------------
# Figure 17: Form D Avg. Amount Raised per entity
#--------------------------------------------------

formd_data_US |> 
  select(year, stateorcountry, biz_id, COUNTY, incremental_amount) |> 
  mutate(COUNTY = stringr::str_pad(COUNTY, 5, pad = "0")) |>
  left_join(
    rucc |> select(FIPS, RUCC_2023),
    by = c("COUNTY" = "FIPS")
  ) |>
  mutate(
    rucc_type = ifelse(RUCC_2023 %in% c("1", "2", "3"), "metro", "rural")
  ) |>
  group_by(year, biz_id, rucc_type) |>
  summarise(
    raised = sum(incremental_amount, na.rm = TRUE),
    .groups = "drop"
  ) |>
  group_by(year, rucc_type) |>
  summarise(
    average_raised = mean(raised, na.rm = TRUE),
    .groups = "drop"
  ) |>
  ggplot(aes(x = year, y = average_raised,
             color = rucc_type, group = rucc_type)) +   # <- group here
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  scale_x_continuous(breaks = unique(formd_data_US$year)) +
  scale_y_continuous(labels = scales::label_comma()) +
  scale_color_manual(
    values = c(
      "metro" = "blue",
      "rural" = "purple"
    ),
    name = "RUCC type"
  ) +
  labs(
    title    = "Average Form D deal size by year, metro vs rural",
    subtitle = "2015–2024; average dollars raised per business",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC."
  ) +
  theme_im() +
  theme(legend.position = "bottom") -> x
  
  
  save_fig(
    p        = x,
    filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/17_formD_yearly_avg_raised_biz.jpeg",
    w        = 16.5,
    h        = 5.5
  )

rm(x)

formd_data_US |>
  select(COUNTY, incremental_amount) |>
  mutate(COUNTY = stringr::str_pad(COUNTY, 5, pad = "0")) |>
  left_join(rucc |> select(FIPS, RUCC_2023), by = c("COUNTY" = "FIPS")) |>
  mutate(
    RUCC_2023   = as.integer(RUCC_2023),
    rucc_type   = ifelse(RUCC_2023 %in% c(1, 2, 3), "metro", "rural")
  ) |>
  count(RUCC_2023, rucc_type)
