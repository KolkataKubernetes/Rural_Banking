vc_formd_vol <- ggplot(
  vol_all,
  aes(
    x       = x_pos,
    y       = value,
    fill    = series,      # region colors
    pattern = rucc_grp     # metro vs rural as pattern
  )
) +
  ggpattern::geom_col_pattern(
    color           = "grey30",
    pattern_density = 0.35,
    pattern_spacing = 0.02,
    pattern_colour  = "black"
  ) +
  # Percent-of-national label on top of each region bar
  geom_text(
    data = label_df,
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
    breaks = x_breaks,
    labels = x_labels
  ) +
  # --- region colors: same code as your previous items
  scale_fill_manual(
    values = c(
      "National avg."                    = "black",
      "National avg. (excl. CA, MA, NY)" = "grey60",
      "Midwest avg. (excl. WI)"          = "blue",
      "Wisconsin"                        = "#c5050c"
    ),
    name = NULL
  ) +
  # --- RUCC patterns: metro solid, rural striped
  scale_pattern_manual(
    values = c(
      "metro/metro-adjacent" = "none",
      "rural"                = "stripe"
    ),
    name = NULL
  ) +
  scale_y_continuous(labels = label_comma()) +
  labs(
    title    = "Incremental Form D Capital per Average State, by Region and RUCC",
    subtitle = "2015–2024; bars show average state incremental dollars; shading/pattern shows metro vs rural counties",
    x        = "Year",
    y        = "Average incremental dollars per state",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

vc_formd_vol

save_fig(
  p        = vc_formd_vol,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/10_incremental_formD_time.jpeg",
  w        = 16.5,
  h        = 5.5
)