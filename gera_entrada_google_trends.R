library(tidyverse)
library(lubridate)

.HELP <- "
Usage:
Rscript gera_entrada_google_trends.R -p <proposicoes_filepath> -a <apelidos_filepath> 
"

#' @title Get arguments from command line option parsing
#' @description Get arguments from command line option parsing
get_args <- function() {
  args = commandArgs(trailingOnly=TRUE)
  
  option_list = list(
    optparse::make_option(c("-p", "--proposicoes_filepath"), 
                          type="character", 
                          default="data/proposicoes.csv",
                          help=.HELP, 
                          metavar="character"),
    optparse::make_option(c("-a", "--apelidos_filepath"), 
                          type="character", 
                          default="data/apelidos.csv",
                          help=.HELP, 
                          metavar="character"),
    optparse::make_option(c("-f", "--update_flag"), 
                          type="character", 
                          default=1,
                          help=.HELP, 
                          metavar="character")
  );
  
  opt_parser <- optparse::OptionParser(option_list = option_list) 
  opt <- optparse::parse_args(opt_parser)
  return(opt);
}

## Process args
args <- get_args()
print(args)

proposicoes_filepath <- args$proposicoes_filepath
apelidos_filepath <- args$apelidos_filepath
update_flag <- args$update_flag

if (update_flag == 1 | !file.exists(apelidos_filepath)) {
  cat(paste0("Criando novo arquivo em"), apelidos_filepath, "...\n")
  
  source(here::here("scripts/keywords/generate_keywords.R"))
  
  proposicao <- read_csv(proposicoes_filepath)
  df_google_trends <- generate_keywords(proposicao)
  
  write_csv(df_google_trends, apelidos_filepath)
  
  cat("Feito!\n")
}
