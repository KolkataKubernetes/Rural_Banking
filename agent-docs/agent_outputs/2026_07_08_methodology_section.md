## M.1 Data Sources

This section summarizes the data sources and transformations used in the current report draft. The language below is based on the latest Word draft, the staged figure scripts, and the exploratory workbooks currently stored in this repository.

### Population Normalizations

Several figures compare places of very different size, so raw counts are converted to population-scaled measures where appropriate. For state-year figures, the codebase uses participation-based population estimates constructed from `0_inputs/CORI/fips_participation.csv`. For each state and year, estimated population is calculated as the labor force divided by the labor-force participation rate. This denominator is used for the venture capital figures, the bank lending frequency and lending volume time series, and the peer-state CDFI comparisons.

County-level figures use county-specific denominators. The bank and credit union county maps use reviewed county population audit files derived from Census population estimates for the relevant year. County-level CDFI figures use the county population estimates stored in `labor_force_county.rds`, which combine LAUS county labor-force data with the state participation rate to back out county population. Depending on the figure, these denominators are expressed as branches or loans per 10,000 residents, loan counts per 100,000 or 1 million residents, venture activity per 1 million residents, or lending dollars per resident.

### Lending

The lending section draws on several distinct data sources because no single public dataset captures bank structure, branch geography, and small business loan originations at the same level of detail.

For banks, institution counts, branch counts, and branch geography are calculated from the FDIC Summary of Deposits. These records identify individual branch offices and the chartered institutions that operate them, which makes them well suited for measuring consolidation, branch density, and the location of headquarters. In the report-facing bank figure set, these data are used to count institutions, branches, branches per institution, branches per resident, and headquarters by county.

To measure small business lending activity, we use the annual public Community Reinvestment Act (CRA) aggregate releases. These files report loan counts and dollar volumes by geography and loan-size category, which are not available from the FDIC branch files. The report focuses on the three CRA size buckets below $1 million: under $100,000, $100,000-$250,000, and $250,000-$1 million. The code harmonizes multiple CRA release formats across time, including pipe-delimited early files, CSV releases, and fixed-width annual aggregate files, so that counts and dollar volumes are measured consistently from 2000 through 2023. For the earliest years, CRA volume fields reported in thousands are converted back to dollar values in the harmonized series.

Credit union figures are built from NCUA branch records and NCUA call-report financial statement files. The branch records are used to identify the location of Wisconsin credit union offices and headquarters, while the financial statement files provide aggregate commercial loan counts, commercial loan balances, and total assets. Unlike the CRA bank data, the staged NCUA files do not provide a comparable public breakdown of commercial lending by loan-size bucket. As a result, the credit union section focuses on aggregate commercial lending, commercial lending as a share of assets, average loan size, and branch geography rather than on size-specific small business loan originations.

CDFI figures rely on both institution-level (ILR) and transaction-level (TLR) public releases. The ILR is used to identify the county footprint of reporting CDFIs through a ZIP-to-county crosswalk, while the TLR is used for lending activity, active-lender counts, and county lending totals. The current harmonized TLR workflow preserves business-lending flags, county allocations, and multiple year fields, but the public releases still leave some timing limitations unresolved. In particular, `2016` is absent from the comparable series and the `2017` timing remains sensitive to how reporting year is assigned. For that reason, pooled recent county summaries and broad peer-state comparisons are more stable than a single-year interpretation of the `2016-2017` transition.

Taken together, these lending datasets serve different purposes. FDIC and NCUA files describe the structure and geography of financial institutions, while CRA and CDFI transaction files describe the flow of credit.

### Equity

The venture capital section uses the PitchBook-NVCA Venture Monitor state summary tables staged locally in `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx` and `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`. These files provide annual state-level deal counts and capital committed. In the current figure workflow, state-year venture totals are joined to the participation-based population estimates described above. Multi-year comparisons are then constructed by summing deal counts, capital committed, and annual population over the full 2015-2024 window before calculating per-capita rates. Average deal size is measured as total capital committed divided by total deal count over the same comparison window. PitchBook compiles these data from regulatory filings, investor disclosures, press releases, company submissions, and related market reporting; in this report, we use the published state summary tables rather than raw firm-level venture transactions.

