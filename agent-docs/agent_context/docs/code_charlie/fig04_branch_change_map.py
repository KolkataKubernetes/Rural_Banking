#!/usr/bin/env python3
"""
Figure 4: Change in Bank Branches per 10,000 Residents (2009-2023, Quintile Map)
================================================================================
Choropleth map showing the absolute change in branches per 10K between 2009 and 2023.

Data Source: FDIC SOD 2009 & 2023, Census Bureau population.
Output:      fig04_branch_change_map.png
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

# ── 2023 data ────────────────────────────────────────────────────────────────
sod_23 = pd.read_csv(os.path.join(DATA_DIR, 'SOD_CustomDownload_ALL_2023_06_30.csv'),
                      header=0, dtype=str, on_bad_lines='skip')
wi_23 = sod_23[sod_23['STALPBR'] == 'WI']
bc_23 = wi_23['CNTYNAMB'].value_counts().reset_index()
bc_23.columns = ['CNTYNAMB', 'count_23']

df_pop_23 = pd.read_excel(os.path.join(DATA_DIR, 'co-est2024-pop-55.xlsx'))
df_pop_23['county'] = (df_pop_23['county']
    .str.replace(r'^\.', '', regex=True)
    .str.replace(r' County, Wisconsin', '', regex=True))

m23 = bc_23.merge(df_pop_23, left_on='CNTYNAMB', right_on='county', how='left')
m23['bpc_23'] = (m23['count_23'] / m23['pop']) * 10000

# ── 2009 data ────────────────────────────────────────────────────────────────
sod_09 = pd.read_csv(os.path.join(DATA_DIR, 'SOD_CustomDownload_ALL_2009_06_30.csv'),
                      header=0, dtype=str, on_bad_lines='skip')
wi_09 = sod_09[sod_09['STALPBR'] == 'WI']
bc_09 = wi_09['CNTYNAMB'].value_counts().reset_index()
bc_09.columns = ['CNTYNAMB', 'count_09']

df_pop_09 = pd.read_excel(os.path.join(DATA_DIR, 'co-est00int-01-55.xls'), engine='xlrd')
df_pop_09['county'] = (df_pop_09['county']
    .str.replace(r'^\.', '', regex=True)
    .str.replace(r' County', '', regex=True))

m09 = bc_09.merge(df_pop_09, left_on='CNTYNAMB', right_on='county', how='left')
m09['bpc_09'] = (m09['count_09'] / m09['pop']) * 10000

# ── Compute change ───────────────────────────────────────────────────────────
change = m09[['CNTYNAMB', 'bpc_09']].merge(m23[['CNTYNAMB', 'bpc_23']], on='CNTYNAMB', how='outer')
change['abs_change'] = change['bpc_23'] - change['bpc_09']

# ── Load shapefile ───────────────────────────────────────────────────────────
try:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2023/COUNTY/tl_2023_us_county.zip")
except:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip")
wi_counties = counties[counties['STATEFP'] == '55'].copy()
wi_counties['NAME_upper'] = wi_counties['NAME'].str.upper()
change['CNTYNAMB_upper'] = change['CNTYNAMB'].str.upper()

gdf = wi_counties.merge(change, left_on='NAME_upper', right_on='CNTYNAMB_upper', how='left')

# ── Plot (diverging colormap) ────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(10, 12))
gdf.plot(column='abs_change', cmap='RdYlGn', linewidth=0.8, edgecolor='white',
         legend=True, ax=ax, missing_kwds={'color': 'lightgray'},
         legend_kwds={'label': 'Change in branches per 10K', 'shrink': 0.5})

ax.set_title('Figure 4: Change in Bank Branches per 10,000 Residents\n(2009–2023)', fontsize=14, fontweight='bold')
ax.axis('off')
fig.text(0.99, 0.01, 'Data: FDIC SOD & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig04_branch_change_map.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
