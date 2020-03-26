#' @title Gera o datframe com palavras-chave para o filtro dos tweets
#' @description A partir do dataframe de proposições, retorna um dataframe contendo as colunas
#' nome_formal e apelido processadas.
#' @param proposicoes Dataframe de proposições
#' @return Dataframe com apelido e nome formal processadas.
generate_keywords <- function(proposicoes) {
  library(tidyverse)
  
  df_google_trends <- 
    proposicoes %>% 
    mutate(apelido = iconv(apelido, from="UTF-8", to="ASCII//TRANSLIT") %>% 
             stringr::str_replace_all("[[:punct:]]", "") %>% 
             stringr::str_replace_all("[[:space:]]{2}", " ") %>% 
             substring(1, 85),
           nome_formal = paste0(sigla_tipo, " ", numero, "/", lubridate::year(data_apresentacao))) %>% 
    select(id_leggo, id_ext, casa, apelido, nome_formal, apresentacao = data_apresentacao)
  
  return(df_google_trends)
}
