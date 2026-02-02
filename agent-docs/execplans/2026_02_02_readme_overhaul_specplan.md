# README Template And Repository-Filled README

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan is written and must be maintained in accordance with `agent-docs/PLANS.md`.

## Purpose / Big Picture

After completing this plan, the repository will have a new, project-specific README template derived from `agent-docs/agent_context/docs/AUTHOR_DATASET_READMEtemplate.md` and best-practice dataset documentation, and the main `README.md` will be filled in by scanning the repository for the required fields. A user will be able to read `README.md` and understand the project’s data pipeline, inputs, outputs, and reproducibility requirements without referring to external documents. Success is visible by (1) the presence of a refined template section in the README (or a separate template file if chosen in the plan), and (2) a fully populated README that matches the template fields and includes concrete file paths and descriptions derived from the repo.

## Progress

- [x] (2026-02-02 00:00 local) Produce a refined README template by evaluating each field in the provided template against this project’s scope and documentation needs. Draft saved to `agent-docs/execplans/README_template_draft.md`.
- [x] (2026-02-02 00:00 local) Scan the repository and fill the refined template in `README.md`, preserving evidence and notes for any fields that cannot be populated. Backup saved to `README.2026-02-02.bak.md`.

## Surprises & Discoveries

- None yet.

## Decision Log

- Decision: Preserve the existing `README.md` by copying it to a dated backup before replacement.
  Rationale: The project instructions default to non-destructive updates, and a backup allows safe rollback while still superseding the old README.
  Date/Author: 2026-02-02 / Codex
- Decision: Override README governance restrictions for this spec so restricted sections (Funding, Reproducibility, Methodology, Access/Licensing, Project Overview) may be edited to match the approved template.
  Rationale: User granted explicit approval for this spec to supersede the restriction set in `agent-docs/README_update_instructset.md`.
  Date/Author: 2026-02-02 / Codex

## Outcomes & Retrospective

- Not started.

## Context and Orientation

The repository root contains data inputs, processing scripts, and documentation. The current README is at `README.md`. The template the user referenced is at `agent-docs/agent_context/docs/AUTHOR_DATASET_READMEtemplate.md`. The pipeline is primarily R-based, with code under `1_code/` and inputs under `0_inputs/`. The plan must avoid network access and must not introduce new estimators or changes in analytical scope. All paths should be repository-relative unless the README explicitly needs to mention `input_root.txt` as the mechanism for external data locations.

Terms used in this plan:

A “template field” is a heading or bullet from `AUTHOR_DATASET_READMEtemplate.md` that expects a project-specific value. “Refined template” means the evaluated and curated set of those fields, adapted to the project’s purpose and structure (keeping required fields, removing irrelevant ones, and adding missing fields that are necessary for reproducibility).

## Plan of Work

First, review `agent-docs/agent_context/docs/AUTHOR_DATASET_READMEtemplate.md` and evaluate each field for relevance to this repository. For each field, decide whether to keep, modify, move, or drop it. Add any missing fields needed to document a reproducible data pipeline (for example, explicit data input locations, pipeline order, output artifacts, and known constraints). Produce a refined template that is tailored to this project. The refined template should be organized into clear sections and should include guidance prompts that can be removed when filling the README.

Second, scan the repository to populate the refined template. Use fast text search and file listings to find sources of truth: existing `README.md`, `AGENTS.md`, `Data_Dict.qmd`, `1_code/` scripts, `0_inputs/` directories, and `agent-docs/` reference documents. Capture file paths, input names, output files, and script responsibilities. Replace template placeholders with concrete information. If a field cannot be populated from local evidence, mark it explicitly in the README with a TODO note and a short explanation of what is missing and where it should be found. Ensure the README does not introduce new analysis or interpretations; only document what exists and is verifiable in the repo.

Finally, replace `README.md` with the filled-in content and keep a backup copy of the original README. Ensure the resulting README remains internally focused, includes a section for legacy code under `1_code/legacy`, and documents outputs and TEMP/TEST scripts where relevant.

## Concrete Steps

1. Review template and current README.

   Working directory: `/Users/indermajumdar/Research/Rural_Banking`

   Commands:

     rg --files
     cat agent-docs/agent_context/docs/AUTHOR_DATASET_READMEtemplate.md
     cat README.md

   Expected outcome: a clear list of template fields and the current README content.

2. Draft the refined template and stage it in a temporary file for review (for example `agent-docs/execplans/README_template_draft.md`).

   Commands:

     cat <<'EOF' > agent-docs/execplans/README_template_draft.md
     [template content]
     EOF

   Expected outcome: a refined template draft with placeholders and instructions.

3. Scan the repository to fill the template.

   Commands (examples, adjust as needed):

     rg -n "input_root" -S
     rg -n "TEMP|TEST" -S
     rg -n "output|write" 1_code
     rg --files 0_inputs 1_code 2_processed_data agent-docs
     rg -n "legacy" 1_code

   Expected outcome: collected evidence for inputs, outputs, pipeline steps, and legacy code documentation.

4. Back up the existing README and write the filled template to `README.md`.

   Commands:

     cp README.md README.2026-02-02.bak.md
     cat <<'EOF' > README.md
     [filled template content]
     EOF

   Expected outcome: the README is replaced with populated content and the old README remains available in a dated backup.

## Validation and Acceptance

Run no scripts by default. Validation is documentation-based.

Acceptance criteria:

- `README.md` follows the refined template structure and contains project-specific content.
- All references to inputs, scripts, and outputs use repository-relative paths, and align with actual files.
- A legacy section exists that describes `1_code/legacy` per project documentation rules.
- Any unfilled fields are explicitly marked with TODO notes that describe what evidence is missing.
- The prior README is preserved as `README.2026-02-02.bak.md`.

Sanity checks:

- Spot-check at least three referenced files in the README and confirm they exist.
- Confirm any described outputs in `2_processed_data/` (or other output directories) exist or are clearly labeled as expected outputs.
- Confirm the pipeline order in README is consistent with `AGENTS.md`.

## Idempotence and Recovery

The steps are safe to re-run. If the README content needs revision, re-run the edit step and overwrite `README.md` again. If the backup already exists, either keep the first backup and create a new dated backup, or explicitly document that the backup was updated. If errors are found, restore the backup by copying it back to `README.md` and re-apply changes.

## Artifacts and Notes

Keep short snippets of evidence (file paths and brief excerpts) in the working notes during execution to justify README statements. Do not embed large transcripts in the README itself.


Update Note: Initial plan created to scope the README template refinement and repository scan/update workflow. 2026-02-02 / Codex
Update Note: Marked Task 1 complete and recorded draft template location after creating `agent-docs/execplans/README_template_draft.md`. 2026-02-02 / Codex
Update Note: Marked Task 2 complete after populating `README.md` from repository scan and creating `README.2026-02-02.bak.md`. 2026-02-02 / Codex
