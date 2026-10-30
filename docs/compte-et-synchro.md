# Compte coach et synchronisation (V1-EQU-01, V1-TEC-03)

> **Statut : proposition, à valider avec Yann.** Rien n'est codé. Les points marqués « À décider » attendent sa réponse.

## Ce qu'on veut

- **Hors ligne d'abord, toujours.** Le match se joue sans réseau, comme aujourd'hui. La synchro n'est qu'une sauvegarde et un passage d'un appareil à l'autre (tablette au gymnase, téléphone à la maison).
- **Un compte simple.** Pas de mot de passe à retenir pour un coach bénévole.
- **Des données de mineures protégées.** Le serveur ne reçoit que ce que l'app connaît déjà (prénom, numéro, genre en mixte), hébergé en France. Une suppression dans l'app se propage au serveur.
- **Tester d'abord en local.** Tout tourne dans `docker compose`, qui reproduit o2switch.

## Où vit l'API

Dans le site PHP existant (`web/app`), sous `/api/v1/…`, avec la même base MariaDB. C'est l'option 1 de `docs/architecture.md` :
- o2switch est en France, et PHP comme MariaDB y sont natifs ; pas de serveur en plus à payer ni à surveiller.
- L'API est versionnée (`/api/v1`) : si un jour il faut du temps réel (V2 : coach adjoint, parent qui saisit), on pourra déménager sur un VPS sans changer l'app.
- Le serveur **ne rejoue pas les règles du volley**. Il stocke les données telles que l'app les envoie (le même JSON qu'en local). Les règles restent dans `mobile/lib/domain`, et nulle part ailleurs.

## Le compte : code à 6 chiffres par e-mail

1. Le coach saisit son e-mail dans l'app.
2. Le serveur envoie un code à 6 chiffres, valable 10 minutes, utilisable une seule fois.
3. Le coach tape le code dans l'app : il est connecté sur cet appareil.

Pourquoi un code plutôt qu'un lien magique : le lien obligerait à ouvrir l'app depuis le mail (liens profonds Android et iOS à configurer). Le code se tape sur la tablette même si le mail arrive sur le téléphone.

Côté sécurité :
- **Pas de mot de passe stocké.** Le code est conservé haché, avec une limite de tentatives et d'envois.
- **Jeton d'appareil** : à la connexion, l'appareil reçoit un jeton aléatoire, gardé dans le stockage sécurisé du téléphone (`flutter_secure_storage`). Le serveur n'en garde que l'empreinte (hachage). Un jeton par appareil, révocable (« Déconnecter cet appareil »).
- **Pas de JWT** : un simple jeton opaque, vérifié en base, suffit et se révoque instantanément.

En local, les e-mails sont captés par **Mailpit** (un conteneur de plus dans `docker compose`) : on lit le code sur http://localhost:8025.

**À décider :** le compte est-il **facultatif** (l'app marche sans compte, comme aujourd'hui ; le compte sert à sauvegarder et à changer d'appareil) ? C'est la recommandation : pas de barrière à l'entrée pour essayer l'app.

## La synchronisation

### Ce qu'on synchronise

Des **documents**, chacun avec un identifiant créé sur l'appareil (c'est déjà le cas avec `newId()`) :

| Document | Contenu (JSON actuel de l'app) |
|---|---|
| Équipe | nom, catégorie, format, saison, couleur, effectif |
| Match | fiche du match (adversaire, date, règles, présentes) |
| Événements d'un match | la liste complète des `MatchEvent`, dans l'ordre |
| Composition type | une par équipe et par format |
| Schéma tactique | la bibliothèque de l'équipe |

### Comment

Le modèle est celui du « tirer, pousser », avec un numéro de révision posé par le serveur :
- Chaque document a une **révision serveur** (`rev`), un compteur qui ne fait que monter.
- L'app retient la plus grande révision reçue (`lastRev`).
- **Pousser** : l'app envoie les documents modifiés depuis la dernière synchro. Le serveur les enregistre et leur donne une nouvelle `rev`.
- **Tirer** : l'app demande « tout ce qui a changé depuis `lastRev` » et l'applique en local.
- **Quand** : à l'ouverture de l'app, à la fin d'un match, au retour du réseau, et avec un bouton « Synchroniser » dans les réglages. **Jamais pendant un échange** : la saisie en match ne dépend pas du réseau.

### Conflits

En V1, une équipe appartient à un seul coach. Un conflit n'arrive donc que si ce coach modifie la même chose sur deux appareils sans réseau. Règle : **la dernière modification gagne, document par document**.

Exception, les événements d'un match : deux appareils qui saisissent le même match en même temps, c'est un cas que l'app ne doit pas encourager. Si ça arrive, on garde la version qui a le plus d'événements, et on prévient le coach.

### Suppressions (RGPD)

Supprimer une joueuse ou une équipe dans l'app envoie une **pierre tombale** : l'identifiant et « supprimé ». Le serveur **efface vraiment le contenu** et ne garde que cette marque, pour que les autres appareils suppriment aussi. La suppression du compte efface tout côté serveur.

## Base de données (MariaDB)

```
coaches         id, email, created_at
login_codes     coach_email, code_hash, expires_at, attempts
devices         id, coach_id, token_hash, name, last_seen_at
documents       id, coach_id, kind, rev, deleted, data (JSON), updated_at
                index (coach_id, rev)
```

Une seule table `documents`, générique : le serveur n'a pas à connaître la forme d'une équipe ou d'un match. Il suffit d'une migration de plus dans `web/app/database/migrations`.

## API

```
POST /api/v1/auth/code        { email }                  → envoie le code
POST /api/v1/auth/verify      { email, code, deviceName } → { token }
POST /api/v1/sync             { lastRev, changes: [...] } → { rev, changes: [...] }
DELETE /api/v1/account                                    → efface tout
POST /api/v1/auth/logout                                   → révoque ce jeton
```

Un seul appel `sync` pousse et tire à la fois : moins d'allers-retours sur un réseau de gymnase.

## Tester en local

1. `docker compose up -d` : site, API, MariaDB, Mailpit.
2. Tablette branchée en USB : `adb reverse tcp:8080 tcp:8080`. L'app parle alors à `http://localhost:8080`, c'est-à-dire au PC, sans toucher au Wi-Fi ni au pare-feu.
3. Le code de connexion se lit dans Mailpit (http://localhost:8025).
4. Le HTTP en clair n'est autorisé que dans la version de développement ; la version publiée n'accepte que HTTPS.

Tests automatiques : côté PHP, `web/tests/run.php` (sans dépendance, comme aujourd'hui) ; côté app, un faux serveur en mémoire pour tester la synchro sans réseau.

## Découpage proposé (une PR chacun)

1. **API locale** : migration, `/auth/code`, `/auth/verify`, `/sync`, Mailpit dans docker, tests PHP.
2. **App, compte** : écran « Mon compte » (e-mail, code, déconnexion), jeton dans le stockage sécurisé.
3. **App, synchro** : révisions locales, pousser et tirer, déclencheurs, indicateur « synchronisé il y a 2 min ».
4. **Suppressions et compte** : pierres tombales, suppression du compte.
5. **Mise en ligne sur o2switch** : d'abord en préproduction, HTTPS, envoi d'e-mails réel.

## À décider avec Yann

1. Compte **facultatif** (recommandé) ou obligatoire ?
2. Connexion par **code à 6 chiffres** (recommandé) ou par mot de passe ?
3. En V1, une équipe = **un seul coach** (recommandé) ; le partage avec un adjoint vient en V2 ?
4. Nom de domaine de l'API en production (celui du site, sous `/api/v1`).
