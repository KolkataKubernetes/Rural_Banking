# Harmonize CDFI Lending Releases Into a Reusable Intermediate

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

This is the upstream CDFI ingest plan. It exists to resolve raw-file contracts before the descriptive workbook is built. The downstream consumer is `agent-docs/execplans/2026_05_28_CDFI.md`.

## Purpose / Big Picture

After this change, a contributor will be able to run a reproducible CDFI ingest step that reads the staged lending-release files, harmonizes their schema differences, records field completeness, and writes a reusable cleaned intermediate under `2_processed_data`. That cleaned intermediate will let later figure work proceed without repeatedly re-solving raw column-name changes, geography parsing, sample-definition ambiguity, or year-assignment ambiguity inside notebooks.

The visible outcome is a validated transaction-level artifact at `2_processed_data/cdfi_tlr_harmonized.rds`, a field-completeness audit at `2_processed_data/cdfi_field_coverage_by_year.csv`, and a plain-text sidecar at `2_processed_data/cdfi_tlr_harmonization_notes.txt` that documents the harmonization steps and field-mapping decisions. The revised year-assignment goal is to add a `cdfi_fiscal_year` field built from a combined `ILR` + `TLR` rule rather than relying only on the first-pass date-first `analysis_year`. For this first pass, the staged `2023` NMTC workbook is explicitly excluded.

## Progress

- [x] (2026-05-28 16:26Z) Read `agent-docs/PLANS.md` and converted the original rough CDFI note into ExecPlan form.
- [x] (2026-05-28 16:26Z) Inspected the staged CDFI folders under `0_inputs/2017_CDFI`, `0_inputs/2018_CDFI`, `0_inputs/2019_CDFI`, `0_inputs/2020_CDFI`, `0_inputs/2021_CDFI`, `0_inputs/2022_CDFI`, and `0_inputs/2024_CDFI_NMTC_Release`.
- [x] (2026-05-28 16:26Z) Inspected representative raw headers from the older `TLR`, `CLR`, `ILR`, and `NMTC` files.
- [x] (2026-05-28 16:26Z) Confirmed that `2_processed_data/labor_force_county.rds` exists for later county-normalized work, but kept that denominator logic out of the ingest contract itself.
- [x] (2026-05-28 16:26Z) Read `agent-docs/agent_context/docs/draft_es_cdfi.docx` and extracted the implied sample and output expectations that the ingest step needs to support.
- [x] (2026-05-28 16:26Z) Split the original combined CDFI plan into this ingest plan and the downstream descriptive plan at `agent-docs/execplans/2026_05_28_CDFI.md`.
- [x] (2026-05-28 16:26Z) Confirmed that the historical `ILR` extract carries explicit `fiscalyear` values from `2003` through `2015`, while the historical `TLR` extract is pooled across years and does not expose a clean `fiscalyear` header field.
- [x] (2026-05-28 18:06Z) Implemented `1_code/1_1_transform/1_1_1_cdfi_tlr_harmonize.R` to read the historical and annual TLR releases, harmonize core fields, derive geography, and construct the first-pass comparable series.
- [x] (2026-05-28 18:06Z) Wrote `2_processed_data/cdfi_tlr_harmonized.rds` with 2,438,107 harmonized rows and 2,434,209 distinct event keys spanning `2003-2022`.
- [x] (2026-05-28 18:06Z) Wrote `2_processed_data/cdfi_field_coverage_by_year.csv`.
- [x] (2026-05-28 18:06Z) Wrote `2_processed_data/cdfi_tlr_harmonization_notes.txt`.
- [x] (2026-05-28 18:06Z) Validated that the first-pass output excludes the staged `2023` NMTC workbook and that the harmonization notes sidecar documents the implemented rules.
- [x] (2026-05-29 11:47Z) Re-read the historical CIIS documentation and confirmed that CDFI publication logic treated loan origination dates in fiscal-year terms rather than plain calendar-year terms.
- [x] (2026-05-29 12:23Z) Revised the ingest contract so the cleaned artifact design now includes a `cdfi_fiscal_year` field and preserves `analysis_year` for comparison.
- [x] (2026-05-29 12:58Z) Updated `1_code/1_1_transform/1_1_1_cdfi_tlr_harmonize.R` to document and construct the revised fiscal-year field.
- [x] (2026-05-29 13:15Z) Wrote non-destructive TEMP comparison artifacts: `2_processed_data/cdfi_tlr_harmonized_TEMP.rds`, `2_processed_data/cdfi_field_coverage_by_year_TEMP.csv`, and `2_processed_data/cdfi_tlr_harmonization_notes_TEMP.txt`.
- [x] (2026-05-29 13:19Z) Compared `analysis_year`, `cdfi_fiscal_year`, and a memo-style `report_year - 1` comparison rule against Wisconsin statewide memo benchmarks.

