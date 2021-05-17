library(tidyverse)

#' @title Processa os dados de tweets sobre proposições
#' @description A partir de um dataframe dos tweets, retorna a coluna com a
#' data do primeiro dia da semana para padronizar com o Google Trends
#' @param df Dataframe de tweets de saída da função fetch_tweets()
#' @return Dataframe de tweets por proposição e por semana
.process_date <- function(df) {
  df <- df %>%
    mutate(week = aweek::date2week(created_at)) %>%
    mutate(date = aweek::week2date(week, week_start = 1, floor_day = T)) %>% 
    select(-c(week, created_at))
  return(df)
}

#' @title Calcula a pressão no Twitter
#' @description A partir de um dataframe dos tweets, calcula a pressão no Twitter.
#' @param df Dataframe de tweets com a data processada
#' @return Dataframe de tweets com pressão da semana
.calcula_pressao <- function(df) {
  df %>%
    complete(date, id_leggo, fill = list(interactions = 0)) %>%
    mutate_at(vars(user_count:sum_interactions),
              list(~ ifelse(is.na(.), 0, .))) %>%
    mutate(log_interactions = if_else(sum_interactions > 0,
                                      log2(sum_interactions),
                                      0)) %>%
    group_by(date) %>%
    mutate(
      norm_user_count = user_count / max(user_count),
      norm_log_sum_interactions = log_interactions / max(log_interactions)
    ) %>%
    ungroup() %>%
    mutate(pressao_twitter = 0.5 * norm_user_count + 0.5 * norm_log_sum_interactions) %>%
    group_by(id_leggo) %>%
    mutate(pressao_twitter_movel = zoo::rollmean(
      pressao_twitter,
      k = 3,
      fill = 0,
      align = "right"
    )) %>% 
    ungroup()
}

#' @title Processa dados de tweets
#' @description Mapeia dados de tweets e mapeia interesses por id_leggo
#' @param twitter_filepath Caminho do dataframe de tweets sobre as proposições
#' @param interesses_filepath Caminho para o csv contendo o mapeamento de id_leggo para interesses
#' @return Dataframe de Tweets com interesses
process_tweets_trends <-
  function(twitter_filepath, interesses_filepath, proposicoes_filepath) {
    if (is.null(twitter_filepath)) {
      source(here::here("scripts/tweets/fetcher_tweets.R"))
      twitter_trends <-
        fetch_proposicoes_tweets()
    } else {
      twitter_trends <- read_csv(twitter_filepath)
    }
    
    twitter_trends <- twitter_trends %>%
      .process_date()
    
    twitter_pressao <- twitter_trends %>%
      mutate(interactions = replace_na(interactions, 0)) %>%
      group_by(id_leggo, date) %>%
      summarise(user_count = n_distinct(username),
                sum_interactions = sum(interactions)) %>%
      ungroup() %>% 
      .calcula_pressao() %>% 
      select(id_leggo,
             date,
             user_count,
             sum_interactions,
             pressao_twitter) %>% 
      mutate(pressao_twitter = pressao_twitter * 100)
      
    interesses <- read_csv(interesses_filepath) %>%
      select(id_leggo, interesse)
    
    proposicoes <- read_csv(proposicoes_filepath) %>% 
      select(id_leggo, id_ext, casa)
    
    twitter_trends_alt <- twitter_pressao %>%
      left_join(interesses,  by = "id_leggo") %>% 
      left_join(proposicoes,  by = "id_leggo") %>% 
      select(id_leggo,
             id_ext,
             casa,
             interesse,
             date,
             user_count,
             sum_interactions,
             pressao_twitter) %>% 
      distinct()
    
    return(twitter_trends_alt)
    
  }
