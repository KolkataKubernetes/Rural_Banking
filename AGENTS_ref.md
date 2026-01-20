# AGENTS.md

## Project Purpose
Farmland Preservation Program pipeline: ingest GIS and transaction data, compute treatment assignments and covariates, produce figures and inference-ready panels.

## Working Directory
- Project root: this repository.
- Data is external; paths resolve via `*_root.txt` files in `0_inputs`, `2_processed_data`, `3_outputs`, `4_db`.

## Environment
- Use conda env in `environment.yml`.
- Python + R scripts are both used.
- Avoid network calls unless explicitly requested (LSB API, Census API).

## Pathing Rules
- Do not hardcode user-specific paths when editing scripts unless asked.
- Prefer `utils/paths.py` and `*_root.txt` files for inputs/outputs.
- If a script already uses hardcoded local paths, document it instead of refactoring unless requested.

## Pipeline Order (High-Level)
1. Ingest FP boundaries.
2. Build land tenure DB.
3. Pull and clean LSB transactions.
4. Compute intersections/hulls.
5. Assign treatment + timing (TEMP files are still required).
6. Match PLSS to transactions.
7. Add boundary distances and covariates (SSURGO, CPI, CDL, Census).
8. Run R visualization/inference scripts.

## TEMP/TEST Policy
- TEMP/TEST files exist and can overwrite canonical outputs.
- Do not delete or refactor TEMP/TEST without explicit request.
- If making changes that affect outputs, call out which TEMP/TEST scripts might also need updates.

## Outputs
- Document every output file written by scripts (even ad-hoc).
- Prefer non-destructive updates; don't overwrite outputs without being asked.

## Documentation
- Keep README detailed and internally focused.
- If adding new scripts, update README with purpose, inputs, outputs, dependencies.
- Keep README readable: short paragraphs and blank lines between bullet entries.

## Safety
- Never run destructive git commands unless explicitly asked.
- If unexpected changes appear, stop and ask.

## Communication
- Be concise and explicit about any assumptions.
- Ask before doing anything that writes outside the repo or makes network calls.

## Task - Specific Docs

Task-specific routines are contained in ./agent-docs.

./agent-docs/PLANS.md - Use this as a template in the planning phase.

./README.md - Contains rich details on the repo structure, dependencies and outputs you previously created

./agent-docs/execplans/. - Use this subfolder to store plans we have finalized as a .md file. During the planning phase, I'll iterate on these files with you, which will then be used to execute workplans.

## Reasoning & Scope Control
- Optimize for correctness and reproducibility over elegance.
- Do not introduce new estimators, identification strategies, or modeling choices unless explicitly asked.
- Never infer research intent from file names alone.