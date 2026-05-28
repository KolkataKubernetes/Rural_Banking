#!/usr/bin/env python3
"""
Figure 9: Growth Index of Small Business Lending Volume (2000-2023)
===================================================================
Line chart showing indexed growth in loan dollars per 10K residents by
size category, base year = 2000.

Data Source: CRA aggregate data & Census Bureau (WIPOP).
Output:      fig09_lending_volume_growth.png
"""

import os, warnings
warnings.filterwarnings('ignore')
import pandas as pd
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FIG_DIR  = os.path.join(DATA_DIR, 'figure_scripts', 'output')
os.makedirs(FIG_DIR, exist_ok=True)

plt.rcParams.update({'font.family': 'sans-serif', 'font.size': 11,
                      'axes.spines.top': False, 'axes.spines.right': False})

col_widths = [5,4,1,1,2,3,5,7,1,1,3,3,10,10,10,10,10,10,10,10,10,10,29]
col_names = ["Table_ID","Year","Loan_Type","Action_Type","State_FIPS","County_FIPS",
             "MSA_MD","Census_Tract","Split_County","Pop_Class","Income_Group",
             "Report_Level","Loans_U100k_Num","Loans_U100k_Amt",
             "Loans_100_250_Num","Loans_100_250_Amt",
             "Loans_250_1M_Num","Loans_250_1M_Amt",
             "Loans_Over1M_Num","Loans_Over1M_Amt",
             "Loans_Rev_Num","Loans_Rev_Amt","Filler"]

amt_cols = ['Loans_U100k_Amt', 'Loans_100_250_Amt', 'Loans_250_1M_Amt']

all_years = []

# 2000-2004
for yr in range(2000, 2005):
    try:
        df = pd.read_csv(os.path.join(DATA_DIR, f'aggr/tract_{yr}.txt'), delimiter='|')
        wi = df[(df['state'] == 55) & (df['report_level'] == 200)]
        all_years.append({
            'Year': yr,
            'Loans_U100k_Amt': wi['vol_100k'].sum() * 1000,
            'Loans_100_250_Amt': wi.get('vol_250k', pd.Series([0])).sum() * 1000 if 'vol_250k' in wi.columns else 0,
            'Loans_250_1M_Amt': wi.get('vol_1M', pd.Series([0])).sum() * 1000 if 'vol_1M' in wi.columns else 0,
        })
    except Exception as e:
        print(f"  Skip {yr}: {e}")

# 2005-2018
for yr in range(2005, 2019):
    try:
        df = pd.read_csv(os.path.join(DATA_DIR, f'cra_old/cra_{yr}.csv'), dtype=str, on_bad_lines='skip')
        df['state_fips'] = df['fips'].str[:2]
        wi = df[df['state_fips'] == '55']
        all_years.append({
            'Year': yr,
            'Loans_U100k_Amt': wi['loan_vol_100k'].astype(int).sum(),
            'Loans_100_250_Amt': wi['loan_vol_250k'].astype(int).sum() if 'loan_vol_250k' in wi.columns else 0,
            'Loans_250_1M_Amt': wi['loan_vol_1M'].astype(int).sum() if 'loan_vol_1M' in wi.columns else 0,
        })
    except Exception as e:
        print(f"  Skip {yr}: {e}")

# 2019-2023
for yr in range(19, 24):
    fpath = os.path.join(DATA_DIR, f'{yr}exp_aggr/cra20{yr}_Aggr_A11.dat')
    try:
        df = pd.read_fwf(fpath, widths=col_widths, names=col_names, dtype=str)
        wi = df[(df['State_FIPS'] == '55') & (df['Report_Level'] == '200')]
        for c in amt_cols:
            wi[c] = wi[c].fillna(0).astype(int) * 1000
        all_years.append({
            'Year': 2000 + yr,
            'Loans_U100k_Amt': wi['Loans_U100k_Amt'].sum(),
            'Loans_100_250_Amt': wi['Loans_100_250_Amt'].sum(),
            'Loans_250_1M_Amt': wi['Loans_250_1M_Amt'].sum(),
        })
    except Exception as e:
        print(f"  Skip 20{yr}: {e}")

cra = pd.DataFrame(all_years).sort_values('Year')

wipop = pd.read_csv(os.path.join(DATA_DIR, 'WIPOP.csv'))
wipop['Year'] = pd.to_datetime(wipop['observation_date']).dt.year
wipop['pop'] = wipop['WIPOP'] * 1000
cra = cra.merge(wipop[['Year', 'pop']], on='Year', how='inner')

for col in amt_cols:
    cra[f'{col}_pc'] = cra[col] / cra['pop'] * 10000

base = cra[cra['Year'] == 2000].iloc[0]
for col in amt_cols:
    cra[f'{col}_idx'] = cra[f'{col}_pc'] / base[f'{col}_pc'] * 100

fig, ax = plt.subplots(figsize=(10, 5))
ax.plot(cra['Year'], cra['Loans_U100k_Amt_idx'], marker='o', color='#2E75B6', linewidth=2, label='Under $100K')
ax.plot(cra['Year'], cra['Loans_100_250_Amt_idx'], marker='s', color='#BF4D28', linewidth=2, label='$100K–$250K')
ax.plot(cra['Year'], cra['Loans_250_1M_Amt_idx'], marker='^', color='#4CAF50', linewidth=2, label='$250K–$1M')
ax.axhline(y=100, color='gray', linestyle='--', alpha=0.5)
ax.set_xlabel('Year')
ax.set_ylabel('Growth Index (2000 = 100)')
ax.set_title('Figure 9: Small Business Lending Volume per 10K Residents\n(Growth Index, 2000 = 100)')
ax.legend()
ax.grid(axis='y', linestyle='-', alpha=0.3)
fig.text(0.99, 0.01, 'Data: CRA & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig09_lending_volume_growth.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
