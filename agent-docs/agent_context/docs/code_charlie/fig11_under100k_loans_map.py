#!/usr/bin/env python3
"""
Figure 11: Under-$100K Small Business Loans per 10K Residents (2023, County Map)
================================================================================
Choropleth map showing frequency of under-$100K CRA loans by WI county.

Data Source: CRA 2023 aggregate & Census Bureau population.
Output:      fig11_under100k_loans_map.png
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

col_widths = [5,4,1,1,2,3,5,7,1,1,3,3,10,10,10,10,10,10,10,10,10,10,29]
col_names = ["Table_ID","Year","Loan_Type","Action_Type","State_FIPS","County_FIPS",
             "MSA_MD","Census_Tract","Split_County","Pop_Class","Income_Group",
             "Report_Level","Loans_U100k_Num","Loans_U100k_Amt",
             "Loans_100_250_Num","Loans_100_250_Amt",
             "Loans_250_1M_Num","Loans_250_1M_Amt",
             "Loans_Over1M_Num","Loans_Over1M_Amt",
             "Loans_Rev_Num","Loans_Rev_Amt","Filler"]

# ── Load 2023 CRA county-level ──────────────────────────────────────────────
fpath = os.path.join(DATA_DIR, '23exp_aggr/cra2023_Aggr_A11.dat')
df = pd.read_fwf(fpath, widths=col_widths, names=col_names, dtype=str)
wi = df[(df['State_FIPS'] == '55') & (df['Report_Level'] == '200')].copy()
wi['Loans_U100k_Num'] = wi['Loans_U100k_Num'].fillna(0).astype(int)
wi['County_FIPS'] = wi['County_FIPS'].str.zfill(3)
county_loans = wi.groupby('County_FIPS')['Loans_U100k_Num'].sum().reset_index()

# ── Population ───────────────────────────────────────────────────────────────
df_pop = pd.read_excel(os.path.join(DATA_DIR, 'co-est2024-pop-55.xlsx'))
df_pop['county'] = (df_pop['county']
    .str.replace(r'^\.', '', regex=True)
    .str.replace(r' County, Wisconsin', '', regex=True))

# ── Shapefile ────────────────────────────────────────────────────────────────
try:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2023/COUNTY/tl_2023_us_county.zip")
except:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip")
wi_counties = counties[counties['STATEFP'] == '55'].copy()

# Merge CRA by county FIPS
gdf = wi_counties.merge(county_loans, left_on='COUNTYFP', right_on='County_FIPS', how='left')
gdf = gdf.merge(df_pop, left_on='NAME', right_on='county', how='left')
gdf['loans_pc'] = (gdf['Loans_U100k_Num'] / gdf['pop']) * 10000

fig, ax = plt.subplots(figsize=(10, 12))
gdf.plot(column='loans_pc', cmap='YlOrRd', linewidth=0.8, edgecolor='white',
         legend=True, ax=ax, missing_kwds={'color': 'lightgray'},
         legend_kwds={'label': 'Loans per 10K residents', 'shrink': 0.5})

ax.set_title('Figure 11: Under-$100K Small Business Loans per 10K Residents\nby County (2023)',
             fontsize=14, fontweight='bold')
ax.axis('off')
fig.text(0.99, 0.01, 'Data: CRA & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig11_under100k_loans_map.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
