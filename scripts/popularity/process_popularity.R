library(tidyverse)

#' @title Processa dados de pressão
#' @description A partir de um dataframe com os tweets já sumarizados (trends) e do caminho para
#' os arquivos processados do google Trends, combina-os em um indice único e retorna um novo
#' dataframe com todas as colunas de ambos os dataframes mais um índice combinado.
#' @param twitter_filepath Caminho do dataframe de tweets sobre as proposições
#' @param pops_folderpath Caminho para os arquivos de destino do script fetch_google_trends.py
#' @param interesses_filepath Caminho para o csv contendo o mapeamento de id_leggo para interesses
#' @return Dataframe com índices do Google Trends e Twitter por PL e semana
combine_indexes <-
  function(twitter_filepath = NULL,
           pops_folderpath,
           interesses_filepath,
           proposicoes_filepath) {
    source(here::here("scripts/tweets/process_tweets.R"))
    #source(here::here("scripts/google_trends/process_google_trends.R"))
    
    #google_trends <- .bind_trends(pops_folderpath, interesses_filepath)
    google_trends <- tibble(
      id_leggo = character(),
      id_ext = integer(),
      casa = character(),
      interesse = character(),
      max_pressao_principal = double(),
      max_pressao_rel = double(),
      maximo_geral_perc = double(),
      date = as.Date(character())
    )
    
    twitter_trends <-
      read_tweets_trends(twitter_filepath,
                         interesses_filepath,
                         proposicoes_filepath)
    
    trends <- dplyr::full_join(
      google_trends,
      twitter_trends,
      by = c("id_leggo", "interesse", "id_ext", "casa", "date")
    ) %>%
      dplyr::mutate(
        twitter_mean_popularity = dplyr::if_else(is.na(twitter_trends), 0, twitter_trends),
        trends_max_popularity = dplyr::if_else(is.na(maximo_geral_perc), 0, maximo_geral_perc)
      ) %>%
      dplyr::mutate_at(vars(c("max_pressao_principal", "max_pressao_rel")),
                       ~ replace_na(., 0)) %>% 
      dplyr::mutate(popularity = twitter_mean_popularity) %>%
      dplyr::select(
        id_leggo,
        id_ext,
        casa,
        interesse,
        date,
        trends_max_pressao_principal = max_pressao_principal,
        trends_max_pressao_rel = max_pressao_rel,
        trends_max_popularity,
        twitter_mean_popularity,
        popularity
      ) %>%
      dplyr::distinct()
    
    return(trends)
  }