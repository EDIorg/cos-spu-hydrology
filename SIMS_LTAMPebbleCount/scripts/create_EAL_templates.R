# Create metadata templates ---------------------------------------------------

# Use EAL to create metadata templates. Once used, function calls  will be 
# commented out to prevent them from running again, but keeping them around in 
# case they need to be regenerated.

# Initialize work space --------------------------------------------------------

setwd("/Users/csmith/Code/cos-spu-hydrology/SIMS_LTAMPebbleCount")

library(remotes)
library(EMLassemblyline) # Install from GitHub: install_github("EDIorg/EMLassemblyline")

path_templates <- "./metadata_templates"
path_data <- "./data"

# Create metadata templates ----------------------------------------------------

# template_core_metadata(
#   path = path_templates,
#   license = "CC0"
# )

# template_table_attributes(
#   path = path_templates,
#   data.path = paste0(path_data, "/processed"),
#   data.table = c(
#     "SIMS_LTAMPebbleCount_Summary.csv",
#     "SIMS_LTAMPebbleCount_Working.csv"
#   )
# )