## Surprises & Discoveries

- Observation: The yearly CDFI folders are not one uniform release family.
  Evidence: `2017_CDFI` contains split historical `TLR` files and one `ILR` file; `2018_CDFI` through `2022_CDFI` contain annual `TLR` and `CLR` files; `2024_CDFI_NMTC_Release` contains an Excel workbook with NMTC-style project sheets rather than the older lending-release layout.

- Observation: The older `TLR` files appear to be the best backbone for a reusable small-business-finance intermediate.
  Evidence: representative headers from `releaseTLR_fy18.csv` and `tlr_fy22_release.csv` include transaction identifiers, annual fields, raw geography, original amount, investee type, purpose, and transaction type.

- Observation: The historical institution-level extract is explicitly year-coded, but the historical transaction-level extract is not split into yearly files and does not expose a clean annual field in the header.
  Evidence: `releaseILR_fy03_15(1of1).csv` includes `fiscalyear` values from `2003` through `2015`; `releaseTLR_fy03_15(1of5).csv` is a pooled historical transaction file whose header includes `dateclosed` but no `fiscalyear` field.

- Observation: The draft memo strongly implies that a business-lending subset will be needed downstream.
  Evidence: `agent-docs/agent_context/docs/draft_es_cdfi.docx` repeatedly defines the CDFI section using business loans and specifically references investee type `BUS`.

- Observation: The default `Rscript` is not reliable in this environment.
  Evidence: direct `Rscript -e ...` calls failed with a missing `libreadline.6.2.dylib`, while `/usr/local/bin/Rscript -e ...` worked.

- Observation: Many raw project FIPS values were exported without a leading zero, so geography cannot be derived safely without padding.
  Evidence: in `releaseTLR_fy18.csv`, 32,657 non-missing `projectfipscode_2010` values had length `10` rather than `11`; the harmonization script restores those tract-like codes by left-padding to width `11`.

- Observation: `org_id + trans_id` alone is not a stable cross-file transaction key.
  Evidence: inspection across the annual TLR releases showed repeated `org_id + trans_id` pairs that differ by report year, amount, and geography; the implemented event key therefore uses `report_year + org_id + trans_id` when report year is available.

- Observation: The cleaned first-pass series has no `2016` rows after the documented year-construction and filtering rules.
  Evidence: `2_processed_data/cdfi_field_coverage_by_year.csv` runs from `2003` through `2015`, then resumes at `2017`; no `2016` row appears in the coverage audit.

- Observation: The `2021` and `2022`-era rows rely heavily on report-year fallback because transaction dates are frequently missing in the later releases.
  Evidence: `share_analysis_year_from_report_fallback` is `0.7294` for `analysis_year = 2021` and `0.7997` for `analysis_year = 2022` in `2_processed_data/cdfi_field_coverage_by_year.csv`.

- Observation: The historical CIIS documentation describes loan origination timing in fiscal-year terms, not just in calendar-year terms derived from `dateclosed`.
  Evidence: `0_inputs/2017_CDFI/CDFI CIIS Data Documentation15.docx` states that `dateclosed` should be cleaned with `P&A#7` and `P&A#9`, blanked when it occurs after the reporting fiscal year, and converted to fiscal years closed based on each CDFI's fiscal year end.

