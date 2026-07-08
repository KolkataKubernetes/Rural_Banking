Data sources:

## Population Normalizations

- Use BLS data to get total eligible workforce by county - and then adjust for the state labor participation rate to get an estimate of the total workforce.

## Lending section

FDIC Call Report data are used for lending institution descriptives

Community Reinvestment Act data to identify lending activity at the county level. CRA data includes information on the number of loans and amount issued, categorized into three size buckets: <$100,000, $100,000 - $250,000, $250,000 - $1 MM.

Credit union data comes from NCUA Call Reports, which are effectively an analog of the FDIC call report data.

We pull CDFI institution characteristics and lending activity from annual institution-level (ILR) and transaction-level (TLR) disclosures made public by the US Department of XX.

## Equity section

Venture Capital Activity: We use data from the Pitchbook-NVCA Venture Monitor. Both the report and associated data are released every quarter, and includes data on venture capital fundraising activities aggregated to the state-year level. [CONFIRM]: Pitchbook collects venture capital data from SEC Form D releases, and also solicits deal information from venture capital firms across the US. While the report is publically available, the aggregated state data is only available to paid subscribers. 

Private Equity Activity: Yearly report provided by Pitchbook. Details the amount raised and number of deals by US region. We calculate a national average by averaging each metric across regions. The only region we evaluate individually is the Great Lakes (IL, IN, MI, MN, OH, WI)


## Figure Descriptions

Figure 1: Figure 1 is calculated using FDIC institution and branch records (Summary of Deposits). For a given year, values in the institution series are the total unique count of institutions operating at least one branch in Wisconsin, while the "Branches" series shows the total count of physical branch locations in the state. Institutions are identified by institution certificate number and branchesa are identified by individual office records.

Figure 2, 2b: Figures 2 and 2b were calculated using the unique institutions and branch identifiers mentioned in the description for figure 1.  Dividing the annual count of physical branches by the number of unique banking institutions yields the average number of branches operated per institution in the state. The numbers in figure 2 are the mean and median number of branches per banking institutions in Wisconsin each year, while the bars in figure 2b are created by grouping institutions by total branch count.

Figure 3: Figure 3 is calculated using data from the 2023 Community Reinvestment Act (CRA) public data release. For each Wisconsin county, the number of bank branches was divided by county population and scaled to a per-10,000 resident rate. Population numbers were derived by ____ . 


Figure 4 [NO CODE]: Figure 4 is calculated using the FDIC Call report data (highlight if this is right). Tracts are defined as "served" if at least one bank branch is within 5 miles of the census tract centroid, or are otherwise categorized as "Lending Desert".

Figure 5 [NO CODE]: Skipping this. I'm not sure how the distinction is made between "underserved" and "served" census tracts.

Figure 6: Figure 6 is calculated using lending activity in 2023 that was disclosed as part of the Community Reinvestment Act (CRA) data public data release. The data release includes loan counts and total lending volumes, disaggregated into three size cateogries: Under $100K, $100-250K, and $250K-$1 M. The columns are calculated for Wisconsin counties only. The '# of loans' column was calculated by summing the count of loans in 2023 for each category. the '% of loans' column was calculated by dividing the count of loans in that category by the total count of loans in Wisconsin issued in 2023. Similarly, the 'Volume' and '% of Volume' columns were calculating by summing the number of dollars issued for each loan category and dividing by the total dollars issued that year. The 'Avg. Size' column is calculated for each category by dividing the total volume by the total number of loans.

Figure 8: Figure 8 is calculated using the CRA data for each year. The annual count of CRA loans in each size bucket (Under $100K, $100-250K, and $250K-$1 M) is indexed to its year-2000 value, with the value for the year 2000 set to 100. The figure plots yearly growth in loan originations relative to the indexed year-2000 value.

Figure 9: Figure 9 is calculated using the CRA data for each year. The annual dollar value of CRA loans in each size bucket (Under $100K, $100-250K, and $250K-$1 M) is indexed to its year-2000 value, with the value for the year 2000 set to 100. 

### Credit Union Figures

Figure CU-01 [NO CODE, ASK CHARLIE]: Figure CU-01 is calculated using NCUA call report and branch records. The location of each credit union branch as of 2023 is plotted in the U.S..

Figure CU-03: Figure CU-03 is calculated using NCUA call report branch record data. The red bar plot series plots the annual count of unique credit union institutions operating at least one branch in Wisconsin, while the blue bar plot calculates the total number of credit union branches in the state. 

Figure CU-06: Figure CU-06 is calculated using NCUA call report branch record data. The blue line plot represents credit union lending activity as a share of total credit union assets in Wisconsin over time: For all credit union institutions operating at least one branch in the state, the total volume of commercial loans outstanding was divided by total assets each year to express commercial lending as a share of assets at the state level.

Figure CU-11: Figure CU-11 is calculated using NCUA call report branch record data. The red line plot represents the count of loans per 10,000 residents: For each year, the total count of loans was scaled to a per-10,000 resident rate following the same procedure detailed in the above description for Figure 3. The blue bar plot represents a per capita measure of loan volumes: For all credit union institutions with at least one branch in the state, the total volume of commercial loans outstanding was divided by the population in Wisconsin that year.

Figure CU-10: Figure CU-10 is calculated using NCUA call report branch record data. The blue bar plot represents the average commercial loan size issued by creid unions with at least one branch in Wisconsin: For each year, the total volume of loans issued was divided by the count of loans statewide.

### CDFI

Figure CDFI-1: Figure CDFI-1 is calculated using CDFI Institution Level Release (ILR) data and Zip code to county crosswalks issued by the department of Housing and Urban Development (HUD). We assign the zip code of each CDFI listed in the ILR to a county using the HUD zip code to county crosswalk, and then calculate the number count of unique CDFIs in each county using an organization identfier provided in the ILR. 

