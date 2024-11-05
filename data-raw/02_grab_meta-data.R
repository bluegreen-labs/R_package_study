# load libraries
library(tidyverse)
library(rvest)

# update html files if any
html_files <- list.files(
  "data-raw/articles/",
  "*.html",
  recursive = TRUE,
  full.names = TRUE
)

data <- lapply(html_files, function(file) {
  # read html file
  html_data <- read_html(file)

  content <- html_data |>
    html_elements("section.article-section.article-section__full") |>
    html_text()

  references <- html_data |>
    html_elements("section.article-section.article-section__full") |>
    html_elements("section#references-section") |>
    html_text()

  # If no references were found this is a redirect to a pdf
  # or some other fake page, flag as unprocessed
  if (length(references) == 0) {
    df <- tibble(
      doi = basename(file),
      processed = FALSE,
      citations = NA,
      cran = NA,
      bioconductor = NA,
      github_link = NA,
      package_install = NA
    )
    return(df)
  }

  # replace references with nothing in content
  content <- gsub(references, "", content, fixed = TRUE)

  # write html content to txt
  # for manual inspection
  writeLines(
    content,
    paste0(tools::file_path_sans_ext(file), ".txt")
  )

  # Mention of CRAN or Bioconductor
  cran <- grepl("CRAN", content, ignore.case = TRUE)
  bioconductor <- grepl("Bioconductor", content, ignore.case = TRUE)

  # grab github link, assumes first mention to be
  # the package
  links <- html_data |>
    html_elements("section.article-section.article-section__full") |>
    html_elements("a") |>
    html_text()
  github <- links[grep("/github", links)][1]

  # grab number of citations
  citations <- html_data |>
    html_elements("div.epub-section.cited-by-count") |>
    html_text2()
  citations <- as.numeric(gsub(",", "", gsub("Citations: ", "", citations)))
  citations <- ifelse(length(citations) == 0, 0, citations)

  # grab installation references
  package_install_cran <- grepl(
    glob2rx("*install.package*"),
    content,
    ignore.case = TRUE
  )
  package_install_bioc <- grepl(
    glob2rx("*install(*"),
    content,
    ignore.case = TRUE
  )
  package_install <- ifelse(
    any(c(package_install_bioc, package_install_cran)),
    TRUE,
    FALSE
  )

  df <- dplyr::tibble(
    doi = tools::file_path_sans_ext(basename(file)),
    processed = TRUE,
    citations = citations,
    cran = cran,
    bioconductor = bioconductor,
    repo_link = github,
    package_install = package_install
  )

  return(df)
})

# bind data
data <- bind_rows(data)

# read in full meta-data
article_meta_data <- read.table(
  "data/article_list.csv",
  header = TRUE,
  sep = ","
)

# join with data from content
data <- left_join(article_meta_data, data) |>
  select(-year)

# drop processed flag if all sites were
# properly processed
if (all(data$processed)) {
  data <- data |>
    select(-processed)
}

# grab package name from title (provisional)
package_names <- sub(":.*$", "", data$titles)
package_names <- lapply(package_names, function(package) {
  strings <- strsplit(package, " ")[[1]]
  ifelse(length(strings) > 1, NA, strings)
})
data$package_name <- do.call("rbind", package_names)

# write to file
write.table(
  data,
  "data/annotated_article_list.csv",
  col.names = TRUE,
  row.names = FALSE,
  quote = TRUE,
  sep = ","
)
