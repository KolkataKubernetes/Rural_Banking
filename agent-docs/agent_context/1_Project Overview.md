# 1_Project Overview

Purpose of this project is to evaluate how small business finance trends have evolved in Wisconsin. This is joint work with Tessa Conroy at UW-Madison. I'm looking to build visuals and analysis similar to the report in the context folder, @./CORI_Rural-America-Struggle-Access-Private-Capital_May2025-compressed.pdf. I've added a bunch of legacy code to the ./1_code/legacy subfolder, that should be documented in the README in a seperate section. We'll be using this code to build a new codebase together.

## DATA

Three data sources I care about. You'll see an input_root.txt that links to a mounted disk. I'd prefer that you try running any scripts using the mounted disk - but if that isn't feasible, you can go ahead and create a filepath within the repository for our immediate purposes. 

### SEC FORM D DATA (CORI)

This is mainly SEC Form D Data, along with a HUD crosswalk. This data is pulled from a custom API that is provided by the Center for Rural Innovation (CORI). Link to the API I access is here: github.com/matthewjrogers/dform. I have tried pulling data from the API with the R script @./1_code/1_0_ingest/CORI_formd.R. I wrote this R Script, following the logic outlined in the Github account github.com/matthewjrogers/dform. My understanding of this process is found in the section ## LOGIC FOR CORI API.


### PITCHBOOK VC MONITOR DATA (Pitchbook)

I downloaded this data from Pitchbook - it's from a publication co-authored between the National Venture Capital Association (NVCA). The original source document was downloaded directly from the Pitchbook website and contains a bunch of tabs, most which aren't necessary. The source document is found in @./0_inputs/Pitchbook/Q3_2025_PitchBook-NVCA_Venture_Monitor_Summary_XLS_20370.xlsx, but the relevant excel spreadsheets you should care about are found in @./0_inputs/Pitchbook/Pitchbook_dealcount.xlsx and @./0_inputs/Pitchbook/Pitchbook_dealvol.xlsx.

# SBA DATA

These are the SBA 504 and SBA 7_A data, retreived through a public FOIA request. the URL to the public FOIA data is https://data.sba.gov/dataset/7-a-504-foia . Downloaded data that is relevant here is 


## LOGIC FOR CORI API

# API Information:

Looks like CORI has their data documentation in two places:

1. https://github.com/ruralinnovation/formd-interactive-map: Information on how CORI uses Form D data to make an interactive map
2. https://github.com/matthewjrogers/dform: Information on the R Package used to pull R data.
3. SEC Form Data is also all available as a seperate ZIP download. [Link here](https://www.sec.gov/data-research/sec-markets-data/form-d-data-sets).

# Data Organization:

In broad strokes, CORI combines two data sources: “Offers” and “Issuers” to arrive at a geolocated view of Form D level behavior.

## How CORI cleans form-d data:

***Definition: Issuers vs. Offerings***

- Issuers: Describes entities that are filing an offering. Entities with multiple filings  will appear several times in this dataset.
- Offerings: Each fundraise event.

***Overview of Issuer Data cleaning***

**Cleaning names**

- Standardize entity, city naming conventions (remove punctuation and whitespace) ✅

**Associating Issuers with counties (NOT IN FORM D API PULL)**

- Issuers must list an address in each form D filing.
- Load HUD zipcode to county crosswalk (2021 and 2014 vintages) ✅
    - If there’s a one-to-one match, the location falls out immediately. ✅
    - If a ZIP spans multiple counties, default to the county where more of the business addresses are located. ✅
    - As a final screen, use Census Geocoder to associate address with county. SKIP FOR NOW
- If none of the three above steps are successful, throw away the issuer.

**Identifying year of incorporation**

- problem: yearofinc_value_entered is blank in some instances.
    - Group by CIK and name, and then take the smallest year value entered. Also fill in with yearofinc_timespan_choice column (the value_entered column may be blank depending on this value)

**Collapsing Industry Identifier**

- ❓ Collapse all industries into a seperate comma separated string (There’s no industry group in the offerings data)

**Join Issuers and offerings dataset**

Join by:

- accessionnumber (SEC number assigned to each submission)
- year
- quarter
- filter on primary issuers only

**Correct “totalamountsold” to get at the total amount raised within each round.**

- “totalamountsold” → cumulative amount raised by a company
1. Create a business ID 
    1. Combination of CIK Code, Accession # Prefix ❓Are we sure this difference is meaningful? and not just holding companies?
2. Create a funding round ID, sort funding within each around. Funding rounds are created by matching the following columns (One business ID might have multiple funding round ID’s)
    1. sale_date
    2. isequitytype
    3. isdebttype
    4. ispooledinvestmentfundtype (raising a fund or capital?)
    5. isbusinesscombinationtrans (M&A activity)
3. Sort the funding round ID’s in order using the accession number (using the accession number)
4. Calculate the incremental amount raised using this amount
5. Create a flag for whether a security includes pooled investment fund interests → We want to avoid these for the comparable analysis to CORI.

# Using the CORI API

- Hitting a snag at the moment because htmltab was removed from CRAN (it’s an updated package). Need to develop a work around.
- Ended up invoking the package using devtools and a github URL.
- Looks like I was able to do my first data download when manually including a user token.
- What I don’t know now is whether the aggregation step included in the mapping API is already done, and whether I have duplicate accession numbers… I’ll have to review the code files.
    - Looks like I need to do this myself.

