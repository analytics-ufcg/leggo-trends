# -*- coding: utf-8 -*- 

from fetch_google_trends import *
from datetime import date, datetime
from datetime import timedelta
import pandas as pd

def test_get_data_inicial():
    assert get_data_inicial('2019-08-22') == '2019-08-22', 'Deveria ser 2019-08-22'
    assert get_data_inicial('2015-08-22') == (date.today() - timedelta(days=180)).strftime('%Y-%m-%d'), 'Deveria ser a data de 6 meses atrás'

def test_formata_timeframe():
    assert formata_timeframe('2019-03-10') == '2019-03-10' + ' ' + date.today().strftime('%Y-%m-%d'), 'Deveria ser a data de 6 meses atrás até hoje'

def test_calcula_maximo():
    lista_com_dados_teste = [
        [16526,	'2019-02-18', 'camara', 0, 0, 0, False],
        [16526, '2019-02-18', 'camara', 100, 0, 20, False],
        [16526, '2019-02-18', 'camara', 0, 100, 30, False],
        [16526, '2019-02-18', 'camara', 45, 46, 100, False],
        [16526, '2019-02-25', 'camara', 46, 45, 45, False]
    ]
    lista_com_dados_gabarito = [
        [16526,	'2019-02-18', 'camara', 0, 0, 0, False, 0, 0, 0.0],
        [16526, '2019-02-18', 'camara', 100, 0, 20, False, 100, 20, 100.0],
        [16526, '2019-02-18', 'camara', 0, 100, 30, False, 100, 30, 100.0],
        [16526, '2019-02-18', 'camara', 45, 46, 100, False, 46, 100, 100.0],
        [16526, '2019-02-25', 'camara', 46, 45, 45, False, 46, 45, 46]
    ]

    df_teste = pd.DataFrame(lista_com_dados_teste, columns = ['id_ext', 'date', 'casa', 'pl', 'apelido', 'rel', 'isPartial'])
    df_gabarito = pd.DataFrame(lista_com_dados_gabarito, columns = ['id_ext', 'date', 'casa', 'pl', 'apelido', 'rel', 'isPartial', 'max_pressao_principal', 'max_pressao_rel',	'maximo_geral'])

    assert df_gabarito.equals(calcula_maximos(df_gabarito, 'apelido', 'pl')), 'Máximos diferentes'

if __name__ == "__main__":
    test_get_data_inicial()
    test_formata_timeframe()
    test_calcula_maximo()
    print('Parabéns! Tudo bacana!')