# Módulo da Pressão

Módulo que usa informações adquiridas de redes sociais e buscadores sobre proposições para ver o engajamento da população, chamado de pressão pelo Painel Parlametria.

O arquivo de configuração necessário é o `configuration.env`.

Está dividido em três partes principais:

- **Coleta de dados pelo Google Trends** (não mais utilizado);
- **Coleta de dados pelo leggo-twitter**;
- **Combinação desses dois índices na geração da pressão** (hoje em dia não usamos mais o Trends na geração da pressão, mas o código é adaptável caso necessário);

## Docker

Criamos um Docker para que o usuário consiga rodar os scripts independente do ambiente, inclusive pelo [leggo-geral](https://github.com/parlametria/leggo-geral).

Para rodá-lo:

Caso seja a primeira vez ou sempre que fizer alguma alteração no código:

```
docker-compose build
```

### Coleta de dados pelo Google Trends

Para baixar os dados do score das buscas sobre as proposições no Google, é necessário gerar o csv de apelidos que será input do script que baixa essas informações.

#### 1. Gerar o csv de apelidos

Esse csv é input para o script que baixa os dados do Google Trends. Para executá-lo é só copiar o código abaixo:

```
docker-compose run --rm leggo-trends \
 Rscript gera_entrada_google_trends.R \
 -p <data_folder>/proposicoes.csv \
 -a <data_folder>/apelidos.csv
```

onde `<data_folder>` é o caminho da pasta onde está o csv de proposições (usado como input) e o local onde o csv de apelidos serão salvos.

#### 2. Executar o script que baixa dados do Google Trends

Além de baixar os dados, este script também salva um backup circular dos csvs com ciclos de 7 dias (isto é, os dados de uma execução ficam salvos por até 7 dias, conforme novas execuções forem surgindo). Para baixar esses dados, é só executar o comando abaixo:

```
docker-compose run --rm leggo-trends \
 python3 fetch_google_trends.py \
 <data_folder>/apelidos.csv \
 <data_folder>/pops/ \
 <data_folder>/pops_backups/ \
 configuration.env
```

onde `<data_folder>` é o caminho da pasta onde está o csv de apelidos (usado como input) e o local onde os csv com os dados do Google Trends sobre as proposições (incluindo o backup) serão salvos.

### Coleta de dados pelo leggo-twitter

Para baixar os dados de tweets sobre proposições em um intervalo de datas, é só executar o comando abaixo:

```
docker-compose run --rm leggo-trends \
      Rscript scripts/tweets/export_tweets.R \
      -u <url_twitter_api>/proposicoes \
      -i <data_inicial> \
      -f <data_final> \
      -o <data_path>/tweets_proposicoes.csv 
```

onde:
- `<url_twitter_api>`: Endereço para a API do leggo-twitter: https://leggo-twitter.herokuapp.com/api;
- `<data_inicial>`: Data inicial do intervalo, no formato AAAA-MM-DD;
- `<data_final>`: Data final do intervalo, no formato AAAA-MM-DD;
- `<data_path>`: Caminho para o destino do csv tweets_proposicoes.csv (entrada do processador de pressão).

### Combinação desses dois índices na geração da pressão

Como último passo, para gerar o csv final com os dados de pressão das proposições, é só executar o seguinte código:

```
docker-compose run --rm leggo-trends \
      Rscript scripts/popularity/export_popularity.R \
      -t <data_path>/tweets_proposicoes.csv \
      -g <data_path>/pops \
      -i <data_path>/interesses.csv \
      -p <data_path>/proposicoes.csv \
      -o <data_path>/pressao.csv
```

onde `<data_path>` é o caminho onde todos os arquivos serão buscados e o csv de pressão será salvo.