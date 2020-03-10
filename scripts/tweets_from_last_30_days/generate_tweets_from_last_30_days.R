#' @title Retorna os usernames dos parlamentares
#' @description A partir de uma planilha do Drive, retorna os dados de usernames dos parlamentares no twitter.
#' @return Dataframe com usernames de parlamentares no twitter
.get_parliamentarians_usernames <- function() {
  library(tidyverse)
  
  source(here::here("scripts/utils/constants.R"))
  
  parliamentarians_username <-
    readr::read_csv(.PARLIAMENTARIANS_SPREADSHEETS_URL) %>%
    dplyr::select(id_parlamentar, casa, twitter, twitter2 = `twitter2 (se houver)`) %>%
    dplyr::filter(!is.na(twitter) | !is.na(twitter2))
  
  parliamentarians_username_twitter_2 <-
    parliamentarians_username %>%
    dplyr::filter(!is.na(twitter2)) %>%
    dplyr::select(id_parlamentar,
                  casa,
                  twitter = twitter2)
  
  parliamentarians_username <- parliamentarians_username %>%
    dplyr::select(-twitter2) %>%
    rbind(parliamentarians_username_twitter_2) %>%
    dplyr::mutate(casa = iconv(casa, to = "ASCII//TRANSLIT")) %>% # Remove accents in string
    dplyr::distinct()
  
  return(parliamentarians_username)
  
}

#' @title Retorna os parlamentares que ativos no Twitter
#' @description A partir da lista de usernames, retorna os parlamentares que tiveram alguma 
#' atividade no Twitter nos últimos 30 dias.
#' @return Dataframe com parlamentares ativos no Twitter nos últimos 30 dias.
.filter_active_users <- function(usernames_list) {
  library(tidyverse)
  
  users_df <- rtweet::lookup_users(usernames_list) %>%
    rtweet::tweets_data()
  
  last_30_days <- Sys.Date() - 30
  
  active_users <- users_df %>%
    dplyr::filter(created_at >= last_30_days) %>%
    dplyr::select(user_id, username = screen_name)
  
  return(active_users)
}

#' @title Retorna os dados de entrada para a função do leggoTrends que retorna os tweets dos últimos 30 dias.
#' @description A partir do dataframe com os apelidos das proposições, processa e retorna as palavras-chave 
#' que filtrarão os tweets. É nesta função que as consultas dos autores de interesse serão geradas.
#' @param  words_df Dataframe contendo os dados de apelidos das proposições.
#' @return Uma lista contendo: um dataframe com as queries de autores e uma string com as palavras-chave
#' geradas do nome formal e apelido das proposições.
.process_functions_inputs <- function(words_df) {
  library(tidyverse)
  
  active_users <- .get_parliamentarians_usernames() %>%
    dplyr::pull(twitter) %>%
    .filter_active_users() %>%
    dplyr::mutate(query = paste0("from:", username))
  
  queries <- active_users %>%
    dplyr::mutate(n_char = nchar(query) + nchar(" OR ")) %>%
    dplyr::group_by(group_500 = MESS::cumsumbinning(n_char, 256)) %>%
    dplyr::mutate(cumsum_500 = cumsum(n_char)) %>%
    dplyr::group_by(group_500) %>%
    dplyr::summarise(authors_query = paste0( query, collapse = " OR ")) %>% 
    dplyr::ungroup() %>% 
    dplyr::select(authors_query)
  
  words_df <- words_df %>% 
    dplyr::mutate(query = paste0(tolower(apelido), "|", tolower(nome_formal)))
  
  words_query <- paste0(words_df %>% 
                          dplyr::pull(query), 
                        collapse = "|")
  
  return(list(queries, words_query))
}

#' @title Retorna os usernames dos parlamentares
#' @description A partir de uma planilha do Drive, retorna os dados de usernames dos parlamentares no twitter.
#' @return Dataframe com usernames de parlamentares no twitter
search_last_30_days <- function(words_df, 
                                from_date = format(Sys.time() - 60 * 60 * 24 * 30, '%Y%m%d%H%M'), 
                                to_date = format(Sys.time(), '%Y%m%d%H%M')) {
  library(tidyverse)
  
  processed_inputs <- .process_functions_inputs(words_df)
  
  source(here::here("R/twitter.R"))
  
  queries <- processed_inputs[[1]] %>% 
    dplyr::top_n(30)
  words_query <- processed_inputs[[2]]
  
  token <- leggoTrends::generate_token(
    Sys.getenv("APP_NAME"),
    Sys.getenv("TWITTER_ACCESS_TOKEN"),
    Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET"),
    Sys.getenv("TWITTER_API_KEY"),
    Sys.getenv("TWITTER_API_SECRET_KEY"))

  env_name <- Sys.getenv("TWITTER_DEV_ENV")
  
  tweets <- purrr::map_df(
   queries$authors_query, ~ get_tweets_pls_last_30_days(.x,
                                               words_filter = words_query,
                                               from_date = from_date,
                                               to_date = to_date,
                                               token = token,
                                               env_name = env_name))
  return(tweets)
}
