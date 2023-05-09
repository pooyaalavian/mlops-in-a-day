import logging
import os
import glob
import pyodbc
from azure.identity import ClientSecretCredential
from azure.keyvault.secrets import SecretClient
from azure.core.exceptions import HttpResponseError
import json
from pathlib import Path

ODBC_DRIVER = 'SQL Server'
# ODBC_DRIVER = 'ODBC Driver 17 for SQL Server'

# logging.basicConfig(filename='example.log', encoding='utf-8', level=logging.DEBUG)

def read_env():
    with open('sp.env.json') as f:
        data = json.load(f)
        os.environ['TENANT_ID'] = data['tenant']
        os.environ['CLIENT_ID'] = data['appId']
        os.environ['CLIENT_SECRET'] = data['password']
        
    with open('env.json') as f:
        data = json.load(f)
        for key in data:
            os.environ[key.upper()] = data[key]['value']

def get_conn_str():
    key_vault_uri = os.environ["KEYVAULTURI"]
    credential = ClientSecretCredential(
        tenant_id=os.environ['TENANT_ID'],
        client_id=os.environ['CLIENT_ID'],
        client_secret=os.environ['CLIENT_SECRET']
    )
    client = SecretClient(key_vault_uri, credential)
    connection_string = client.get_secret('sqlconnstr').value
    return connection_string


def run_query(qry, result=False):
    print ('[run_query]', qry[0:100])
    cursor = conn.cursor().execute(qry)
    if result:
        rows = cursor.fetchall()
        return [list(x) for x in rows]
    else:
        cursor.commit()
        return True


def get_version(file:str):
    v = file.split('.sql')[0].split('-',1)[1]
    print (f'[get_version] {file} -> {v}')
    return v


def is_script_deployed(file: str):
    print('[is_script_deployed]', file)
    version = get_version(file)
    try:
        res = run_query(f"SELECT * FROM [dbo].[_sqlVersion] where [version]='{version}'", True)
    except: 
        return False

    if len(res)==0:
        return False 
    if len(res)==1:
        return True 
    raise Exception(f'Script has been deployed {len(res)} times.')


def insert_version(file: str):
    print('[insert_version]', file)
    version = get_version(file)
    run_query(f"INSERT INTO [dbo].[_sqlVersion] VALUES ('{version}', CURRENT_TIMESTAMP)")


def deploy_script(file: str):
    print('[deploy_script]', file)
    with open(file) as f:
        data = f.read()
        # try:
        run_query(data)
        insert_version(file)
        # except:
            # print(f'{file} failed.')


def main():
    files = glob.glob('sql/*.sql')
    files = sorted(files)
    for file in files:
        print(file)
        if not is_script_deployed(file):
            deploy_script(file)

    
if __name__ == '__main__':
    read_env()
    cs = f'Driver={{{ODBC_DRIVER}}};' + get_conn_str()
    print(cs)
    conn = pyodbc.connect(cs)
    main()
