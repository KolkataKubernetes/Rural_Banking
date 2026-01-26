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

