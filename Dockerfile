FROM rocker/tidyverse:3.6.2

WORKDIR leggo-trends

RUN apt-get update
RUN apt-get install libssl-dev libxml2-dev libcurl4-openssl-dev libgit2-dev vim less -y 

RUN R -e "install.packages(c('lubridate', 'optparse', 'here', 'dotenv', 'aweek', 'futile.logger', 'RCurl', 'zoo'), dependencies=TRUE, repos='http://cran.rstudio.com/')"

RUN apt-get update
RUN apt-get install -y python3-pip

RUN pip3 install pandas
RUN pip3 install --upgrade --user git+https://github.com/GeneralMills/pytrends
RUN pip3 install unidecode
RUN pip3 install -U python-dotenv

COPY . .