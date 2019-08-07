library(rtweet)
library(lubridate)
library(tidyverse)

get_pressao <- function(tweets) {
  pressao <- tweets %>%
    group_by(termo, week) %>%
    summarise(tweets = n(),
              retweets = sum(retweet_count),
              favs = sum(favorite_count))
}

get_tweets_pls <- function(words_df) {
  tweets_apelidos <- purrr::map_df(words_df$apelido, ~ .get_tweets(.x))
  tweets_nome_formal <- purrr::map_df(words_df$nome_formal, ~ .get_tweets(.x))
  tweets <- bind_rows(tweets_apelidos, tweets_nome_formal)
}

.get_tweets <- function(word) {
  cat(paste0("\n", "Baixando tweets com termo: '", word, "'...", "\n"))
  tweets <- search_tweets(word, n = 250000, retryonratelimit = TRUE, include_rts = FALSE)
  if (check_dataframe(tweets)) {
    tweets <- tweets %>% 
      mutate(termo = word) %>% 
      mutate(week = epiweek(created_at))
  }
  tweets

}

#' @title Verifica dataframe
#' @description Verifica se um determinado daframe dado é nulo ou vazio.
#' @param df Dataframe a ser verificado
#' @return Dataframe vazio.
#' @export
check_dataframe <- function(df) {
  if ((is.null(df) || (nrow(df) == 0))) {
    warning("Dataframe de entrada deve ser não-nulo e não-vazio.")
    return(FALSE)
  }
  return(TRUE)
}
