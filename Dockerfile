FROM python:3.6
COPY . .
ADD fetch_google_trends.py /
RUN pip3 install pandas
RUN pip install git+https://github.com/musaprg/pytrends
RUN pip install unidecode
CMD [ "python", "./fetch_google_trends.py", "./data/apelidos.csv", "./pops/"]
