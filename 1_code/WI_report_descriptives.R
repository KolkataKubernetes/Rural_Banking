#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name: WI Small Business Finance Descriptives
# Current author:   Inder Majumdar
# Creation date:    December 3 2025
# Last updated:     December 3 2025
# Description: 
#///////////////////////////////////////////////////////////////////////////////

# CONFIG --------------------------------------------------------

library(tidyverse)
library(scales)
library(readxl)
library(ggrepel)
library(maps)
library(plotly)

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
formd_dir <- '/Users/indermajumdar/Downloads/form_d'

# Load Data --------------------------------------------------------

dealcount <- read_xlsx(countdir)
dealvol   <- read_xlsx(voldir)
participationdir <- read_csv('/Users/indermajumdar/Downloads/fips_participation.csv')
bds_fa <- read_csv('/Users/indermajumdar/Downloads/bds2023_st_fa.csv')

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

# --- Pitchbook data with IQR, TS

# 1) dealcount IQR by year (exclude CA)
count_iqr <- count_wide |>
  filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
  group_by(year) |>
  summarise(
    p25 = quantile(count, 0.25, na.rm = TRUE),
    p50 = quantile(count, 0.50, na.rm = TRUE),
    p75 = quantile(count, 0.75, na.rm = TRUE),
    .groups = "drop"
  )

# 2) dealvol IQR by year (exclude CA)
vol_iqr <- vol_wide |>
  filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
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
      filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
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
  mutate(year = as.numeric(year)) |>
  mutate(wi_percent = dealcount_wi/dealcount_national) # add WI percent

vol_ts_data <- vol_iqr |>
  left_join(
    vol_wide |>
      filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
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
  mutate(year = as.numeric(year)) |> 
  mutate(wi_percent = dealvol_wi/dealvol_national) # Add WI percent

# Barplots: Dealcount and Capital Committed  --------------------------------------------------

# --- Dealcount over time

count_ts_data |> 
  select(year, dealcount_national, dealcount_wi, wi_percent) |>
  ggplot(aes(x = factor(year))) +
  geom_col(aes(y = dealcount_national, fill = "National avg."),
           position = position_dodge(width = 0.7), width = 0.65) +
  geom_col(aes(y = dealcount_wi, fill = "Wisconsin"),
           position = position_dodge(width = 0.7), width = 0.65) +
  geom_text(
    aes(
      y     = dealcount_wi,
      label = scales::percent(wi_percent, accuracy = 0.1)
    ),
    position = position_dodge(width = 0.7),
    vjust = -0.6,
    size = 3
  ) +
  scale_fill_manual(values = c("Wisconsin" = "#c5050c", "National avg." = "grey60")) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Venture Capital Deal Count: Wisconsin vs National Average",
    subtitle = "2015-2024",
    x = "Year",
    y = "Number of deals",
    fill = NULL,
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California, New York, and Massachusetts omitted."
  ) +
  theme_im() -> vc_dealcount

