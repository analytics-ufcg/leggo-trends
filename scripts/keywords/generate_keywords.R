#' @title Gera o datframe com palavras-chave para o filtro dos tweets
#' @description A partir do dataframe de proposições, retorna um dataframe contendo as colunas
#' nome_formal e apelido processadas.
#' @param proposicoes Dataframe de proposições
#' @return Dataframe com apelido e nome formal processadas.
generate_keywords <- function(proposicoes) {
  library(tidyverse)
  
  processed_proposicoes <- .process_proposicoes(proposicoes)
  
  df_google_trends <- 
    processed_proposicoes %>% 
    mutate(apelido = iconv(apelido, from="UTF-8", to="ASCII//TRANSLIT")) %>% 
    select(id_ext, casa, apelido, nome_formal, apresentacao)
  
  return(df_google_trends)
}

#' @title Filtra as proposições que não são NAs de uma coluna
#' @description A partir do dataframe de proposições, retorna um dataframe contendo 
#' a coluna a ser filtrada e a coluna 'apelido'
#' @param proposicoes Dataframe de proposições
#' @param column Nome da coluna a ser filtrada.
#' @return Dataframe com coluna filtrada e apelido.
.filter_proposicoes <- function(proposicoes, column) {
  library(tidyverse)
  df <- proposicoes %>% 
    dplyr::filter(!is.na(!!column)) %>% 
    dplyr::select(!!column, apelido)
  
  return(df)
}


#' @title Processa as proposições para serem convertidas em apelidos
#' @description A partir do dataframe de proposições, retorna um dataframe contendo 
#' no formato a ser usado pela função que gera as palavras-chave
#' @param proposicoes Dataframe de proposições
#' @return Dataframe com colunas id_ext, casa, nome_formal, apelido e apresentacao
.process_proposicoes <- function(proposicoes) {
  library(tidyverse)
  
  proposicoes_camara <- .filter_proposicoes(proposicoes, quo(id_camara)) %>% 
    .process_proposicoes_camara()
  
  proposicoes_senado <- .filter_proposicoes(proposicoes, quo(id_senado)) %>% 
    .process_proposicoes_senado()
  
  proposicoes_alt <- proposicoes_camara %>% 
    rbind(proposicoes_senado)
  
  return(proposicoes_alt)
  
}

#' @title Processa as proposições da Câmara para serem convertidas em apelidos
#' @description A partir do dataframe de proposições da Câmara, retorna um dataframe contendo 
#' no formato a ser usado pela função que gera as palavras-chave
#' @param proposicoes_camara Dataframe de proposições
#' @return Dataframe com colunas id_ext, casa, nome_formal, apelido e apresentacao
.process_proposicoes_camara <- function(proposicoes_camara) {
  library(tidyverse)
  
  proposicoes_camara <- proposicoes_camara %>%
    dplyr::mutate(data = map(id_camara,
                             rcongresso::fetch_proposicao_camara)) %>%
    tidyr::unnest(data)
  
  proposicoes_camara <- proposicoes_camara %>%
    dplyr::mutate(casa = "camara",
                  apresentacao = gsub('T', ' ', dataApresentacao) %>%
                    as.Date(),
                  nome_formal = paste0(siglaTipo, " ", numero, "/", lubridate::year(apresentacao))) %>%
    dplyr::select(id_ext = id_camara,
                  casa,
                  nome_formal,
                  apelido,
                  apresentacao)
  
  return(proposicoes_camara)
  
}

#' @title Processa as proposições do Senado para serem convertidas em apelidos
#' @description A partir do dataframe de proposições do Senado, retorna um dataframe contendo 
#' no formato a ser usado pela função que gera as palavras-chave
#' @param proposicoes_senado Dataframe de proposições
#' @return Dataframe com colunas id_ext, casa, nome_formal, apelido e apresentacao
.process_proposicoes_senado <- function(proposicoes_senado) {
  library(tidyverse)
  
  proposicoes_senado <- proposicoes_senado %>%
    dplyr::mutate(data = map(id_senado,
                             rcongresso::fetch_proposicao_senado)) %>%
    tidyr::unnest(data)
  
  proposicoes_senado <- proposicoes_senado %>%
    dplyr::mutate(casa = "senado",
                  apresentacao = as.Date(data_apresentacao)) %>%
    dplyr::select(id_ext = id_senado,
                  casa,
                  nome_formal = descricao_identificacao_materia,
                  apelido,
                  apresentacao)
  
  return(proposicoes_senado)
}
