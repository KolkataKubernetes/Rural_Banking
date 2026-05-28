#!/usr/bin/env python3
"""
Figure 5: Banking Institutions per 10,000 Residents by County (2023, Quintile Map)
==================================================================================
Choropleth of unique banking institutions per 10K residents by WI county.

Data Source: FDIC SOD 2023 & Census Bureau population.
Output:      fig05_institutions_per_10k_map.png
"""

import os, warnings
warnings.filterwarnings('ignore')
import pandas as pd
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
import geopandas as gpd

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FIG_DIR  = os.path.join(DATA_DIR, 'figure_scripts', 'output')
os.makedirs(FIG_DIR, exist_ok=True)

sod = pd.read_csv(os.path.join(DATA_DIR, 'SOD_CustomDownload_ALL_2023_06_30.csv'),
                   header=0, dtype=str, on_bad_lines='skip')
wi = sod[sod['STALPBR'] == 'WI']
inst_counts = wi.groupby('CNTYNAMB')['NAMEFULL'].nunique().reset_index()
inst_counts.columns = ['CNTYNAMB', 'n_inst']

df_pop = pd.read_excel(os.path.join(DATA_DIR, 'co-est2024-pop-55.xlsx'))
df_pop['county'] = (df_pop['county']
    .str.replace(r'^\.', '', regex=True)
    .str.replace(r' County, Wisconsin', '', regex=True))

merged = inst_counts.merge(df_pop, left_on='CNTYNAMB', right_on='county', how='left')
merged['i_pc'] = (merged['n_inst'] / merged['pop']) * 10000

try:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2023/COUNTY/tl_2023_us_county.zip")
except:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip")
wi_counties = counties[counties['STATEFP'] == '55'].copy()
wi_counties['NAME_upper'] = wi_counties['NAME'].str.upper()
merged['CNTYNAMB_upper'] = merged['CNTYNAMB'].str.upper()

gdf = wi_counties.merge(merged, left_on='NAME_upper', right_on='CNTYNAMB_upper', how='left')

fig, ax = plt.subplots(figsize=(10, 12))
gdf.plot(column='i_pc', cmap='Blues', linewidth=0.8, edgecolor='white',
         legend=True, ax=ax, missing_kwds={'color': 'lightgray'},
         legend_kwds={'label': 'Institutions per 10K', 'shrink': 0.5})

ax.set_title('Figure 5: Banking Institutions per 10,000 Residents by County (2023)', fontsize=14, fontweight='bold')
ax.axis('off')
fig.text(0.99, 0.01, 'Data: FDIC SOD & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig05_institutions_per_10k_map.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
