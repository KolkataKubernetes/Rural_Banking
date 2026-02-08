# Decomposing Wisconsin's Rural vs. Urban Business Formation Statistics

- In @1_code/1_2_visualize/scratch/bfs_explore.qmd, we explored the Business Formation Statistics. 
- This new quarto document will replicate some of those findings but also pull new data in from the county business patterns to determine sectors that are driving growth in this sector.
- I would also like to pull in SBA data to figure out how sensitive business formation is to changes in County Business Patterns.
- All changes should be made in relevant code chunks in 1_code/workbooks/2026_02_08_sba_bfs_cbp.qmd.
- I forgot to provide text descriptions of NAICS codes. Included in the CBP data is a set of NAICS codes for each row - details on how this file was created can be found in @1_code/1_0_ingest/census_CBP. What I'd like you to do is match the two digit codes against the CSV file @0_inputs/naics_2digit_sectors_2007_2012_2017.csv.

# High level goals:

## Review the patterns found in @1_code/1_2_visualize/scratch/bfs_explore.qmd

- First, I just want to replicate the first two graphs/charts in Business Formation Statistics Descriptives. Specifically, the "Business Applications by Category (Average State)" and "Business Applications by Category (Average State)" - rural only graphs. (Chunks: bfs_lollipop_bizapp_all, bfs_lollipop_bizapp_rural)
- Then, I want to see if we can replicate the two descriptives above using the CBP data (@2_processed_data/CBP_all.rds). This should be done by summing establishment counts (ESTAB), and splitting out rurality using the "rurality" column (Chunks: cbp_ollipop_bizapp_all, ollipop_bizapp_rural)


## What sectors are contributing most to Wisconsin's change in business dynamics? 
- I would then like an interactive pie chart that takes Wisconsin's CBP data, and does a pie chart of establishments by two-digit NAICS code. The pie chart should be the sum of establishments in the state from 2005 to 2024, matching the time range of the BFS data.

## Section contribution analysis

## Do SBA Loan Data predict County Business Patterns?
