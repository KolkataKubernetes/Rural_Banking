# 01/29/2026: Figure Feedback to be implemented

## Table-setting Context

- For each file, update the output filepath to: "/Users/indermajumdar/Documents/Research/Rural Banking/2025_WI_report/2026_01_29_v2". For reasons we have previously documented, you won't be able to actually execute the code. Just update the filepath and I'll run the code to validate any outputs.
- Using the feedback below, I want you to create a new execplan that follows our incumbent format. I'd like you to include a section in the execplan that clearly breaks out, by figure the changes that will be made.
- I make reference below to a "per million population" normalization. To construct this, take the fips_paricipation.csv and divide Force by the Participation Rate to get the number of state residents. (Force/(Participation/100)). You'll then need to divide again to get a per million figure. If you think this is incorrect, feel free to push back and we can iterate within the execplan before finalizing and executing the execplan
- The fips_participation CSV does not contain 2025 data. I checked this link to make sure there was no 2025 data: https://www.bls.gov/lau/rdscnp16.htm. No need to look this up, but it's important to document in the execplan that we did check the BLS website for 2025 annual data and didn't find any. I'll have to note that in my email to Tessa as well. This means that when I ask you to divide by "per million population", you'll need to remove 2025 values from the series. Does this make sense?
- When making the execplan that spells out the correction for the "per million population" normalization, I'd like you to spec out whether it makes more sense to edit 1_0_1_wi_descriptives and change the data transformation process, or whether it makese more sense to just make adjustments in the visualization files.

## Figure 1
- Our label currently reads as a percent of national average. Instead, I'd like you to show the value/level for each series.
- Normalize to "per million population" per the instruction set above

## Figure 2
- Our label currently reads as a percent of national average. Instead, I'd like you to show the value/level for each series.
- Normalize to "per million population" per the instruction set above

## Figure 3
- Our label currently reads as a percent of national average. Instead, I'd like you to show the value/level for each series.

## Figure 8
- Normalize to "per million population" per the instruction set above

## Figure 9
- Label the year. Follow the verbiage that we used for other figures that use the upstream Form D JSON. We know it's since 2010, but don't know if it includes 2025 data etc.

## Figure 11
- Normalize to "per million population" per the instruction set above

## Figure 12
- Normalize to "per million population" per the instruction set above

## Figure 15
- Remove the categorization by RUCC type. Also transform into a pie chart


## Figure 18
- Our label currently reads as a percent of national average. Instead, I'd like you to show the value/level for each series.