- Observation: The public historical `TLR` extract does not preserve the `fiscalyear` field needed to apply the CIIS fiscal-year rule directly from transaction data alone.
  Evidence: the historical `TLR` header exposes `dateclosed` but no `fiscalyear`, while the historical `ILR` extract does carry `fiscalyear` and can therefore serve as the institutional-year bridge input.

- Observation: The public historical `ILR` extract does not actually preserve the `reportYearEnd` field needed for an exact organization-specific fiscal-year-end bridge.
  Evidence: the CIIS documentation references `reportYearEnd`, but the staged public `releaseILR_fy03_15(1of1).csv` header does not include a `reportYearEnd` column.

- Observation: A best-feasible `cdfi_fiscal_year` proxy can still be created from the preserved fields by using `report_year` where observed and falling back to historical `transaction_year`.
  Evidence: the first-pass harmonized RDS already preserves `report_year`, `transaction_year`, `analysis_year`, and `source_family`, which are sufficient to build TEMP comparison artifacts without re-solving raw schema issues.

- Observation: The revised `cdfi_fiscal_year` proxy does not improve year coverage.
  Evidence: both `cdfi_field_coverage_by_year.csv` and `cdfi_field_coverage_by_year_TEMP.csv` span the same years: `2003-2015`, then `2017-2022`, with no `2016`.

- Observation: The revised `cdfi_fiscal_year` proxy improves post-2017 fiscal-year timing consistency, but it does not get Wisconsin closer to the memo's labeled `2017` figure.
  Evidence: under `cdfi_fiscal_year`, Wisconsin business lending remains only `5.5` loans and about `$0.12M` in `2017`, while `2018` becomes about `1,142` loans and `$151.8M`; the memo's published `2017` target is `1,172` loans and `$156M`.

## Decision Log

- Decision: Split the original combined CDFI planning work into a dedicated ingest plan and a dedicated descriptive notebook plan.
  Rationale: schema harmonization, sample definition, and comparability decisions are upstream data-contract tasks and should not be repeatedly reinterpreted inside the notebook.
  Date/Author: 2026-05-28 / User + Codex

- Decision: Use the older `TLR` family as the canonical first-pass ingest target.
  Rationale: those files support the broadest set of requested figures and appear to provide the key fields needed for transaction counts, dollar totals, average size, and geography-based summaries.
  Date/Author: 2026-05-28 / Codex

- Decision: Treat `CLR` and `ILR` as supporting audit inputs rather than the primary cleaned artifact source.
  Rationale: the downstream workbook mostly needs transaction-level flexibility; `CLR` and `ILR` are useful for validation or special cases but should not define the main reusable intermediate unless a blocking issue appears in `TLR`.
  Date/Author: 2026-05-28 / Codex

- Decision: Exclude the staged `2023` NMTC workbook from the first-pass ingest scope.
  Rationale: the user explicitly asked not to spend time litigating whether the NMTC format can be converted to match the incumbent lending-release backbone.
  Date/Author: 2026-05-28 / User + Codex

- Decision: Add a plain-text harmonization sidecar as a required output.
  Rationale: the user explicitly requested a separate reproducibility note that documents the harmonization steps outside the code and binary RDS output.
  Date/Author: 2026-05-28 / User + Codex

- Decision: The first-pass `analysis_year` remains preserved in the cleaned data, but it is no longer the intended endpoint for the year contract.
  Rationale: the historical CIIS documentation shows that CDFI publication logic was organized around reporting fiscal years, so a date-first calendar-year variable is useful for audit but is not the best target for memo reconciliation or final descriptive timing.
  Date/Author: 2026-05-29 / User + Codex

