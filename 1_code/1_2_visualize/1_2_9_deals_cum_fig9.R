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