Figure CDFI-2: Figure CDFI-2 is calculated using the 2022 CDFI Transaction Level Release (TLR) data along with zip code to county crosswalks issued by the department of Housing and Urban Development (HUD). The TLR data records individual lending and investment transactions made by CDFIs. The left panel in CDFI-2 is calculated by counting the total number of CDFIs that have made at least one transaction in a given county. The right panel is calculated by summing the total volume of loans and investments made by CDFIs in that year.

### Venture Capital Figures

Figure 2 (VC): Figure VC-2 is calculated using the Pitchbook Venture Capital Monitor Q4 2025 data release. For each year, we calculate the total volume of venture capital dollars invested ("Capital committed") by U.S. region: each line plot represents a different set of U.S. states as detailed in the legend.

Figure 3 (VC): Figure VC-3 is calculated using the Pitchbook Venture Capital Monitor Q4 2025 data release. For each state, we create a measure of deal count by summing the total number of venture capital deals announced between 2015 and 2024. The bar charts illustrate the top 10 states by deal count, with the Wisconsin bar plot highlighted in red.

Figure 4 (VC): Figure VC-4 is calculated using the Pitchbook Venture Capital Monitor Q4 2025 data release. For each state, capital committed values are averaged for the years 2015-2024 and then summed to create regional averages. 

Figure 1 (VC): Figure VC-1 is calculated using the Pitchbook Venture Capital Monitor Q4 2025 data release. For each state, total capital committed is calculated across the years 2015-2024. Deal counts and deal value are both indexed to their year-2019 values, with the value for the year 2019 set to 100. The figure plots yearly growth in Deal count and Deal value both Nationally and for the Great Lakes region (IL, IN, MI, MN, OH, WI).


### Private Equity

Figure 0 (PE): Figure PE-0 is calculated using the Pitchbook 2025 Annual Private Equity Report and 2025 Annual US Private Equity Middle Market Report data releases. The Private Equity data releases provide measures of deal count and total deal value aggregated by U.S. region.

### Appendix

Figure 2c: Figure 2C is calculated using FDIC institution and branch records (Summary of Deposits). Restricting the sample to commercial banks headquartered in Wisconsin, we calculate the total assets for each bank in the sample in 2024. The bar charts illustrate the top 5 Wisconsin headquartered by total assets. 

Figure 2d: Figure 2C is calculated using FDIC institution and branch records (Summary of Deposits). We calculate the total number of branches in Wisconsin for each bank using FDIC data for 2024. The bar chart illustrates the top 10 banks by the total number of Wisconsin branches in 2024.

Lender access: Need more information to write this.

Figure 4: Figure 4 is calculated using data from the Community Reinvestment Act (CRA) public data release. For each county, we subtracted the per-10,000-resident branch rate in 2009 from the corresponding rate in 2023 to measure the net change in CRA-recognized branch density over the fourteen-year period.

Figure 4-VC: Figure 4-VC is calculated using the Pitchbook Venture Capital Monitor Q4 2025 data release. For each state, we calculate a measure of average deal size by dividing the total VC deal volume by total VC deal count between 2015 and 2024. The bar chart illustrates the top 10 states by deal size, and includes Wisconsin in red for reference. The number above the Wisconsin bar plot indicates Wisconsin's rank relative to the top 10 states.

#### Appendix A.2.

Figure 10: Figure 10 is calculated using the CRA data for each year from 2000 through 2023. For each year, we sum the total dollar volume of CRA-reported small business loans in Wisconsin in the under-$100,000 size bucket and divide that total by the corresponding number of under-$100,000 loans. The figure plots this statewide annual average loan size in dollars over time.

#### Appendix A.3.

Figure CU-04: Figure CU-04 is calculated using NCUA branch record data. For each Wisconsin county, we scale the number of credit union branches by county population to a per-10,000-resident rate using NCUA branch records, and map the resulting density at the county level.

Figure CU-04: Figure CU-04 is calculated using NCUA branch record data. We scale and map the number of credit unions headquartered in each county to a per-10,000-county resident rate.

#### Appendix A.4.

Figure 2 is calculated using the Pitchbook 2025 Annual Private Equity Report and 2025 Annual US Private Equity Middle Market Report data releases. For each year, we measure the Great Lakes region’s share of U.S. private equity activity separately for overall private equity and middle-market private equity. The figure reports these annual shares for two underlying metrics, deal count and deal value, so that each series shows the fraction of total U.S. activity attributable to the Great Lakes region in a given year. The figure therefore plots the Great Lakes share of national private equity activity over time, with separate panels for deal count and deal value and separate series for overall versus middle-market private equity.



## General notes:

Figure 3: Is branch location really in the CRA data?

No code for the following figures:
Figure 4
Figure 5
Figure 7

Figure 6 in this document was previously titled "Figure 6" in prior drafts. The title has been updated due to changes in figure order.

Figures 1 and 2 need specific column references in the call report data that are

I want to make sure that CRA data is released in annual vintages. Will 



### Example: Figure 1 is calculated using data on employer and nonemployer firms from the Census’ 2019 NES-D series on employer and
nonemployer firms. The numbers in this figure are the sum of total classifiable employer and nonemployer firms owned by minority and nonminority owners. The Census classifies nonminority as anyone who identifies as non-Hispanic white and minority as any person who does not identify as being non-Hispanic white (U.S. Census Bureau, 2019d). 

Questions that require further exploration: 
Why do we need both call report data AND the CRA data?
Why does figure 3 in the report use 2023 data, when we have 2024 call report data available?