- Decision: Revise the ingest target so the cleaned artifact includes a derived `cdfi_fiscal_year` field built from combined `ILR` + `TLR` logic, and treat that field as the preferred downstream year variable once validated.
  Rationale: `ILR` preserves explicit institution-year fiscal reporting, while `TLR` preserves transaction dates and detail. Combining them is the most defensible path toward the CIIS-style fiscal-year timing described in the documentation and should improve treatment of the `2016-2017` gap.
  Date/Author: 2026-05-29 / User + Codex

- Decision: Keep the canonical processed outputs unchanged for now and evaluate the revised fiscal-year logic through TEMP artifacts first.
  Rationale: the user asked to test whether the revised year logic improves coverage and memo alignment, and the non-destructive TEMP comparison shows that it does not yet justify replacing the current backbone.
  Date/Author: 2026-05-29 / Codex

- Decision: Normalize 10-digit tract-like geography codes to 11 digits by left-padding before deriving state and county FIPS.
  Rationale: the raw project FIPS exports drop leading zeros for some states, and geography parsing would otherwise assign incorrect state and county identifiers.
  Date/Author: 2026-05-28 / Codex

- Decision: Define transaction events with `report_year + org_id + trans_id` when report year exists, and use `analysis_year + org_id + trans_id` only for historical rows that lack report year.
  Rationale: `org_id + trans_id` pairs are reused across report years in the annual releases, so a report-year-aware key is required to avoid conflating distinct events.
  Date/Author: 2026-05-28 / Codex

- Decision: Preserve multi-geography rows and add equal-split allocation weights for state and county aggregation instead of collapsing them away during ingest.
  Rationale: some event keys appear on multiple geography rows within the same event; retaining those rows plus transparent allocation weights is safer than hard-coding one geography choice at ingest time.
  Date/Author: 2026-05-28 / Codex

- Decision: Assume `/usr/local/bin/Rscript` for any scripted validation described in this plan.
  Rationale: the environment-default `Rscript` is broken here and would make the plan fail for a novice.
  Date/Author: 2026-05-28 / Codex

## Outcomes & Retrospective

The planning outcome is now cleaner. This plan isolates the raw harmonization problem and makes the descriptive workbook depend on a documented cleaned-data contract rather than informal notebook-side parsing.

Implementation is complete for the first-pass ingest, but the year-assignment contract is now being revised. The current script `1_code/1_1_transform/1_1_1_cdfi_tlr_harmonize.R` writes three outputs under `2_processed_data`: `cdfi_tlr_harmonized.rds`, `cdfi_field_coverage_by_year.csv`, and `cdfi_tlr_harmonization_notes.txt`. The current harmonized RDS contains 2,438,107 rows and 41 columns, spans `2003-2022`, and carries explicit business, amount, geography, and allocation flags for downstream descriptive work, but its first-pass `analysis_year` should now be treated as an interim audit variable rather than the final intended timing field.

The revised test is now complete. The TEMP comparison artifacts show that the best-feasible `cdfi_fiscal_year` proxy is useful as an audit field, but it does not repair the missing `2016` and it does not improve alignment with the memo's labeled `2017` Wisconsin series. The `2023` NMTC question remains out of first-pass scope by user instruction.

The clearest empirical result is that the memo still aligns much better with a separate comparison-only `memo_year = report_year - 1` convention for the annual files than with the revised fiscal-year proxy. For Wisconsin business lending, the TEMP comparison gives:

- `analysis_year`, `2017`: about `5.5` loans and `$0.12M`
- `cdfi_fiscal_year`, `2017`: about `5.5` loans and `$0.12M`
- `memo_year` comparison, `2017`: about `1,142` loans and `$151.8M`

That last line remains the closest to the memo's published `2017` benchmark of roughly `1,172` loans and `$156M`, but it is a comparison convention rather than a literal fiscal-year field.

## Context and Orientation

This repository already separates ingest, transformation, and visualization work. The CDFI task should follow that structure. The raw staged files live under `0_inputs`, while this plan’s outputs belong in `2_processed_data` for later reuse.

