library(tidyverse)

#' @title Processa dados de pressão
#' @description A partir de um dataframe com os tweets já sumarizados (trends) e do caminho para
#' os arquivos processados do google Trends, combina-os em um indice único e retorna um novo
#' dataframe com todas as colunas de ambos os dataframes mais um índice combinado.
#' @param twitter_filepath Caminho do dataframe de tweets sobre as proposições
#' @param pops_folderpath Caminho para os arquivos de destino do script fetch_google_trends.py
#' @param interesses_filepath Caminho para o csv contendo o mapeamento de id_leggo para interesses
#' @param proposicoes_filepath Caminho para o csv de proposições
#' @return Dataframe com índices do Google Trends e Twitter por PL e semana
combine_indexes <-
  function(twitter_filepath = NULL,
           pops_folderpath,
           interesses_filepath,
           proposicoes_filepath) {
    source(here::here("scripts/tweets/process_tweets.R"))
    #source(here::here("scripts/google_trends/process_google_trends.R"))
    
    # google_trends <- .bind_trends(pops_folderpath, interesses_filepath)
    
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
      process_tweets_trends(twitter_filepath,
                            interesses_filepath,
                            proposicoes_filepath)
    
    trends <- dplyr::full_join(
      google_trends,
      twitter_trends,
      by = c("id_leggo", "interesse", "date", "id_ext", "casa")
    ) %>%
      mutate_at(
        vars(
          max_pressao_principal,
          max_pressao_rel,
          maximo_geral_perc,
          user_count,
          sum_interactions,
          pressao_twitter
        ),
        list( ~ ifelse(is.na(.), 0, .))
      ) %>%
      mutate(trends_max_popularity = maximo_geral_perc,
             popularity = pressao_twitter * 100) %>%
      select(
        id_leggo,
        id_ext,
        casa,
        interesse,
        date,
        trends_max_pressao_principal = max_pressao_principal,
        trends_max_pressao_rel = max_pressao_rel,
        trends_max_popularity,
        user_count,
        sum_interactions,
        twitter_mean_popularity = pressao_twitter,
        popularity
      ) %>%
      distinct()
    
    return(trends)
  }