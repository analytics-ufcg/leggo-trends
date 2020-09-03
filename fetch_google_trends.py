# -*- coding: utf-8 -*- 

import pandas as pd
import shutil
import sys
import re
import time
import os
import random
import os
import math
import datetime
from datetime import datetime as dt
from datetime import date, timedelta
from pytrends.request import TrendReq
from pytrends.exceptions import ResponseError
from unidecode import unidecode
from pathlib import Path
from dotenv import load_dotenv


def print_usage():
    '''
    Função que printa a chamada correta em caso de o usuário passar o número errado
    de argumentos
    '''

    print ('Chamada Correta: python fetch_google_trends.py <df_path> <export_path> <config_path>')

def get_data_inicial(apresentacao):
    '''
    Caso a apresentação tenha sido feita em menos de 6 meses retorna a data da apre
    sentação, caso contrário, retorna a data de 6 meses atrás
    '''
    
    seis_meses_atras = date.today() - timedelta(days=180)
    if apresentacao > seis_meses_atras:
        return apresentacao.strftime('%Y-%m-%d')
    else:
        return seis_meses_atras.strftime('%Y-%m-%d')

def formata_timeframe(passado_formatado):
    '''
    Formata o timeframe para o formato aceitável pelo pytrends
    '''

    return passado_formatado + ' ' + date.today().strftime('%Y-%m-%d')

def formata_apelido(apelido):
    '''
    Formata o apelido da proposição, limitando seu conteúdo 
    para o tamanho aceitado pelo pytrends
    '''

    return apelido[:85] if not pd.isna(apelido) else ''

def formata_nome_formal(nome_formal):
    '''
    Formata o nome da proposição para não incluir o ano de 
    criação
    '''

    # Separa nome e ano
    nome_separado = nome_formal.split("/", maxsplit=1)[0]

    # Formata para MPV ser MP
    nome_separado = re.sub('MPV', 'MP', nome_separado)

    return nome_separado

def formata_keywords(keywords):
    '''
    Formata as palavtas-chave da proposição, limitando 
    seu conteúdo para o tamanho aceitado pelo pytrends
    (100 caracteres)
    '''

    formated_keywords = ''
    if not pd.isna(keywords):
        keys = keywords.split(';')
        for i in range(len(keys)):
            if len(formated_keywords) + len(keys[i]) < 100:
                formated_keywords += keys[i]
            if len(formated_keywords) < 100:
                formated_keywords += ';'
    
        if formated_keywords[-1] == ';':
            return formated_keywords[:-1]
            
    return formated_keywords

def get_trends(termos, timeframe):
    '''
    Retorna os trends
    '''
    
    pytrend.build_payload(termos, cat=0, timeframe=timeframe, geo='BR', gprop='')
 
def get_popularidade(termo, timeframe):
    '''
    Retorna a popularidade de termos passados em um intervalo de tempo
    (timeframe)
    '''

    get_trends(termo, timeframe)

    return pytrend.interest_over_time()

def calcula_maximos(pop_df, termos_base):
    '''
    Calcula o máximo de pressão entre termos principais e relacionados
    '''

    termos = pop_df

    # Calcula o máximo da pressão baseada nos termos principais
    termos['max_pressao_principal'] = termos[termos_base].max(axis=1)
    cols_names = termos_base + ['date', 'max_pressao_principal', 'isPartial']

    # Calcula o máximo de pressão baseada nos termos relacioados
    cols_termos_relacionados = termos.columns[~termos.columns.isin(cols_names)]
    termos['max_pressao_rel'] = termos[cols_termos_relacionados].max(axis=1) if (len(cols_termos_relacionados) > 0) else 0

    # calcula o máximo de pressão entre termos principais e relacionados
    termos['maximo_geral'] = termos[['max_pressao_rel','max_pressao_principal']].max(axis=1)

    return termos

def agrupa_por_semana(pop_df):
    '''
    Agrupa por semana começando na segunda e calcula os máximos das colunas
    '''

    pop_df = pop_df.reset_index()
    pop_df = pop_df.groupby(['id_ext', pd.Grouper(key='date', freq='W-MON'), 'casa', 'interesse']).agg('max')
    pop_df = pop_df.reset_index()
    pop_df['date'] = pd.to_datetime(pop_df['date']) - pd.to_timedelta(7, unit = 'd')

    return pop_df

def create_directory(export_path):
    '''
    Cria um diretório de backups composto por diretórios nomeados com timestamp, 
    que guardam os csvs de popularidade. 
    '''
    now = datetime.datetime.today() 
    timestamp_str = now.strftime("%d-%m-%Y")
    backup_path = os.path.join(export_path+'backups/')

    if not os.path.exists(backup_path):
        try:
            os.makedirs(backup_path)
        except OSError as e: 
            print("Erro ao criar diretório de backups: %s." %(e.strerror))
    
    dest_path = os.path.join(backup_path+timestamp_str)

    if not os.path.exists(dest_path):
        try:
            os.makedirs(dest_path)
        except OSError as e: 
            print("Erro ao criar diretório: %s." %(e.strerror))

    keep_last_dirs(backup_path)
    
    for filename in os.listdir(export_path):
            try: 
                full_file_name = os.path.join(export_path, filename)
                shutil.copy2(full_file_name,dest_path)
            except OSError as e:
                print("Erro ao copiar arquivos do diretório de popularidade: %s." %(e.strerror))

