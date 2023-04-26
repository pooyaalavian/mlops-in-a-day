import datetime
import logging
import os
import azure.functions as func
import pyodbc
import json
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import HttpResponseError
from datetime import datetime, timedelta

def get_connection():
    key_vault_uri = os.environ["KEY_VAULT_URI"]
    credential = DefaultAzureCredential() 
    client = SecretClient(key_vault_uri, credential)
    connection_string = client.get_secret('sqlconnstr').value
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};' + connection_string)
    return conn

def run_query(qry, result=False):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(qry)
    if result:
        rows = cursor.fetchall() 
        return [list(x) for x in rows]
    cursor.commit()
    return True


def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = datetime.datetime.utcnow().replace(
        tzinfo=datetime.timezone.utc).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')
    
    dt_end = datetime.now()
    dt_start = dt_end + timedelta(-30)

    dt_start = dt_start.strftime('%Y-%m-%d %H:%M:%S')
    dt_end = dt_end.strftime('%Y-%m-%d %H:%M:%S')

    mse = run_query(f"exec sp_calculate_mse '{dt_start}', '{dt_end}'", True)[0][0]

    if mse > 0.15:
        logging.warn("Triggering model retraining")
    else:
        logging.info("model ok.")

    logging.info('Python timer trigger function ran at %s', utc_timestamp)
