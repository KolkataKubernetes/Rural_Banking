This README template was drafted on [YYYY-MM-DD] by [NAME].

Notes for editors:
- Replace all bracketed text with project-specific information.
- Delete any lines marked as instructions once filled.
- Keep sections in this order unless there is a strong reason to move them.

# Project Overview

## Title

[Project title]

## Purpose and Scope

[Short paragraph describing the project purpose, scope boundaries, and intended outputs.]
[Explicitly state that this repository builds Wisconsin-focused small business finance data and visuals aligned to the CORI reference report.]

## Reference Report Alignment

[Name and path of the reference report used for structure alignment.]
[Explain what “alignment” means in this context (structure, scope, aggregation level), without adding analysis.]

## Contacts

[Just use my contact info for now. I've filled it in already so no edits needed for this section]

Primary contact:
- Name: Inder Majumdar
- ORCID (if available): https://orcid.org/0009-0004-1693-303X
- Institution: UW Madison
- Email: imajumdar@wisc.edu

## Funding

[Redact this section]

## Dates and Geography

- Date(s) of data collection or coverage:
- Geographic coverage (state/region/country; include counties if applicable):

# Repository Orientation

## High-Level Structure

[Brief prose describing the main directories and their roles.]

- `0_inputs/`: [What lives here; how it is organized.]
- `1_code/`: [Script organization; ingest/transform/visualize.]
- `2_processed_data/`: [Analysis-ready/intermediate outputs.]
- `agent-docs/`: [Reference docs and plans.]

## Data Location and Pathing

[Describe how `input_root.txt` is used to locate external data.]
[State whether any scripts use hardcoded paths and where.]

# Data Sources and Access

## Primary Data Sources

[List each source with origin, local path, and how it enters the pipeline.]

- Source name:
  - Origin (local copy, agency, vendor):
  - Local path(s):
  - Ingest script(s):
  - Notes/constraints:

## Derived or Upstream Data

[Identify any data derived from other sources and list those sources.]

## Access, Licensing, and Restrictions

- Licenses or restrictions placed on the data:
- Links to publications that cite or use the data (if internal, list paths or titles):
- Links/relationships to ancillary data sets:
- Recommended citation for this dataset/repository:
- For public datasets sourced from either a federal or state agency, explain clearly the agency provenance of each dataset

# Pipeline Summary

## Pipeline Order (High-Level)

[List the pipeline steps in order, matching `AGENTS.md` and actual scripts.]

1. [Step name and script path]
2. [Step name and script path]
3. [Step name and script path]

## Inputs, Processing, and Outputs

[Describe how raw/inputs become processed outputs, with concrete file references.]

# Scripts and Outputs (Inventory)

## Ingest Scripts

[List ingest scripts with inputs and outputs.]

- Script path:
  - Inputs:
  - Outputs:
  - Notes:

## Transform/Clean Scripts

[List transform/clean scripts with inputs and outputs.]

- Script path:
  - Inputs:
  - Outputs:
  - Notes:

## Visualization Scripts

[List visualization scripts with inputs and outputs.]

- Script path:
  - Inputs:
  - Outputs (include output paths or target directories):
  - Notes:

## Output Files and Directories

[Enumerate key outputs and where they are written.]

- `2_processed_data/`:
  - [Output file or subdirectory]: [Description]
- Other output locations (if outside repo):
  - [Path]: [Description]

## TEMP/TEST Outputs

[If any TEMP/TEST scripts exist, list them and the outputs they touch.]

# Data Dictionaries and Schemas

[Point to any data dictionaries or schema docs in the repo.]

- Path:
- Scope:

# Methodology and Processing Notes

## Data Collection / Generation

[Describe methods used for collection/generation; cite internal docs or scripts.]

## Processing Steps

[Describe processing methods used to generate submitted data from raw data.]

## Software and Dependencies

[List required software and key R packages with versions if known.]

- R version:
- Packages:

## Quality Assurance

[Describe any QA checks, validations, or constraints used.]

## People and Roles

[People involved with collection, processing, analysis, and submission.]

# Reproducibility

## How to Run

[Remoove this section]

- Working directory:
- Command(s):
- Expected outputs:

## Known Issues and Limitations

[List known limitations without interpreting results.]

# Versioning and Change Log

## Dataset Versions

- Are there multiple versions of the dataset?
  - If yes, name of file(s) updated:
  - Why updated:
  - When updated:

## Change Log

[Short chronological list of major README/data changes.]

# Legacy Code

[Describe legacy code under `1_code/legacy`, its purpose, and status.]

# Appendix: Data-Specific Information

[Repeat this section for each dataset, folder, or file as appropriate.]

## Data-Specific Information for: [FILENAME]

- Number of variables:
- Number of cases/rows:
- Variable list (name, description, units, value labels):
- Missing data codes:
- Specialized formats or abbreviations:

