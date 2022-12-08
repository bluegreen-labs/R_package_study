# data for meta-data analysis

The `articles_list.csv` is the original list of data using the search function on
the journal website for the term "package" in the application category. In this
study I will focus on R packages alone due to familiarity as a developer.

Data are then automatically amended with additional meta-data such as citations
the publication date, as well as the scraped github repos if any and any mention
of CRAN installation routines.

This data is then manually screened for correctness. The included fields are:

- study title
- link of the article
- doi of the article
- publication date
- github link
- mention of CRAN
- mention of Bioconductor
- package install routine instructions
- package name
- repository

Additional tests included after cleaning are:

- installation success (does the package install CRAN / repo)
- last commit to repo (if any)
- number of contributors to the package repository, not authors

