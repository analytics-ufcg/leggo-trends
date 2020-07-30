# Módulo de Timeline dos Parlamentares no Twitter

Este módulo é responsável por baixar os tweets dos parlamentares brasileiros atuais. Esses dados correspondem aos últimos 3 mil tweets da linha do tempo de cada um dos congressistas que possuem conta no Twitter.

Para a obtenção dessas informações, utilizamos uma [planilha](https://docs.google.com/spreadsheets/d/e/2PACX-1vR5y-CWna1pZCgeuYxj8vMt-nHJYTsyNRd9xiFVL_ntFr98XwAYRnlxl7FzZqSD3WGP5xkkP45ntyD1/pub?gid=901295581&single=true&output=csv) contendo os nomes de usuários dos parlamentares como entrada para a função `get_timelines()` do pacote [**rtweet**](https://rtweet.info/reference/index.html). 

## Uso

Para baixar esses dados, basta estar neste diretório e digitar o código abaixo no terminal:

```
Rscript export_parlamentares_timeline.R -o <arquivo_destino.csv>
```

- O parâmetro -o corresponde ao caminho e nome do arquivo com os dados de saída do script. Se não for passado nenhum valor, o csv será salvo em `data/timelines.csv`.
