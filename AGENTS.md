# AGENTS.md

## Project Purpose
Construct and maintain a reproducible data pipeline to assemble, clean, and visualize Wisconsin-focused small business finance data.  
The goal is to generate analysis-ready datasets and figures that are *consistent in structure and scope* with the reference CORI report stored in `agent-docs/agent_context/CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf`.  
This document constrains implementation and workflow; it does not authorize interpretive analysis, estimator choice, or scope expansion unless explicitly requested.

## Working Directory
- Project root: this repository.
- Data may live on a mounted disk referenced by `input_root.txt`; prefer this mechanism when running scripts.

## Environment
- R scripts are primary (e.g., `1_code/1_0_ingest/CORI_formd.R`).
- Do not introduce Python or other languages unless explicitly requested.
- Avoid network calls unless explicitly instructed; assume required data are already present locally unless told otherwise.

## Pathing Rules
- Do not hardcode user-specific paths unless asked.
- Prefer `input_root.txt` and repository-relative paths.
- If a script already uses hardcoded paths, document this behavior instead of refactoring unless explicitly requested.

## Pipeline Order (High-Level)
1. Ingest CORI Form D data and HUD crosswalk using `1_code/1_0_ingest/CORI_formd.R`.
2. Clean issuers and offerings; join on accession/year/quarter; compute incremental amounts raised.
3. Ingest Pitchbook Venture Monitor data from:
   - `0_inputs/Pitchbook/Pitchbook_dealcount.xlsx`
   - `0_inputs/Pitchbook/Pitchbook_dealvol.xlsx`
4. Incorporate SBA 7(a) and 504 FOIA data **from local copies already staged in inputs**.  
   (The public source is `https://data.sba.gov/dataset/7-a-504-foia`, but fetching from the network is not permitted unless explicitly requested.)
5. Produce Wisconsin-focused tables and visuals that align in structure, definitions, and aggregation level with the CORI reference report.

## TEMP/TEST Policy
- TEMP/TEST outputs may exist and may overwrite canonical outputs.
- Do not delete or refactor TEMP/TEST files without explicit request.
- If changes affect outputs, explicitly note which TEMP/TEST scripts may also require updates.

## Outputs
- Document every output file written by scripts, including ad hoc outputs.
- Default to non-destructive updates; do not overwrite existing outputs unless explicitly instructed.

## Documentation
- Keep README detailed and internally focused.
- Document legacy code in `1_code/legacy` in a separate README section.
- If adding new scripts, update the README with purpose, inputs, outputs, and dependencies.

## Safety
- Never run destructive git commands unless explicitly asked.
- If unexpected changes or ambiguities appear, stop and ask before proceeding.

## Communication
- Be concise and explicit about assumptions.
- Ask before writing outside the repository or making any network calls.

## Task-Specific Docs
- Task-specific routines and planning documents are contained in `agent-docs`.

./agent-docs/PLANS.md - Use this as a template in the planning phase.

./agent-docs/execplans/. - Use this subfolder to store plans we have finalized as a .md file. During the planning phase, I'll iterate on these files with you, which will then be used to execute workplans.

## README Governance and Automation Rules

Codex is authorized to update the README **only** within the boundaries defined below.  
Codex is not authorized to reinterpret project goals, redefine scope, or infer intent beyond explicit instructions.
Codex should only update the README when asked. When the README is to be updated, please follow the instruction set provided in /agent-docs/README_update_instructset.md.


## Reasoning & Scope Control
- Optimize for correctness and reproducibility over elegance.
- Do not introduce new estimators, identification strategies, variable constructions, or sample definitions unless explicitly requested.
- Never infer research intent from file names, directory structure, or reference documents.