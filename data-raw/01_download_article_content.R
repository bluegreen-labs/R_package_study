# load libraries
library(RSelenium)
library(tidyverse)
library(rvest)

# make connection to docker run
# browser server
remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L,
  browserName = "firefox"
)

remDr$open()

# read in article list
articles <- read.csv("data/article_list.csv")

# loop over all articles and download the
# html page (all these can be read freely
# so should provide true content)
lapply(articles$links[321:nrow(articles)], function(url){

  message(url)
  if(file.exists(
    file.path("data-raw/articles/", basename(url),
              paste0(basename(url),".html")))) {
    return(NULL)
  }

  # navigate to page and download
  # content
  remDr$navigate(url)
  content <- remDr$getPageSource()

  # create output directory
  dir.create(file.path("data-raw/articles/", basename(url)), recursive = TRUE)

  # write html content to file
  writeLines(
    content[[1]],
    file.path("data-raw/articles/", basename(url),
              paste0(basename(url),".html"))
    )

  # sleep for a second not to
  # wake publishing giants
  Sys.sleep(5)
})

# close session
remDr$close()
