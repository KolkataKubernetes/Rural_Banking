#!/usr/bin/env python3
"""
Figure CU-3: Wisconsin Credit Union Institutions and Branches Over Time
=======================================================================
Dual-axis line chart showing CU institutions vs branches (2005-2024).

Data Source: NCUA Call Report data.
Output:      fig_cu03_institutions_branches_time.png
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

records = []
for year in range(2015, 2025):
    prefix = f'call-report-data-{year}-12'
    branch_file = os.path.join(DATA_DIR, prefix, 'Credit Union Branch Information.txt')
    try:
        df = pd.read_csv(branch_file, encoding='cp1252')
        wi = df[df['PhysicalAddressStateCode'] == 'WI']
        n_branches = len(wi)
        n_inst = wi['CU_NUMBER'].nunique()
        records.append({'year': year, 'institutions': n_inst, 'branches': n_branches})
    except Exception as e:
        print(f"  Skip {year}: {e}")

# Try earlier years with QCR format
for year in range(2005, 2015):
    prefix = f'QCR{year}12'
    branch_file = os.path.join(DATA_DIR, prefix, 'Credit Union Branch Information.txt')
    try:
        df = pd.read_csv(branch_file, encoding='cp1252')
        wi = df[df['PhysicalAddressStateCode'] == 'WI']
        n_branches = len(wi)
        n_inst = wi['CU_NUMBER'].nunique()
        records.append({'year': year, 'institutions': n_inst, 'branches': n_branches})
    except Exception as e:
        print(f"  Skip {year}: {e}")

if not records:
    print("No NCUA data found. Ensure call-report-data directories exist.")
    exit(1)

df = pd.DataFrame(records).sort_values('year')

fig, ax1 = plt.subplots(figsize=(10, 5))
color_inst = '#BF4D28'
color_br = '#2E75B6'

ax1.plot(df['year'], df['institutions'], marker='o', color=color_inst, linewidth=2, label='Institutions')
ax1.set_xlabel('Year')
ax1.set_ylabel('Number of Institutions', color=color_inst)
ax1.tick_params(axis='y', labelcolor=color_inst)

ax2 = ax1.twinx()
ax2.plot(df['year'], df['branches'], marker='s', color=color_br, linewidth=2, label='Branches')
ax2.set_ylabel('Number of Branches', color=color_br)
ax2.tick_params(axis='y', labelcolor=color_br)

ax1.set_title('Figure CU-3: Wisconsin Credit Union Institutions and Branches')
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='center left')
ax1.grid(axis='y', linestyle='-', alpha=0.3)

fig.text(0.99, 0.01, 'Data: NCUA Call Reports', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig_cu03_institutions_branches_time.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
