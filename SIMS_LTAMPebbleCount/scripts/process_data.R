# Process data files

# Initialize work space -------------------------------------------------------

library(tidyverse)
library(dplyr)

setwd("/Users/csmith/Code/cos-spu-hydrology/SIMS_LTAMPebbleCount")

# Simplify column names -------------------------------------------------------

# Simplify column names in data files (long and containing symbols) by 
# transforming them to codes (alpha-numerics and underscores).

attributes <- read_csv("./data/processed/attributes.csv")

# Summary

summary <- read_csv("./data/raw/SIMS_LTAMPebbleCount_Summary.csv")
summary_attributes <- filter(attributes, `UPLOAD FILE NAME` == "SIMS_PebbleCount_Summary.csv")
long_names <- tibble("ATTRIBUTE NAME" = colnames(summary))
short_names <- left_join(long_names, summary_attributes, by = "ATTRIBUTE NAME")
colnames(summary) <- short_names$`ATTRIBUTE CODE`

# Working

working <- read_csv("./data/raw/SIMS_LTAMPebbleCount_Working.csv")
working_attributes <- filter(attributes, `UPLOAD FILE NAME` == "SIMS_PebbleCount_Working.csv")
long_names <- tibble("ATTRIBUTE NAME" = colnames(working))
short_names <- left_join(long_names, working_attributes, by = "ATTRIBUTE NAME")
colnames(working) <- short_names$`ATTRIBUTE CODE`

# Write results to file -------------------------------------------------------

write_csv(summary, "./data/processed/SIMS_LTAMPebbleCount_Summary.csv")
write_csv(working, "./data/processed/SIMS_LTAMPebbleCount_Working.csv") 
