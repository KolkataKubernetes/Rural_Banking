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