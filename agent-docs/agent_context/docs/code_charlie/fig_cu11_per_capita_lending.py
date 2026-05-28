#!/usr/bin/env python3
"""
Figure CU-11: Per Capita Commercial Lending & Originations (WI CUs, 2017-2024)
===============================================================================
Dual-axis chart: bar = per capita lending amount, line = originations per 10K.

Data Source: NCUA Call Reports & Census Bureau (WIPOP).
Output:      fig_cu11_per_capita_lending.png
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

wi_population = {
    2017: 5793147, 2018: 5809319, 2019: 5824581, 2020: 5897375,
    2021: 5881608, 2022: 5903975, 2023: 5930405, 2024: 5960975
}

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

        total_amt = pd.to_numeric(wi_fs.get('ACCT_475A1', pd.Series([0])), errors='coerce').sum()
        total_num = pd.to_numeric(wi_fs.get('ACCT_090A1', pd.Series([0])), errors='coerce').sum()
        pop = wi_population.get(year, 5900000)

        records.append({
            'year': year,
            'per_cap_amt': total_amt / pop,
            'per_10k_num': 10000 * total_num / pop,
        })
    except Exception as e:
        print(f"  Skip {year}: {e}")

df = pd.DataFrame(records).sort_values('year')

fig, ax1 = plt.subplots(figsize=(9, 5))

# Bars: per capita lending amount
bars = ax1.bar(df['year'], df['per_cap_amt'], color='#2E75B6', alpha=0.7, label='$ per Capita')
ax1.set_xlabel('Year')
ax1.set_ylabel('Loan Amount per Capita ($)', color='#2E75B6')
ax1.tick_params(axis='y', labelcolor='#2E75B6')
ax1.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, _: f'${int(x):,}'))

# Line: originations per 10K
ax2 = ax1.twinx()
ax2.plot(df['year'], df['per_10k_num'], marker='o', color='#BF4D28', linewidth=2, label='Loans per 10K')
ax2.set_ylabel('Originations per 10,000 Residents', color='#BF4D28')
ax2.tick_params(axis='y', labelcolor='#BF4D28')

ax1.set_title('Figure CU-11: Per Capita Commercial Lending by Wisconsin Credit Unions')
lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines1 + lines2, labels1 + labels2, loc='upper left')
ax1.grid(axis='y', linestyle='-', alpha=0.3)
ax1.set_xticks(df['year'].values)

fig.text(0.99, 0.01, 'Data: NCUA & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig_cu11_per_capita_lending.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
