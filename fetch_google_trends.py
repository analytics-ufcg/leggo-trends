# -*- coding: utf-8 -*- 

import pandas as pd
from pytrends.request import TrendReq
from datetime import date, datetime
from datetime import timedelta
from unidecode import unidecode
import sys

# Argumentos que o programa deve receber:
# -1º: Path para o arquivo onde estão os apelidos, nomes formais e datas de apresentações
# -2º: Path para a pasta onde as tabelas de popularidades devem ser salvas

if len(sys.argv) != 3:
    print_usage()
    exit(1)

df_path = sys.argv[1]
export_path = sys.argv[2]

pytrend = TrendReq()

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
    if datetime.strptime(apresentacao,'%Y-%m-%d').date() > seis_meses_atras:
        return apresentacao
    else:
        return seis_meses_atras.strftime('%Y-%m-%d')

def formata_timeframe(passado_formatado):
    '''
    Formata o timeframe para o formato aceitável pelo pytrends
    '''

    return passado_formatado + ' ' + date.today().strftime('%Y-%m-%d')

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

    termos_relacionados_formal = get_termos_relacionados([nome_formal], timeframe)
    termos_relacionados_apelido = get_termos_relacionados([apelido], timeframe)
    termos_relacionados_total = termos_relacionados_formal.append(termos_relacionados_apelido)
    termos_relacionados_total = termos_relacionados_total.drop_duplicates(subset ="query")
    if (len(termos_relacionados_total) > 0):
        termos_relacionados_total = termos_relacionados_total.sort_values(by=['value'], ascending=False)[:3]['query']

    return termos_relacionados_total.values.tolist()

def calcula_maximos(pop_df, apelido, nome_formal):
    '''
    Calcula o máximo da pressão entre o apelido e o nome formal,
    entre os termos relacionados e a pressão geral
    '''

    termos = pop_df
    termos['max_pressao_principal'] = termos[[apelido,nome_formal]].max(axis=1)
    termos['max_pressao_rel'] = termos[termos.columns[~termos.columns.isin([apelido, nome_formal, 'date', 'max_pressao_principal', 'isPartial'])]].max(axis=1)
    termos['maximo_geral'] = termos[['max_pressao_rel','max_pressao_principal']].max(axis=1)

    return termos

def agrupa_por_semana(pop_df):
    '''
    Agrupa por semana começando na segunda e calcula os máximos das colunas
    '''

    pop_df = pop_df.reset_index()
    pop_df = pop_df.groupby(['id_ext', pd.Grouper(key='date', freq='W-MON'), 'casa']).agg('max')
    pop_df = pop_df.reset_index()
    pop_df['date'] = pd.to_datetime(pop_df['date']) - pd.to_timedelta(7, unit = 'd')

    return pop_df

def write_csv_popularidade(df_path, export_path):
    '''
    Para cada linha do csv calcula e escreve um csv com a popularidade da proposição
    '''

    props_sem_popularidade = 0
    apelidos = pd.read_csv(df_path, encoding='utf-8')
    for index, row in apelidos.iterrows():
        timeframe = formata_timeframe(get_data_inicial(row['apresentacao']))
        apelido = 'PL do Veneno'
        nome_formal = 'PL 6299/2002'
        id_ext = str(row['id_ext'])
        casa = row['casa']
        print('Pesquisando a popularidade: ' + apelido)
        termos_relacionados = [nome_formal, apelido] + get_termos_mais_populares(nome_formal, apelido, timeframe)
        termos = [unidecode(termo_rel) for termo_rel in termos_relacionados]
        pop_df = get_popularidade(termos, timeframe)

        if (pop_df.empty):
            props_sem_popularidade += 1
            print ('O Google nao retornou nenhum dado sobre: ' + apelido)
        else:
            pop_df = calcula_maximos(pop_df, apelido, nome_formal)
            pop_df['id_ext'] = id_ext
            pop_df['casa'] = casa
            pop_df = agrupa_por_semana(pop_df)
            pop_df.to_csv(export_path + 'pop_' + id_ext + '.csv', encoding='utf8')
    if (props_sem_popularidade > 0):
        print('Não foi possível retornar a popularidade de ' + str(props_sem_popularidade) + '/' + str(len(apelidos)) + ' proposições.')

write_csv_popularidade(df_path, export_path)