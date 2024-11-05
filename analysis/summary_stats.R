# calculate age of the package
# set to the analysis date (not assigning dynamically
# as tied to when the data was generated Dec 20th 2022)
library(tidyverse)

df <- read.csv2(
  "data/annotated_article_list_screened.csv",
  sep = ",",
  header = TRUE
)

df <- df |>
  mutate(
    package_age = as.numeric(difftime(as.Date("2022-12-20"), as.Date(date_published)), units = "days")/365,
    maintenance_age = as.numeric(difftime(as.Date("2022-12-20"), as.Date(last_commit)), units = "days"),
    yearly_downloads = ifelse(yearly_downloads == 0, NA, yearly_downloads)
  )

df |>
  summarize(
    perc_on_cran = length(which(on_cran == TRUE))/n() * 100,
    perc_on_bioconductor = length(which(bioconductor == TRUE))/n() * 100,
    pkgs_on_github = length(which(grepl("github", repo_link_manual))),
    perc_on_github = pkgs_on_github/n() * 100,
    cran_attrition = length(which(on_cran == FALSE & was_on_cran == TRUE))/n() * 100,
    removal_age_mean = mean(package_age[which(on_cran == FALSE & was_on_cran == TRUE)]),
    removal_age_sd = sd(package_age[which(on_cran == FALSE & was_on_cran == TRUE)]),
    issues_mean = mean(issues, na.rm = TRUE),
    issues_sd = sd(issues, na.rm = TRUE),
    unit_test = mean(tests, na.rm = TRUE) * 100,
    vign = mean(vignettes, na.rm = TRUE) * 100,
    perc_sole_contrib = length(which(contributors == 1))/pkgs_on_github * 100,
    contributors_mean = mean(contributors, na.rm = TRUE),
    contributors_sd = sd(contributors, na.rm = TRUE),
    maintenance_age_mean = mean(maintenance_age, na.rm = TRUE),
    maintenance_age_sd = sd(maintenance_age, na.rm = TRUE),
    downloads_min = min(yearly_downloads, na.rm = TRUE),
    downloads_max = max(yearly_downloads, na.rm = TRUE),
    downloads_median = median(yearly_downloads, na.rm = TRUE)
  ) |>
  print()
