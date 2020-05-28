#!/usr/bin/env Rscript
library(tidyverse)

source(here::here("scripts/parlamentares_timeline/fetch_parlamentares_timeline.R"))

if(!require(optparse)){
  install.packages("optparse")
  suppressWarnings(suppressMessages(library(optparse)))
}

option_list = list(
  make_option(
    c("-o", "--out"),
    type = "character",
    default = here::here("data/timelines.csv"),
    help = "nome do arquivo com os dados de linha do tempo [default= %default]",
    metavar = "character"
  )
) 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

output_filepath <- opt$out

cat("Baixando linhas do tempo dos parlamentares...\n")

timelines <- fetch_timelines()

write_csv(timelines, output_filepath)

cat("Feito!\n")
