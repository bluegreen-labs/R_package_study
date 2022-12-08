library(RSelenium)
library(tidyverse)
library(rvest)

# list html files if any
html_files <- list.files("data-raw", "*.html", full.names = TRUE)

if (length(html_files) == 0) {
  # run with: docker run -p 4445:4444 selenium/standalone-firefox:2.53.1

  # search for package & (Applications || APPLICATIONS)
  url1 <- "https://besjournals.onlinelibrary.wiley.com/action/doSearch?AllField=package&SeriesKey=2041210x&pageSize=500&startPage=&rel=nofollow&ContentItemCategory=Application"
  url2 <- "https://besjournals.onlinelibrary.wiley.com/action/doSearch?AllField=package&SeriesKey=2041210x&pageSize=500&startPage=&rel=nofollow&ContentItemCategory=APPLICATION"
  url3 <- "https://besjournals.onlinelibrary.wiley.com/action/doSearch?AllField=package&SeriesKey=2041210x&pageSize=500&startPage=&rel=nofollow&ContentItemCategory=PRACTICAL%20TOOLS"

  urls <- c(url1, url2, url3)

  remDr <- remoteDriver(
    remoteServerAddr = "localhost",
    port = 4445L,
    browserName = "firefox"
  )

  remDr$open()

  lapply(seq(1, length(urls), 1), function(idx){
    remDr$navigate(urls[idx])
    content <- remDr$getPageSource()
    writeLines(
      content[[1]],
      file.path("data-raw/",
                paste0("content_", idx,".html")))
  })

  remDr$close()

  # update html files if any
  html_files <- list.files("data-raw", "*.html", full.names = TRUE)
}

data <- lapply(html_files, function(file){
  html_data <- read_html(file)

  # get title
  titles <- html_data |>
    html_elements("span.hlFld-Title") |>
    html_text()

  # get date published
  date_published <- html_data |>
    html_elements("p.meta__epubDate") |>
    html_text()
  date_published <- lubridate::dmy(date_published)
  date_published <- gsub("First published: ","", date_published)

  # get links
  links <- html_data |>
    html_elements("a.publication_title.visitable") |>
    html_attr("href")
  links <- paste0("https://besjournals.onlinelibrary.wiley.com", links)

  # get doi
  doi <- basename(links)

  # get package name
  # first approximat based on regexpr
  package_names <- sub(':.*$','', titles)
  package_names <- lapply(package_names, function(package){
    strings <- strsplit(package," ")[[1]]
    ifelse(length(strings)>1, NA, strings)
  })
  package_names <- do.call("rbind", package_names)

  df <- tibble(
    titles = titles,
    r_package = ifelse(grepl("r package", titles, ignore.case = TRUE), TRUE, FALSE),
    links = links,
    doi = doi,
    date_published = date_published
    )

  return(df)
})

data <- bind_rows(data) |>
  mutate(
    date_published = as.Date(date_published),
    year = format(date_published, "%Y")
  )

write.table(
  data,
  "data/article_list.csv",
  col.names = TRUE,
  row.names = FALSE,
  quote = TRUE,
  sep = ","
  )
