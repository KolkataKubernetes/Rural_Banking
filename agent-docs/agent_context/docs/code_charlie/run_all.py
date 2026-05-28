#!/usr/bin/env python3
"""
Master Script: Run All Figure Generation Scripts
=================================================
Executes each figure script in order and reports success/failure.

Usage:
    python run_all.py           # Run all scripts
    python run_all.py --bank    # Run only banking scripts
    python run_all.py --cu      # Run only credit union scripts

Output directory: figure_scripts/output/
"""

import os
import sys
import subprocess
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── Script registry ──────────────────────────────────────────────────────────
# Each entry: (filename, description, category)

SCRIPTS = [
    # ── Banking Figures ──────────────────────────────────────────────────────
    ("fig01_institutions_and_branches.py",
     "Fig 1: WI Banking Institutions & Branches (2000-2024)", "bank"),

    ("fig02_branch_institution_ratio.py",
     "Fig 2: Median/Mean Branches per Institution (2000-2024)", "bank"),

    ("fig02b_institution_size_distribution.py",
     "Fig 2b: Institution Size Distribution (2024)", "bank"),

    ("fig02c_top5_banks_assets.py",
     "Fig 2c: Top 5 WI-HQ Banks by Assets (2024)", "bank"),

    ("fig02d_top5_banks_branches.py",
     "Fig 2d: Top 5 Banks by WI Branch Count (2024)", "bank"),

    ("fig03_branches_per_10k_map.py",
     "Fig 3: Bank Branches per 10K Residents Map (2023)", "bank"),

    ("fig04_branch_change_map.py",
     "Fig 4: Change in Branches per 10K Map (2009-2023)", "bank"),

    ("fig05_institutions_per_10k_map.py",
     "Fig 5: Banking Institutions per 10K Map (2023)", "bank"),

    ("fig06_headquarters_map.py",
     "Fig 6: Bank Headquarters by County Map (2024)", "bank"),

    ("fig08_lending_frequency_growth.py",
     "Fig 8: Lending Frequency Growth Index (2000-2023)", "bank"),

    ("fig09_lending_volume_growth.py",
     "Fig 9: Lending Volume Growth Index (2000-2023)", "bank"),

    ("fig10_avg_loan_size.py",
     "Fig 10: Average Loan Size Under $100K (2000-2023)", "bank"),

    ("fig11_under100k_loans_map.py",
     "Fig 11: Under-$100K Loans per 10K Map (2023)", "bank"),

    ("fig12_under100k_volume_map.py",
     "Fig 12: Under-$100K Volume per Capita Map (2023)", "bank"),

    ("fig13_regional_comparison.py",
     "Fig 13: Regional Comparison (Midwest States)", "bank"),

    # ── Credit Union Figures ─────────────────────────────────────────────────
    ("fig_cu03_institutions_branches_time.py",
     "Fig CU-3: WI CU Institutions & Branches Over Time", "cu"),

    ("fig_cu04_branches_per_10k_wi_map.py",
     "Fig CU-4: CU Branches per 10K Residents Map", "cu"),

    ("fig_cu06_commercial_pct_assets.py",
     "Fig CU-6: Commercial Lending as % of Assets", "cu"),

    ("fig_cu10_avg_loan_size.py",
     "Fig CU-10: Average CU Commercial Loan Size", "cu"),

    ("fig_cu11_per_capita_lending.py",
     "Fig CU-11: Per Capita CU Commercial Lending", "cu"),
]

def run_script(filename, description):
    """Run a single script and return (success, elapsed_time, error_msg)."""
    script_path = os.path.join(SCRIPT_DIR, filename)
    if not os.path.exists(script_path):
        return False, 0, f"File not found: {filename}"

    start = time.time()
    try:
        result = subprocess.run(
            [sys.executable, script_path],
            capture_output=True, text=True, timeout=300,
            cwd=SCRIPT_DIR
        )
        elapsed = time.time() - start
        if result.returncode == 0:
            return True, elapsed, result.stdout.strip()
        else:
            return False, elapsed, result.stderr.strip()[-500:]
    except subprocess.TimeoutExpired:
        return False, 300, "TIMEOUT (>5 min)"
    except Exception as e:
        return False, time.time() - start, str(e)


def main():
    # Parse category filter
    category_filter = None
    if '--bank' in sys.argv:
        category_filter = 'bank'
    elif '--cu' in sys.argv:
        category_filter = 'cu'

    # Ensure output directory exists
    os.makedirs(os.path.join(SCRIPT_DIR, 'output'), exist_ok=True)

    scripts_to_run = [(f, d, c) for f, d, c in SCRIPTS
                      if category_filter is None or c == category_filter]

    print("=" * 70)
    print("  BANKING PROPOSAL — FIGURE GENERATION")
    print(f"  Running {len(scripts_to_run)} scripts")
    print("=" * 70)

    results = []
    for i, (filename, desc, cat) in enumerate(scripts_to_run, 1):
        tag = "BANK" if cat == "bank" else "CU  "
        print(f"\n[{i}/{len(scripts_to_run)}] [{tag}] {desc}")
        print(f"  Script: {filename}")

        success, elapsed, msg = run_script(filename, desc)
        status = "OK" if success else "FAIL"
        results.append((filename, desc, status, elapsed))

        print(f"  Status: {status} ({elapsed:.1f}s)")
        if msg:
            for line in msg.split('\n')[-3:]:
                print(f"    {line}")

    # ── Summary ──────────────────────────────────────────────────────────────
    print("\n" + "=" * 70)
    print("  SUMMARY")
    print("=" * 70)
    passed = sum(1 for _, _, s, _ in results if s == "OK")
    failed = sum(1 for _, _, s, _ in results if s == "FAIL")
    total_time = sum(t for _, _, _, t in results)

    print(f"  Passed: {passed}/{len(results)}")
    print(f"  Failed: {failed}/{len(results)}")
    print(f"  Total time: {total_time:.1f}s")

    if failed > 0:
        print("\n  Failed scripts:")
        for f, d, s, _ in results:
            if s == "FAIL":
                print(f"    - {f}: {d}")

    print(f"\n  Output directory: {os.path.join(SCRIPT_DIR, 'output')}/")
    print("=" * 70)

    return 0 if failed == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
