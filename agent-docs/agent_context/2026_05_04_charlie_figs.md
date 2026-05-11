# Data and Code Integration: Charlie's Scripts

- As a reminder, we currently have our ingest scripts saved in 1_0_ingest, data cleaning in 1_1_transform, and the visualization scripts saved in 1_2_visualize. 
- Our entire pipeline is currently built in R. A collaborator on this project has built complementary visuals in Python, and is leaving our project. My high level goals are to: 
  - Translate his python code into R scripts
  - Integrate the R scripts into our pipeline, mantaining the syntax practices and design language employed in our current work while availing each of the data sources he uses. 
, and the Python Scripts to be referenced in agent-docs/agent_context/docs/charlie_scripts.

## Data Sources
- For now, I have placed all of the required data in 0_inputs/data_charlie. I included the original Zip Files in 0_inputs/data_charlie_downloads, but do not use these zip files when replicating the actual code pipeline. There are three datasources in 0_inputs/data_charlie:
  - NCUA Data, (NCUA: National Credit Union Association)
  - FDIC Data, 
  - CRA Data (CRA: Community Reinvestment Act)

## Reference Code

- The original Python Scripts are located in agent-docs/agent_context/docs/code_charlie. Each target R script (see below) makes explicit reference to one of the .py files in this filepath.
- This code uses common Python libraries/packages. I want each of these files to be translated into R using the tidyverse and ggplot.


## Pipeline Integration

- I have added skeleton "R" scripts that I would like for you to complete, using the reference code. The R scripts are in 1_code/1_2_visualize_figs_charlie. 
- You'll notice that while I've added figures 1 through 2d, I haven't added the remainder.
  - My hope is that you will have picked up on the pattern, without me having to explicitly create the skeletons for each file. The end goal of this work plan cycle is to replicate each script in agent-docs/agent_context/docs/code_charlie by creating an associated R script and following the exact same structure I have followed in the skeletons I manually set up. That is, the preamble should clearly spell out File Name, Author, the date created, and the script's purpose. 
    - The script's purpose is to replicate the given file from agent-docs/agent_context/docs/code_charlie. This creates a visible audit trail for other economists who would like to replicate my owrk.
  - Similarly, each script should contain the following seperate sections:
    - Setup and configuration
    - Load Inputs
    - Construct Figure
    - Save Outputs
  - It is important that each file contain the exact same structure to maintiain a high level of readability. Do not deviate from this format for this task without explicit permission.
  - Given the procedure above, I would like for you to replicate all of the python scripts in code_charlie that are prefixed "figXX" and "fig_cuXX". No need to build the R analogue of run_all.py

As always, please respond with any clarifying questions as we iterate on the spec plan.
