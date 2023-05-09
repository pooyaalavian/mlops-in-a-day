import json 

with open('env.json','r') as cl, open('sp.env.json','r') as sp, open('.env','w') as f:
    d = {}
    d1 = json.load(sp)
    d['client_id'] = d1['appId']
    d['client_secret'] = d1['password']
    d['tenant_id'] = d1['tenant']
    
    d2 = json.load(cl)
    for k in d2:
        d[k] = d2[k]['value']
    
    for key in d:
        f.write(f'{key}={d[key]}\n')
    