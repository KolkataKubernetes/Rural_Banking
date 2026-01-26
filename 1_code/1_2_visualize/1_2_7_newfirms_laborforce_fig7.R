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