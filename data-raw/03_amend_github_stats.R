# load libraries
library(tidyverse)
library(RSelenium)
library(rvest)

# make connection to docker run
# browser server
remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L,
  browserName = "firefox"
)

remDr$open()

# read in meta-data
df <- read.csv2(
  "data/annotated_article_list_screened.csv",
  sep = ",",
  header = TRUE
) |>
  select(
    -starts_with("issues"),
    -starts_with("contributors"),
    -starts_with("tests"),
    -starts_with("vignettes"),
    -starts_with("last_commit")
  ) |>
  mutate(
    repo_link_manual = gsub('^\\/|\\/$', '', repo_link_manual)
  )

github_links <- df |>
  filter(
    grepl("github", repo_link_manual)
  )

# read personal access token github
token <- readLines("TOKEN")

data <- lapply(github_links$repo_link_manual, function(url) {

  message(url)

  project_base <- gsub("https://github.com/","", url)
  api_commit_issues <- file.path("https://api.github.com/repos", project_base)
  api_contrib <- sprintf("https://api.github.com/repos/%s/contributors", project_base)

  # navigate to page and download
  # content
  remDr$navigate(url)
  content <- remDr$getPageSource()

  # read html file
  html_data <- read_html(content[[1]])

  # get contributions
  i <- 1
  contributors <- 0
  continue <- TRUE
  while(continue) {
    df <- gh(api_contrib, .token = token, page = i)
    contributors <- contributors + length(df)
    if(length(df) == 0){
      continue <- FALSE
    }
    i <- i + 1
  }

  # get the date of the last commit and number off issues
  df <- gh(api_commit_issues, .token = token)
  last_commit <- df$pushed_at |>
    as.POSIXct(format = "%Y-%m-%dT%H:%M:%SZ")
  issues <- df$open_issues

  # grab details on tests and vignettes
  package_content <- html_data |>
    html_elements("div.Details-content--hidden-not-important.js-navigation-container.js-active-navigation-container.d-md-block") |>
    html_elements("a") |>
    html_text2()

  vignettes <- ifelse(any(grepl("vignette", package_content)),TRUE, FALSE)
  tests <- ifelse(any(grepl("tests", package_content)),TRUE, FALSE)

  # time out
  Sys.sleep(2)

  return(
    data.frame(
      issues = issues,
      contributors = contributors,
      vignettes = vignettes,
      tests = tests,
      last_commit = last_commit
    )
  )
})

# bind data to original
data <- bind_rows(data)
github_links <- bind_cols(github_links, data)
df <- left_join(df, github_links)

# overwrite original
write.table(
  df,
  "data/annotated_article_list_screened.csv",
  col.names = TRUE,
  row.names = FALSE,
  quote = TRUE,
  sep = ","
)

# close session
remDr$close()
