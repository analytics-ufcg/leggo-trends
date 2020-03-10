#!/usr/bin/env Rscript
library(magrittr)
library(tidyverse)

source(here::here("scripts/generate_30_days_tweets.R"))

help <- "
Usage:
Rscript export_tweets_from_last_3_months.R <pls_words_filepath> <data_path>
"

## Process args
args <- commandArgs(trailingOnly = TRUE)
min_num_args <- 2
if (length(args) < min_num_args) {
  stop(paste("Wrong number of arguments!", help, sep = "\n"))
}
pls_words_filepath <- args[1]
data_path <- args[2]

## Install local repository R package version
devtools::install()
devtools::install_github("mrdwab/SOfun")

## Read PLs list
pls_words <- readr::read_csv(pls_words_filepath)

new_tweets <- leggoTrends::get_tweets_pls(pls_words) %>%
  dplyr::mutate_all(~ as.character(.))

trends <- leggoTrends::generate_twitter_trends(new_tweets)

write_csv(new_tweets, paste0(data_path, "/tweets.csv"))

write_csv(trends, paste0(data_path, "/trends.csv"))