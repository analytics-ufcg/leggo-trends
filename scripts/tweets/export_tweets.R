#!/usr/bin/env Rscript
library(tidyverse)

source(here::here("scripts/tweets/fetcher_tweets.R"))

if (!require(optparse)) {
  install.packages("optparse")
  suppressWarnings(suppressMessages(library(optparse)))
}

option_list = list(
  make_option(
    c("-u", "--url"),
    type = "character",
    help = "URL da api do Leggo Twitter",
    metavar = "character"
  ),
  make_option(
    c("-i", "--data_inicial"),
    type = "character",
    default = NULL,
    help = "Data inicial no formato YYYY-MM-DD",
    metavar = "character"
  ),
  make_option(
    c("-f", "--data_final"),
    type = "character",
    default = NULL,
    help = "Data final no formato YYYY-MM-DD",
    metavar = "character"
  ),
  make_option(
    c("-o", "--out"),
    type = "character",
    default = here::here("data/tweets_proposicoes.csv"),
    help = "caminho do arquivo de saída deste script [default= %default]",
    metavar = "character"
  )
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

url <- opt$url
data_inicial <- opt$data_inicial
data_final <- opt$data_final
output_path <- opt$out

print(opt)
cat("Baixando dados de Twitter por proposição e semana...\n")

tweets <- fetch_proposicoes_tweets(url, data_inicial, data_final)

write_csv(tweets, paste0(output_path))

cat("Feito!\n")
