# Harmonize CDFI Lending Releases Into a Reusable Intermediate

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan must be maintained in accordance with `agent-docs/PLANS.md`.

This is the upstream CDFI ingest plan. It exists to resolve raw-file contracts before the descriptive workbook is built. The downstream consumer is `agent-docs/execplans/2026_05_28_CDFI.md`.

## Purpose / Big Picture

After this change, a contributor will be able to run a reproducible CDFI ingest step that reads the staged lending-release files, harmonizes their schema differences, records field completeness, and writes a reusable cleaned intermediate under `2_processed_data`. That cleaned intermediate will let later figure work proceed without repeatedly re-solving raw column-name changes, geography parsing, or sample-definition ambiguity inside notebooks.

The visible outcome is a validated transaction-level artifact at `2_processed_data/cdfi_tlr_harmonized.rds`, a field-completeness audit at `2_processed_data/cdfi_field_coverage_by_year.csv`, and a plain-text sidecar at `2_processed_data/cdfi_tlr_harmonization_notes.txt` that documents the harmonization steps and field-mapping decisions. For this first pass, the staged `2023` NMTC workbook is explicitly excluded.

## Progress

- [x] (2026-05-28 16:26Z) Read `agent-docs/PLANS.md` and converted the original rough CDFI note into ExecPlan form.
- [x] (2026-05-28 16:26Z) Inspected the staged CDFI folders under `0_inputs/2017_CDFI`, `0_inputs/2018_CDFI`, `0_inputs/2019_CDFI`, `0_inputs/2020_CDFI`, `0_inputs/2021_CDFI`, `0_inputs/2022_CDFI`, and `0_inputs/2024_CDFI_NMTC_Release`.
- [x] (2026-05-28 16:26Z) Inspected representative raw headers from the older `TLR`, `CLR`, `ILR`, and `NMTC` files.
- [x] (2026-05-28 16:26Z) Confirmed that `2_processed_data/labor_force_county.rds` exists for later county-normalized work, but kept that denominator logic out of the ingest contract itself.
- [x] (2026-05-28 16:26Z) Read `agent-docs/agent_context/docs/draft_es_cdfi.docx` and extracted the implied sample and output expectations that the ingest step needs to support.
- [x] (2026-05-28 16:26Z) Split the original combined CDFI plan into this ingest plan and the downstream descriptive plan at `agent-docs/execplans/2026_05_28_CDFI.md`.
- [x] (2026-05-28 16:26Z) Confirmed that the historical `ILR` extract carries explicit `fiscalyear` values from `2003` through `2015`, while the historical `TLR` extract is pooled across years and does not expose a clean `fiscalyear` header field.
- [ ] Implement the harmonization step and write `2_processed_data/cdfi_tlr_harmonized.rds`.
- [ ] Write `2_processed_data/cdfi_field_coverage_by_year.csv`.
- [ ] Write `2_processed_data/cdfi_tlr_harmonization_notes.txt`.

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

- Decision: Assume `/usr/local/bin/Rscript` for any scripted validation described in this plan.
  Rationale: the environment-default `Rscript` is broken here and would make the plan fail for a novice.
  Date/Author: 2026-05-28 / Codex

## Outcomes & Retrospective

The planning outcome is now cleaner. This plan isolates the raw harmonization problem and makes the descriptive workbook depend on a documented cleaned-data contract rather than informal notebook-side parsing.

The remaining substantive choice is narrower now: whether the first-pass cleaned sample is explicitly business-only. The `2023` NMTC question has been removed from first-pass scope by user instruction.

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
- At minimum, preserve harmonized fields for source release, canonical year, `org_id`, `trans_id`, original transaction amount, raw geography code, derived state FIPS, derived county FIPS when present, investee type, purpose, transaction type, and any industry field that can support sector work.
- Preserve enough provenance to distinguish the `historical 2003-2015 extract` from the `2018-2022 annual files`.
- Include one canonical annual field in the cleaned file even though the historical `TLR` raw files do not expose a clean `fiscalyear` header column. The sidecar notes file must document exactly how that year field was derived for the historical records.
- The cleaned file may contain both an all-records sample and a downstream business-sample flag, but the plan must settle which field defines the default business-only subset if that is the chosen contract.

Operational contract for `2_processed_data/cdfi_field_coverage_by_year.csv`:

