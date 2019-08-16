library(tidyverse)
library(lubridate)

proposicao <- read_csv("../leggo-backend/data/proposicoes.csv")

df_google_trends <- 
  proposicao %>% 
  mutate(apresentacao = as.Date(ymd_hms(data_apresentacao)),
         nome_formal = paste0(sigla_tipo, " ", numero, "/", year(apresentacao)),
         apelido = iconv(apelido, from="UTF-8", to="ASCII//TRANSLIT")) %>% 
  select(apelido, nome_formal, apresentacao, id_ext) %>% 
  group_by(apelido) %>% 
  arrange(apelido, apresentacao) %>%  
  slice(n())

write_csv(df_google_trends, "../leggo-trends/apelidos.csv")
