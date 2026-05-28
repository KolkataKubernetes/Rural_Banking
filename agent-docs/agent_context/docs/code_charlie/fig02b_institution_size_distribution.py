#!/usr/bin/env python3
"""
Figure 2b: Distribution of Wisconsin Banking Institutions by Branch Count
=========================================================================
Bar chart showing how many institutions fall into each branch-count bucket.

Data Source: FDIC Summary of Deposits (SOD) 2024.
Output:      fig02b_institution_size_distribution.png
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
hq_counts = wi.groupby('CERT').size()

bins = [0, 2, 6, 11, 21, 51, 300]
labels = ["1", "2-5", "6-10", "11-20", "21-50", "50+"]
binned = pd.cut(hq_counts, bins=bins, labels=labels, right=False)
bucket_counts = binned.value_counts().sort_index()

fig, ax = plt.subplots(figsize=(9, 5))
bars = ax.bar(range(len(bucket_counts)), bucket_counts.values, color='#2E75B6')
ax.set_xticks(range(len(bucket_counts)))
ax.set_xticklabels(labels)
ax.set_xlabel('Number of Branches')
ax.set_ylabel('Number of Institutions')
ax.set_title('Figure 2b: Wisconsin Banking Institutions by Number of Branches (2024)')
for bar in bars:
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, h + 1, str(int(h)), ha='center', fontsize=10)

stats_text = f"Mean: {hq_counts.mean():.1f}  |  Median: {hq_counts.median():.0f}  |  Total: {len(hq_counts)}"
ax.text(0.98, 0.95, stats_text, transform=ax.transAxes, ha='right', va='top',
        fontsize=9, bbox=dict(facecolor='white', alpha=0.7, edgecolor='gray'))
ax.grid(axis='y', linestyle='-', alpha=0.3)
fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig02b_institution_size_distribution.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
