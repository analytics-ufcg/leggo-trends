#' @title Gera estatísticas dos termos no twitter
#' @description Cria um dataframe com 'desempenho' dos termos no twitter por semana
#' @param tweets Dataframe com tweets
#' @return Dataframe com estatísticas dos termos
#' @export
generate_twitter_trends <- function(tweets) {
  pressao <- tweets %>%
    dplyr::group_by(id_leggo, id_ext, casa, week) %>%
    dplyr::summarise(tweets = n(),
              retweets = sum(as.integer(retweet_count)),
              favs = sum(as.integer((favorite_count))))
}

#' @title Retorna tweets recentes
#' @description Retorna tweets dos últimos 6-9 dias que contêm termos passados
#' @param words_df Dataframe com palavras a serem pesquisadas
#' @return Dataframe com tweets
#' @export
get_tweets_pls <- function(words_df) {
  tweets_apelidos <- purrr::map_df(words_df$apelido, ~ get_tweets(.x))
  tweets_nome_formal <- purrr::map_df(words_df$nome_formal, ~ get_tweets(.x))
  tweets <- dplyr::bind_rows(tweets_apelidos, tweets_nome_formal)
  cols <- sapply(tweets, class)
  cols_type_list <- cols %in% 'list'
  names_cols <- cols[cols_type_list]
  columns <- names(names_cols)
  tweets_unlist <- SOfun::col_flatten(tweets, cols = columns)
  tweets_unlist <- tweets_unlist %>% dplyr::select(-columns)
}

#' @title Retorna tweets recentes
#' @description Retorna tweets dos últimos 6-9 dias que contêm termo passado
#' @param word Palavra a ser pesquisada
#' @return Dataframe com tweets
#' @export
get_tweets <- function(word) {
  cat(paste0("\n", "Baixando tweets com termo: '", word, "'...", "\n"))
  tweets <- rtweet::search_tweets(word, n = 250000, retryonratelimit = TRUE, include_rts = FALSE, verbose = F)
  if (leggoTrends::check_dataframe(tweets)) {
    tweets <- tweets %>%
      dplyr::mutate(termo = word) %>%
      dplyr::mutate(week = lubridate::epiweek(created_at))
  }
  tweets

}