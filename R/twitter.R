library(rtweet)
library(lubridate)
library(tidyverse)

#'@export
get_tweets_pls <- function(words_df) {
  tweets <- purrr::map_df(words_df$termos, ~ .get_tweets(.x))
  
}

.get_tweets <- function(word) {
  print(paste0("Baixando tweets com termo: '", word, "'..."))
  tweets <- search_tweets(word, n = 18000, include_rts = FALSE)
  tweets <- tweets %>% 
    mutate(termo = word) %>% 
    mutate(week = epiweek(created_at))
  pressao <- tweets %>%
    group_by(termo, week) %>%
    summarise(tweets = n(),
              retweets = sum(retweet_count),
              favs = sum(favorite_count))
}

