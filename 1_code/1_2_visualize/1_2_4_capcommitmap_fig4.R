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