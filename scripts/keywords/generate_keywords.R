#' @title Gera o datframe com palavras-chave para o filtro dos tweets
#' @description A partir do dataframe de proposições, retorna um dataframe contendo as colunas
#' nome_formal e apelido processadas.
#' @param proposicoes Dataframe de proposições
#' @param interesses Dataframe de interesses
#' @return Dataframe com apelido e nome formal processadas.
generate_keywords <- function(proposicoes, interesses) {
  library(tidyverse)
  source(here::here("scripts/utils/utils.R"))
  
  prop_interesses <- proposicoes %>% 
    left_join(interesses %>% 
                select(id_leggo, interesse, apelido, keywords), 
              by = c("id_leggo"))
  
  df_apelidos <- 
    prop_interesses %>% 
    mutate(apelido = .remove_pontuacao(apelido),
           keywords = .remove_pontuacao(keywords),
           nome_formal = paste0(sigla_tipo, " ", numero, "/", lubridate::year(data_apresentacao))) %>% 
    select(id_leggo, id_ext, casa, apelido, nome_formal, apresentacao = data_apresentacao, interesse, keywords)
  
  return(df_apelidos)
}
