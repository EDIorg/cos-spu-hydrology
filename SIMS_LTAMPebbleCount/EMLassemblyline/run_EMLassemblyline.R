# This script creates EML metadata for the LTAMPebbleCount dataset. It generates
# a set of metadata templates, fills them in with source metadata from the 
# LTAMPebbleCount database, and then creates EML metadata from the templates.
# The metadata generation tool being used here is EMLassemblyline (EAL)
# (https://ediorg.github.io/EMLassemblyline/index.html).

# Initialize work space --------------------------------------------------------

# Install and load required packages

# install.packages(c("remotes", "tidyverse", "dplyr"))
library(remotes)
library(tidyverse)
library(dplyr)

# install_github("EDIorg/EMLassemblyline")
library(EMLassemblyline)

# Define file paths to be used below

setwd("/Users/csmith/Data/ForColin_2024-0404_pebbles")  # set working directory
path_templates <- "./EMLassemblyline/metadata_templates"
path_data <- "."
path_eml <- "./EMLassemblyline/eml"

# Compile metadata -----------------------------------------------------------

# Read the source metadata files. These were exported to .csv from the 
# LTAMPebbleCountMetadata.xlsx workbook.

codes <- read_csv(file = paste0(path_data, "/LTAMPebbleCountMetadata - Codes.csv"))
definitions <- read_csv(file = paste0(path_data, "/LTAMPebbleCountMetadata - Definitions.csv"))
ezeml <- read_csv(file = paste0(path_data, "/LTAMPebbleCountMetadata - EZML.csv"))
names_and_units <- read_csv(file = paste0(path_data, "/LTAMPebbleCountMetadata - NamesAndUnits.csv"))

# FIXME definition of the Pebble B-Axis Length attribute isn't ending up in the
# final metadata. Adding it here manually. Fix is to align column names so
# information can be transferred on keys. Replace the "Pebble B-Axis Length" 
# value in the ATTRIBUTE NAME column of the definitions table with "Pebble 
# B-Axis Length (mm)"

index <- which(definitions$`ATTRIBUTE NAME` == "Pebble B-Axis Length")
definitions$`ATTRIBUTE NAME`[index] <- "Pebble B-Axis Length (mm)"

# Join these tables together and remove redundant columns. This is the first in
# a set of steps that will transform the source metadata into EAL templates, 
# that can be used to create EML metadata.

# Split the names and units table into two tables, one for each data table
# to be described in the EML.

summary <- names_and_units %>% filter(`UPLOAD FILE NAME` == "SIMS_PebbleCount_Summary.csv")
working <- names_and_units %>% filter(`UPLOAD FILE NAME` == "SIMS_PebbleCount_Working.csv")

# Join definitions to the summary and working tables by the commonly shared
# column, ATTRIBUTE NAME.

summary <- left_join(summary, definitions, by = "ATTRIBUTE NAME")
working <- left_join(working, definitions, by = "ATTRIBUTE NAME")

# Select only the columns needed for the EAL templates.

summary <- summary %>% 
  select(
    `ATTRIBUTE NAME`, 
    starts_with("ATTRIBUTE DATA TYPE (Lookup"),
    `ATTRIBUTE DATA TYPE UNIT`,
    starts_with("ATTRIBUTE DESCRIPTION"),
    starts_with("ATTRIBUTE DATA TYPE UNIT DESCRIPTION")
    )

working <- working %>%
  select(
    `ATTRIBUTE NAME`, 
    starts_with("ATTRIBUTE DATA TYPE (Lookup"),
    `ATTRIBUTE DATA TYPE UNIT`,
    starts_with("ATTRIBUTE DESCRIPTION"),
    starts_with("ATTRIBUTE DATA TYPE UNIT DESCRIPTION")
  )

# Use the mapping file to convert source metadata values into EAL equivalents, 
# so EAL can process them.

mapping <- read_csv(file = paste0(path_data, "/LTAMPebbleCountMetadata - Mapping.csv"))

for (row in 1:nrow(mapping)) {
  mapping$source_value[row]
  source_value <- mapping$source_value[row]
  target_value <- mapping$target_value[row]
  column <- mapping$column[row]
  # For summary table
  index <- which(summary[[column]] == source_value)
  summary[[column]][index] <- target_value
  # For working table
  index <- which(working[[column]] == source_value)
  working[[column]][index] <- target_value
}

