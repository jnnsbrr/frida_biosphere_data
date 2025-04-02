require(tidyverse)

# paths
project_dir <- "."
data_dir <- file.path(project_dir, "data")
original_data_dir <- file.path(data_dir, "original")

# utility functions
source(file.path(project_dir, "scripts", "utils.R"))

# download FAO historical food balances data
historical_balances_file <- download_fao_data(
  fao_code = "FBSH",
  data_dir = original_data_dir
)

# download FAO recent food balances data
recent_balances_file <- download_fao_data(
  fao_code = "FBS",
  data_dir = original_data_dir
)

food_elements <- c(
  "Food supply (kcal/capita/day)"
)

food_items <- c(
  "Vegetal Products",
  "Animal Products",
  "Fish, Seafood",
  "Aquatic Products, Other"
)

# Read the historical data (before 2010) with different approach
hist_balances_data <- readr::read_csv(historical_balances_file) |>
  filter(Area %in% "World")

hist_balances <- hist_balances_data |>
  # For historical data food supply in per capita has to be multiplied by
  #   population to get the total food supply
  filter(Element %in% c(food_elements, "Total Population - Both sexes")) |>
  filter(Item %in% c(food_items, "Population")) |>
  # After 2010 recent data (file) is available and is preferred
  filter(Year >= 1980 & Year < 2010) |>
  # Conversion to total food supply
  mutate(Population = if_else(Item == "Population", Value, NA)) |>
  group_by(Year) |>
  fill(Population, .direction = "down") |>
  ungroup() |>
  filter(!Item == "Population") |>
  mutate(
    Value = if_else(
      Element == "Food supply (kcal/capita/day)",
      Value * 365 * 1e-3 * 1e-6 * Population,
      Value
    )
  ) |>
  select(-c(`Element Code`, `Item Code`, `Item Code (FBS)`, `Year Code`, `Flag`,
            `Area`, `Area Code`, `Area Code (M49)`, `Population`)) |>
  # Convert food supply into PCal
  mutate(
    Element = if_else(
      Element == "Food supply (kcal/capita/day)", "Food supply", Element
    )
  ) |>
  mutate(Unit = "pcal")


recent_balances <- readr::read_csv(recent_balances_file) |>
  filter(Area %in% "World") |>
  filter(Element %in% food_elements) |>
  filter(Item %in% food_items) |>
  select(-c(`Element Code`, `Item Code`, `Item Code (FBS)`, `Year Code`, `Flag`,
            `Area Code`, `Area Code (M49)`, `Area`)) |>
  mutate(
    Value = if_else(Element == "Food supply (kcal)", Value * 1e-6, Value)
  ) |>
  mutate(Unit = if_else(Element == "Food supply (kcal)", "pcal", Unit)) |>
  mutate(
    Element = if_else(
      Element == "Food supply (kcal)", "Food supply", Element
    )
  )


food_data <- recent_balances |>
  full_join(hist_balances,
            by = c("Item", "Element", "Year", "Unit", "Value")) |>
  spread(Item, Value) |>
  mutate(
    `Aquatic Animal Products` = `Fish, Seafood` + `Aquatic Products, Other`
  ) |>
  mutate(
    `Land Animal Products` = `Animal Products` - `Aquatic Animal Products`
  ) |>
  select(-c(`Fish, Seafood`, `Aquatic Products, Other`)) |>
  mutate(
    `Aquatic Animal Products Share` = `Aquatic Animal Products` / `Animal Products` # nolint
  ) |>
  select(!c("Note", "Element"))

write_csv(
  food_data,
  file.path(
    data_dir,
    "fao_food_production.csv"
  )
)