save_fig(p = vc_dealcount, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/1_vc_dealcount.jpeg')



vol_ts_data |> 
  select(year, dealvol_national, dealvol_wi, wi_percent) |>
  ggplot(aes(x = factor(year))) +
  geom_col(aes(y = dealvol_national, fill = "National avg."),
           position = position_dodge(width = 0.7), width = 0.65) +
  geom_col(aes(y = dealvol_wi, fill = "Wisconsin"),
           position = position_dodge(width = 0.7), width = 0.65) +
  geom_text(
    aes(
      y     = dealvol_wi,
      label = scales::percent(wi_percent, accuracy = 0.1)
    ),
    position = position_dodge(width = 0.7),
    vjust = -0.6,
    size = 3
  ) +
  scale_fill_manual(values = c("Wisconsin" = "#c5050c", "National avg." = "grey60")) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title = "Venture Capital Capital Committed: Wisconsin vs National Average",
    subtitle = "2015-2024",
    x = "Year",
    y = "USD (million)",
    fill = NULL,
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. California, New York, and Massachusetts omitted."
  ) +
  theme_im() -> vc_cap_comitted

  save_fig(p = vc_cap_comitted, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/2_vc_cap_comitted.jpeg')

# Map: 2024 levels  --------------------------------------------------

vol_2024 <- vol_wide |>
  filter(year %in% c("2024")) |>
  filter(!(State %in% c('California','Massachusetts', 'New York'))) |>
  pivot_wider(names_from = year, values_from = count) |>
  rename(total = '2024')


map_df <- map_data("state") |>
  mutate(State = str_to_title(region)) 
  

map_level <- map_df |>
  left_join(vol_2024, by = "State")

p_map_level <- ggplot(map_level, aes(long, lat, group = group, fill = total)) +
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

p_map_level

save_fig(p = p_map_level, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/3_cap_committed_map.jpeg')


# Wisconsin: Capital Committed Per Deal, time series  --------------------------------------------------

vol_ts_data |>
  select(year, dealvol_wi, dealvol_national) |>
  left_join(count_ts_data |> select(year, dealcount_wi, dealcount_national), by = 'year') |>
  mutate(
    vol_per_deal_wi        = dealvol_wi / dealcount_wi,
    vol_per_deal_national  = dealvol_national / dealcount_national
  ) |>
  ggplot(aes(x = year)) +
  geom_line(aes(y = vol_per_deal_wi,       color = "Wisc."),    linewidth = 0.9) + 
  geom_line(aes(y = vol_per_deal_national, color = "Nat. Avg."), linewidth = 0.9) +
  scale_color_manual(
    values = c("Wisc." = "#b2182b", "Nat. Avg." = "grey40"),
    name   = NULL
  ) +
  scale_x_continuous(breaks = scales::pretty_breaks()) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title = "Average Capital Committed Per Deal, Wisconsin vs National Average",
    x = "Year",
    y = "USD (million)",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. National average excludes California, New York, and Massachusetts.."
  ) +
  theme_im() 

# Wisconsin: Capital Committed Per Deal, bar plot  --------------------------------------------------

vol_ts_data |>
  select(year, dealvol_wi, dealvol_national) |>
  left_join(
    count_ts_data |> select(year, dealcount_wi, dealcount_national),
    by = "year"
  ) |>
  mutate(
    vol_per_deal_wi       = dealvol_wi / dealcount_wi,
    vol_per_deal_national = dealvol_national / dealcount_national,
    vol_deal_pct = vol_per_deal_wi/vol_per_deal_national
  ) |>
  ggplot(aes(x = factor(year))) +
  geom_col(
    aes(y = vol_per_deal_national, fill = "National avg."),
    position = position_dodge(width = 0.7),
    width = 0.65
  ) +
  geom_col(
    aes(y = vol_per_deal_wi, fill = "Wisconsin"),
    position = position_dodge(width = 0.7),
    width = 0.65
  ) + 
  geom_text(
    aes(
      y     = 1,
      label = scales::percent(vol_deal_pct, accuracy = 0.1)
    ),
    position = position_dodge(width = 0.7),
    vjust = -0.6,
    size = 3
  ) +
  scale_fill_manual(
    values = c("Wisconsin" = "#c5050c", "National avg." = "grey60"),
    name   = NULL
  ) +
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title   = "Average Capital Committed Per Deal, Wisconsin vs National Average",
    subtitle = "2015–2024",
    x       = "Year",
    y       = "USD (million)",
    caption = "Source: Pitchbook Venture Capital Monitor Q3 2025. National average excludes California, New York, and Massachusetts."
  ) +
  theme_im() -> cap_per_count_barplot

