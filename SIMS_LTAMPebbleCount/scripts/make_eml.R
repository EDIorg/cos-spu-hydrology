# Make EML metadata from EAL templates


# Initialize work space --------------------------------------------------------

setwd("/Users/csmith/Code/cos-spu-hydrology/SIMS_LTAMPebbleCount")

library(remotes)
library(EMLassemblyline) # Install from GitHub: install_github("EDIorg/EMLassemblyline")

path_templates <- "./metadata_templates"
path_eml <- "./eml"
path_data <- "./data"

# Make EML from metadata templates --------------------------------------------

# Once all your metadata templates are complete call this function to create 
# the EML.

EMLassemblyline::make_eml(
  path = path_templates,
  data.path = paste0(path_data, "/processed"),
  eml.path = path_eml, 
  dataset.title = "Long Term Aquatic Monitoring (LTAM) Pebble Count, 2006-2017", 
  temporal.coverage = c("2006-01-01", "2017-01-01"), 
  geographic.description = "Study site", 
  geographic.coordinates = c("47.6199", "-121.77", "47.6199", "-121.77"), 
  maintenance.description = "Update if data is collected after 2017.", 
  data.table = c("SIMS_LTAMPebbleCount_Working.csv", "SIMS_LTAMPebbleCount_Summary.csv"), 
  data.table.name = c("SIMS_LTAMPebbleCountWorking2006_2017","SIMS_LTAMPebbleCountSummary2006_2017"),
  data.table.description = c("Long Term Aquatic Monitoring (LTAM) pebble count data, 2006-2017", "Long Term Aquatic Monitoring (LTAM) pebble count summary analysis, 2006-2017"),
  data.table.quote.character = c('"', '"'),
  other.entity = c("SIMS_LTAMPebbleCount_GraphsTables.xlsx"),
  other.entity.name = c("SIMS_LTAMPebbleCount_GraphsTables"),
  other.entity.description = c("Excel workbook that has the analysis for pebble count data (graphs, tables, formulas, and statistics). The workbook contains conditional formatting. This file will be useful if the data steward wants to replicate the analysis in the future."),
  user.id = "EDI",
  user.domain = "EDI", 
  package.id = "cos-spu.108.2")
