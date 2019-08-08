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