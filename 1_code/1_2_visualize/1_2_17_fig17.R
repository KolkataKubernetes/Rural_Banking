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