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

product_elements <- c(
  "Production",
  "Food",
  "Feed",
  "Losses",
  "Seed",
  "Residuals",
  "Other uses (non-food)"
)

product_items <- c(
  "Cereals - Excluding Beer",
  "Starchy Roots",
  "Sugar Crops",
  "Sugar & Sweeteners",
  "Pulses",
  "Treenuts",
  "Oilcrops",
  "Vegetable Oils",
  "Vegetables",
  "Fruits - Excluding Wine"
)

# Read the historical data (before 2010) with different approach
hist_balances_data <- readr::read_csv(historical_balances_file) |>
  filter(Area %in% "World")

hist_balances <- hist_balances_data |>
  # For historical data food supply in per capita has to be multiplied by
  #   population to get the total food supply
  filter(
    Element %in% c(
      "Total Population - Both sexes",
      "Food supply (kcal/capita/day)",
      product_elements
    )
  ) |>
  filter(Item %in% c(product_items, "Population")) |>
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
      Value * 365 * 1e-3 * Population,
      Value
    )
  ) |>
  mutate(
    Element = if_else(
      Element == "Food supply (kcal/capita/day)", "Food supply", Element
    )
  ) |>
  select(-c(`Element Code`, `Item Code`, `Item Code (FBS)`, `Year Code`, `Flag`,
            `Area`, `Area Code`, `Area Code (M49)`, `Population`)) |>
  # Convert into Gt
  mutate(Value = if_else(Element %in% product_elements, Value * 1e-6, Value)) |>
  mutate(Unit = if_else(Element %in% product_elements, "Gt", Unit)) |>
  mutate(
    Element = if_else(
      Element %in% product_elements, paste0(Element, " [GtC]"), Element
    )
  ) |>
  # Convert food supply into PCal
  mutate(
    Value = if_else(Element == "Food supply", Value * 1e-6, Value)
  ) |>
  mutate(Unit = if_else(Element == "Food supply", "PCal", Unit)) |>
  mutate(
    Element = if_else(
      Element == "Food supply", "Food [PCal]", Element
    )
  )


# Read the recent data (from 2010) with different approach
recent_balances_data <- readr::read_csv(recent_balances_file) |>
  filter(Area %in% "World")

recent_balances <- recent_balances_data |>
  filter(Element %in% product_elements) |>
  filter(Item %in% product_items) |>
  select(-c(`Element Code`, `Item Code`, `Item Code (FBS)`, `Year Code`, `Flag`,
            `Area Code`, `Area Code (M49)`, `Area`, `Note`)) |>
  # Convert into Gt
  mutate(Value = if_else(Element %in% product_elements, Value * 1e-6, Value)) |>
  mutate(Unit = if_else(Element %in% product_elements, "Gt", Unit)) |>
  mutate(
    Element = if_else(
      Element %in% product_elements, paste0(Element, " [GtC]"), Element
    )
  ) |>
  # Convert food supply into PCal
  mutate(
    Value = if_else(Element == "Food supply (kcal)", Value * 1e-6, Value)
  ) |>
  mutate(Unit = if_else(Element == "Food supply (kcal)", "PCal", Unit)) |>
  mutate(
    Element = if_else(
      Element == "Food supply (kcal)", "Food [PCal]", Element
    )
  )

# Combine the historical and recent data
balances_data <- recent_balances |>
  full_join(hist_balances)

# Convert the data into GtC (carbon content)
carbon_data <- balances_data  %>%
  filter(Element %in%  paste0(product_elements, " [GtC]")) |>
  mutate(Value = Value * 0.45) |>
  mutate(Unit = "GtC")

# Add carbon data to the balances data to have all data in one table
production_data <- balances_data |>
  full_join(
    carbon_data,
    by = c("Item", "Element", "Year", "Unit", "Value")
  ) |>
  group_by(Element, Year, Unit) |>
  summarise(Value = sum(Value)) |>
  mutate(Item = "Total") |>
  filter(Unit != "Gt") |>
  select(!Unit) |>
  spread(Element, Value) |>
  mutate(`Crop production [GtC]` = `Production [GtC]`) |>
  select(!c("Residuals [GtC]", "Item")) |>
  mutate(gtc_per_pcal = `Food [GtC]` / `Food [PCal]`) |>
  mutate(`Feed [PCal]` = `Feed [GtC]` / gtc_per_pcal) |>
  mutate(`Losses [PCal]` = `Losses [GtC]` / gtc_per_pcal) |>
  mutate(`Seed [PCal]` = `Seed [GtC]` / gtc_per_pcal) |>
  mutate(`Other uses (non-food) [PCal]` = `Other uses (non-food) [GtC]` / gtc_per_pcal) |>
  mutate(`Crop production [PCal]` = `Crop production [GtC]` / gtc_per_pcal) |>
  select(
    c(
      "Year",
      "Crop production [GtC]", "Crop production [PCal]",
      "Food [GtC]", "Food [PCal]",
      "Feed [GtC]", "Feed [PCal]",
      "Losses [GtC]", "Losses [PCal]",
      "Seed [GtC]", "Seed [PCal]",
      "Other uses (non-food) [GtC]", "Other uses (non-food) [PCal]",
      "gtc_per_pcal"
    )
  )

write_csv(
  production_data,
  file.path(data_dir, "fao_crop_production.csv")
)
