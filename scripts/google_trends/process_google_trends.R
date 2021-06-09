#' @title Processa dados do google trends
#' @description Reúne todos os csv de google trends e mapeia o interesse
#' baseado no id_leggo
#' @param pops_folderpath Caminho da pasta contendo os csvs de google trends
#' @param interesses_filepath Caminho para o csv contendo o mapeamento de id_leggo para interesses
#' @return Dataframe de google trends com interesse mapeado
bind_google_trends <-
  function(pops_folderpath, interesses_filepath) {
    files <- list.files(pops_folderpath, pattern = 'pop_', full.names = T)
    
    interesses <- read_csv(interesses_filepath) %>%
      select(id_leggo, interesse)
    
    google_trends <-
      purrr::map_df(files,
                    ~ readr::read_csv(
                      .x,
                      col_types = readr::cols(
                        .default = "d",
                        id_ext = "c",
                        id_leggo = "c",
                        interesse = "c",
                        casa = "c",
                        isPartial = "l",
                        date = readr::col_date(format = "%Y-%m-%d"),
                        maximo_geral = "d"
                      )
                    )) %>%
      dplyr::mutate(maximo_geral_perc = round(maximo_geral / 100, 2))
    
    if (!"interesse" %in% names(google_trends)) {
      google_trends <- google_trends %>%
        dplyr::left_join(interesses,  by = "id_leggo")
    }
    
    google_trends <- google_trends %>%
      dplyr::select(
        id_leggo,
        id_ext,
        casa,
        interesse,
        max_pressao_principal,
        max_pressao_rel,
        maximo_geral_perc,
        date
      )
    
    return(google_trends)
  }
