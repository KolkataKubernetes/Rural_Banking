# Markdown construction: 2026_03_01_windicator_wi_bizgrowth.qmd

## Data Sources

The goal of this spec plan is to consolidate some of the patterns we have observed in @2026_02_08_sba_bfs_cbp.qmd and @bfs_explore.qmd and develop a few visuals in preparation for an agricultural economics/rural community development extension article. 

There are four main datasources. The first three you've already used in @2026_02_08_sba_bfs_cbp.qmd, I believe:

1) bfs: Business formation statistics.

2) cbp: County Business Pattern business statistics.1

3) participation: Contains state-level FIPS participation data, w

These data sources should already be familiar from other files we have already built (see file references above). We additionally need the following new data, which can be found in 

4) nes: non-employer statistics, which you pulled using an API call in the script @census_NES.r

## Tasks to be completed

1) First, update the Config chunk so that all four data sources are loaded, with pre-visual transformations completed for each visualization. You might need to update this as you go.

2) In chunks lollipop_bfs and lollipop_cbp, I want you to reproduce the lollipops we created in the bfs_lollipop_bizapp_rural and cbp_lollipop_bizapp_rural chunks of @2026_02_08_sba_bfs_cbp.qmd.

3) In lollipop_cbp_1mill, take lollipop_cbp and normalize per 1 million people using fips_participation.csv. You've done this before in @2026_02_08_sba_bfs_cbp.qmd.

4) In lollipop_nes, make a lollipop chart like we did for lollipop_cbp but using the NES data. In lollipop_nes_1mill, normalize per 1 million people. Remember in this case I want rural counties only! 

## General Guidance - A note on transparency and reproducibility

I really care about transparency and reproducibility. Add comments so I know what you did, and what transformed data frames are used for which chunks! 