def keep_last_dirs(backup_path):
    '''
    Gera dicionário com nomes dos diretórios e a data de criação deles. A partir desse dicionário, 
    são apagados os diretórios mais antigos, deixando os 3 mais recentes.  
    '''
    dirs_to_keep=3
    diretory_creation_times = {}
    count = 0

    for dir_name in os.listdir(backup_path):
        dict = {backup_path: os.path.getctime(backup_path)}
        diretory_creation_times.update(dict)

    for item in sorted(diretory_creation_times, key = diretory_creation_times.get, reverse=True):
        count +=1
        try:
            if(count > dirs_to_keep):
                shutil.rmtree(item)
        except OSError as e:
                print("Erro ao apagar diretórios de backup: %s." %(e.strerror))
        
def calcula_lote_dia(df_apelidos):
    '''
    Calcula com base no epoch do sistema o lote de proposições que deve ser pesquisado no dia
    '''

    # calcula o epoch
    diff_data = dt.today() - dt.utcfromtimestamp(0)
    referencia_dias = diff_data.days

    props_dia = int(os.getenv("PROPOSITIONS_DAY"))
    total_lotes = math.ceil(len(df_apelidos.index) / props_dia)
    lote_dia = (referencia_dias % total_lotes) + 1

    return lote_dia

def write_csv_popularidade(apelidos, lote_dia, export_path):
    '''
    Para cada linha do csv calcula e escreve um csv com a popularidade da proposição
    '''

    tempo_entre_req = int(os.getenv("TRENDS_WAIT_TIME"))
    props_sem_popularidade = 0

    print('Coletando popularidade das proposições do lote %s' %(lote_dia)) 

    for index, row in apelidos.iterrows():

        lote = row['lote']

        # verificação se o lote da proposição é o do dia
        if (lote == lote_dia):
            
            # timeframe de até 6 meses da data de execução do script
            timeframe = formata_timeframe(get_data_inicial(row['apresentacao']))

            nome_formal = row['nome_formal']
            id_ext = str(row['id_ext'])
            casa = row['casa']
            id_leggo = row['id_leggo']
            interesse = row['interesse']

            # separa o nome da proposição do ano e trata MPVs
            nome_simples = formata_nome_formal(nome_formal) 
 
            # Cria conjunto de termos e adiciona aspas
            termos = [nome_simples]
            termos = ['"' + termo + '"' for termo in termos]

            # Inicializa o dataframe
            cols_names = [
                    'id_leggo',
                    'id_ext',
                    'date',
                    'casa',
                    'interesse',
                    nome_formal,
                    'isPartial',
                    'max_pressao_principal',
                    'max_pressao_rel',
                    'maximo_geral']

            pop_df = pd.DataFrame(columns = cols_names)

            # Tenta recupera a popularidade
            tentativas = int(os.getenv("TRENDS_RETRIES"))
            for n in range(0, tentativas):
                try:
                    print('Tentativa %s de coletar a popularidade da proposição %s da agenda %s' %(n+1, nome_formal, interesse))
                    # Recupera as informações de popularidade a partir dos termos
                    pop_df = get_popularidade(termos, timeframe)
                    break
    
                except ResponseError as error:
                    print(error.args)
                    time.sleep((2 ** n) + random.random())

            # Caso da proposição sem popularidade
            if (pop_df.empty):
        
                print('Nome: %s Lote: %s TimeFrame: %s termos: %s sem informações do trends' %(nome_formal, lote, timeframe, termos))
                props_sem_popularidade += 1

            else:
                print('Nome: %s Lote: %s TimeFrame: %s termos: %s com popularidade' %(nome_formal, lote, timeframe, termos))

                pop_df = calcula_maximos(pop_df, termos)
                pop_df['id_leggo'] = id_leggo
                pop_df['id_ext'] = id_ext
                pop_df['casa'] = casa
                pop_df['interesse'] = interesse
                pop_df = agrupa_por_semana(pop_df)

            # Escreve resultado da consulta para uma proposição
            filename = export_path + 'pop_' + str(id_leggo) + '_' + str(interesse) + '.csv'
            pop_df.to_csv(filename, encoding='utf8', index=False)

            # Esperando para a próxima consulta do trends
            time.sleep(tempo_entre_req + random.random())


if __name__ == "__main__":
    # Argumentos que o programa deve receber:
    # -1º: Path para o arquivo onde estão os apelidos, nomes formais e datas de apresentações
    # -2º: Path para a pasta onde as tabelas de popularidades devem ser salvas
    # -3º: Path para o arquivo onde estão as configurações do fetch

    if len(sys.argv) != 4:
        print_usage()
        exit(1)

    df_path = sys.argv[1]
    export_path = sys.argv[2]
    conf_path = sys.argv[3]

    load_dotenv(dotenv_path=conf_path)

    connect_timeout = int(os.getenv("TRENDS_CONNECT_TIMEOUT"))
    response_timeout = int(os.getenv("TRENDS_RESPONSE_TIMEOUT"))

    pytrend = TrendReq(timeout=(connect_timeout, response_timeout))

    apelidos = pd.read_csv(df_path, encoding='utf-8', parse_dates=['apresentacao'])
    lote_dia = calcula_lote_dia(apelidos)

    # Atualiza o diretório para remover proposições que não são de interesse
    if (lote_dia == 1):
        create_directory(export_path)

    write_csv_popularidade(apelidos, lote_dia, export_path)
