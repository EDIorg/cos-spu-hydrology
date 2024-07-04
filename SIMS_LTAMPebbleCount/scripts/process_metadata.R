# Process source metadata for conversion to EML formatted metadata

# Initialize work space -------------------------------------------------------

library(readxl)
library(tidyverse)
library(dplyr)

setwd("/Users/csmith/Code/cos-spu-hydrology/SIMS_LTAMPebbleCount")

# Compile source metadata -----------------------------------------------------

# Read

source_file <- "./data/raw/LTAMPebbleCountMetadata.xlsx"
forms_sheet <- read_excel(source_file, sheet = "Forms")
attributes_sheet <- read_excel(source_file, sheet = "Attributes")
codes_sheet <- read_excel(source_file, sheet = "Codes")
ezml_sheet <- read_excel(source_file, sheet = "EZML")

# Join forms and attributes

attributes <- left_join(attributes_sheet, forms_sheet, by = "ATTRIBUTE NAME") %>%
  rename(
    "ATTRIBUTE DESCRIPTION" = "ATTRIBUTE DESCRIPTION (to do - add what 999 and -999 mean)",
    "ATTRIBUTE CODE" = "ATTRIBUTE CODE (This code is useful if needing to substitute this code for the (long) Attribute Name; Also, if needed to import into other programs, this code may be better than the Attribute Name)",
    "ATTRIBUTE DATA TYPE" = "ATTRIBUTE DATA TYPE (copied from tab no. 2)",
    "ATTRIBUTE DATA TYPE UNIT DESCRIPTION" = "ATTRIBUTE DATA TYPE UNIT DESCRIPTION (make sure \"TIMESTAMP\" loads down to the second. Might have to upload as \"text\" to preserve all of the TIMESTAMP)",
  ) %>%
  select(
    "UPLOAD FILE NAME",
    "ATTRIBUTE NAME",
    "ATTRIBUTE CODE",
    "ATTRIBUTE DESCRIPTION",
    "ATTRIBUTE DATA TYPE",
    "ATTRIBUTE DATA TYPE UNIT",  # TODO: Remove if unused
    "ATTRIBUTE DATA TYPE UNIT DESCRIPTION"
  )

# Fix SIMS_LTAMPebbleCount_Working.csv metadata -------------------------------

# Data has column "Master Sorting No." (with a period), and metadata
# has column "Master Sorting No" (without a period). This prevents matching. 
# Fix this.

i <- which(attributes$`ATTRIBUTE NAME` == "Master Sorting No")
attributes$`ATTRIBUTE NAME`[i] <- "Master Sorting No."

# Many columns at the end of this file are not described in the metadata. Add
# descriptions for these columns.

data_colnames <- colnames(read_csv("./data/raw/SIMS_LTAMPebbleCount_Working.csv"))
metadata_colnames <- filter(attributes, `UPLOAD FILE NAME` == "SIMS_PebbleCount_Working.csv") %>%
  select(`ATTRIBUTE NAME`) %>%
  pull()
missing_colnames <- setdiff(data_colnames, metadata_colnames)

# Create tibble of missing column names and descriptions

new_metadata <- tibble(
  `UPLOAD FILE NAME` = "SIMS_PebbleCount_Working.csv",
  `ATTRIBUTE NAME` = missing_colnames,
  `ATTRIBUTE CODE` = NA,
  `ATTRIBUTE DESCRIPTION` = NA,
  `ATTRIBUTE DATA TYPE` = NA,
  `ATTRIBUTE DATA TYPE UNIT` = NA,
  `ATTRIBUTE DATA TYPE UNIT DESCRIPTION` = NA
)

# Create attribute description from attribute name

new_metadata$`ATTRIBUTE DESCRIPTION` <- new_metadata$`ATTRIBUTE NAME`

# Create attribute codes from attribute names by using underscores instead of 
# spaces, hyphens, and parentheses.

new_metadata$`ATTRIBUTE CODE` <- gsub(" ", "_", new_metadata$`ATTRIBUTE NAME`)
new_metadata$`ATTRIBUTE CODE` <- gsub("-", "_", new_metadata$`ATTRIBUTE CODE`)
new_metadata$`ATTRIBUTE CODE` <- gsub("\\(", "", new_metadata$`ATTRIBUTE CODE`)
new_metadata$`ATTRIBUTE CODE` <- gsub("\\)", "", new_metadata$`ATTRIBUTE CODE`)

# Fill remaining columns based on other metadata

new_metadata$`ATTRIBUTE DATA TYPE` <- "NUMBER"
new_metadata$`ATTRIBUTE DATA TYPE UNIT` <- "MM"
new_metadata$`ATTRIBUTE DATA TYPE UNIT DESCRIPTION` <- "millimeters"

# Append new metadata to existing metadata

attributes <- bind_rows(attributes, new_metadata)

# Write metadata --------------------------------------------------------------

write_csv(attributes, "./data/processed/attributes.csv")
write_csv(codes_sheet, "./data/processed/codes.csv")
write_csv(ezml_sheet, "./data/processed/ezml.csv")