# Reformat the attribute name column for joining with the EAL attributes
# template below.

summary <- summary %>% rename("attributeName" = `ATTRIBUTE NAME`)
working <- working %>% rename("attributeName" = `ATTRIBUTE NAME`)

# Pause here to work on the EAL templates ...

# Create metadata templates ---------------------------------------------------

# Use EAL to create metadata templates. Once used, function calls  will be 
# commented out to prevent them from running again, but keeping them around in 
# case they need to be regenerated.

# template_core_metadata(
#   path = path_templates,
#   license = "CC0"
# )

# template_table_attributes(
#   path = path_templates,
#   data.path = path_data,
#   data.table = c(
#     "SIMS_LTAMPebbleCount_Summary.csv", 
#     "SIMS_LTAMPebbleCount_Working.csv"
#   )
# )

# Note, we will need to create a template for the categorical variables after
# the categorical attributes have been classified. The code below needs to know
# which columns to get unique categorical values from.

# Join EAL templates with source metadata and format ---------------------------

# Now that the EAL templates have been created, we can join them with the source
# metadata.

# Read the EAL attribute templates

summary_eal <- read_tsv(file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Summary.txt"))
working_eal <- read_tsv(file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Working.txt"))

# Drop all columns from the EAL attribute templates except for the 
# attributeName, which we'll use to order the metadata descriptions with the
# order found by EAL when it created the attribute templates.

summary_eal <- summary_eal %>% select(attributeName)
working_eal <- working_eal %>% select(attributeName)

# Left join the EAL templates with the source metadata on the attributeName
# column.

summary <- left_join(summary, summary_eal, by = "attributeName")
working <- left_join(working, working_eal, by = "attributeName")

# Rename existing columns to match the EAL templates.

summary <- summary %>% 
  rename(
    "class" = starts_with("ATTRIBUTE DATA TYPE (Lookup"),
    "dateTimeFormatString" = `ATTRIBUTE DATA TYPE UNIT`,
    "attributeDefinition" = starts_with("ATTRIBUTE DESCRIPTION"),
    "unit" = starts_with("ATTRIBUTE DATA TYPE UNIT DESCRIPTION")
  )
working <- working %>% 
  rename(
    "class" = starts_with("ATTRIBUTE DATA TYPE (Lookup"),
    "dateTimeFormatString" = `ATTRIBUTE DATA TYPE UNIT`,
    "attributeDefinition" = starts_with("ATTRIBUTE DESCRIPTION"),
    "unit" = starts_with("ATTRIBUTE DATA TYPE UNIT DESCRIPTION")
  )

# Do a little clean up on the values.
# FIXME: Move this operation to the mapping file

# Clean up: Convert "MM" to NA in the dateTimeFormatString column
summary$dateTimeFormatString <- ifelse(summary$dateTimeFormatString == "MM", NA, summary$dateTimeFormatString)
working$dateTimeFormatString <- ifelse(working$dateTimeFormatString == "MM", NA, working$dateTimeFormatString)

# Clean up: Convert format string to accepted value
working$dateTimeFormatString <- ifelse(working$dateTimeFormatString == "M/D/YYYY hh:mm:ss", "MM/DD/YYYY hh:mm:ss", working$dateTimeFormatString)

# Clean up: Values in the 'units' column should be NA when the 'class' column
# contains either a value of 'character' or 'categorical'. These don't have
# units.
summary$unit <- ifelse(summary$class == "character" | summary$class == "categorical", NA, summary$unit)
working$unit <- ifelse(working$class == "character" | working$class == "categorical", NA, working$unit)

# Add missing columns and rearrange to complete the EAL attribute templates
missing_columns <- c("missingValueCode", "missingValueCodeExplanation")
summary <- summary %>% 
  mutate(
    missingValueCode = NA,
    missingValueCodeExplanation = NA
  ) %>% 
  select(
    attributeName,
    attributeDefinition,
    class,
    unit,
    dateTimeFormatString,
    missingValueCode,
    missingValueCodeExplanation
  )
working <- working %>% 
  mutate(
    missingValueCode = NA,
    missingValueCodeExplanation = NA
  ) %>% 
  select(
    attributeName,
    attributeDefinition,
    class,
    unit,
    dateTimeFormatString,
    missingValueCode,
    missingValueCodeExplanation
  )

# Add missing value codes. These are not defined in the source metadata tables,
# but rather determined by conversation with the data creator.

missing_value_code <- "-999"
missing_value_code_explanation <- "Missing value"

summary$missingValueCode <- missing_value_code
summary$missingValueCodeExplanation <- missing_value_code_explanation
working$missingValueCode <- missing_value_code
working$missingValueCodeExplanation <- missing_value_code_explanation

# Write the EAL attribute templates to file -----------------------------------

write_tsv(summary, file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Summary.txt"))
write_tsv(working, file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Working.txt"))


# Create categorical variables metadata template ------------------------------

# Create categorical variables template after categorical attributes have been
# classified. The code below needs to know which columns to get unique values
# from.

template_categorical_variables(path_templates, path_data)

# Read the EAL categorical variables template
catvars_eal <- read_tsv(file = paste0(path_templates, "/catvars_SIMS_LTAMPebbleCount_Summary.txt"))

# FIXME: Catvars of source don't align with attribute classes defined by the source.
# Adding boilerplate for the time being

catvars_eal$definition <- "TBD"

# Write to file
write_tsv(catvars_eal, file = paste0(path_templates, "/catvars_SIMS_LTAMPebbleCount_Summary.txt"))

# Complete other EAL templates ------------------------------------------------

# TODO: Transfer this information programmatically. Manually adding for now.

# Read the personnel.txt table
personnel <- read_tsv(file = paste0(path_templates, "/personnel.txt"))

# Add an empty row to the personnel table
personnel <- personnel %>% add_row()
personnel$givenName <- "Amy"
personnel$surName <- "Reichenbach"
personnel$organizationName <- "EDI/SPU to confirm"
personnel$electronicMailAddress <- "EDI/SPU to confirm"
personnel$organizationName <- "EDI/SPU to confirm"
personnel$userId <- "EDI/SPU to confirm"
personnel$role <- "EDI/SPU to confirm"
personnel$projectTitle <- "EDI/SPU to confirm"
personnel$fundingAgency <- "EDI/SPU to confirm"
personnel$fundingNumber <- "EDI/SPU to confirm"

# # Add 2 more rows
# personnel <- personnel %>% add_row() %>% add_row()
# 
# # Copy the information from the first row into the following 2 rows
# personnel[2:3, ] <- personnel[1, ]

personnel$role <- c("creator", "contact", "publisher")

# Write to file
write_tsv(personnel, file = paste0(path_templates, "/personnel.txt"))

# Edit the keywords.txt template
keywords <- read_tsv(file = paste0(path_templates, "/keywords.txt"))
# Add 3 empty rows
keywords <- keywords %>% add_row() %>% add_row() %>% add_row()
keywords$keyword <- c("Pebble count", "Long Term Aquatic Monitoring", "LTAM")

# Write to file
write_tsv(keywords, file = paste0(path_templates, "/keywords.txt"))

# Make EML from metadata templates --------------------------------------------

# Once all your metadata templates are complete call this function to create 
# the EML.

EMLassemblyline::make_eml(
  path = path_templates,
  data.path = path_data,
  eml.path = path_eml, 
  dataset.title = "Long Term Aquatic Monitoring (LTAM) Pebble Count, 2006-2017", 
  temporal.coverage = c("2006-01-01", "2017-01-01"), 
  geographic.description = "Study site", 
  geographic.coordinates = c("47.6199", "-121.77", "47.6199", "-121.77"), 
  maintenance.description = "Update if data is collected after 2017.", 
  data.table = c("SIMS_LTAMPebbleCount_Working.csv", "SIMS_LTAMPebbleCount_Summary.csv"), 
  data.table.name = c("SIMS_LTAMPebbleCountWorking2006_2017","SIMS_LTAMPebbleCountSummary2006_2017"),
  data.table.description = c("Long Term Aquatic Monitoring (LTAM) pebble count data, 2006-2017", "Long Term Aquatic Monitoring (LTAM) pebble count summary analysis, 2006-2017"),
  other.entity = c("SIMS_LTAMPebbleCount_GraphsTables.xlsx"),
  other.entity.name = c("SIMS_LTAMPebbleCount_GraphsTables"),
  other.entity.description = c("Excel workbook that has the analysis for pebble count data (graphs, tables, formulas, and statistics). The workbook contains conditional formatting. This file will be useful if the data steward wants to replicate the analysis in the future."),
  user.id = "EDI",
  user.domain = "EDI", 
  package.id = "cos-spu.108.1")
