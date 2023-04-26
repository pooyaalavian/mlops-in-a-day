import logging

import azure.functions as func
import os
# import pymssql
import pyodbc
import json
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import HttpResponseError


def get_connection():
    key_vault_uri = os.environ["KEY_VAULT_URI"]
    log(key_vault_uri)
    credential = DefaultAzureCredential() 
    log(credential)
    client = SecretClient(key_vault_uri, credential)
    connection_string = client.get_secret('sqlconnstr').value
    log(connection_string)
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

def log(s):
    logging.info(s)

def main(req: func.HttpRequest) -> func.HttpResponse:
    log('Python HTTP trigger function processed a request.')
    try:
        predictions = []
        outcomes = []
        arr = req.get_json()
        for data in arr:
            for key in ['type', 'id', 'ts', 'inputs', 'value']:
                if data.get(key) is None:
                    return func.HttpResponse(f'Key "{key}" not present.', status_code = 400)
            req_type = data.get('type')
            req_id = data.get('id')
            req_ts = data.get('ts')
            req_inputs = data.get('inputs')
            req_value = data.get('value')

            val= f"('{req_ts}','{req_id}','{req_inputs}','{req_value}')"

            if req_type == 'prediction':
                predictions.append(val)
            elif req_type == 'outcome':
                outcomes.append(val)
            else:
                return func.HttpResponse(f'"type" property must be "prediction" or "outcome".', status_code=400)
        
        if len(predictions)>0:
            query = 'INSERT INTO [dbo].[prediction] VALUES '+ ', '.join(predictions)
            res = run_query(query)
            logging.info(f"Recorded {len(predictions)} predictions.")
        if len(outcomes)>0:
            query = 'INSERT INTO [dbo].[outcome] VALUES '+ ', '.join(outcomes)
            res = run_query(query)
            logging.info(f"Recorded {len(outcomes)} outcomes.")

        return func.HttpResponse('Success', status_code=201)

    except Exception as e:
        logging.info(f'generic error: {e}')
        return func.HttpResponse(f"Error ({e}). Request was not processed.", status_code=500)


    

