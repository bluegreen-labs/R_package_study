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

data <- lapply(html_files, function(file){

  # read html file
  html_data <- read_html(file)

  content <- html_data |>
    html_elements("section.article-section.article-section__full") |>
    html_text()

  references <- html_data |>
    html_elements("section.article-section.article-section__full") |>
    html_elements("section#references-section") |>
    html_text()

  if(length(references)==0){

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
    paste0(tools::file_path_sans_ext(file),".txt")
  )

  # Mention of CRAN or Bioconductor
  cran <- grepl("CRAN", content)
  bioconductor <- grepl("Bioconductor", content)

  # grab github link, assumes first mention to be
  # the package
  links <- html_data |>
    html_elements("section.article-section.article-section__full") |>
    html_elements("a") |>
    html_text()
  github <- links[grep("/github", links)][1]

  # was an installation routine mentioned
  package_install <- grepl(glob2rx("install.packages*"), content)

  # grab number of citations
  citations <- html_data |>
    html_elements("div.epub-section.cited-by-count") |>
    html_text2()
  citations <- as.numeric(gsub("Citations: ","", citations))
  citations <- ifelse(length(citations) == 0, 0, citations)

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
  sep = ','
  )

# join with data from content
data <- left_join(article_meta_data, data)

# write to file
write.table(
  data,
  "data/annotated_article_list.csv",
  col.names = TRUE,
  row.names = FALSE,
  quote = TRUE,
  sep = ","
)
