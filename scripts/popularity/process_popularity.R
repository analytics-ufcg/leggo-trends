#' @title Processa a popularidade de uma proposição para uma semana
#' @description A partir de um dataframe com os tweets já sumarizados (trends) e retorna
#' a popularidade da PL em relação a todos os tweets sobre PLs do Leg.go.
#' @param trends Dataframe de saída da função leggoTrends::generate_twitter_trends(tweets)
#' @return Dataframe de trends do twitter com popularidade por PL e por semana
calculate_populatiry_score <- function(trends) {
  library(tidyverse)
  
  trends_alt <- trends %>%
    dplyr::group_by(week) %>%
    dplyr::mutate(total_retweets = sum(retweets),
                  total_likes = sum(favs)) %>%
    dplyr::mutate(general_popularity = (total_retweets * 7 + total_likes * 3) / 10) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(id_leggo, id_ext, casa, week) %>%
    dplyr::mutate(
      popularity = (retweets * 7 + favs * 3) / 10,
      mean_popularity = popularity / general_popularity
    ) %>%
    dplyr::select(id_leggo, id_ext, casa, date = week, mean_popularity)
  
  return(trends_alt)
}

#' @description A partir de um dataframe com os tweets já sumarizados (trends) e do caminho para
#' os arquivos processados do google Trends, combina-os em um indice único e retorna um novo
#' dataframe com todas as colunas de ambos os dataframes mais um índice combinado.
#' @param twitter_trends Dataframe de saída da função leggoTrends::generate_twitter_trends(tweets)
#' @param pops_folderpath Caminho para os arquivos de destino do script fetch_google_trends.py
#' @return Dataframe com índices do Google Trends e Twitter por PL e semana
combine_indexes <- function(twitter_trends, pops_folderpath) {
  library(tidyverse)
  
  files <- list.files(pops_folderpath, full.names = T)
  
  google_trends <- purrr::map_df(files, ~ readr::read_csv(.x))
  
  trends <- dplyr::inner_join(google_trends,
                              twitter_trends,
                              by = c("id_leggo", "id_ext", "casa", "date")) %>%
    dplyr::rename(twitter_mean_popularity = mean_popularity,
                  trends_max_popularity = maximo_geral) %>% 
    dplyr::mutate(popularity = 0.5 * twitter_mean_popularity + 0.5 * trends_max_popularity) %>% 
    dplyr::distinct()
  
  return(trends)
}