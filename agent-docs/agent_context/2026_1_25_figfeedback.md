# FIGURE FEEDBACK TO IMPLEMENT

1) Figure 1: Collapse to an 11 year average using 2015-2025. Should be able to do this using the current RDS that's being invoked
2) Figure 2: Collapse to a 11 year average using 2015-2025. Should be able to do this using the current RDS that's being invoked
3) Figure 3: Collapse to a 11 year average using 2015-2025. You will need to recalculate this by using the RDS data for figures 1 and 2, summing capital committed and dealcount seperately, and dividing to get the average deal size across the 10 years
4) Figure 8: Update for CORI's totals using the JSON file that we pulled from their map Git: Located in @./0_inputs/upstream/formd-interactive-map/src/data/formd_map.json
5) Figure 9: Update for CORI's totals using the JSON file that we pulled from their map Git: Located in @./0_inputs/upstream/formd-interactive-map/src/data/formd_map.json
4) Figure 11: Collapse to a 10 year average using 2016-2025. Drop the metro vs. Non-Metro delineation. Normalize to per 1 million labor force participants (not 100,000)
5) Figure 12: Collapse to a 10 year average using 2016-2025. Drop the metro vs. Non-Metro delineation.

# Figures we will not include in final report:
Figures 4,5,6,7,10,13,14. Prefix all dropped figure R scripts with "DROP_".

# New figures to add

Add a new figure that is Form D Deal Size ACROSS states, 10 year average using 2016-2025 data. No metro vs. Non-Metro delineation, which is what 13 and 14 do - and I don't want it for the "average" state - I want it grouped as in Figures 11 and 12 with no metro vs. Non-Metro delineation


# ANSWERS TO AGENT QUERIES

1) Where possible, use 2015 to 2025 inclusive. If that's not possible, use 2016 to 2025.
2) The x axis label in these situations should be a single category description such as "2015-2025 average", or whatever average you end up having to use per (1) above.
3) You can keep the same figure numbering/names.
4) For the JSON fields, I want all data at the county level. The relevant JSON feature field is 'name_co'. Recall I only want Wisconsin counties, which means I only want name_co that ends in "WI". For figure 8, use "total_amount_raised". For figure 9, want "num_funded_entities".