The staged CDFI files fall into four relevant labels:

- `TLR` means transaction-level release. These are the key raw inputs for this ingest plan.
- `CLR` means summarized lending release. These can help check totals or support later diagnostic work.
- `ILR` means institution-level release. The historical `2017_CDFI` folder includes one such file.
- `NMTC` means New Markets Tax Credit. The staged `2024_CDFI_NMTC_Release` workbook appears to represent a different reporting system than the earlier lending releases and is intentionally excluded from this first-pass ingest.

The downstream descriptive plan is `agent-docs/execplans/2026_05_28_CDFI.md`. That notebook must read this plan’s cleaned outputs rather than directly harmonizing raw releases inline.

## Data Contracts, Inputs, and Dependencies

Primary software dependencies:

- R packages already common in this repo: `tidyverse`, `readxl`, and `readr`.
- `/usr/local/bin/Rscript` for validation.

Primary raw inputs for the first-pass harmonized intermediate:

- `0_inputs/2017_CDFI/releaseTLR_fy03_15(1of5).csv`
- `0_inputs/2017_CDFI/releaseTLR_fy03_15(2of5).csv`
- `0_inputs/2017_CDFI/releaseTLR_fy03_15(3of5).csv`
- `0_inputs/2017_CDFI/releaseTLR_fy03_15(4of5).csv`
- `0_inputs/2017_CDFI/releaseTLR_fy03_15(5of5).csv`
- `0_inputs/2018_CDFI/releaseTLR_fy18.csv`
- `0_inputs/2019_CDFI/releaseTLR_fy19.csv`
- `0_inputs/2020_CDFI/releaseTLR_fy20.csv`
- `0_inputs/2021_CDFI/releaseTLR_fy21.csv`
- `0_inputs/2022_CDFI/tlr_fy22_release.csv`

Secondary raw inputs for audit or comparability checks:

- `0_inputs/2017_CDFI/releaseILR_fy03_15(1of1).csv`
- `0_inputs/2018_CDFI/releaseCLR_fy18.csv`
- `0_inputs/2019_CDFI/releaseCLR_fy19.csv`
- `0_inputs/2020_CDFI/releaseCLR_fy20.csv`
- `0_inputs/2021_CDFI/releaseCLR_fy21.csv`
- `0_inputs/2022_CDFI/clr_fy22_release.csv`

Required outputs:

- `2_processed_data/cdfi_tlr_harmonized.rds`
- `2_processed_data/cdfi_field_coverage_by_year.csv`
- `2_processed_data/cdfi_tlr_harmonization_notes.txt`

Operational contract for `2_processed_data/cdfi_tlr_harmonized.rds`:

- One row per harmonized transaction-level record from the comparable older CDFI lending-release family.
- At minimum, preserve harmonized fields for source release, `transaction_year`, `report_year`, `analysis_year`, derived `cdfi_fiscal_year`, `org_id`, `trans_id`, original transaction amount, raw geography code, derived state FIPS, derived county FIPS when present, investee type, purpose, transaction type, and any industry field that can support sector work.
- Preserve enough provenance to distinguish the `historical 2003-2015 extract` from the `2018-2022 annual files`.
- Include one preferred downstream annual field in the cleaned file even though the historical `TLR` raw files do not expose a clean `fiscalyear` header column. The revised preferred field should be `cdfi_fiscal_year` if implementation succeeds; the sidecar notes file must document exactly how that field was derived for the historical and annual records.
- The cleaned file may contain both an all-records sample and a downstream business-sample flag, but the plan must settle which field defines the default business-only subset if that is the chosen contract.

Operational contract for `2_processed_data/cdfi_field_coverage_by_year.csv`:

- One row per preferred downstream year, plus enough supporting fields or notes to audit how the counts change under alternative year rules.
- At minimum, report total rows, share with usable amount, share with usable raw geography, share with usable county FIPS, share with non-missing investee type, share with business investee type if defined, and share with usable industry field.
- Include a note or flag if any year comes from a structurally distinct source family that should not be pooled without caution.

