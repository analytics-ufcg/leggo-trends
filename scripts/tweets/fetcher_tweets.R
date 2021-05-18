library(tidyverse)
library(futile.logger)

#' @title Baixa dados de tweets por proposição
#' @description A partir de uma url e um intervalo de datas,
#' retorna dados de número de tweets e número de
#' interações (soma de replies, retweets e likes) totais
#' por proposição e dia.
#' @param url URL da API
#' @param data_inicial Data inicial do intervalo
#' @param data_final Data final do intervalo
#' @return Dataframe contendo id_proposicao_leggo,
#' num_tweets, interactions e created_at.
fetch_proposicoes_tweets <-
  function(url = "https://leggo-twitter.herokuapp.com/api/proposicoes",
           data_inicial = NULL,
           data_final = NULL) {
    if (is.null(data_inicial))
      data_inicial <- lubridate::ymd(Sys.Date()) - months(3)
    
    if (is.null(data_final))
      data_final <- Sys.Date()
    
    flog.info(
      str_glue(
        "Baixando dados de tweets sobre proposições entre {data_inicial} e {data_final}"
      )
    )
    
    url <-
      str_glue("{url}?data_inicial={data_inicial}&data_final={data_final}")
    
    data <- RCurl::getURL(url) %>%
      jsonlite::fromJSON()
    
    if (is.null(nrow(data))) {
      data <- tibble(
        id_leggo = character(),
        num_tweets = integer(),
        interactions = integer(),
        created_at = date()
      )
    } else {
      data <- data %>% 
        rename(id_leggo = id_proposicao_leggo)
    }
    
    return(data)
  }
