#!/usr/bin/env python3
# À lancer avec docker compose démarré (voir docs/compte-et-synchro.md) : python scripts/test-api-local.py
"""Essai de bout en bout de l'API locale (docker compose) : inscription, synchro entre deux appareils,
conflit, mot de passe oublié via Mailpit, déconnexion, suppression du compte."""
import json
import re
import time
import urllib.error
import urllib.request

B = 'http://localhost:8080/api/v1'
EMAIL = f'essai{int(time.time())}@exemple.fr'


def call(method, path, body=None, token=None):
    data = None if body is None else json.dumps(body, ensure_ascii=False).encode('utf-8')
    req = urllib.request.Request(B + path, data=data, method=method, headers={'Content-Type': 'application/json'})
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode('utf-8'))


def ok(label, cond, extra=''):
    print(('  ✓ ' if cond else '  ✗ ') + label + (f'  {extra}' if extra and not cond else ''))
    return cond


results = []
s, r = call('POST', '/auth/register', {'email': EMAIL, 'password': 'mot de passe de test', 'deviceName': 'Tablette'})
results.append(ok('inscription 201', s == 201, r))
tablet = r.get('token')

team = {'id': 't1', 'kind': 'team', 'baseRev': 0, 'data': {'name': 'M15 filles', 'players': [{'firstName': 'Inès', 'number': 3}, {'firstName': 'Chloé', 'number': 9}]}}
events = {'id': 'events:m1', 'kind': 'events', 'baseRev': 0, 'data': [{'type': 'startSet'}, {'type': 'rally', 'winner': 'us'}]}
s, r = call('POST', '/sync', {'lastRev': 0, 'changes': [team, events]}, tablet)
results.append(ok('la tablette pousse 2 documents', s == 200 and r['pushed'] == {'t1': 1, 'events:m1': 2}, r))

s, r = call('POST', '/auth/login', {'email': EMAIL, 'password': 'mot de passe de test', 'deviceName': 'Téléphone'})
results.append(ok('connexion du téléphone', s == 200, r))
phone = r.get('token')

s, r = call('POST', '/sync', {'lastRev': 0}, phone)
names = [p['firstName'] for p in r['changes'][0]['data']['players']] if s == 200 else []
results.append(ok('le téléphone tire, accents intacts', names == ['Inès', 'Chloé'], r))

call('POST', '/sync', {'lastRev': 2, 'changes': [dict(events, baseRev=2, data=events['data'] + [{'type': 'rally', 'winner': 'them'}] * 3)]}, phone)
s, r = call('POST', '/sync', {'lastRev': 2, 'changes': [dict(events, baseRev=2, data=events['data'][:1])]}, tablet)
results.append(ok('conflit de match : le journal le plus long reste', r.get('conflicts') == ['events:m1'] and len(r['changes'][0]['data']) == 5, r))

s, r = call('POST', '/sync', {'lastRev': 3, 'changes': [{'id': 't1', 'kind': 'team', 'baseRev': 1, 'deleted': True}]}, tablet)
s, r = call('POST', '/sync', {'lastRev': 3}, phone)
results.append(ok('suppression transmise au téléphone', r['changes'][0]['deleted'] is True and r['changes'][0]['data'] is None, r))

s, r = call('POST', '/auth/reset-code', {'email': EMAIL})
time.sleep(1)
with urllib.request.urlopen('http://localhost:8025/api/v1/search?query=' + urllib.parse.quote('to:' + EMAIL)) as m:
    found = json.loads(m.read().decode('utf-8'))
snippet = found['messages'][0]['Snippet'] if found.get('messages') else ''
code = re.search(r'\b(\d{6})\b', snippet)
results.append(ok('code reçu dans Mailpit', code is not None, snippet))
if code:
    s, r = call('POST', '/auth/reset', {'email': EMAIL, 'code': code.group(1), 'newPassword': 'nouveau mot de passe', 'deviceName': 'Tablette'})
    results.append(ok('nouveau mot de passe', s == 200, r))
    new = r.get('token')
    s, _ = call('POST', '/sync', {'lastRev': 0}, phone)
    results.append(ok('ancien jeton du téléphone révoqué', s == 401))
    s, r = call('POST', '/auth/logout', None, new)
    s, _ = call('POST', '/sync', {'lastRev': 0}, new)
    results.append(ok('déconnexion', s == 401))
    s, r = call('POST', '/auth/login', {'email': EMAIL, 'password': 'nouveau mot de passe'})
    last = r.get('token')
    s, r = call('DELETE', '/account', {'password': 'nouveau mot de passe'}, last)
    results.append(ok('suppression du compte', s == 200, r))
    s, _ = call('POST', '/auth/login', {'email': EMAIL, 'password': 'nouveau mot de passe'})
    results.append(ok('plus de compte ensuite', s == 401))

print(f'\n{sum(results)} / {len(results)} réussis')
