# check cran status
library(tidyverse)
library(cranlogs)

df <- read.csv2(
  "data/annotated_article_list_screened.csv",
  sep = ",",
  header = TRUE
)

# check if available on (current) cran
df <- df |>
  mutate(
    on_cran = package_name %in% available.packages()[, 1]
  )

# check if ever listed on cran
if (!file.exists("data-raw/cran_archive.rds")) {
  download.file(
    "https://cran.rstudio.com/src/contrib/Meta/archive.rds",
    "data-raw/cran_archive.rds"
  )
}
archive <- readRDS("data-raw/cran_archive.rds")
df <- df |>
  mutate(
    was_on_cran = tolower(package_name) %in% names(archive)
  )

df <- df |>
  rowwise() |>
  mutate(
    yearly_downloads = sum(
      cran_downloads(
        from = "2022-01-01",
        to = "2022-12-20",
        packages = package_name)$count)
  )
#
# # overwrite original
# write.table(
#   df,
#   "data/annotated_article_list_screened.csv",
#   col.names = TRUE,
#   row.names = FALSE,
#   quote = TRUE,
#   sep = ","
# )
