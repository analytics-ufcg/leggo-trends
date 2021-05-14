library(tidyverse)
source(here::here("scripts/tweets/process_tweets.R"))

.padroniza_sigla <- function(df) {
  df <- df %>%
    mutate(sigla_processada = gsub("º| |\\.", "", sigla) %>% tolower()) %>%
    mutate(sigla_processada = gsub("mpv", "mp", sigla_processada))
  return(df)
}

.processa_tweets_proposicoes_sem_ano <-
  function(tweets_raw, proposicoes) {
    tweets_proposicoes_sem_ano <- tweets_raw %>%
      filter(!stringr::str_detect(sigla_processada, "/")) %>%
      left_join(
        proposicoes %>%
          mutate(
            sigla_processada_sem_ano = stringr::str_remove(sigla_processada, "/.*")
          ),
        by = c("sigla_processada" = "sigla_processada_sem_ano")
      ) %>%
      group_by(sigla_processada) %>%
      mutate(siglas_diferentes = n_distinct(sigla)) %>%
      ungroup() %>%
      mutate(ambigua = siglas_diferentes > 1) %>%
      filter(!is.na(id_leggo), !ambigua) %>%
      select(id_leggo,
             sigla,
             username,
             created_at,
             text,
             interactions)
    return(tweets_proposicoes_sem_ano)
  }

mapeia_citadas_para_id <-
  function(tweets_raw_filepath = here::here("reports/nova_pressao/data/tweets_parlamentares_e_influenciadores_v2.csv.zip"),
           proposicoes_filepath = here::here("reports/nova_pressao/data/proposicoes.csv")) {
    tweets_raw <- read_csv(tweets_raw_filepath) %>%
      rename(sigla = citadas) %>%
      .padroniza_sigla() %>%
      select(-sigla)
    
    proposicoes <- read_csv(proposicoes_filepath) %>%
      distinct(sigla, id_leggo) %>%
      .padroniza_sigla()
    
    tweets_proposicoes <- tweets_raw %>%
      left_join(proposicoes, by = "sigla_processada") %>%
      filter(!is.na(id_leggo)) %>%
      select(id_leggo,
             sigla,
             username,
             created_at,
             text,
             interactions)
    
    tweets_proposicoes_sem_ano <-
      .processa_tweets_proposicoes_sem_ano(tweets_raw, proposicoes)
    
    tweets_proposicoes_df <- tweets_proposicoes %>%
      bind_rows(tweets_proposicoes_sem_ano) %>% 
      distinct(sigla, created_at, text, username, .keep_all = T)
    
    ## Removendo dfs não mais utilizados
    rm(proposicoes,
       tweets_raw,
       tweets_proposicoes,
       tweets_proposicoes_sem_ano)
    
    tweets_proposicoes_df <- tweets_proposicoes_df %>%
      .process_tweets()
    
    return(tweets_proposicoes_df)
  }

.processa_dados_para_relatorio <- function(tweets_proposicoes) {
  df <- tweets_proposicoes %>%
    group_by(id_leggo, sigla, date) %>%
    mutate(interactions = if_else(is.na(interactions), 0, interactions)) %>%
    summarise(user_count = n_distinct(username),
              sum_interactions = sum(interactions)) %>%
    ungroup() %>%
    mutate(log_sum_interactions = if_else(sum_interactions > 0, log2(sum_interactions), 0)) %>%
    mutate(
      norm_user_count = user_count / max(user_count, na.rm = T),
      norm_sum_interactions = sum_interactions / max(sum_interactions, na.rm = T),
      norm_log_sum_interactions = log_sum_interactions / max(log_sum_interactions, na.rm = T)
    ) %>%
    mutate(
      metricas_normalizadas = 0.5 * norm_user_count + 0.5 * norm_sum_interactions,
      metricas_norm_log_interactions = 0.5 * norm_user_count + 0.5 * norm_log_sum_interactions
    )
  
  return(df)
}


write_csv(mapeia_citadas_para_id(), here::here("reports/nova_pressao/data/tweets_proposicoes.csv"))
