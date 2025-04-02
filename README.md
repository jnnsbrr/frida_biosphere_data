# FRIDA Biosphere Data

This repository contains a collection of R scripts to generate input data sets for the FRIDA model. The FRIDA model is hosted at [WorldTransFRIDA](https://github.com/metno/WorldTransFRIDA).
The scripts download and process data for usage in FRIDA's "Land Use and Agriculture" (biosphere) module.

## Data Sources

The input datasets are derived (currently only) from available FAOSTAT datasets provided by the Food and Agriculture Organization of the United Nations (FAO) and contain:

1. [**Land use**](./data/fao_land_use.csv) Land use in Mha for land system types of FRIDA: Forest, Grassland, Cropland & Habitable land
2. [**Crop production**](./data/fao_crop_production.csv) Production in PCal & GtC for different uses: Food, Feed, Seed, Losses & Others
3. [**Food Production**](./data/fao_food_production.csv) Food production in PCal in terms of Vegetal products & Animal products (land & aquatic)
4. [**Fertilization**](./data/fao_fertilization.csv) Fertilizer application (artificial fertilizer & livestock manure) in MtN


## Usage
To use the scripts, you need to have R installed on your system. You can run the scripts in RStudio or any other R environment.
1. Clone the repository to your local machine.
2. Open the R script files in your R environment.
3. Adjust the `project_dir` and run the numbered scripts in the repository to generate the input datasets.


## Questions/Problems

In case of questions / problems please contact Jannes Breier jannesbr@pik-potsdam.de.
