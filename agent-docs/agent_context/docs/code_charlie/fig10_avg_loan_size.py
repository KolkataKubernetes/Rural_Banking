#!/usr/bin/env python3
"""
Figure 10: Average Small Business Loan Size Over Time (2000-2023)
=================================================================
Line chart showing average loan size for under-$100K category.

Data Source: CRA aggregate data.
Output:      fig10_avg_loan_size.png
"""

import os, warnings
warnings.filterwarnings('ignore')
import pandas as pd
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FIG_DIR  = os.path.join(DATA_DIR, 'figure_scripts', 'output')
os.makedirs(FIG_DIR, exist_ok=True)

plt.rcParams.update({'font.family': 'sans-serif', 'font.size': 11,
                      'axes.spines.top': False, 'axes.spines.right': False})

# Load pre-computed data if available, otherwise compute
data_file = os.path.join(DATA_DIR, 'fig_under100k_data.csv')
if os.path.exists(data_file):
    cra = pd.read_csv(data_file)
else:
    print("Pre-computed data not found. Run fig08 or graph_under100k_loans notebook first.")
    exit(1)

fig, ax = plt.subplots(figsize=(10, 5))
ax.plot(cra['Year'], cra['avg_size'], marker='o', color='#2E75B6', linewidth=2)
ax.set_xlabel('Year')
ax.set_ylabel('Average Loan Size ($)')
ax.set_title('Figure 10: Average Small Business Loan Size (Under $100K Category)\n2000–2023')
ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f'${int(x):,}'))
ax.grid(axis='y', linestyle='-', alpha=0.3)
fig.text(0.99, 0.01, 'Data: CRA', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig10_avg_loan_size.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
