import json 

with open('env.json','r') as cl, open('sp.env.json','r') as sp, open('secrets.env.json','w') as f:
    d = {}
    d1 = json.load(sp)
    d['clientId'] = d1['appId']
    d['clientSecret'] = d1['password']
    d['tenantId'] = d1['tenant']
    
    d2 = json.load(cl)
    d['subscriptionId'] = d2['subscriptionId']['value']
    
    json.dump(d,f,indent=4)
    