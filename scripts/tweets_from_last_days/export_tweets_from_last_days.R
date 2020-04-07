#!/usr/bin/env Rscript
library(magrittr)
library(tidyverse)

source(here::here("scripts/tweets_from_last_days/fetch_tweets_from_last_days.R"))
source(here::here("scripts/popularity/process_popularity.R"))

if(!require(optparse)){
  install.packages("optparse")
  suppressWarnings(suppressMessages(library(optparse)))
}

option_list = list(
  make_option(
    c("-a", "--apl"),
    type = "character",
    default = here::here("data/apelidos.csv"),
    help = "caminho do arquivo de apelidos [default= %default]",
    metavar = "character"
  ),
  make_option(
    c("-o", "--out"),
    type = "character",
    default = here::here("data/"),
    help = "nome da pasta destino dos arquivos de saída [default= %default]",
    metavar = "character"
  )
) 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

pls_words_filepath <- opt$apl
data_path <- opt$out

## Read PLs list
if (!file.exists(pls_words_filepath)) {
  stop("Arquivo com os apelidos não encontrado. Execute o script gera_entrada_google_trends.R")
  
} else {
  words_df <- readr::read_csv(pls_words_filepath)
}

cat("Gerando dados de tweets sobre proposições e os de trends (sumarizado por proposição)...\n")
new_tweets <- search_last_tweets(words_df) %>%
  dplyr::mutate_all(~ as.character(.))

trends <- leggoTrends::generate_twitter_trends(new_tweets) %>%
  calculate_populatiry_score()

write_csv(new_tweets, paste0(data_path, "/tweets.csv"))
write_csv(trends, paste0(data_path, "/trends.csv"))

cat("Feito!\n")
