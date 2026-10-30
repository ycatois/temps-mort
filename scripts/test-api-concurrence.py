#!/usr/bin/env python3
# À lancer avec docker compose démarré (voir docs/compte-et-synchro.md) : python scripts/test-api-concurrence.py
"""Synchros simultanées sur MariaDB : aucun document ne doit être perdu pour un appareil.
Chaque appareil pousse ses documents un par un et tire en suivant son lastRev ; à la fin, chacun doit
avoir vu tous les documents de tous les appareils."""
import json
import threading
import time
import urllib.request

B = 'http://localhost:8080/api/v1'
EMAIL = f'concurrence{int(time.time())}@exemple.fr'
DEVICES, ROUNDS = 4, 40


def call(path, body, token=None):
    req = urllib.request.Request(B + path, data=json.dumps(body).encode(), method='POST', headers={'Content-Type': 'application/json'})
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read().decode())


first = call('/auth/register', {'email': EMAIL, 'password': 'mot de passe de test', 'deviceName': 'A0'})['token']
tokens = [first] + [call('/auth/login', {'email': EMAIL, 'password': 'mot de passe de test', 'deviceName': f'A{i}'})['token'] for i in range(1, DEVICES)]
seen = [set() for _ in range(DEVICES)]
errors = []
start = threading.Barrier(DEVICES)


def device(i):
    last = 0
    start.wait()
    try:
        for n in range(ROUNDS):
            doc = {'id': f'd{i}-{n}', 'kind': 'play', 'baseRev': 0, 'data': {'n': n}}
            r = call('/sync', {'lastRev': last, 'changes': [doc]}, tokens[i])
            seen[i].update(r['pushed'].keys())
            seen[i].update(c['id'] for c in r['changes'])
            last = r['rev']
        # Dernière synchro sans rien pousser : rattraper ce que les autres ont écrit après.
        time.sleep(0.5)
        r = call('/sync', {'lastRev': last}, tokens[i])
        seen[i].update(c['id'] for c in r['changes'])
    except Exception as e:  # noqa: BLE001
        errors.append(f'appareil {i} : {e}')


threads = [threading.Thread(target=device, args=(i,)) for i in range(DEVICES)]
for t in threads:
    t.start()
for t in threads:
    t.join()

expected = {f'd{i}-{n}' for i in range(DEVICES) for n in range(ROUNDS)}
for i in range(DEVICES):
    missing = expected - seen[i]
    print(f'  {"✓" if not missing else "✗"} appareil {i} : {len(seen[i])}/{len(expected)} documents vus' + (f', manquants {sorted(missing)[:5]}' if missing else ''))
total = call('/sync', {'lastRev': 0}, tokens[0])
revs = [c['rev'] for c in total['changes']]
print(f'  {"✓" if len(set(revs)) == len(revs) else "✗"} révisions toutes distinctes ({len(revs)} documents)')
print('  erreurs : ' + ('; '.join(errors) if errors else 'aucune'))
