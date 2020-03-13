#!/usr/bin/env Rscript
library(magrittr)
library(tidyverse)

source(here::here("scripts/tweets_from_last_days/generate_tweets_from_last_days.R"))

help <- "
Usage:
Rscript export_tweets_from_last_days.R <pls_words_filepath> <data_path>
"

## Process args
args <- commandArgs(trailingOnly = TRUE)
min_num_args <- 2
if (length(args) < min_num_args) {
  stop(paste("Wrong number of arguments!", help, sep = "\n"))
}
pls_words_filepath <- args[1]
data_path <- args[2]

cat("Instalando o pacote do leggoTrends...")
## Install local repository R package version
devtools::install()
devtools::install_github("mrdwab/SOfun")

## Read PLs list
if (!file.exists(pls_words_filepath)) {
  cat("Arquivo com os apelidos não encontrado. Gerando arquivo...")
  source(here::here("scripts/keywords/generate_keywords.R"))
  words_df <- generate_keywords(readr::read_csv(here::here("data/proposicoes.csv")))
  
} else {
  words_df <- readr::read_csv(pls_words_filepath)
}

cat("Gerando dados de tweets sobre proposições e os de trends (sumarizado por proposição)...\n")
new_tweets <- search_last_tweets(words_df) %>%
  dplyr::mutate_all(~ as.character(.))

trends <- leggoTrends::generate_twitter_trends(new_tweets)

write_csv(new_tweets, paste0(data_path, "/tweets.csv"))
write_csv(trends, paste0(data_path, "/trends.csv"))

cat("Feito!\n")