save_fig(p = cap_per_count_barplot, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/4_cap_per_count_barplot.jpeg')



# Age 0 Businesses  --------------------------------------------------

## Each year's stats

bds_fa |>
  #filter(st == 55) |>
  filter(year > 2014) |>
  filter(fage == "a) 0") |> 
  filter(!(st %in% c("06", "36", "25"))) |>
  transmute(year, st, fage,firms = as.numeric(firms)) |>
  group_by(year) |>
  mutate(firms_pct = firms/sum(firms)) |>
  ungroup() |>
  arrange(year, desc(firms_pct)) |>
  mutate(
    group = case_when(
      st == "55" ~ "WI. Only",
      st %in% c("27", "19", "17", "26", "18") ~ "Midwest (excl. WI)",
      TRUE ~ "All Other States (excl. CA, MA, NY)"
    )
  ) |>
  group_by(year, group) |>
  reframe(avg_firms = mean(firms)) -> bds_fa_yearly_group


bds_fa_yearly_group |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_firms, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"           = "#c5050c",   # Badger red
      "Midwest (excl. WI)" = "grey50",
      "All Other States (excl. CA, MA, NY)"   = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Average Firms",
    title = "Business Age 0 Firm Births by Region"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> new_firms_barplot
  
  save_fig(p = new_firms_barplot, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/5_new_firms_barplot.jpeg')

# Age 0 Businesses, Participation Adjustment  --------------------------------------------------

bds_fa |>
  filter(year > 2014) |>
  filter(fage == "a) 0") |> 
  filter(!(st %in% c("06", "36", "25"))) |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  transmute(year, st, fage, firms = as.numeric(firms), Participation) |>
  mutate(adjusted_firms = firms*(Participation/100)) |>
  group_by(year) |>
  mutate(adjusted_firms_pct = adjusted_firms/sum(adjusted_firms)) |>
  ungroup() |>
  arrange(year, desc(adjusted_firms_pct)) |>
  mutate(
    group = case_when(
      st == "55" ~ "WI. Only",
      st %in% c("27", "19", "17", "26", "18") ~ "Midwest (excl. WI)",
      TRUE ~ "All Other States (excl. CA, MA, NY)"
    )
  ) |>
  group_by(year, group) |>
  reframe(avg_adjusted_firms = mean(adjusted_firms)) -> bds_fa_yearly_group_adjusted

bds_fa_yearly_group_adjusted |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_adjusted_firms, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"           = "#c5050c",   # Badger red
      "Midwest (excl. WI)" = "grey50",
      "All Other States (excl. CA, MA, NY)"   = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Average Firms",
    title = "Business Age 0 Firm Births by Region",
    subtitle = "Weighted By labor participation %"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> new_firms_barplot_weight_labor
  
  save_fig(p = new_firms_barplot_weight_labor, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/6_new_firms_barplot_weight_labor.jpeg')

# Age 0 Businesses, Active Labor Force   --------------------------------------------------

bds_fa |>
  filter(year > 2014) |>
  filter(fage == "a) 0") |> 
  filter(!(st %in% c("06", "36", "25"))) |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  transmute(year, st, fage, firms = as.numeric(firms), Force) |>
  mutate(adjusted_firms = firms/ Force) |>
  group_by(year) |>
  mutate(adjusted_firms_pct = adjusted_firms/sum(adjusted_firms)) |>
  ungroup() |>
  arrange(year, desc(adjusted_firms_pct)) |>
  mutate(
    group = case_when(
      st == "55" ~ "WI. Only",
      st %in% c("27", "19", "17", "26", "18") ~ "Midwest (excl. WI)",
      TRUE ~ "All Other States (excl. CA, MA, NY)"
    )
  ) |>
  group_by(year, group) |>
  reframe(avg_adjusted_firms = mean(adjusted_firms)) -> bds_fa_yearly_group_adjusted

bds_fa_yearly_group_adjusted |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_adjusted_firms, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"           = "#c5050c",   # Badger red
      "Midwest (excl. WI)" = "grey50",
      "All Other States (excl. CA, MA, NY)"   = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    x = "Year",
    y = "Average Firms",
    title = "Business Age 0 Firm Births by Region",
    subtitle = "Normalized for Labor Force Participation Size"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> new_firms_barplot_normalized_size
  
  save_fig(p = new_firms_barplot_normalized_size, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/7_new_firms_barplot_normalized_size.jpeg')


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
  select(entityname, stateorcountry, stateorcountrydescription, zipcode, COUNTY, entitytype, year, over100recipientflag, incremental_amount) |>
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

library(sf)
library(tigris)
library(dplyr)
library(ggplot2)
library(scales)

options(tigris_use_cache = TRUE)

wi_counties <- counties(state = "WI", cb = TRUE, year = 2023) |> 
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
# 1. group-year totals of incremental Form D dollars
#--------------------------------------------------

formd_group_year <- formd_data_US |>
  # COUNTY is 5-digit FIPS; extract state FIPS (first 2 digits)
  mutate(
    county_fips = str_pad(COUNTY, width = 5, pad = "0"),
    st          = substr(county_fips, 1, 2)
  ) |>
  group_by(year, st) |>
  summarise(
    incremental_dollars = sum(incremental_amount, na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  filter(!is.na(Force), Force > 0) |>
  mutate(
    adjusted_dollars = incremental_dollars / Force
  ) |>
  mutate(
    group = case_when(
      st == "55" ~ "WI. Only",
      st %in% c("27", "19", "17", "26", "18") ~ "Midwest (excl. WI)",  # MN, IA, IL, MI, IN
      TRUE ~ "All Other States (excl. CA, MA, NY)"
    )
  ) |>
  group_by(year, group) |>
  reframe(
    avg_adjusted_dollars = mean(adjusted_dollars, na.rm = TRUE),
    avg_incremental_dollars = mean(incremental_dollars)
  ) 



  

#--------------------------------------------------
# 4. Plot Bars
#--------------------------------------------------

formd_group_year |>
  group_by(year) |>
  mutate(
    nat_avg_dollars = avg_incremental_dollars[
      group == "All Other States (excl. CA, MA, NY)"
    ][1],
    pct_of_nat = avg_incremental_dollars / nat_avg_dollars
  ) |>
  ungroup() |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_incremental_dollars, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"                            = "#c5050c",   # Badger red
      "Midwest (excl. WI)"                  = "grey50",
      "All Other States (excl. CA, MA, NY)" = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(
    labels = label_comma(),
    name   = "Avg. incremental Form D dollars"
  ) +
  labs(
    x        = "Year",
    title    = "Form D Capital Raised by Region"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> incremental_formD_time
  
  save_fig(p = incremental_formD_time, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/10_incremental_formD_time.jpeg')

#--------------------------------------------------
# 5. Plot Bars - normalized for work force
#--------------------------------------------------

formd_group_year |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_adjusted_dollars, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"                        = "#c5050c",   # Badger red
      "Midwest (excl. WI)"              = "grey50",
      "All Other States (excl. CA, MA, NY)" = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(
    labels = label_comma(),
    name   = "Avg. incremental Form D dollars / labor force"
  ) +
  labs(
    x        = "Year",
    title    = "Form D Capital Raised by Region",
    subtitle = "Incremental dollars normalized by state labor force size"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> incremental_formD_time_normalized
  
  save_fig(p = incremental_formD_time_normalized, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/11_incremental_formD_time_normalized.jpeg')
  

# Form D Visualizations: Wisconsin vs. Nat, Midwest count avg. over time  --------------------------------------------------


#--------------------------------------------------
# 1. group-year totals of incremental Form D dollars
#--------------------------------------------------

formd_group_year_count <- formd_data_US |>
  # COUNTY is 5-digit FIPS; extract state FIPS (first 2 digits)
  mutate(
    county_fips = str_pad(COUNTY, width = 5, pad = "0"),
    st          = substr(county_fips, 1, 2)
  ) |>
  group_by(year, st) |>
  summarise(
    count = n(),
    .groups = "drop"
  ) |>
  left_join(participationdir, by = c("year", "st" = "FIPS")) |>
  filter(!is.na(Force), Force > 0) |>
  mutate(
    adjusted_count = count / Force
  ) |>
  mutate(
    group = case_when(
      st == "55" ~ "WI. Only",
      st %in% c("27", "19", "17", "26", "18") ~ "Midwest (excl. WI)",  # MN, IA, IL, MI, IN
      TRUE ~ "All Other States (excl. CA, MA, NY)"
    )
  ) |>
  group_by(year, group) |>
  reframe(
    avg_adjusted_count = mean(adjusted_count, na.rm = TRUE),
    avg_count = mean(count)
  ) 

#--------------------------------------------------
# 4. Plot Bars
#--------------------------------------------------

formd_group_year_count |>
  group_by(year) |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_count, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"                            = "#c5050c",   # Badger red
      "Midwest (excl. WI)"                  = "grey50",
      "All Other States (excl. CA, MA, NY)" = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(
    labels = label_comma(),
    name   = "Avg. Deal Count"
  ) +
  labs(
    x        = "Year",
    title    = "Form D Deal Count by Region"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> formD_dealcount_time_normalized
  
  save_fig(p = formD_dealcount_time_normalized, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/12_formD_dealcount_time_normalized.jpeg')
  

#--------------------------------------------------
# 6. Average deal size (incremental dollars per deal)
#    using group-level averages
#--------------------------------------------------

formd_group_year_dealsize <- formd_group_year |>
  select(year, group, avg_incremental_dollars) |>
  left_join(
    formd_group_year_count |>
      select(year, group, avg_count),
    by = c("year", "group")
  ) |>
  mutate(
    avg_deal_size = avg_incremental_dollars / avg_count
  )

formd_group_year_dealsize |>
  mutate(
    group = factor(
      group,
      levels = c("WI. Only", "Midwest (excl. WI)", "All Other States (excl. CA, MA, NY)")
    )
  ) |>
  ggplot(aes(x = factor(year), y = avg_deal_size, fill = group)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  scale_fill_manual(
    values = c(
      "WI. Only"                            = "#c5050c",   # Badger red
      "Midwest (excl. WI)"                  = "grey50",
      "All Other States (excl. CA, MA, NY)" = "grey75"
    ),
    name = NULL
  ) +
  scale_y_continuous(
    labels = label_comma(),
    name   = "Average deal size (incremental dollars per deal)"
  ) +
  labs(
    x        = "Year",
    title    = "Average Form D Deal Size by Region"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  ) +
  theme_im() -> formD_dealsize

save_fig(p = formD_dealsize, filename = '/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/13_formD_dealsize.jpeg')


#--------------------------------------------------
# 6. Sankey
#--------------------------------------------------

# Existing (from your code)
region_midwest <- c("Iowa", "Minnesota", "Wisconsin", "Illinois", "Indiana", "Michigan", "Ohio")
region_west    <- c("California", "Washington", "Oregon")
region_east    <- c("Connecticut", "Maine", "Massachusetts", "New Hampshire", "New Jersey",
                    "New York", "Pennsylvania", "Rhode Island", "Vermont")
region_southeast <- c("Alabama", "Arkansas", "Florida", "Georgia", "Kentucky",
                      "Louisiana", "Mississippi", "North Carolina", "South Carolina",
                      "Tennessee", "Virginia", "West Virginia")

# Additional sets for your new buckets
pnw_states      <- c("Washington", "Oregon")
southwest_states <- c("Arizona", "New Mexico", "Nevada", "Utah", "Colorado")
south_states     <- c("Texas", "Oklahoma")  # everything not caught by others will default to "South" anyway

assign_bucket <- function(state, region_midwest, region_east, region_southeast,
                          region_west, pnw_states, southwest_states, south_states) {
  case_when(
    state == "California"    ~ "CA",
    state == "New York"      ~ "NY",
    state == "Massachusetts" ~ "MA",
    state %in% region_midwest         ~ "Midwest",
    state %in% region_east            ~ "Northeast",
    state %in% region_southeast       ~ "Southeast",
    state %in% pnw_states             ~ "PNW",
    state %in% southwest_states       ~ "Southwest",
    state %in% region_west            ~ "West",
    state %in% south_states           ~ "South",
    TRUE                              ~ "South"   # catch-all for leftovers
  )
}

vol_avg_10yr <- vol_wide |>
  # your definition of 10-year: everything except 2025
  filter(year != "2025") |>
  group_by(State) |>
  summarise(mean_vol = mean(count, na.rm = TRUE), .groups = "drop") |>
  mutate(
    Country = "USA",
    bucket  = assign_bucket(
      State,
      region_midwest, region_east, region_southeast,
      region_west, pnw_states, southwest_states, south_states
    )
  )

# USA -> bucket flows
usa_bucket_10yr <- vol_avg_10yr |>
  group_by(bucket) |>
  summarise(
    Country   = "USA",
    total_vol = sum(mean_vol, na.rm = TRUE),
    .groups   = "drop"
  ) |>
  transmute(from = Country, to = bucket, value = total_vol)

# Midwest -> WI vs Rest of Midwest
midwest_detail_10yr <- vol_avg_10yr |>
  filter(bucket == "Midwest") |>
  mutate(
    from = "Midwest",
    to   = if_else(State == "Wisconsin", "Wisconsin", "Rest of Midwest")
  ) |>
  group_by(from, to) |>
  summarise(value = sum(mean_vol, na.rm = TRUE), .groups = "drop")

# Combine links
sankeydata_10yr <- bind_rows(usa_bucket_10yr, midwest_detail_10yr)

# Nodes and IDs
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
      text = "VC Flows: 10-year average (USD millions)<br><sup>USA → Regions (with Midwest split)</sup>"
    )
  )

# ----- 2024 sankey data (new structure) -------------------------------------

vol_avg_2024 <- vol_wide |>
  filter(year == "2024") |>
  group_by(State) |>
  summarise(mean_vol = mean(count, na.rm = TRUE), .groups = "drop") |>
  mutate(
    Country = "USA",
    bucket  = assign_bucket(
      State,
      region_midwest, region_east, region_southeast,
      region_west, pnw_states, southwest_states, south_states
    )
  )

usa_bucket_2024 <- vol_avg_2024 |>
  group_by(bucket) |>
  summarise(
    Country   = "USA",
    total_vol = sum(mean_vol, na.rm = TRUE),
    .groups   = "drop"
  ) |>
  transmute(from = Country, to = bucket, value = total_vol)

midwest_detail_2024 <- vol_avg_2024 |>
  filter(bucket == "Midwest") |>
  mutate(
    from = "Midwest",
    to   = if_else(State == "Wisconsin", "Wisconsin", "Rest of Midwest")
  ) |>
  group_by(from, to) |>
  summarise(value = sum(mean_vol, na.rm = TRUE), .groups = "drop")

sankeydata_2024 <- bind_rows(usa_bucket_2024, midwest_detail_2024)

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
      text = "VC Flows: 2024 (USD millions)<br><sup>USA → Regions (with Midwest split)</sup>"
    )
  )

outdir <- "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures"

# Ensure directory exists (optional)
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# Save 10-year Sankey
htmlwidgets::saveWidget(
  p_sankey_10yr,
  file = file.path(outdir, "vc_sankey_10yr_vol.html"),
  selfcontained = TRUE
)

# Save 2024 Sankey
htmlwidgets::saveWidget(
  p_sankey_2024,
  file = file.path(outdir, "vc_sankey_2024_vol.html"),
  selfcontained = TRUE
)

