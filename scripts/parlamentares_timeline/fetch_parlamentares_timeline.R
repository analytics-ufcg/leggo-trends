#' @title Retorna os usernames dos parlamentares
#' @description A partir de uma planilha do Drive, retorna os dados de usernames dos parlamentares no twitter.
#' @return Dataframe com usernames de parlamentares no twitter
.get_parliamentarians_usernames <- function() {
  library(tidyverse)
  
  source(here::here("scripts/utils/constants.R"))
  
  parliamentarians_username <-
    readr::read_csv(.PARLIAMENTARIANS_SPREADSHEETS_URL, 
                    col_types = readr::cols(.default = "c")) %>%
    dplyr::select(
      id_parlamentar,
      casa,
      nome_eleitoral,
      partido,
      uf = UF,
      twitter,
      twitter2 = `twitter2 (se houver)`
    ) %>%
    dplyr::filter(!is.na(twitter) | !is.na(twitter2))
  
  parliamentarians_username_twitter_2 <-
    parliamentarians_username %>%
    dplyr::filter(!is.na(twitter2)) %>%
    dplyr::select(-twitter,
                  twitter = twitter2)
  
  parliamentarians_username <- parliamentarians_username %>%
    dplyr::select(-twitter2) %>%
    rbind(parliamentarians_username_twitter_2) %>%
    dplyr::mutate(
      casa = iconv(casa, to = "ASCII//TRANSLIT"), # Remove accents in string
      nome_eleitoral = stringr::str_to_title(nome_eleitoral)
    ) %>%
    dplyr::distinct()
  
  return(parliamentarians_username)
  
}

#' @title Retorna as linhas do tempo dos parlamentares
#' @description A partir de uma planilha do Drive, retorna os 3000 últimmos tweets de
#' cada um dos parlamentares.
#' @return Dataframe com tweets dos parlamentares
fetch_timelines <- function() {
  library(tidyverse)
  
  parliamentarians_usernames <- .get_parliamentarians_usernames()
  
  timelines_df <-
    purrr::map_df(parliamentarians_usernames$twitter, function(x) {
      cat(paste0("Baixando timeline do usuário ", x, "...\n"))
      return(rtweet::get_timeline(x, n = 3000))
    })
  
  timelines_df <-
    timelines_df %>%
    dplyr::select(
      status_id,
      username = screen_name,
      created_at,
      text,
      favorite_count,
      reply_count,
      retweet_count,
      retweet_screen_name,
      retweet_text
    ) %>%
    dplyr::mutate(
      username = tolower(username),
      status_url = paste0("https://twitter.com/",
                          username,
                          "/status/",
                          status_id)
    ) %>%
    dplyr::select(-status_id)
  
  timelines_proc <- parliamentarians_usernames %>%
    dplyr::mutate(twitter = tolower(twitter)) %>%
    dplyr::inner_join(timelines_df, by = c("twitter" = "username"))
  
  return(timelines_proc)
}
