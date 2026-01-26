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
