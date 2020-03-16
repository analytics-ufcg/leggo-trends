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
    dplyr::mutate(general_popularity = (total_retweets * 0.7 + total_likes * 0.3) / 2) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(id_leggo, id_ext, casa, week) %>%
    dplyr::mutate(
      popularity = (retweets * 0.7 + favs * 0.3) / 2,
      mean_popularity = popularity / general_popularity
    ) %>%
    dplyr::select(id_leggo, id_ext, casa, date = week, mean_popularity)
  
  return(trends_alt)
}