Expected revised comparable series:

- `2003-2022` from the older lending-release family, with explicit re-audit of `2016-2017` once `cdfi_fiscal_year` is implemented.

## Plan of Work

Implementation should proceed in four milestones.

### Milestone 1: Inventory and harmonize the comparable older lending releases

Read the older `TLR` files and map their differing raw column names onto one canonical schema. This is the core deliverable. The implementer must explicitly reconcile differences such as `fiscalyear` versus `tlr_submission_year__c`, `originalamount` versus `original_loan_investment_amount_`, and `projectfipscode_2010` versus `fipscode_2010`.

The canonical schema should keep both the harmonized columns and enough raw provenance to audit the mapping later. Parse the raw FIPS code into derived state and county identifiers where possible, but do not discard the original geography field.

### Milestone 2: Build the fiscal-year bridge

Use the historical `ILR` extract as the institution-year bridge input for fiscal reporting. The implementation should recover each CDFI's fiscal-year context from `ILR`, then use that context plus `TLR` `dateclosed` to derive a `cdfi_fiscal_year` field that more closely follows the CIIS publication rule than plain calendar-year assignment.

At minimum, the implementation should:

- preserve the raw `dateclosed`-based `transaction_year`,
- preserve annual `report_year` where observed,
- derive `cdfi_fiscal_year` with a documented bridge rule,
- retain first-pass `analysis_year` for comparison,
- and write notes about any unresolved edge cases, especially whether `2016` remains absent after the revised rule.

### Milestone 3: Settle sample flags and geography validity

Create explicit flags rather than silently filtering during ingest. At minimum define:

- whether the row qualifies as business lending under the raw investee-type field,
- whether the geography is valid at the state level,
- whether the geography is valid at the county level,
- whether the amount field is usable,
- whether the industry field is usable.

If the implementer decides to write only one cleaned artifact, those flags must still be included so the descriptive notebook can subset reproducibly.

### Milestone 4: Write the cleaned intermediate and the coverage audit

Write `2_processed_data/cdfi_tlr_harmonized.rds` and `2_processed_data/cdfi_field_coverage_by_year.csv`. The coverage audit is not optional. It is the mechanism that tells later contributors which figure families are defensible.

The output write should be non-destructive by default. If the canonical filename already exists and overwriting has not been explicitly approved, write `_TEMP` variants first and compare them before replacing anything.

### Milestone 5: Write the reproducibility sidecar

Write `2_processed_data/cdfi_tlr_harmonization_notes.txt` as a plain-text summary of the harmonization workflow. At minimum it must document which raw files were read, how the historical and annual schemas were matched, how `cdfi_fiscal_year` was constructed for the historical and annual records, how that field differs from `transaction_year`, `report_year`, and `analysis_year`, which business-sample rule was used, and which first-pass exclusions were applied.

## Concrete Steps

Run all commands from the repository root: `/Users/indermajumdar/Research/Rural_Banking`.

1. Implement the harmonization step and write the cleaned outputs:

    /usr/local/bin/Rscript <cdfi ingest entrypoint>

The exact implementation path may be chosen during execution, but the required outputs are:

    2_processed_data/cdfi_tlr_harmonized.rds
    2_processed_data/cdfi_field_coverage_by_year.csv
    2_processed_data/cdfi_tlr_harmonization_notes.txt

2. Validate the cleaned intermediate shape:

    /usr/local/bin/Rscript -e 'x <- readRDS("2_processed_data/cdfi_tlr_harmonized.rds"); cat(nrow(x), "\n"); cat(paste(names(x), collapse = "\n"), "\n")'

