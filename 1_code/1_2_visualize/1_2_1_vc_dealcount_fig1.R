
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