- One row per canonical year.
- At minimum, report total rows, share with usable amount, share with usable raw geography, share with usable county FIPS, share with non-missing investee type, share with business investee type if defined, and share with usable industry field.
- Include a note or flag if any year comes from a structurally distinct source family that should not be pooled without caution.

Expected first-pass comparable series:

- `2003-2022` from the older lending-release family.

## Plan of Work

Implementation should proceed in four milestones.

### Milestone 1: Inventory and harmonize the comparable older lending releases

Read the older `TLR` files and map their differing raw column names onto one canonical schema. This is the core deliverable. The implementer must explicitly reconcile differences such as `fiscalyear` versus `tlr_submission_year__c`, `originalamount` versus `original_loan_investment_amount_`, and `projectfipscode_2010` versus `fipscode_2010`.

The canonical schema should keep both the harmonized columns and enough raw provenance to audit the mapping later. Parse the raw FIPS code into derived state and county identifiers where possible, but do not discard the original geography field.

### Milestone 2: Settle sample flags and geography validity

Create explicit flags rather than silently filtering during ingest. At minimum define:

- whether the row qualifies as business lending under the raw investee-type field,
- whether the geography is valid at the state level,
- whether the geography is valid at the county level,
- whether the amount field is usable,
- whether the industry field is usable.

If the implementer decides to write only one cleaned artifact, those flags must still be included so the descriptive notebook can subset reproducibly.

### Milestone 3: Write the cleaned intermediate and the coverage audit

Write `2_processed_data/cdfi_tlr_harmonized.rds` and `2_processed_data/cdfi_field_coverage_by_year.csv`. The coverage audit is not optional. It is the mechanism that tells later contributors which figure families are defensible.

The output write should be non-destructive by default. If the canonical filename already exists and overwriting has not been explicitly approved, write `_TEMP` variants first and compare them before replacing anything.

### Milestone 4: Write the reproducibility sidecar

Write `2_processed_data/cdfi_tlr_harmonization_notes.txt` as a plain-text summary of the harmonization workflow. At minimum it must document which raw files were read, how the historical and annual schemas were matched, how the canonical year field was constructed for the historical `TLR` records, which business-sample rule was used, and which first-pass exclusions were applied.

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

    /usr/local/bin/Rscript -e 'x <- readRDS("2_processed_data/cdfi_tlr_harmonized.rds"); cat(min(x$analysis_year, na.rm = TRUE), max(x$analysis_year, na.rm = TRUE), "\n")'

    /usr/local/bin/Rscript -e 'x <- read.csv("2_processed_data/cdfi_field_coverage_by_year.csv"); print(head(x))'

    sed -n '1,80p' 2_processed_data/cdfi_tlr_harmonization_notes.txt

Expected short transcript excerpt:

    2003 2022
    <head of coverage audit prints without error>

The exact canonical year column may differ if documented, but this plan expects one harmonized annual field that can drive downstream aggregations.

## Validation and Acceptance

Acceptance criteria:

1. `2_processed_data/cdfi_tlr_harmonized.rds` exists and is readable.
2. `2_processed_data/cdfi_field_coverage_by_year.csv` exists and is readable.
3. `2_processed_data/cdfi_tlr_harmonization_notes.txt` exists and is readable.
4. The cleaned intermediate preserves one row per harmonized transaction-level record from the older comparable release family.
5. The cleaned intermediate includes explicit flags or fields that allow the downstream notebook to define a business-only sample and a usable-geography sample reproducibly.

Sanity checks:

- The harmonized file should begin in `2003` and reach at least `2022`.
- `org_id`, `trans_id`, amount, and canonical year should not disappear during harmonization.
- Geography parsing should preserve the raw field and create derived state and county identifiers where possible.
- The coverage audit should show year-by-year completeness rather than only one overall aggregate.
- The harmonization notes sidecar should state plainly that `2023` NMTC was excluded from first-pass scope.

## Idempotence and Recovery

The harmonization workflow should be deterministic given unchanged raw files. Re-running it should reproduce the same cleaned outputs.

If a raw field mapping is ambiguous, do not guess silently. Record the ambiguity in this plan, preserve the raw field in the cleaned output if feasible, and choose the narrowest defensible harmonized mapping.

If the historical `TLR` year-derivation rule proves messier than expected, the safe recovery path is to preserve the raw date fields, document the exact fallback rule in the sidecar note, and avoid pretending the annual field was observed directly in the raw file.

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
