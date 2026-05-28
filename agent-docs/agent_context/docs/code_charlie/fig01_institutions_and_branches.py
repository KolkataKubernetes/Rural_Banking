#!/usr/bin/env python3
"""
Figure 1: Count of Wisconsin Banking Institutions and Branches (2000-2024)
=========================================================================
Dual-axis line chart showing the number of FDIC-insured commercial banking
institutions and their branches in Wisconsin over a 25-year period.

Data Source: FDIC Summary of Deposits (SOD) annual files.
Output:      fig01_institutions_and_branches.png
"""

import os
import warnings
warnings.filterwarnings('ignore')

import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# ── Paths ────────────────────────────────────────────────────────────────────
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FIG_DIR  = os.path.join(DATA_DIR, 'figure_scripts', 'output')
os.makedirs(FIG_DIR, exist_ok=True)

# ── Style ────────────────────────────────────────────────────────────────────
plt.rcParams.update({
    'font.family': 'sans-serif', 'font.size': 11,
    'axes.spines.top': False, 'axes.spines.right': False,
})

# ── Load SOD data for each year ──────────────────────────────────────────────
sod_files = sorted([f for f in os.listdir(DATA_DIR)
                     if f.startswith('SOD_Custom') and f.endswith('.csv') and '-2.csv' not in f])

records = []
for f in sod_files:
    yr = int(f.split('_')[3])
    try:
        sod = pd.read_csv(os.path.join(DATA_DIR, f), low_memory=False, encoding='latin-1')
        wi = sod[sod['STALPBR'] == 'WI']
        records.append({
            'year': yr,
            'n_institutions': wi['CERT'].nunique(),
            'n_branches': len(wi),
        })
    except Exception as e:
        print(f"  Skipping {f}: {e}")

df = pd.DataFrame(records).sort_values('year')

# ── Plot ─────────────────────────────────────────────────────────────────────
fig, ax1 = plt.subplots(figsize=(10, 5))

color_inst = '#BF4D28'
color_branch = '#2E75B6'

ax1.plot(df['year'], df['n_institutions'], marker='o', color=color_inst,
         linewidth=2, label='Institutions')
ax1.set_xlabel('Year')
ax1.set_ylabel('Number of Institutions', color=color_inst)
ax1.tick_params(axis='y', labelcolor=color_inst)

ax2 = ax1.twinx()
ax2.plot(df['year'], df['n_branches'], marker='s', color=color_branch,
         linewidth=2, label='Branches')
ax2.set_ylabel('Number of Branches', color=color_branch)
ax2.tick_params(axis='y', labelcolor=color_branch)

ax1.set_title('Figure 1: Wisconsin Banking Institutions and Branches (2000–2024)')
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='center right')
ax1.grid(axis='y', linestyle='-', alpha=0.3)
ax1.set_xticks(df['year'].values[::2])
ax1.set_xticklabels(df['year'].values[::2], rotation=45, ha='right')

fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits', ha='right', va='bottom',
         fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig01_institutions_and_branches.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
