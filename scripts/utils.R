
download_fao_data <- function(fao_code, data_dir) {
  # Download FAO dataset
  # Get the dataset
  meta_data <- FAOSTAT::read_bulk_metadata(fao_code) |>
    dplyr::filter(FileContent == "All Data Normalized") # nolint

  tmp_dir <- tempdir()

  FAOSTAT::download_faostat_bulk(
    meta_data$URL,
    data_folder = tmp_dir
  )

  tmp_dataset <- unzip(
    file.path(tmp_dir, basename(meta_data$URL)),
    exdir = tmp_dir
  )

  tmp_data <- tmp_dataset[
    which(
      tools::file_path_sans_ext(basename(tmp_dataset)) == tools::file_path_sans_ext(basename(meta_data$URL)) # nolint
    )
  ]

  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

  data <- file.path(data_dir, basename(tmp_data))
  # Move the file to the data folder
  file.copy(
    tmp_data,
    file.path(data_dir, basename(tmp_data)),
    overwrite = TRUE
  )

  return(data)
}

# production_data <- download_fao_data(fao_code = "QCL", data_dir = data_dir)

# historical_balances_data <- download_fao_data(
#   fao_code = "FBSH",
#   data_dir = data_dir
# )

# recent_balances_data <- download_fao_data(
#   fao_code = "FBS",
#   data_dir = data_dir
# )
