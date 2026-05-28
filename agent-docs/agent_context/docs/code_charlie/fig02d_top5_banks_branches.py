#!/usr/bin/env python3
"""
Figure 2d: Top 5 Banks by Number of Wisconsin Branches (2024)
=============================================================
Horizontal bar chart of the five banks with the most WI branches.

Data Source: FDIC Summary of Deposits (SOD) 2024.
Output:      fig02d_top5_banks_branches.png
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

branch_counts = wi.groupby(['CERT', 'NAMEFULL']).size().reset_index(name='branches')
top5 = branch_counts.nlargest(5, 'branches').copy()
top5['label'] = (top5['NAMEFULL']
    .str.replace(', National Association', '', regex=False)
    .str.replace(', N.A.', '', regex=False))

fig, ax = plt.subplots(figsize=(9, 4))
ax.barh(range(len(top5)), top5['branches'].values, color='#2E75B6', height=0.6)
ax.set_yticks(range(len(top5)))
ax.set_yticklabels(top5['label'].values)
ax.invert_yaxis()
ax.set_xlabel('Number of Branches in Wisconsin')
ax.set_title('Figure 2d: Top 5 Banks by Number of Wisconsin Branches (2024)')
for i, v in enumerate(top5['branches'].values):
    ax.text(v + 1, i, str(v), va='center', fontsize=10)
ax.set_xlim(0, top5['branches'].max() * 1.2)
fig.text(0.99, 0.01, 'Data: FDIC Summary of Deposits', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig02d_top5_banks_branches.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
