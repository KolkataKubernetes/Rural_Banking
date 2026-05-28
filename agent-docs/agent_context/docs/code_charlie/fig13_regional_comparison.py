#!/usr/bin/env python3
"""
Figure 13: Regional Comparison — WI vs. Midwestern Peers
========================================================
Bar charts comparing small business lending frequency and volume per 10K
residents across Midwestern states.

Data Source: FDIC SOD 2023 & Census Bureau state populations.
Output:      fig13a_regional_loans_per_10k.png, fig13b_regional_volume_per_10k.png
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

# ── Midwest states ───────────────────────────────────────────────────────────
midwest = {
    'WI': '55', 'MN': '27', 'MI': '26', 'IL': '17', 'IA': '19',
    'IN': '18', 'OH': '39', 'ND': '38', 'SD': '46',
}

col_widths = [5,4,1,1,2,3,5,7,1,1,3,3,10,10,10,10,10,10,10,10,10,10,29]
col_names = ["Table_ID","Year","Loan_Type","Action_Type","State_FIPS","County_FIPS",
             "MSA_MD","Census_Tract","Split_County","Pop_Class","Income_Group",
             "Report_Level","Loans_U100k_Num","Loans_U100k_Amt",
             "Loans_100_250_Num","Loans_100_250_Amt",
             "Loans_250_1M_Num","Loans_250_1M_Amt",
             "Loans_Over1M_Num","Loans_Over1M_Amt",
             "Loans_Rev_Num","Loans_Rev_Amt","Filler"]

# ── State populations (2023 estimates) ───────────────────────────────────────
# Approximate 2023 populations for Midwest states
state_pop = {
    'WI': 5930405, 'MN': 5737915, 'MI': 10034113, 'IL': 12516863,
    'IA': 3207004, 'IN': 6833037, 'OH': 11780017, 'ND': 783926, 'SD': 909824,
}

# ── Load CRA 2023 for all states ────────────────────────────────────────────
fpath = os.path.join(DATA_DIR, '23exp_aggr/cra2023_Aggr_A11.dat')
df = pd.read_fwf(fpath, widths=col_widths, names=col_names, dtype=str)
df = df[df['Report_Level'] == '200']
df['Loans_U100k_Num'] = df['Loans_U100k_Num'].fillna(0).astype(int)
df['Loans_U100k_Amt'] = df['Loans_U100k_Amt'].fillna(0).astype(int) * 1000

records = []
for abbr, fips in midwest.items():
    state_df = df[df['State_FIPS'] == fips]
    pop = state_pop.get(abbr, 1)
    records.append({
        'state': abbr,
        'loans_num': state_df['Loans_U100k_Num'].sum(),
        'loans_amt': state_df['Loans_U100k_Amt'].sum(),
        'pop': pop,
        'loans_pc': state_df['Loans_U100k_Num'].sum() / pop * 10000,
        'vol_pc': state_df['Loans_U100k_Amt'].sum() / pop * 10000,
    })

comp = pd.DataFrame(records).sort_values('loans_pc', ascending=True)

# ── Figure 13a: Loans per 10K ───────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(9, 5))
colors = ['#2E75B6' if s != 'WI' else '#BF4D28' for s in comp['state']]
ax.barh(comp['state'], comp['loans_pc'], color=colors, height=0.6)
ax.set_xlabel('Under-$100K Loans per 10,000 Residents')
ax.set_title('Figure 13a: Small Business Loans per 10K Residents\n(Midwest Comparison, 2023)')
for i, (v, s) in enumerate(zip(comp['loans_pc'].values, comp['state'].values)):
    ax.text(v + 2, i, f'{v:.0f}', va='center', fontsize=9)
ax.set_xlim(0, comp['loans_pc'].max() * 1.15)
fig.text(0.99, 0.01, 'Data: CRA & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig13a_regional_loans_per_10k.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")

# ── Figure 13b: Volume per 10K ──────────────────────────────────────────────
comp2 = comp.sort_values('vol_pc', ascending=True)
fig, ax = plt.subplots(figsize=(9, 5))
colors = ['#2E75B6' if s != 'WI' else '#BF4D28' for s in comp2['state']]
ax.barh(comp2['state'], comp2['vol_pc'], color=colors, height=0.6)
ax.set_xlabel('Under-$100K Loan Volume per 10,000 Residents ($)')
ax.set_title('Figure 13b: Small Business Lending Volume per 10K Residents\n(Midwest Comparison, 2023)')
for i, (v, s) in enumerate(zip(comp2['vol_pc'].values, comp2['state'].values)):
    ax.text(v + 500, i, f'${v:,.0f}', va='center', fontsize=9)
ax.set_xlim(0, comp2['vol_pc'].max() * 1.15)
fig.text(0.99, 0.01, 'Data: CRA & Census Bureau', ha='right', va='bottom', fontsize=8, color='gray')
plt.tight_layout()
outpath = os.path.join(FIG_DIR, 'fig13b_regional_volume_per_10k.png')
plt.savefig(outpath, dpi=300, bbox_inches='tight')
plt.close()
print(f"Saved → {outpath}")
