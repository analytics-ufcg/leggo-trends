#' @title Processa os dados de tweets sobre proposições
#' @description A partir de um dataframe dos tweets, retorna a coluna com a
#' data do primeiro dia da semana para padronizar com o Google Trends
#' @param df Dataframe de tweets de saída da função fetch_tweets()
#' @return Dataframe de tweets por proposição e por semana
.process_tweets <- function(df) {
  df <- df %>%
    mutate(week = aweek::date2week(created_at)) %>%
    mutate(date = aweek::week2date(week, week_start = 1, floor_day = T)) %>% 
    select(id_leggo,
           num_tweets,
           interactions,
           date)
  return(df)
}

#' @title Processa dados de tweets
#' @description Mapeia dados de tweets e mapeia interesses por id_leggo
#' @param twitter_filepath Caminho do dataframe de tweets sobre as proposições
#' @param interesses_filepath Caminho para o csv contendo o mapeamento de id_leggo para interesses
#' @return Dataframe de Tweets com interesses
read_tweets_trends <-
  function(twitter_filepath, interesses_filepath) {
    if (is.null(twitter_filepath)) {
      source(here::here("scripts/tweets/fetcher_tweets.R"))
      twitter_trends <-
        fetch_proposicoes_tweets()
    } else {
      twitter_trends <- read_csv(twitter_filepath)
    }
    
    twitter_trends <- twitter_trends %>%
      .process_tweets()
    
    interesses <- read_csv(interesses_filepath) %>%
      select(id_leggo, interesse)
    
    twitter_trends <- twitter_trends %>%
      dplyr::left_join(interesses,  by = "id_leggo")
    
    twitter_trends_alt <- twitter_trends %>%
      mutate(interactions = if_else(is.na(interactions), 0, interactions)) %>% 
      mutate(interactions_normalizado = interactions/max(interactions))
    
    return(twitter_trends_alt)
    
  }
