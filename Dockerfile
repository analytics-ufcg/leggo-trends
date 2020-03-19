FROM rocker/tidyverse:3.6.2

WORKDIR leggo-trends

RUN apt-get update
RUN apt-get install libssl-dev libxml2-dev libcurl4-openssl-dev vim less -y
COPY DESCRIPTION .

RUN R -e "install.packages('tidyverse',dependencies=TRUE, repos='http://cran.rstudio.com/')" 
RUN R -e "install.packages('lubridate',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('optparse',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('devtools',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "install.packages('glmnet',dependencies=TRUE, repos='http://cran.rstudio.com/')"
RUN R -e "devtools::install_github('ekstroem/MESS')"
RUN R -e "devtools::install_github('ropensci/rtweet')"

RUN apt-get update && apt-get install -y python3.6 python3-pip

RUN pip3 install pandas
RUN pip install git+https://github.com/GeneralMills/pytrends
RUN pip install unidecode

COPY . .

RUN R -e "devtools::install()"

CMD cd scripts/tweets_from_last_days && Rscript export_tweets_from_last_days.R ../../data/apelidos.csv ../../data
