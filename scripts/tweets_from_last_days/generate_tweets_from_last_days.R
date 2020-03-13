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
    dplyr::group_by(group_500 = MESS::cumsumbinning(n_char, 500)) %>%
    dplyr::mutate(cumsum_500 = cumsum(n_char)) %>%
    dplyr::group_by(group_500) %>%
    dplyr::summarise(authors_query = paste0(query, collapse = " OR ")) %>%
    dplyr::ungroup() %>%
    dplyr::select(authors_query)
  
  if ("keywords" %in% names(queries)) {
    words_df <- words_df %>%
      dplyr::mutate(query = paste0(tolower(apelido),
                                   "|",
                                   tolower(nome_formal)))
  } else {
    words_df <- words_df %>%
      dplyr::mutate(query = paste0(
        tolower(apelido),
        "|",
        tolower(nome_formal),
        if_else(is.na(keywords),
                '',
                paste0("|", tolower(keywords)))
      ))
  }
  
  words_df <- words_df %>%
    dplyr::select(id_leggo, id_ext, casa, query)
  
  return(list(queries, words_df))
}

#' @title Filtra os tweets a partir de regex
#' @description Recebe dois dataframes, filtrando os textos dos tweets de acordo com uma lista de regex e
#' retorna um dataframe com os tweets filtrados e proposições relativas
#' @return Dataframe com dados de tweets e proposições citadas.
.filter_tweets <- function(tweets, words_query) {
  library(tidyverse)
  
  tweets_alt <- tweets %>%
    dplyr::mutate(processed_text = iconv(tolower(text), to = "ASCII//TRANSLIT")) %>%
    dplyr::select(favorite_count, retweet_count, processed_text, week)
  
  df <- tweets_alt %>%
    fuzzyjoin::regex_inner_join(words_query, by = c(processed_text = "query")) %>%
    dplyr::select(-query)
  
  return(df)
}


#' @title Retorna os usernames dos parlamentares
#' @description A partir de uma planilha do Drive, retorna os dados de usernames dos parlamentares no twitter.
#' @return Dataframe com usernames de parlamentares no twitter
search_last_tweets <- function(words_df) {
  library(tidyverse)
  
  processed_inputs <- .process_functions_inputs(words_df)
  
  queries <- processed_inputs[[1]]
  words_query <- processed_inputs[[2]]
  
  tweets <-
    purrr::map_df(queries$authors_query, ~ leggoTrends::get_tweets(.x))
  
  filtered_tweets <- .filter_tweets(tweets, words_query)
  
  return(filtered_tweets)
}
