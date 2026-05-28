#!/usr/bin/env python3
"""
Figure 6: Bank Headquarters per County (2024, Quintile Map)
===========================================================
Choropleth of bank headquarters by WI county, showing local control.

Data Source: FDIC SOD 2024.
Output:      fig06_headquarters_map.png
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

sod = pd.read_csv(os.path.join(DATA_DIR, 'SOD_CustomDownload_ALL_2024_06_30.csv'),
                   low_memory=False, encoding='latin-1')
# Main offices only (BRNUM == 0) in WI
hq = sod[(sod['BRNUM'] == 0) & (sod['STALP'] == 'WI')].copy()
hq_counts = hq['CNTYNAMB'].value_counts().reset_index()
hq_counts.columns = ['CNTYNAMB', 'n_hq']

try:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2023/COUNTY/tl_2023_us_county.zip")
except:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip")
wi_counties = counties[counties['STATEFP'] == '55'].copy()
wi_counties['NAME_upper'] = wi_counties['NAME'].str.upper()
hq_counts['CNTYNAMB_upper'] = hq_counts['CNTYNAMB'].str.upper()

gdf = wi_counties.merge(hq_counts, left_on='NAME_upper', right_on='CNTYNAMB_upper', how='left')
gdf['n_hq'] = gdf['n_hq'].fillna(0)

fig, ax = plt.subplots(figsize=(10, 12))
gdf.plot(column='n_hq', cmap='YlOrRd', linewidth=0.8, edgecolor='white',
         legend=True, ax=ax, legend_kwds={'label': 'Number of Bank HQs', 'shrink': 0.5})

ax.set_title('Figure 6: Bank Headquarters by County (2024)', fontsize=14, fontweight='bold')
ax.axis('off')

total_hq = int(gdf['n_hq'].sum())
ax.text(0.02, 0.02, f'Total WI bank HQs: {total_hq}', transform=ax.transAxes,
        fontsize=10, bbox=dict(facecolor='white', alpha=0.7))

fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig06_headquarters_map.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