The private equity section uses two complementary sources because the staged private equity inputs do not provide a Wisconsin-specific state-year deal flow series comparable to the venture capital files. Regional private equity trend figures are calculated from PitchBook's annual regional private equity tables, with the Great Lakes region used as the most relevant benchmark for Wisconsin. Those figures compare Great Lakes deal counts, deal values, and the Great Lakes share of overall and middle-market U.S. private equity activity from 2019 through 2025. State-level private equity exposure figures are drawn instead from the PE Risk Index Data Sheet, which provides cross-sectional measures such as the share of state pension assets invested in private equity and population exposure to concentrated PE ownership. As a result, the private equity section combines regional deal-flow measures with state exposure indicators rather than a Wisconsin-only private equity deal-count series.

## M.2 Figure Descriptions

### Banking and Credit

**Figure 1.** Figure 1 is calculated using FDIC Summary of Deposits records for Wisconsin. For each year, the institution series counts unique banking institutions operating at least one Wisconsin branch, while the branch series counts the total number of Wisconsin branch office records. In the report-facing version of the figure, the institution counts are restricted to the commercial bank subset used in the current script.

**Figure 2.** Figure 2 is calculated from the same FDIC branch records used in Figure 1. For each year, branches are first counted within each institution, and the figure then reports the statewide mean and median number of branches per institution.

**Figure 2b.** Figure 2b is also calculated from FDIC Summary of Deposits records. Using the 2024 Wisconsin branch snapshot, each institution is grouped by its total number of branches, and the bars report the number of institutions that fall into each branch-count category.

**Figure 3.** Figure 3 is calculated using 2023 FDIC Summary of Deposits branch records and reviewed 2023 county population estimates. For each Wisconsin county, we count all bank branch office records, divide that count by county population, and multiply by 10,000 to express branch density as branches per 10,000 residents. The figure is therefore a county-level snapshot of bank branch availability in 2023 rather than a CRA-based lending measure.

**Figure 4.** Figure 4 maps tract-level access to bank branches as of 2023. Census tracts are classified as served or as lending deserts according to whether at least one bank branch falls within the specified radius of the tract centroid. The report discusses both 5-mile and 10-mile thresholds to show how branch access changes when a broader travel radius is allowed.

**Figure 5.** Figure 5 extends the Figure 4 access concept by introducing a three-category classification. Tracts are classified as not served, underserved, or served depending on both branch proximity and the relative depth of nearby branch access. The figure is intended to distinguish places with no nearby branch presence from places that have only limited access.

**Figure 7.** Figure 7 is calculated from the 2023 CRA public aggregate release. For Wisconsin, total loan counts and total dollar volume are summed separately within each CRA loan-size bucket: under $100,000, $100,000-$250,000, and $250,000-$1 million. The table then reports each bucket's share of statewide loan count, share of statewide loan volume, and average loan size, where average loan size is calculated as total dollar volume divided by total number of loans in that bucket.

**Figure 8.** Figure 8 is calculated from the annual CRA public aggregate releases for 2000 through 2023. For each year and each loan-size bucket, the total number of Wisconsin loans is divided by the annual Wisconsin population estimate and scaled to loans per 10,000 residents. Each per-capita series is then indexed to its year-2000 value, with 2000 set equal to 100.

**Figure 9.** Figure 9 is constructed in parallel to Figure 8, but uses lending volume rather than loan count. For each year and size bucket, total Wisconsin CRA loan volume is divided by annual population and scaled to dollars per 10,000 residents, after which each series is indexed to its year-2000 value.

**Figure CU-03.** Figure CU-03 is calculated using NCUA branch records. For each year, the figure counts unique credit union institutions with a Wisconsin main office and the total number of Wisconsin credit union branches, showing how institutional consolidation differs from the evolution of the branch network.

**Figure CU-06.** Figure CU-06 is calculated from NCUA financial statement files. For Wisconsin credit unions, total commercial loans outstanding are divided by total assets in each year to express commercial lending as a share of assets.

**Figure CU-10.** Figure CU-10 is calculated using NCUA financial statement data for Wisconsin credit unions. In each year, the total commercial loan balance is divided by the total number of commercial loans to measure average loan size.

**Figure CU-11.** Figure CU-11 combines loan balances, loan counts, and annual Wisconsin population totals for Wisconsin credit unions. The bar series reports commercial lending dollars per resident, while the line series reports the number of commercial loans per 10,000 residents. Read together with Figure CU-10, the figure shows whether growth in credit union lending reflects more loans, larger loans, or both.

### CDFIs

