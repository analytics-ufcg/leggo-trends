# coding: utf-8

import pandas as pd
from pytrends.request import TrendReq
from datetime import date, datetime
from datetime import timedelta
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
    """
    Função que printa a chamada correta em caso de o usuário passar o número errado
    de argumentos
    """

    print ("Chamada Correta: python fetch_google_trends.py <df_path> <export_path>")

def get_data_inicial(apresentacao):
    """
    Caso a apresentação tenha sido feita em menos de 6 meses retorna a data da apre
    sentação, caso contrário, retorna a data de 6 meses atrás
    """
    
    seis_meses_atras = date.today() - timedelta(days=180)
    if datetime.strptime(apresentacao,"%Y-%m-%d").date() > seis_meses_atras:
        return apresentacao
    else:
        return seis_meses_atras.strftime("%Y-%m-%d")

def formata_timeframe(passado_formatado):
    """
    Formata o timeframe para o formato aceitável pelo pytrends
    """

    return passado_formatado + ' ' + date.today().strftime("%Y-%m-%d")

def get_trends(termo, timeframe):

    kw_list = [termo]

    pytrend.build_payload(kw_list, cat=0, timeframe=timeframe, geo='BR', gprop='')
 
def get_popularidade(termo, timeframe):
    get_trends(termo, timeframe)
    return pytrend.interest_over_time()

def get_termos_relacionados(termo, timeframe):
    """
    
    """
    get_trends(termo, timeframe)
    related_queries_dict = pytrend.related_queries()
    related_queries_df = pd.DataFrame.from_dict(related_queries_dict[termo]['top'])[:3]
    if (related_queries_df.empty):
        return []
    else:
        return related_queries_df['query'].tolist()
    
def get_all_trends(termos, timeframe):
    columns_names = ['pop', 'isPartial', 'nome']
    pop_termos = pd.DataFrame()
    for termo in termos:
        pop_df = get_popularidade(termo, timeframe)
        if(not pop_df.empty):
            nome = pop_df.columns[0]
            pop_df['nome'] = nome
            pop_df.columns = columns_names
            if(pop_termos.empty):
                pop_termos = pop_df
            else:
                pop_termos = pop_termos.append(pop_df)

    return pop_termos

def write_csv_popularidade(df_path, export_path):
    """
    Para cada linha do csv calcula e escreve um csv com a popularidade da proposição
    """

    apelidos = pd.read_csv(df_path)
    for index, row in apelidos.iterrows():
        timeframe = formata_timeframe(get_data_inicial(row['apresentacao']))
        apelido = row['apelido']
        nome_formal = row['nome_formal']
        termos_relacionados_formal = get_termos_relacionados(nome_formal, timeframe)
        termos_relacionados_apelido = get_termos_relacionados(apelido, timeframe)
        termos_relacionados = [apelido, nome_formal]
        if (len(termos_relacionados_apelido) != 0 or len(termos_relacionados_formal) != 0):
            if (len(termos_relacionados_apelido) > len(termos_relacionados_formal)):
                termos_relacionados.extend(termos_relacionados_apelido)
            else:
                termos_relacionados.extend(termos_relacionados_formal)
        
        print(termos_relacionados)
        pop_df = get_all_trends(termos_relacionados, timeframe)
        pop_df.to_csv(export_path + apelido + ".csv")

write_csv_popularidade(df_path, export_path)

#print(get_termos_relacionados('Reforma da previdencia', '2019-02-12 2019-08-12'))
#get_all_trends(['PEC 06/2019', 'Nova previdencia', 'reforma da previdencia'], '2019-02-12 2019-08-12').to_csv("teste.csv")