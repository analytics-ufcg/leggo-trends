# -*- coding: utf-8 -*- 

import pandas as pd
from pytrends.request import TrendReq
import time
from datetime import date, datetime
from datetime import timedelta
from unidecode import unidecode
import sys
from pathlib import Path
import shutil


def print_usage():
    '''
    Função que printa a chamada correta em caso de o usuário passar o número errado
    de argumentos
    '''

    print ('Chamada Correta: python fetch_google_trends.py <df_path> <export_path>')

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

def get_trends(termo, timeframe):
    '''
    Retorna os trends
    '''

    pytrend.build_payload(termo, cat=0, timeframe=timeframe, geo='BR', gprop='')
 
def get_popularidade(termo, timeframe):
    '''
    Retorna a popularidade de termos passados em um intervalo de tempo
    (timeframe)
    '''

    get_trends(termo, timeframe)

    return pytrend.interest_over_time()

def get_termos_relacionados(termo, timeframe):
    '''
    Retorna os termos relacionados a um termo passado
    em um período de tempo especificado
    '''

    get_trends(termo, timeframe)
    related_queries_dict = pytrend.related_queries()
    if (len(related_queries_dict) == 0):
        return pd.DataFrame()

    related_queries_df = pd.DataFrame.from_dict(related_queries_dict[termo[0]]['top'])[:3]

    return related_queries_df

def get_termos_mais_populares(nome_formal, apelido, timeframe):
    '''
    De acordo com os termos relacionados ao nome formal da proposição e a seu apelido
    retorna os 3 termos mais popularidades 
    '''

    termos_relacionados_total = get_termos_relacionados([nome_formal], timeframe)

    if apelido:
        termos_relacionados_apelido = get_termos_relacionados([apelido], timeframe)
        termos_relacionados_total = termos_relacionados_total.append(termos_relacionados_apelido)
    
    termos_relacionados_total = termos_relacionados_total.drop_duplicates(subset ="query")
    if (len(termos_relacionados_total) > 0):
        termos_relacionados_total = termos_relacionados_total.sort_values(by=['value'], ascending=False)[:3]['query']

    return termos_relacionados_total.values.tolist()

def calcula_maximos(pop_df, apelido, nome_formal, keywords):
    '''
    Calcula o máximo da pressão entre o apelido, nome formal e
    conjunto de palavras-chave,
    entre os termos relacionados e a pressão geral
    '''

    termos = pop_df

    if apelido:
        termos['max_pressao_principal'] = termos[[apelido,nome_formal]].max(axis=1)
        cols_names = [apelido, nome_formal, 'date', 'max_pressao_principal', 'isPartial']
    else:
        termos['max_pressao_principal'] = termos[nome_formal]
        cols_names = [nome_formal, 'date', 'max_pressao_principal', 'isPartial']

    cols_termos_relacionados = termos.columns[~termos.columns.isin(cols_names)]
    termos['max_pressao_rel'] = termos[cols_termos_relacionados].max(axis=1) if (len(cols_termos_relacionados) > 0) else 0
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
    path = Path(export_path)
    if path.exists():
        try:
            shutil.rmtree(export_path)
        except OSError as e:
            print("Erro ao esvaziar pasta destino: %s." % (e.strerror))
    
    path.mkdir(exist_ok=True)

def write_csv_popularidade(df_path, export_path):
    '''
    Para cada linha do csv calcula e escreve um csv com a popularidade da proposição
    '''
    waiting_time = 2
    max_time = 45
    counter = 0

    props_sem_popularidade = 0
    apelidos = pd.read_csv(df_path, encoding='utf-8', parse_dates=['apresentacao'])
    for index, row in apelidos.iterrows():
        

        time.sleep(waiting_time)
        counter += 1
        if waiting_time < max_time:
            waiting_time = 2 + 1.0065**counter

        timeframe = formata_timeframe(get_data_inicial(row['apresentacao']))
        apelido = formata_apelido(row['apelido'])
        nome_formal = row['nome_formal']
        id_ext = str(row['id_ext'])
        casa = row['casa']
        id_leggo = row['id_leggo']
        interesse = row['interesse']
        keywords = formata_keywords(row['keywords'])

       
        if apelido:
            nome = apelido
            query = [nome_formal, apelido]
            cols_names = [
                'id_leggo', 
                'id_ext', 
                'date', 
                'casa', 
                'interesse', 
                nome_formal, 
                apelido, 
                'isPartial', 
                'max_pressao_principal', 
                'max_pressao_rel', 
                'maximo_geral']
        else:
            nome = nome_formal
            query = [nome_formal]
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

        print('Pesquisando a popularidade: ' + nome + ' (interesse: ' + interesse + ')')

        print('Pesquisa nº: ' + str(counter) + ', Tempo de espera: ' + str(waiting_time) + ' s')

        termos = query + get_termos_mais_populares(nome_formal, apelido, timeframe)
        termos = set(termos)
        
        pop_df = get_popularidade(list(termos), timeframe)

        if keywords:
            palavras_chave = [k for k in keywords.split(';')]
            pop_df = pop_df.append(get_popularidade(palavras_chave, timeframe))

        if (pop_df.empty):
            pop_df = pd.DataFrame(columns = cols_names) 
            props_sem_popularidade += 1

            print ('O Google nao retornou nenhum dado sobre: ' + nome)
        else:
            pop_df = calcula_maximos(pop_df, apelido, nome_formal, keywords)
            pop_df['id_leggo'] = id_leggo
            pop_df['id_ext'] = id_ext
            pop_df['casa'] = casa
            pop_df['interesse'] = interesse
            pop_df = agrupa_por_semana(pop_df)
            
        pop_df.to_csv(export_path + 'pop_' + str(id_leggo) + '_' + str(interesse) + '.csv', encoding='utf8', index=False)

    if (props_sem_popularidade > 0):
        print('Não foi possível retornar a popularidade de ' + str(props_sem_popularidade) + '/' + str(len(apelidos)) + ' proposições.')

if __name__ == "__main__":
    # Argumentos que o programa deve receber:
    # -1º: Path para o arquivo onde estão os apelidos, nomes formais e datas de apresentações
    # -2º: Path para a pasta onde as tabelas de popularidades devem ser salvas

    if len(sys.argv) != 3:
        print_usage()
        exit(1)

    df_path = sys.argv[1]
    export_path = sys.argv[2]

    pytrend = TrendReq(timeout=300)

    create_directory(export_path)

    write_csv_popularidade(df_path, export_path)

