library(sf)
library(tigris)
library(dplyr)
library(readr)
library(ggplot2)

counties <- counties(cb = TRUE, year = 2024) |>
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78")) |>
  st_transform(5070)

rucc <- read_csv('/Users/indermajumdar/Research/Rural_Banking/0_inputs/2023_RUCC.csv') |>
  mutate(
    GEOID = FIPS, 
    RUCC_2023 = factor(RUCC_2023,
                       levels = 1:9,
                       labels = c(
                         "1 Metro ≥1m",
                         "2 Metro 250k–1m",
                         "3 Metro <250k",
                         "4 Nonmetro urban ≥20k, adjacent",
                         "5 Nonmetro urban ≥20k, nonadjacent",
                         "6 Urban 2.5k–20k, adjacent",
                         "7 Urban 2.5k–20k, nonadjacent",
                         "8 Rural <2.5k, adjacent",
                         "9 Rural <2.5k, nonadjacent")
                       )
  )

map_data <- counties |>
  left_join(rucc, by = "GEOID")

ggplot(map_data) +
  geom_sf(aes(fill = RUCC_2023), color = NA) +
  scale_fill_brewer(
    palette = "YlOrRd",
    na.value = "grey90",
    name = "2023 RUCC"
  ) +
  theme_void()