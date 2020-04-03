#' @title Remove pontuações e caracteres especiais.
#' @description Remove pontuações e caracteres especiais de uma string.
#' @param string String a ser processada
#' @return String processada
.remove_pontuacao <- function(string) {
  library(tidyverse)
  
  return(iconv(string, from="UTF-8", to="ASCII//TRANSLIT") %>% 
    stringr::str_replace_all("[[:punct:]]", ""))
}