3. Validate the year coverage and audit file:

    /usr/local/bin/Rscript -e 'x <- readRDS("2_processed_data/cdfi_tlr_harmonized.rds"); cat(min(x$cdfi_fiscal_year, na.rm = TRUE), max(x$cdfi_fiscal_year, na.rm = TRUE), "\n")'

    /usr/local/bin/Rscript -e 'x <- readRDS("2_processed_data/cdfi_tlr_harmonized.rds"); print(with(x, table(cdfi_fiscal_year, analysis_year, useNA = "ifany"))[as.character(2015:2018), as.character(2015:2018), drop = FALSE])'

    /usr/local/bin/Rscript -e 'x <- read.csv("2_processed_data/cdfi_field_coverage_by_year.csv"); print(head(x))'

    sed -n '1,80p' 2_processed_data/cdfi_tlr_harmonization_notes.txt

Expected short transcript excerpt:

    2003 2022
    <2015-2018 comparison prints without error>
    <head of coverage audit prints without error>

The exact preferred year field may still require final validation, but this plan now expects `cdfi_fiscal_year` to be present and documented as the leading downstream year candidate.

## Validation and Acceptance

Acceptance criteria:

1. `2_processed_data/cdfi_tlr_harmonized.rds` exists and is readable.
2. `2_processed_data/cdfi_field_coverage_by_year.csv` exists and is readable.
3. `2_processed_data/cdfi_tlr_harmonization_notes.txt` exists and is readable.
4. The cleaned intermediate preserves one row per harmonized transaction-level record from the older comparable release family.
5. The cleaned intermediate includes explicit flags or fields that allow the downstream notebook to define a business-only sample and a usable-geography sample reproducibly.
6. The cleaned intermediate includes `cdfi_fiscal_year`, `transaction_year`, `report_year`, and `analysis_year`, with sidecar documentation explaining how they differ and which one is preferred downstream.

Sanity checks:

- The harmonized file should begin in `2003` and reach at least `2022`.
- `org_id`, `trans_id`, amount, and the year fields should not disappear during harmonization.
- Geography parsing should preserve the raw field and create derived state and county identifiers where possible.
- The coverage audit should show year-by-year completeness rather than only one overall aggregate.
- The harmonization notes sidecar should state plainly that `2023` NMTC was excluded from first-pass scope.
- The notes sidecar should state plainly whether the revised `cdfi_fiscal_year` rule improves the `2016-2017` gap and what unresolved ambiguity remains.

## Idempotence and Recovery

The harmonization workflow should be deterministic given unchanged raw files. Re-running it should reproduce the same cleaned outputs.

If a raw field mapping is ambiguous, do not guess silently. Record the ambiguity in this plan, preserve the raw field in the cleaned output if feasible, and choose the narrowest defensible harmonized mapping.

If the historical `TLR` fiscal-year bridge proves messier than expected, the safe recovery path is to preserve the raw date fields, preserve the first-pass `analysis_year`, document the exact bridge failure points in the sidecar note, and avoid pretending the preferred annual field was observed directly in the raw file.

## Artifacts and Notes

Files most relevant to this plan:

- `agent-docs/execplans/2026_05_28_CDFI_ingest.md`
- `agent-docs/execplans/2026_05_28_CDFI.md`
- `agent-docs/agent_context/docs/draft_es_cdfi.docx`
- `0_inputs/2017_CDFI`
- `0_inputs/2018_CDFI`
- `0_inputs/2019_CDFI`
- `0_inputs/2020_CDFI`
- `0_inputs/2021_CDFI`
- `0_inputs/2022_CDFI`

## Decision Requests

1. Should the cleaned intermediate’s default analytical sample be explicitly business-only?

Proposed default: yes. Keep all rows if useful for audit, but include a clear business-sample flag and make the downstream notebook’s default sample the business subset. This matches the small-business-finance focus of the repository and the staged CDFI memo.

Change log note: 2026-05-28 — Created a dedicated CDFI ingest ExecPlan under `agent-docs/execplans` and moved raw-schema, sample-definition, and coverage-audit responsibilities into this file. Updated first-pass scope to exclude `2023` NMTC by user instruction and added `cdfi_tlr_harmonization_notes.txt` as a required reproducibility sidecar deliverable.
