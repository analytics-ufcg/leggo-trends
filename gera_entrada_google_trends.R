library(tidyverse)
library(lubridate)

proposicao <- read_csv("../leggo-backend/data/proposicoes.csv")

df_google_trends <- 
  proposicao %>% 
  mutate(nome_formal = paste0(sigla_tipo, " ", numero, "/"),
         apresentacao = as.Date(ymd_hms(data_apresentacao))) %>% 
  select(apelido, nome_formal, apresentacao)
