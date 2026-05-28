#!/usr/bin/env python3
"""
Figure 2: Median and Mean Branches per Banking Institution (2000-2024)
======================================================================
Line chart showing the branch-to-institution ratio over time, illustrating
consolidation trends in Wisconsin banking.

Data Source: FDIC Summary of Deposits (SOD) annual files.
Output:      fig02_branch_institution_ratio.png
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

sod_files = sorted([f for f in os.listdir(DATA_DIR)
                     if f.startswith('SOD_Custom') and f.endswith('.csv') and '-2.csv' not in f])

records = []
for f in sod_files:
    yr = int(f.split('_')[3])
    try:
        sod = pd.read_csv(os.path.join(DATA_DIR, f), low_memory=False, encoding='latin-1')
        wi = sod[sod['STALPBR'] == 'WI']
        bc = wi.groupby('CERT').size()
        records.append({'year': yr, 'median': bc.median(), 'mean': bc.mean()})
    except Exception as e:
        print(f"  Skipping {f}: {e}")

df = pd.DataFrame(records).sort_values('year')

fig, ax = plt.subplots(figsize=(10, 5))
ax.plot(df['year'], df['median'], marker='o', color='#2E75B6', linewidth=2, label='Median')
ax.plot(df['year'], df['mean'], marker='s', color='#BF4D28', linewidth=2, linestyle='--', label='Mean')
ax.set_xlabel('Year')
ax.set_ylabel('Branches per Institution')
ax.set_title('Figure 2: Median and Mean Branches per Banking Institution (2000–2024)')
ax.legend()
ax.grid(axis='y', linestyle='-', alpha=0.3)
ax.set_xticks(df['year'].values[::2])
ax.set_xticklabels(df['year'].values[::2], rotation=45, ha='right')
fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig02_branch_institution_ratio.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