**Figure CDFI-1.** Figure CDFI-1 is calculated using the historical CDFI institution-level release (ILR) and the HUD ZIP-to-county crosswalk. Each reporting organization's ZIP code is assigned to the Wisconsin county with the highest crosswalk allocation weight, and the figure then counts unique reporting organizations by county. The resulting map describes the county footprint of Wisconsin-based CDFIs observed in the public ILR rather than annual lending volume.

**Figure CDFI-2.** Figure CDFI-2 is calculated using the 2022 CDFI transaction-level release (TLR) after harmonization to county geography. For each Wisconsin county, the left panel counts the number of distinct reporting CDFIs making at least one business loan in that county, and the right panel sums county-allocated business lending volume. County totals are based on harmonized county FIPS assignments and county allocation weights in the TLR workflow, not on a ZIP-to-county crosswalk.

### Venture Capital

**Figure VC-1.** Figure VC-1 is calculated using the PitchBook-NVCA Venture Monitor state summary tables for 2015 through 2024. For each state, total capital committed over the period is divided by the sum of annual population over the same period and then scaled to dollars per 1 million residents. California, New York, Massachusetts, and Delaware are excluded from the displayed map because their values are extreme relative to the remaining states.

**Figure VC-2.** Figure VC-2 plots annual venture capital committed per 1 million residents from 2015 through 2024 for Wisconsin and comparison groups. In each year, capital committed is divided by annual population and then plotted as a population-scaled time series.

**Figure VC-3.** Figure VC-3 is calculated by summing venture deal counts for each state across 2015 through 2024 and dividing those totals by the sum of annual population over the same period. The bars show the top 10 states by venture deals per 1 million residents, with Wisconsin included and highlighted for reference.

**Figure VC-4.** Figure VC-4 measures average venture deal size by state over 2015 through 2024. For each state, total capital committed over the period is divided by total deal count over the period, and the resulting values are used to rank the top states, with Wisconsin highlighted for comparison.

### Private Equity

**Figure 0 (PE).** Figure 0 is calculated using PitchBook regional private equity tables for 2019 through 2025. For both the Great Lakes region and the United States as a whole, total deal count and total deal value are indexed to their 2019 values so that both series equal 100 in 2019. The figure therefore compares the relative growth of Great Lakes private equity activity with national private equity activity over time.

**Appendix A.4, Figure 2.** Appendix Figure 2 uses the same PitchBook regional private equity tables to calculate the Great Lakes share of U.S. private equity activity. The figure reports this share separately for deal count and deal value, and separately for overall private equity and middle-market private equity, for each year from 2019 through 2025.

### Appendix

**Appendix A.1, Figure 2c.** Appendix Figure 2c is calculated using 2024 FDIC Summary of Deposits records. We identify banks headquartered in Wisconsin using main-office records, restrict the ranking to institutions that operate at least one Wisconsin branch, and then rank those banks by total assets. The figure displays the top 5 Wisconsin-headquartered banks by total assets in 2024.

**Appendix A.1, Figure 2d.** Appendix Figure 2d is calculated using 2024 FDIC Summary of Deposits branch records for Wisconsin. For each institution, we count the total number of branch offices located in Wisconsin and rank banks by that branch count. The current figure displays the top 5 banks by number of Wisconsin branches in 2024.

**Appendix A.1, Figure 4.** Appendix Figure 4 measures the change in county-level bank branches per 10,000 residents between 2009 and 2023. For each county, the branch-density value in 2009 is subtracted from the corresponding value in 2023 to show the net change in branch availability over the post-recession period.

**Appendix A.1, Figure 6.** Appendix Figure 6 is calculated using FDIC Summary of Deposits records for 2024. Headquarters are identified as main-office records, and the figure counts the number of bank headquarters located in each Wisconsin county.

**Appendix A.2, Figure 10.** Appendix Figure 10 is calculated from the CRA annual aggregate files for 2000 through 2023. For each year, total Wisconsin lending volume in the under-$100,000 bucket is divided by the total number of under-$100,000 loans to measure the average size of small loans in that category.

**Appendix A.3, Figure CU-04.** Appendix Figure CU-04 is calculated using 2023 NCUA branch records and reviewed county population estimates. For each county, the total number of credit union branches is divided by county population and scaled to branches per 10,000 residents.

**Appendix A.3, Figure CU-05.** Appendix Figure CU-05 is calculated using 2023 NCUA branch records and reviewed county population estimates. The figure counts credit union headquarters by county and scales those counts by county population to show the number of headquartered institutions per 10,000 residents.
