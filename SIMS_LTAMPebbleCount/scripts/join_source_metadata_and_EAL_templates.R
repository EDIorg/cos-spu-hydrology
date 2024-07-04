# Join source metadata with EAL templates

# Initialize work space --------------------------------------------------------

setwd("/Users/csmith/Code/cos-spu-hydrology/SIMS_LTAMPebbleCount")

library(remotes)
library(tidyverse)
library(dplyr)
library(EMLassemblyline) # Install from GitHub: install_github("EDIorg/EMLassemblyline")

path_templates <- "./metadata_templates"
path_eml <- "./eml"
path_data <- "./data"

attributes <- read_csv(paste0(path_data, "/processed/attributes.csv"))
codes <- read_csv(paste0(path_data, "/processed/codes.csv"))
mapping <- read_csv(paste0(path_data, "/raw/LTAMPebbleCountMetadata - mapping.csv"))

# Join EAL templates with source metadata and reformat ------------------------

# Apply mapping to source metadata

for (row in 1:nrow(mapping)) {
  source_value <- mapping$source_value[row]
  target_value <- mapping$target_value[row]
  column <- mapping$column[row]
  index <- which(attributes[[column]] == source_value)
  attributes[[column]][index] <- target_value
}

# Read the EAL attribute templates and prepare for join

summary_eal <- read_tsv(paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Summary.txt")) %>% 
  select(attributeName)
working_eal <- read_tsv(file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Working.txt")) %>% 
  select(attributeName)

attributes <- rename(attributes, "attributeName" = `ATTRIBUTE CODE`)

summary <- attributes %>% filter(`UPLOAD FILE NAME` == "SIMS_PebbleCount_Summary.csv")
working <- attributes %>% filter(`UPLOAD FILE NAME` == "SIMS_PebbleCount_Working.csv")

# Join

summary <- left_join(summary_eal, summary, by = "attributeName")
working <- left_join(working_eal, working, by = "attributeName")

# Rename existing columns to match the EAL templates.

summary <- summary %>% 
  rename(
    "class" = "ATTRIBUTE DATA TYPE",
    "dateTimeFormatString" = `ATTRIBUTE DATA TYPE UNIT`,
    "attributeDefinition" = "ATTRIBUTE DESCRIPTION",
    "unit" = "ATTRIBUTE DATA TYPE UNIT DESCRIPTION"
  )
working <- working %>% 
  rename(
    "class" = "ATTRIBUTE DATA TYPE",
    "dateTimeFormatString" = `ATTRIBUTE DATA TYPE UNIT`,
    "attributeDefinition" = "ATTRIBUTE DESCRIPTION",
    "unit" = "ATTRIBUTE DATA TYPE UNIT DESCRIPTION"
  )

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

# Do a little clean up on the values -----------------------------------------

# Convert "MM" to NA in the dateTimeFormatString column

summary$dateTimeFormatString <- ifelse(summary$dateTimeFormatString == "MM", NA, summary$dateTimeFormatString)
working$dateTimeFormatString <- ifelse(working$dateTimeFormatString == "MM", NA, working$dateTimeFormatString)

# Convert format string to accepted value

working$dateTimeFormatString <- ifelse(working$dateTimeFormatString == "M/D/YYYY hh:mm:ss", "MM/DD/YYYY hh:mm:ss", working$dateTimeFormatString)

# Values in the 'units' column should be NA when the 'class' column
# contains either a value of 'character' or 'categorical'. These don't have
# units.

summary$unit <- ifelse(summary$class == "character" | summary$class == "categorical", NA, summary$unit)
working$unit <- ifelse(working$class == "character" | working$class == "categorical", NA, working$unit)

# Write the EAL attribute templates to file -----------------------------------

write_tsv(summary, file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Summary.txt"))
write_tsv(working, file = paste0(path_templates, "/attributes_SIMS_LTAMPebbleCount_Working.txt"))

# Create categorical variables metadata template ------------------------------

# Create categorical variables template after categorical attributes have been
# classified. The code below needs to know which columns to get unique values
# from.

template_categorical_variables(
  path = path_templates, 
  data.path = paste0(path_data, "/processed")
)

# Read the EAL categorical variables template
catvars_eal <- read_tsv(file = paste0(path_templates, "/catvars_SIMS_LTAMPebbleCount_Summary.txt"))


# Add code definitions from source

codes <- rename(
  codes, 
  "definition" = `DESCRIPTION`,
  "code" = `VALUE`
)

codes <- left_join(catvars_eal, codes, by = "code") %>% 
  select(
    attributeName,
    code,
    definition.y
  ) %>%
  rename(
    "definition" = definition.y
  )

# FIXME Remove rows with NA in the 'definition' column.
# This is a temporary fix to remove rows with missing definitions. This should
# be fixed in the mapping file.

codes <- codes %>% filter(!is.na(definition))

# Write to file

write_tsv(codes, file = paste0(path_templates, "/catvars_SIMS_LTAMPebbleCount_Summary.txt"))

# Complete other EAL templates ------------------------------------------------

# # personnel.txt
# 
# personnel <- read_tsv(file = paste0(path_templates, "/personnel.txt"))
# 
# personnel <- personnel %>% add_row()
# personnel$givenName <- "Amy"
# personnel$surName <- "Reichenbach"
# personnel$organizationName <- "EDI/SPU to confirm"
# personnel$electronicMailAddress <- "EDI/SPU to confirm"
# personnel$organizationName <- "EDI/SPU to confirm"
# personnel$userId <- "EDI/SPU to confirm"
# personnel$role <- "EDI/SPU to confirm"
# personnel$projectTitle <- "EDI/SPU to confirm"
# personnel$fundingAgency <- "EDI/SPU to confirm"
# personnel$fundingNumber <- "EDI/SPU to confirm"
# 
# personnel <- personnel %>% add_row() %>% add_row()
# personnel[2:3, ] <- personnel[1, ]
# personnel$role <- c("creator", "contact", "publisher")
# 
# write_tsv(personnel, file = paste0(path_templates, "/personnel.txt"))

# # keywords.txt
# 
# keywords <- read_tsv(file = paste0(path_templates, "/keywords.txt"))
# keywords <- keywords %>% add_row() %>% add_row() %>% add_row()
# keywords$keyword <- c("Pebble count", "Long Term Aquatic Monitoring", "LTAM")
# 
# write_tsv(keywords, file = paste0(path_templates, "/keywords.txt"))



