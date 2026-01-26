
# 3B. Construct the 4-group average-state values for dealcount

cnt_nat <- formd_complete |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg.")

cnt_nat_excl <- formd_complete |>
  filter(!st %in% big3) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "National avg. (excl. CA, MA, NY)")

cnt_midwest <- formd_complete |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Midwest avg. (excl. WI)")

cnt_wi <- formd_complete |>
  filter(st == wi_fips) |>
  group_by(year, rucc_grp) |>
  summarise(value = mean(dealcount, na.rm = TRUE), .groups = "drop") |>
  mutate(group = "Wisconsin")

cnt_all <- bind_rows(cnt_nat, cnt_nat_excl, cnt_midwest, cnt_wi)

# 4B. Percent of national average (sum over RUCC)

series_levels <- c(
  "National avg.",
  "National avg. (excl. CA, MA, NY)",
  "Midwest avg. (excl. WI)",
  "Wisconsin"
)

cnt_all <- cnt_all |>
  mutate(
    series = factor(group, levels = series_levels)
  )

cnt_totals <- cnt_all |>
  group_by(year, series) |>
  summarise(
    region_total = sum(value, na.rm = TRUE),
    .groups      = "drop"
  )

cnt_nat_totals <- cnt_totals |>
  filter(series == "National avg.") |>
  rename(nat_total = region_total) |>
  select(year, nat_total)

cnt_all <- cnt_all |>
  left_join(cnt_totals,     by = c("year", "series")) |>
  left_join(cnt_nat_totals, by = "year") |>
  mutate(pct_of_nat = region_total / nat_total)

# 5B. Manual x-positions

cnt_years <- sort(unique(cnt_all$year))
cnt_year_index <- setNames(seq_along(cnt_years), cnt_years)

cnt_all <- cnt_all |>
  mutate(
    year_idx   = cnt_year_index[as.character(year)],
    series_idx = as.numeric(series),
    x_pos      = year_idx + (series_idx - 2.5) * 0.18
  )

cnt_label_df <- cnt_all |>
  group_by(year, year_idx, series, x_pos, pct_of_nat) |>
  summarise(
    total_value = sum(value, na.rm = TRUE),
    .groups     = "drop"
  )

cnt_x_breaks <- unique(cnt_all$year_idx)
cnt_x_labels <- names(cnt_year_index)[match(cnt_x_breaks, cnt_year_index)]

# 6B. Plot: deal count

vc_formd_dealcount <- ggplot(
  cnt_all,
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
    data = cnt_label_df,
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
    breaks = cnt_x_breaks,
    labels = cnt_x_labels
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
    title    = "Form D Deal Count per Average State, by Region and RUCC",
    subtitle = "2015–2024; bars show average number of Form D filings per state; pattern shows metro vs rural counties",
    x        = "Year",
    y        = "Average Form D filings per state",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to national average."
  ) +
  theme_im() +
  theme(legend.position = "bottom")

vc_formd_dealcount

save_fig(
  p        = vc_formd_dealcount,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/12_formD_dealcount_time.jpeg",
  w        = 16.5,
  h        = 5.5
)
