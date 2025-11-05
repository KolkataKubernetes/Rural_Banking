#///////////////////////////////////////////////////////////////////////////////
#----                              Preamble                                 ----
# File name:  Pitchbook Dealcounts, Deal volume
# Previous author:  -
# Current author:   Inder Majumdar
# Creation date:    November 4 2025
# Last updated: November 4 2025
# Description: Pitchbook dealcount + volume descriptives from the NVCA monitor summary.
#///////////////////////////////////////////////////////////////////////////////

# CONFIG --------------------------------------------------------

#Load packages

library('tidyverse')

#set filepath
path = '/Users/indermajumdar/Downloads'

countdir = paste(path, 'Pitchbook_dealcount.xlsx', sep = "/")

voldir = paste(path, 'Pitchbook_dealvol.xlsx', sep = "/")

#Load data

dealcount <- readxl::read_xlsx(countdir)

dealvol <- readxl::read_xlsx(voldir)

# WIDE TO LONG  --------------------------------------------------------

count_wide <- gather(dealcount, "year", "count", -State)

vol_wide <- gather(dealvol, "year", "count", -State)

rm(dealcount, dealvol)




