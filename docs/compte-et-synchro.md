# Compte coach et synchronisation (V1-EQU-01, V1-TEC-03)

> **Statut : architecture validée par Yann le 2026-10-30** (voir « Décisions »). Rien n'est encore codé ; on teste d'abord en local.

## Ce qu'on veut

- **Hors ligne d'abord, toujours.** Le match se joue sans réseau, comme aujourd'hui. La synchro n'est qu'une sauvegarde et un passage d'un appareil à l'autre (tablette au gymnase, téléphone à la maison).
- **Un compte facultatif.** L'app gratuite marche sans compte, comme aujourd'hui ; le compte sert à sauvegarder et à changer d'appareil. Il deviendra obligatoire pour les formules payantes.
- **Jamais bloqué au gymnase.** Certains gymnases n'ont aucun réseau : ouvrir l'app ne doit jamais attendre le serveur.
- **Des données de mineures protégées.** Le serveur ne reçoit que ce que l'app connaît déjà (prénom, numéro, genre en mixte), hébergé en France. Une suppression dans l'app se propage au serveur.
- **Tester d'abord en local.** Tout tourne dans `docker compose`, qui reproduit o2switch.

## Où vit l'API

Dans le site PHP existant (`web/app`), sous `/api/v1/…`, avec la même base MariaDB. C'est l'option 1 de `docs/architecture.md` :
- o2switch est en France, et PHP comme MariaDB y sont natifs ; pas de serveur en plus à payer ni à surveiller.
- L'API est versionnée (`/api/v1`) : si un jour il faut du temps réel (V2 : coach adjoint, parent qui saisit), on pourra déménager sur un VPS sans changer l'app.
- Le serveur **ne rejoue pas les règles du volley**. Il stocke les données telles que l'app les envoie (le même JSON qu'en local). Les règles restent dans `mobile/lib/domain`, et nulle part ailleurs.

## Le compte : mot de passe, puis empreinte ou visage

Deux choses distinctes :

**1. Se connecter (avec réseau, une fois par appareil).**
- Création du compte : e-mail et mot de passe (12 caractères au moins). Le serveur ne garde que son empreinte, avec `password_hash` (Argon2id si o2switch le propose, sinon bcrypt).
- Connexion sur un nouvel appareil : e-mail et mot de passe. L'appareil reçoit un **jeton d'appareil** aléatoire, gardé dans le stockage sécurisé du téléphone (`flutter_secure_storage`). Le serveur n'en garde que l'empreinte ; un jeton par appareil, révocable (« Déconnecter cet appareil »).
- Le jeton reste valable tant qu'on ne se déconnecte pas : **l'app n'a plus jamais besoin du serveur pour s'ouvrir**. Pas de JWT : un jeton opaque, vérifié en base au moment de la synchro, se révoque instantanément.
- Mot de passe oublié : un code à 6 chiffres par e-mail (réseau nécessaire, c'est inévitable), valable 10 minutes, utilisable une fois, avec une limite de tentatives et d'envois.

**2. Ouvrir l'app (sans réseau, à chaque fois).**
- Verrouillage facultatif, proposé après la première connexion : **empreinte digitale ou visage**, avec repli sur le code de déverrouillage du téléphone (paquet `local_auth`). Tout se passe sur l'appareil : aucun réseau nécessaire.
- L'app ne stocke pas le mot de passe : c'est le téléphone qui vérifie l'empreinte, le visage ou son propre code.
- Sans compte, rien ne change : l'app s'ouvre directement, comme aujourd'hui.

En local, les e-mails (mot de passe oublié) sont captés par **Mailpit** (un conteneur de plus dans `docker compose`) : on les lit sur http://localhost:8025.

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
coaches         id, email, password_hash, created_at
reset_codes     coach_email, code_hash, expires_at, attempts
devices         id, coach_id, token_hash, name, last_seen_at
documents       id, coach_id, kind, rev, deleted, data (JSON), updated_at
                index (coach_id, rev)
```

Une seule table `documents`, générique : le serveur n'a pas à connaître la forme d'une équipe ou d'un match. Il suffit d'une migration de plus dans `web/app/database/migrations`.

## API

```
POST /api/v1/auth/register    { email, password, deviceName } → { token }
POST /api/v1/auth/login       { email, password, deviceName } → { token }
POST /api/v1/auth/reset-code  { email }                         → envoie le code
POST /api/v1/auth/reset       { email, code, newPassword }      → mot de passe changé
POST /api/v1/sync             { lastRev, changes: [...] } → { rev, changes: [...] }
DELETE /api/v1/account                                    → efface tout
POST /api/v1/auth/logout                                   → révoque ce jeton
```

Un seul appel `sync` pousse et tire à la fois : moins d'allers-retours sur un réseau de gymnase.

## Tester en local

1. `docker compose up -d` : site, API, MariaDB, Mailpit.
2. Tablette branchée en USB : `adb reverse tcp:8080 tcp:8080`. L'app parle alors à `http://localhost:8080`, c'est-à-dire au PC, sans toucher au Wi-Fi ni au pare-feu.
3. Les e-mails (mot de passe oublié) se lisent dans Mailpit (http://localhost:8025).
4. Le HTTP en clair n'est autorisé que dans la version de développement ; la version publiée n'accepte que HTTPS.

Tests automatiques : côté PHP, `web/tests/run.php` (sans dépendance, comme aujourd'hui) ; côté app, un faux serveur en mémoire pour tester la synchro sans réseau.

## Découpage proposé (une PR chacun)

1. **API locale** : migration, inscription, connexion, mot de passe oublié, `/sync`, Mailpit dans docker, tests PHP.
2. **App, compte** : écran « Mon compte » (créer, se connecter, se déconnecter), jeton dans le stockage sécurisé, verrouillage par empreinte ou visage.
3. **App, synchro** : révisions locales, pousser et tirer, déclencheurs, indicateur « synchronisé il y a 2 min ».
4. **Suppressions et compte** : pierres tombales, suppression du compte.
5. **Mise en ligne sur o2switch** : d'abord en préproduction, HTTPS, envoi d'e-mails réel.

## Décisions (Yann, 2026-10-30)

1. **Compte facultatif** : l'app gratuite marche sans compte. Il sera obligatoire pour les formules payantes.
2. **Mot de passe**, au moins une fois par appareil, puis **empreinte ou visage** pour ouvrir l'app. Pas de connexion qui dépende du réseau au gymnase.
3. **Une équipe, un seul coach** en V1. Le partage avec un adjoint est gardé pour la V2.
4. **API sur le domaine du site**, sous `/api/v1`.
