#!/usr/bin/env python3
"""
Figure CU-6: Commercial Lending as % of Total Assets (WI Credit Unions, 2017-2024)
==================================================================================
Line chart showing the share of total assets devoted to commercial loans.

Data Source: NCUA Call Reports (FS220L.txt).
Output:      fig_cu06_commercial_pct_assets.png
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
for year in range(2017, 2025):
    prefix = f'call-report-data-{year}-12'
    fs_file = os.path.join(DATA_DIR, prefix, 'FS220L.txt')
    branch_file = os.path.join(DATA_DIR, prefix, 'Credit Union Branch Information.txt')
    try:
        df_fs = pd.read_csv(fs_file, encoding='cp1252')
        df_br = pd.read_csv(branch_file, encoding='cp1252')
        # Get WI CU numbers from main offices
        wi_main = df_br[(df_br['PhysicalAddressStateCode'] == 'WI') & (df_br['MainOffice'] == 'Yes')]
        wi_cu = wi_main.drop_duplicates('CU_NUMBER')['CU_NUMBER']

        wi_fs = df_fs[df_fs['CU_NUMBER'].isin(wi_cu)]

        # ACCT_475A1 = total commercial loans outstanding
        # ACCT_010  = total assets (may vary by year)
        total_commercial = pd.to_numeric(wi_fs.get('ACCT_475A1', pd.Series([0])), errors='coerce').sum()
        total_assets = pd.to_numeric(wi_fs.get('ACCT_010', pd.Series([0])), errors='coerce').sum()

        if total_assets > 0:
            records.append({
                'year': year,
                'pct_assets': (total_commercial / total_assets) * 100,
            })
    except Exception as e:
        print(f"  Skip {year}: {e}")

if not records:
    print("No data loaded. Ensure NCUA call report directories exist.")
    exit(1)

df = pd.DataFrame(records).sort_values('year')

fig, ax = plt.subplots(figsize=(9, 5))
ax.plot(df['year'], df['pct_assets'], marker='o', color='#2E75B6', linewidth=2)
ax.set_xlabel('Year')
ax.set_ylabel('Commercial Loans as % of Total Assets')
ax.set_title('Figure CU-6: Commercial Lending as % of Total Assets\n(Wisconsin Credit Unions)')
ax.grid(axis='y', linestyle='-', alpha=0.3)
ax.set_xticks(df['year'].values)
fig.text(0.99, 0.01, 'Data: NCUA Call Reports', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig_cu06_commercial_pct_assets.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
