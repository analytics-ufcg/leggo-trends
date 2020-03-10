#' @title Gera o datframe com palavras-chave para o filtro dos tweets
#' @description A partir do dataframe de proposições, retorna um dataframe contendo as colunas
#' nome_formal e apelido processadas.
#' @param proposicoes Dataframe de proposições
#' @return Dataframe com apelido e nome formal processadas.
generate_keywords <- function(proposicoes) {
  library(tidyverse)
  df_google_trends <- 
    proposicoes %>% 
    mutate(apresentacao = as.Date(lubridate::ymd_hms(data_apresentacao)),
           nome_formal = paste0(sigla_tipo, " ", numero, "/", lubridate::year(apresentacao)),
           apelido = iconv(apelido, from="UTF-8", to="ASCII//TRANSLIT")) %>% 
    select(id_leggo, apelido, nome_formal, apresentacao, id_ext, casa) %>% 
    group_by(apelido) %>% 
    arrange(apelido, desc(apresentacao)) %>%  
    slice(n())
  
  return(df_google_trends)
}