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