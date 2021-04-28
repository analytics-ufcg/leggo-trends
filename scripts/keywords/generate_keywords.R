#' @title Gera o datframe com palavras-chave para o filtro dos tweets
#' @description A partir do dataframe de proposições, retorna um dataframe contendo as colunas
#' nome_formal e apelido processadas.
#' @param proposicoes Dataframe de proposições
#' @return Dataframe com apelido e nome formal processadas.
generate_keywords <- function(proposicoes) {
  library(tidyverse)
  
  df_apelidos <-
    proposicoes %>%
    select(id_leggo, id_ext, casa, nome_formal = sigla, apresentacao = data_apresentacao) %>%
    distinct(id_leggo, id_ext, casa, .keep_all = T)
  
  return(df_apelidos)
}
