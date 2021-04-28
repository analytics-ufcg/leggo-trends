library(tidyverse)
library(lubridate)
library(dotenv)

.HELP <- "
Usage:
Rscript gera_entrada_google_trends.R -p <proposicoes_filepath> -i <interesses_filepath> -a <apelidos_filepath> <config_filepath>
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
                          metavar="character"),
    optparse::make_option(c("-e", "--config_filepath"),
                          type="character",
                          default=here::here("configuration.env"),
                          help=.HELP,
                          metavar="character")
  );
  
  opt_parser <- optparse::OptionParser(option_list = option_list) 
  opt <- optparse::parse_args(opt_parser)
  return(opt);
}

get_lotes <- function(df_apelidos){

  props_day <- as.numeric(Sys.getenv("PROPOSITIONS_DAY"))
  nprops <- nrow(df_apelidos)
  nlotes <- ceiling(nprops / props_day)

  lotes <- sort(rep(seq(1, nlotes), ceiling(nprops/nlotes))[1:nprops])	
  return(lotes)
}

## Process args
args <- get_args()
print(args)

proposicoes_filepath <- args$proposicoes_filepath
apelidos_filepath <- args$apelidos_filepath
update_flag <- args$update_flag
config_path <- args$config_filepath

if (update_flag == 1 | !file.exists(apelidos_filepath)) {
  cat(paste0("Criando novo arquivo em"), apelidos_filepath, "...\n")
  
  source(here::here("scripts/keywords/generate_keywords.R"))
 
  load_dot_env(config_path)

  proposicoes <- read_csv(proposicoes_filepath)
  df_apelidos <- generate_keywords(proposicoes)
 
  lotes <- get_lotes(df_apelidos)
  df_apelidos <- df_apelidos %>% mutate(lote = lotes)

  write_csv(df_apelidos, apelidos_filepath)
  
  cat("Feito!\n")
}
