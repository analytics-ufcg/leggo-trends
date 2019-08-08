#!/usr/bin/env Rscript
library(magrittr)
library(tidyverse)

help <- "
Usage:
Rscript update_tweets.R <pls_words_filepath> <data_path>
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

current_tweets <- readr::read_csv(paste0(data_path, "/tweets.csv"),
                                  col_types = list(
                                    .default = readr::col_character()))

new_tweets <- leggoTrends::get_tweets_pls(pls_words) %>%
  dplyr::mutate_all(~ as.character(.))

old_tweets = current_tweets %>% dplyr::filter(!(status_id %in% new_tweets$status_id))

updated_tweets <- bind_rows(new_tweets, old_tweets)

trends <- leggoTrends::generate_twitter_trends(updated_tweets)

write_csv(updated_tweets, paste0(data_path, "/tweetssss.csv"))

write_csv(trends, paste0(data_path, "/trends.csv"))
