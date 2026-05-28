#!/usr/bin/env python3
"""
Figure 3: Bank Branches per 10,000 Residents by County (2023, Quintile Map)
===========================================================================
Choropleth map of Wisconsin counties showing bank branch density.

Data Source: FDIC Summary of Deposits (SOD) 2023 & Census Bureau population.
Output:      fig03_branches_per_10k_map.png
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

# ── Load SOD 2023 ────────────────────────────────────────────────────────────
sod = pd.read_csv(os.path.join(DATA_DIR, 'SOD_CustomDownload_ALL_2023_06_30.csv'),
                   header=0, dtype=str, on_bad_lines='skip')
wi = sod[sod['STALPBR'] == 'WI']
county_branches = wi['CNTYNAMB'].value_counts().reset_index()
county_branches.columns = ['CNTYNAMB', 'count']

# ── Load population ──────────────────────────────────────────────────────────
df_pop = pd.read_excel(os.path.join(DATA_DIR, 'co-est2024-pop-55.xlsx'))
df_pop['county'] = (df_pop['county']
    .str.replace(r'^\.', '', regex=True)
    .str.replace(r' County, Wisconsin', '', regex=True))

merged = county_branches.merge(df_pop, left_on='CNTYNAMB', right_on='county', how='left')
merged['b_pc'] = (merged['count'] / merged['pop']) * 10000

# ── Load WI county shapefile ────────────────────────────────────────────────
url = "https://www2.census.gov/geo/tiger/TIGER2023/COUNTY/tl_2023_us_county.zip"
try:
    counties = gpd.read_file(url)
except:
    counties = gpd.read_file("https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip")
wi_counties = counties[counties['STATEFP'] == '55'].copy()
wi_counties['NAME_upper'] = wi_counties['NAME'].str.upper()
merged['CNTYNAMB_upper'] = merged['CNTYNAMB'].str.upper()

gdf = wi_counties.merge(merged, left_on='NAME_upper', right_on='CNTYNAMB_upper', how='left')
gdf['quintile'] = pd.qcut(gdf['b_pc'].dropna(), q=5, labels=False, duplicates='drop')
gdf['quintile'] = gdf['quintile'].fillna(-1).astype(int)

# ── Plot ─────────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(10, 12))
colors = plt.get_cmap('Blues')(np.linspace(0.2, 1, 5))

for q in range(5):
    subset = gdf[gdf['quintile'] == q]
    if len(subset) > 0:
        subset.plot(color=colors[q], linewidth=0.8, edgecolor='white', ax=ax)

# Counties with no data
gdf[gdf['quintile'] == -1].plot(color='lightgray', linewidth=0.8, edgecolor='white', ax=ax)

ax.set_title('Figure 3: Bank Branches per 10,000 Residents by County (2023)', fontsize=14, fontweight='bold')
ax.axis('off')

# Legend
q_labels = []
for i in range(5):
    vals = gdf.loc[gdf['quintile'] == i, 'b_pc']
    if len(vals) > 0:
        q_labels.append(f'Q{i+1}: {vals.min():.1f} – {vals.max():.1f}')
    else:
        q_labels.append(f'Q{i+1}')
legend_patches = [Patch(facecolor=colors[i], edgecolor='black', label=l) for i, l in enumerate(q_labels)]
ax.legend(handles=legend_patches, title='Branches per 10K', loc='lower left', frameon=False)

fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig03_branches_per_10k_map.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
