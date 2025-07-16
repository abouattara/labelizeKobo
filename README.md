# Package to labelize kobotoolbox, ODK, ONA data with .sps file

This repository contains resources developed to apply labels to survey data from KoboToolbox, ODK, or ONA in R using label files (e.g., .sps format). It facilitates the transformation of raw datasets into human-readable formats by automatically applying variable and value labels.

# Package name : labelizeKobo

Apply SPSS (.sps) labels to KoboToolbox, ODK or ONA data in R.

## Installation

```r
remotes::install_github("https://github.com/abouattara/labelize-kobotoolbox-dat/labelizeKobo")

library(labelizeKobo)

data <- readxl::read_xlsx("my_data.xlsx")
labelled_data <- labelize_my_data(data, "labels.sps")

View(labelled_data)
haven::write_dta(data_xls, paste0(getwd(),"/my_data.dta"))
```
