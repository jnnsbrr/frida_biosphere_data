require(tidyverse)

# paths
project_dir <- "."
data_dir <- file.path(project_dir, "data")
original_data_dir <- file.path(data_dir, "original")

# utility functions
source(file.path(project_dir, "scripts", "utils.R"))

# download FAO fertilization data
fertilization_file <- download_fao_data(
  fao_code = "RFN",
  data_dir = original_data_dir
)

# download FAO livestock manure data
manure_file <- download_fao_data(
  fao_code = "EMN",
  data_dir = original_data_dir
)

# Read the fertilization data
fertilizer_data <- readr::read_csv(fertilization_file) |>
  filter(
    Item == "Nutrient nitrogen N (total)" & Element == "Agricultural Use"
  ) |>
  filter(Area == "World") |>
  filter(Year >= 1980)

# process into wide format and convert to MtN
fertilizer <- fertilizer_data |>
  mutate(
    Item = if_else(
      Item ==  "Nutrient nitrogen N (total)",
      "Fertilizer Application",
      Item
    )
  ) |>
  group_by(Area, Item, Year) |>
  summarise(Value = sum(Value, na.rm = TRUE), .groups = "drop") |>
  mutate(Value = Value * 1e-6,
         Unit = "MtN") |>
  spread(Item, Value)

# Read the livestock manure data
manure_data <- readr::read_csv(manure_file) |>
  filter(Item %in% "All Animals" &
           Element == "Manure applied to soils (N content)") |>
  filter(Area == "World") |>
  filter(Year >= 1980)

# process into wide format and convert to MtN
manure <- manure_data |>
  group_by(Area, Item, Year) |>
  summarise(Value = sum(Value, na.rm = TRUE), .groups = "drop") |>
  mutate(Value = Value * 1e-9,
         Unit = "MtN") |>
  spread(Item, Value) |>
  rename(`Manure Application` = `All Animals`)

# join both, manure and fertilizer data into fertilization data
fertilization_data <- manure |>
  full_join(fertilizer) |>
  select(!Area)

# write excel file (requires writexl package)
write_csv(
  fertilization_data,
  file.path(
    data_dir,
    "fao_fertilization.csv"
  )
)
