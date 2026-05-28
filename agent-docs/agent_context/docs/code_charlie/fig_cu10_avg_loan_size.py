#!/usr/bin/env python3
"""
Figure CU-10: Average Commercial Loan Size (WI Credit Unions, 2017-2024)
========================================================================
Bar chart showing average CU commercial loan size over time.

Data Source: NCUA Call Reports (FS220L.txt).
Output:      fig_cu10_avg_loan_size.png
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

records = []
for year in range(2017, 2025):
    prefix = f'call-report-data-{year}-12'
    fs_file = os.path.join(DATA_DIR, prefix, 'FS220L.txt')
    branch_file = os.path.join(DATA_DIR, prefix, 'Credit Union Branch Information.txt')
    try:
        df_fs = pd.read_csv(fs_file, encoding='cp1252')
        df_br = pd.read_csv(branch_file, encoding='cp1252')
        wi_main = df_br[(df_br['PhysicalAddressStateCode'] == 'WI') & (df_br['MainOffice'] == 'Yes')]
        wi_cu = wi_main.drop_duplicates('CU_NUMBER')['CU_NUMBER']
        wi_fs = df_fs[df_fs['CU_NUMBER'].isin(wi_cu)]

        # ACCT_475A1 = total commercial loan amount
        # ACCT_090A1 = number of commercial loans
        total_amt = pd.to_numeric(wi_fs.get('ACCT_475A1', pd.Series([0])), errors='coerce').sum()
        total_num = pd.to_numeric(wi_fs.get('ACCT_090A1', pd.Series([0])), errors='coerce').sum()

        if total_num > 0:
            records.append({
                'year': year,
                'avg_loan': total_amt / total_num,
                'total_amt': total_amt,
                'total_num': total_num,
            })
    except Exception as e:
        print(f"  Skip {year}: {e}")

df = pd.DataFrame(records).sort_values('year')

fig, ax = plt.subplots(figsize=(9, 5))
bars = ax.bar(df['year'], df['avg_loan'], color='#2E75B6')
for bar in bars:
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, h + 5000, f'${h:,.0f}', ha='center', fontsize=9)

ax.set_xlabel('Year')
ax.set_ylabel('Average Loan Size ($)')
ax.set_title('Figure CU-10: Average Commercial Loan Size\n(Wisconsin Credit Unions)')
ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f'${int(x):,}'))
ax.grid(axis='y', linestyle='-', alpha=0.3)
ax.set_xticks(df['year'].values)
fig.text(0.99, 0.01, 'Data: NCUA Call Reports', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig_cu10_avg_loan_size.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
