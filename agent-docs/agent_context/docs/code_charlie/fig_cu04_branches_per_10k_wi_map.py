#!/usr/bin/env python3
"""
Figure CU-4: Credit Union Branches per 10,000 Residents by WI County (2023)
============================================================================
Choropleth map of CU branch density across Wisconsin counties.

Data Source: NCUA Call Report 2023 & Census Bureau population.
Output:      fig_cu04_branches_per_10k_wi_map.png
"""

import os, warnings
warnings.filterwarnings('ignore')
import pandas as pd
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import geopandas as gpd

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FIG_DIR  = os.path.join(DATA_DIR, 'figure_scripts', 'output')
os.makedirs(FIG_DIR, exist_ok=True)

# Load CU branch data
prefix = 'call-report-data-2023-12'
branch_file = os.path.join(DATA_DIR, prefix, 'Credit Union Branch Information.txt')
try:
    df = pd.read_csv(branch_file, encoding='cp1252')
except:
    prefix = 'call-report-data-2022-12'
    branch_file = os.path.join(DATA_DIR, prefix, 'Credit Union Branch Information.txt')
    df = pd.read_csv(branch_file, encoding='cp1252')

wi = df[df['PhysicalAddressStateCode'] == 'WI'].copy()

# Extract county from address (use PhysicalAddressCountyName if available)
if 'PhysicalAddressCountyName' in wi.columns:
    county_col = 'PhysicalAddressCountyName'
else:
    # Fall back to trying to geocode or use FIPS
    county_col = None

if county_col:
    cu_counties = wi[county_col].value_counts().reset_index()
    cu_counties.columns = ['county', 'cu_branches']
else:
    print("No county column found in CU branch data. Using NCUA master file.")
    # Try ncua_master_final.csv
    master = pd.read_csv(os.path.join(DATA_DIR, 'ncua_master_final.csv'), low_memory=False)
    master_wi = master[master['state'] == 'WI'] if 'state' in master.columns else master
    if 'county' in master_wi.columns:
        cu_counties = master_wi['county'].value_counts().reset_index()
        cu_counties.columns = ['county', 'cu_branches']
    else:
        print("Cannot determine county-level CU data. Exiting.")
        exit(1)

df_pop = pd.read_excel(os.path.join(DATA_DIR, 'co-est2024-pop-55.xlsx'))
df_pop['county'] = (df_pop['county']
    .str.replace(r'^\.', '', regex=True)
    .str.replace(r' County, Wisconsin', '', regex=True))

cu_counties['county_clean'] = cu_counties['county'].str.upper().str.strip()
df_pop['county_upper'] = df_pop['county'].str.upper().str.strip()

merged = cu_counties.merge(df_pop, left_on='county_clean', right_on='county_upper', how='left')
merged['cu_pc'] = (merged['cu_branches'] / merged['pop']) * 10000

try:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2023/COUNTY/tl_2023_us_county.zip")
except:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip")
wi_counties = counties[counties['STATEFP'] == '55'].copy()
wi_counties['NAME_upper'] = wi_counties['NAME'].str.upper()

gdf = wi_counties.merge(merged, left_on='NAME_upper', right_on='county_clean', how='left')

fig, ax = plt.subplots(figsize=(10, 12))
gdf.plot(column='cu_pc', cmap='Oranges', linewidth=0.8, edgecolor='white',
         legend=True, ax=ax, missing_kwds={'color': 'lightgray'},
         legend_kwds={'label': 'CU Branches per 10K', 'shrink': 0.5})

ax.set_title('Figure CU-4: Credit Union Branches per 10,000 Residents\nby County (2023)',
             fontsize=14, fontweight='bold')
ax.axis('off')
fig.text(0.99, 0.01, 'Data: NCUA & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig_cu04_branches_per_10k_wi_map.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
