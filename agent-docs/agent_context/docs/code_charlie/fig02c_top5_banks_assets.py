#!/usr/bin/env python3
"""
Figure 2c: Top 5 Wisconsin-Headquartered Banks by Total Assets (2024)
=====================================================================
Horizontal bar chart of the five largest WI-headquartered banks.

Data Source: FDIC Summary of Deposits (SOD) 2024.
Output:      fig02c_top5_banks_assets.png
"""

import os, warnings
warnings.filterwarnings('ignore')
import pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FIG_DIR  = os.path.join(DATA_DIR, 'figure_scripts', 'output')
os.makedirs(FIG_DIR, exist_ok=True)

plt.rcParams.update({'font.family': 'sans-serif', 'font.size': 11,
                      'axes.spines.top': False, 'axes.spines.right': False})

sod = pd.read_csv(os.path.join(DATA_DIR, 'SOD_CustomDownload_ALL_2024_06_30.csv'),
                   low_memory=False, encoding='latin-1')
wi = sod[sod['STALPBR'] == 'WI']

# HQ records (BRNUM == 0) with WI headquarters
hq = sod[sod['BRNUM'] == 0].copy()
wi_certs = wi['CERT'].unique()
wi_hq = hq[(hq['CERT'].isin(wi_certs)) & (hq['STALP'] == 'WI')].copy()
wi_hq['ASSET'] = pd.to_numeric(wi_hq['ASSET'], errors='coerce')

top5 = wi_hq.nlargest(5, 'ASSET')[['NAMEFULL', 'ASSET', 'CITY']].copy()
top5['ASSET_B'] = top5['ASSET'] / 1e6  # thousands → billions
top5['label'] = (top5['NAMEFULL']
    .str.replace(', National Association', '', regex=False)
    .str.replace(', N.A.', '', regex=False)
    .str.replace(', f.s.b.', '', regex=False))

fig, ax = plt.subplots(figsize=(9, 4))
ax.barh(range(len(top5)), top5['ASSET_B'].values, color='#2E75B6', height=0.6)
ax.set_yticks(range(len(top5)))
ax.set_yticklabels(top5['label'].values)
ax.invert_yaxis()
ax.set_xlabel('Total Assets ($ Billions)')
ax.set_title('Figure 2c: Top 5 Wisconsin-Headquartered Banks by Total Assets (2024)')
for i, (v, city) in enumerate(zip(top5['ASSET_B'].values, top5['CITY'].values)):
    ax.text(v + 0.3, i, f'${v:.1f}B  ({city})', va='center', fontsize=10)
ax.set_xlim(0, top5['ASSET_B'].max() * 1.4)
fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig02c_top5_banks_assets.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
