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
                          default="exported/proposicoes.csv",
                          help=.HELP, 
                          metavar="character"),
    optparse::make_option(c("-a", "--apelidos_filepath"), 
                          type="character", 
                          default="exported/apelidos.csv",
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

proposicao <- read_csv(proposicoes_filepath)

df_google_trends <- 
  proposicao %>% 
  mutate(apresentacao = as.Date(ymd_hms(data_apresentacao)),
         nome_formal = paste0(sigla_tipo, " ", numero, "/", year(apresentacao)),
         apelido = iconv(apelido, from="UTF-8", to="ASCII//TRANSLIT")) %>% 
  select(id_leggo, apelido, nome_formal, apresentacao, id_ext, casa) %>% 
  group_by(apelido) %>% 
  arrange(apelido, desc(apresentacao)) %>%  
  slice(n())

write_csv(df_google_trends, apelidos_filepath)