#--------------------------------------------------
# Figure 13: Form D deal size per average state (metro / metro-adjacent)
#--------------------------------------------------

# 13.1  State-level metro deal size
metro_base <- formd_complete |>
  filter(rucc_grp == "metro/metro-adjacent") |>
  group_by(year, st) |>
  summarise(
    incremental_dollars = sum(incremental_dollars, na.rm = TRUE),
    dealcount           = sum(dealcount,           na.rm = TRUE),
    .groups             = "drop"
  ) |>
  mutate(
    dealsize = ifelse(dealcount > 0,
                      incremental_dollars / dealcount,
                      NA_real_)
  )

# 13.2  Average-state values for the 4 regions

metro_nat <- metro_base |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "National avg.")

metro_nat_excl <- metro_base |>
  filter(!st %in% big3) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "National avg. (excl. CA, MA, NY)")

metro_midwest <- metro_base |>
  filter(st %in% midwest_excl_wi) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "Midwest avg. (excl. WI)")

metro_wi <- metro_base |>
  filter(st == wi_fips) |>
  group_by(year) |>
  summarise(
    value = mean(dealsize, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(series = "Wisconsin")

metro_all <- bind_rows(metro_nat, metro_nat_excl, metro_midwest, metro_wi)

# 13.3  Percent of national average

metro_all <- metro_all |>
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
  )

metro_nat_ref <- metro_all |>
  filter(series == "National avg.") |>
  select(year, nat_value = value)

metro_all <- metro_all |>
  left_join(metro_nat_ref, by = "year") |>
  mutate(pct_of_nat = value / nat_value)

# 13.4  Plot

vc_formd_dealsize_metro <- metro_all |>
  ggplot(aes(x = factor(year), y = value, fill = series)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65) +
  geom_text(
    aes(
      label = dplyr::case_when(
        series == "National avg." ~ NA_character_,
        TRUE                      ~ scales::percent(pct_of_nat, accuracy = 1.0)
      )
    ),
    position = position_dodge(width = 0.75),
    vjust    = -0.6,
    size     = 3,
    na.rm    = TRUE
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
  scale_y_continuous(labels = scales::label_comma()) +
  labs(
    title    = "Form D Deal Size per Average State, Metro & Metro-Adjacent Counties",
    subtitle = "2015–2024; average incremental dollars per Form D filing in the average metro/adjacent state",
    x        = "Year",
    y        = "Average deal size (USD)",
    caption  = "Source: SEC Form D; USDA RUCC. Percent labels show each group's average state relative to the national metro average."
  ) +
  theme_im()

vc_formd_dealsize_metro

save_fig(
  p        = vc_formd_dealsize_metro,
  filename = "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/figures/13_formD_dealsize_metro.jpeg",
  w        = 16.5,
  h        = 5.5
)