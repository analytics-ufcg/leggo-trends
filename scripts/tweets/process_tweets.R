library(tidyverse)

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
           interactions,
           date,
           username)
  return(df)
}

#' @title Processa dados de tweets
#' @description Mapeia dados de tweets e mapeia interesses por id_leggo
#' @param twitter_filepath Caminho do dataframe de tweets sobre as proposições
#' @param interesses_filepath Caminho para o csv contendo o mapeamento de id_leggo para interesses
#' @return Dataframe de Tweets com interesses
read_tweets_trends <-
  function(twitter_filepath, interesses_filepath, proposicoes_filepath) {
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
    
    proposicoes <- read_csv(proposicoes_filepath) %>% 
      select(id_leggo, id_ext, casa)
    
    twitter_trends <- twitter_trends %>%
      left_join(interesses,  by = "id_leggo") %>% 
      left_join(proposicoes, by = "id_leggo")
    
    twitter_trends_alt <- twitter_trends %>%
      group_by(id_leggo, date) %>% 
      mutate(user_count = n_distinct(username),
             grouped_interactions = sum(interactions, na.rm = T)) %>% 
      mutate(score = 0.5 * user_count + 0.5 * grouped_interactions) %>% 
      ungroup()
    # %>% mutate(log_score = abs(log2(score))) %>% 
      # mutate(twitter_trends = (log_score / max(log_score, na.rm = T)) * 100) %>% 
      # select(id_leggo,
      #        id_ext,
      #        casa,
      #        interesse,
      #        date,
      #        user_count,
      #        grouped_interactions,
      #        twitter_trends)
     
    return(twitter_trends_alt)
    
  }
