require(tidyverse)

# paths
project_dir <- "C:/Users/jannesbr/projects/worldtrans/frida_biosphere_data"
data_dir <- file.path(project_dir, "data")
original_data_dir <- file.path(data_dir, "original")

# utility functions
source(file.path(project_dir, "scripts", "utils.R"))

# download FAO land use data
landuse_file <- download_fao_data(fao_code = "RL", data_dir = original_data_dir)

landuse <- readr::read_csv(landuse_file) |>
  # Select relevant columns
  select(-c(`Element Code`, `Item Code`, `Year Code`, `Flag`,
            `Area Code`, `Area Code (M49)`)) |>
  # Filter only global data
  filter(Area %in% "World") |>
  # Filter only area values (no shares, etc.)
  filter(Element %in% "Area") |>
  filter(Year >= 1980) |>
  # Filter relevant land use categories for FRIDA
  filter(Item %in% c("Cropland", "Agricultural land",
                     "Forest land", "Other land", "Land area",
                     "Permanent meadows and pastures")) |>
  # Convert units from 1000 ha to Mha
  mutate(Value = 1e-3 * Value) |>
  mutate(Unit = "Mha") |>
  # Spread the data into wide format (each land use category as a column)
  pivot_wider(names_from = Item, values_from = Value) |>
  # Rename columns to match FRIDA land use types
  rename(Grassland = `Permanent meadows and pastures`) |>
  # Assumption: Habitable land = Agricultural land + Forest land
  # Other land is not included in habitable or usable land
  mutate(`Habitable land` = `Agricultural land` + `Forest land`) |>
  # Fill in missing values for habitable land using linear interpolation
  mutate(`Habitable land` = zoo::na.approx(
    `Habitable land`, maxgap = Inf, rule = 2
  )) |>
  # Fill in missing values for forest land using the habitable land value
  #   minus the agricultural land value
  mutate(`Forest land` = if_else(
    is.na(`Forest land`),
    `Habitable land` - `Agricultural land`,
    `Forest land`
  )) |>
  # other land and agricultural land are not used in FRIDA
  select(!c("Other land", "Agricultural land", "Element", "Area", "Note"))

# Write the data to a CSV file
landuse |>
  write_csv(
    file = file_path(data_dir, "fao_landuse.csv"),
  )
