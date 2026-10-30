# Feuille de route

Source : doc « App volley — liste des fonctionnalités V1, V2, V3 » (claude.ai). Ce fichier suit l'avancement dans le dépôt.

Légende : ✅ fait dans le moteur `mobile/lib/domain` (testé) · 🟡 partiel · ⬜ à faire.

> **Changement de cap** : V1-TEC-08 (installation PWA) est remplacée par des apps natives iOS et Android publiées sur les stores (décision d'octobre 2026). Le reste de la V1 est inchangé.


## Comment lire la liste

## V1 — Le banc de touche

### Équipe et effectif (EQU)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-EQU-01 | Créer un compte coach (email + mot de passe, ou lien magique) | Indispensable | ⬜ |
| V1-EQU-02 | Créer une équipe : nom, catégorie (toutes les catégories fédérales, des plus jeunes aux seniors et vétérans, plus loisir et catégorie libre ; liste mise à jour chaque saison), saison, couleur | Indispensable | ✅ nom, catégorie, format, type, saison, couleur du maillot |
| V1-EQU-03 | Ajouter une joueuse : prénom, nom, numéro de maillot, poste principal (passeuse, pointue, réceptionneuse-attaquante, centrale, libero) | Indispensable | 🟡 prénom, numéro, poste (pas de nom : données minimales des mineures) |
| V1-EQU-04 | Poste secondaire et main forte (droitière ou gauchère) | Important | ⬜ |
| V1-EQU-05 | Modifier, archiver ou réactiver une joueuse en cours de saison | Indispensable | ✅ |
| V1-EQU-06 | Gérer plusieurs équipes depuis le même compte et passer de l'une à l'autre | Important | 🟡 plusieurs équipes sur l'accueil, sans compte |
| V1-EQU-07 | Photo de la joueuse (facultative, stockée sur l'appareil) | Confort | ⬜ |
| V1-EQU-08 | Importer un effectif depuis un fichier CSV | Confort | ⬜ |

### Formats de jeu et mixité (FOR)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-FOR-01 | Choisir le format de l'équipe à sa création : 6x6, 4x4 ou 2x2 | Indispensable | ✅ |
| V1-FOR-02 | Choisir le type d'équipe : féminine, masculine ou mixte | Indispensable | ✅ |
| V1-FOR-03 | Renseigner le genre de chaque joueur ou joueuse de l'effectif (nécessaire pour les équipes mixtes) | Indispensable | ✅ |
| V1-FOR-04 | Règles de mixité paramétrables (nombre minimum de femmes sur le terrain selon le règlement du championnat), contrôlées à la composition et à chaque remplacement | Indispensable | ✅ |
| V1-FOR-05 | 4x4 : terrain à 4 zones, rotation à 4, règles de remplacement et de score paramétrables | Indispensable | ✅ |
| V1-FOR-06 | 2x2 : pas de zones de rotation, ordre de service suivi automatiquement, pas de libero | Indispensable | ✅ |
| V1-FOR-07 | Saisie, stats et tableau tactique adaptés au format (6, 4 ou 2 pions, terrain à la bonne échelle) | Indispensable | ⬜ |
| V1-FOR-08 | Changer de format pour un match précis (une équipe 6x6 qui joue un tournoi 4x4 mixte) | Important | ✅ |
| V1-FOR-09 | Modèles de règles prêts à l'emploi (6x6, 4x4 jeunes, 2x2 jeunes, beach 2x2, mixte loisir), à vérifier avec les règlements FFVolley en vigueur | Important | ⬜ |

### Préparation du match (PRE)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-PRE-01 | Créer un match : adversaire, date, heure, lieu, domicile ou extérieur, compétition | Indispensable | ✅ |
| V1-PRE-02 | Choisir le format : 2 ou 3 sets gagnants, points par set, tie-break, format repris de l'équipe (6x6, 4x4, 2x2) et modifiable pour ce match | Indispensable | ✅ |
| V1-PRE-03 | Sélectionner les joueuses présentes (jusqu'à 14 dont 2 liberos) | Indispensable | ✅ avant la composition, modifiable depuis l'historique ; 14 au plus en 6x6 |
| V1-PRE-04 | Composer le six de départ en glissant les joueuses sur les zones 1 à 6 | Indispensable | ✅ glisser-déposer (tablette), appui long ou toucher puis zone (smartphone) |
| V1-PRE-05 | Désigner le ou les liberos (6x6 uniquement) et la capitaine | Indispensable | ✅ deux liberos, changement de libero en cours de set, capitaine |
| V1-PRE-06 | Choisir le système de jeu (4-2, 5-1, 6-2) pour pré-placer les réceptions | Important | 🟡 système choisi et contrôlé, pré-placement des réceptions à faire |
| V1-PRE-07 | Indiquer qui sert en premier | Indispensable | ✅ |
| V1-PRE-08 | Contrôler la composition : alerte si deux passeuses côte à côte en 5-1, libero placée en zone avant | Important | ✅ passeuses selon le système, libero de poste en zone avant |
| V1-PRE-09 | Enregistrer une composition type et la réutiliser au match suivant | Important | ✅ une compo type par équipe et par format |
| V1-PRE-10 | Préparer des compositions différentes par set à l'avance | Confort | ⬜ |

### Feuille de match vivante (MAT)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-MAT-01 | Afficher le score du set, les sets gagnés et l'équipe au service | Indispensable | ✅ |
| V1-MAT-02 | Faire tourner automatiquement l'équipe à chaque side-out gagné | Indispensable | ✅ |
| V1-MAT-03 | Afficher en permanence la rotation en cours (qui est où, qui sert) | Indispensable | ✅ |
| V1-MAT-04 | Remplacement : choisir la sortante et l'entrante, compteur des 6 remplacements, retour à la place d'origine contrôlé | Indispensable | ✅ panneau E06, compteur, retour à la place d'origine (paramètre, actif par défaut en 6x6) |
| V1-MAT-05 | Entrées et sorties du libero en zone arrière, sans décompter les remplacements | Indispensable | ✅ entrée et sortie du libero depuis E06, sortie automatique avant le poste 4 |
| V1-MAT-06 | Temps morts : compteur par équipe et par set | Indispensable | ✅ |
| V1-MAT-07 | Fin de set automatique au score réglementaire, début du set suivant avec nouvelle composition | Indispensable | ✅ |
| V1-MAT-08 | Annuler la dernière action, sans limite de profondeur | Indispensable | ✅ |
| V1-MAT-09 | Corriger à la main le score, le service ou la rotation (cas d'erreur d'arbitrage ou de saisie) | Indispensable | ⬜ |
| V1-MAT-10 | Chronologie du set : liste des points avec qui et comment | Important | ⬜ |
| V1-MAT-11 | Carton ou sanction à l'équipe adverse ou à la sienne | Confort | ⬜ |
| V1-MAT-12 | Mettre un match en pause et le reprendre plus tard | Important | ✅ un match quitté se reprend depuis l'accueil ou la liste des matchs |

### Saisie des statistiques (STA)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-STA-01 | Mode simple : point gagné ou perdu, puis la joueuse concernée (ou « faute adverse ») | Indispensable | ✅ |
| V1-STA-02 | Mode complet : joueuse puis action, en 2 tapes maximum | Indispensable | ✅ joueuse puis geste, gestes groupés par compétence |
| V1-STA-03 | Service : ace, en jeu, faute | Indispensable | ✅ |
| V1-STA-04 | Réception notée de 0 à 3 (faute, mauvaise, moyenne, parfaite) | Indispensable | ✅ |
| V1-STA-05 | Attaque : point, en jeu, faute, contrée | Indispensable | 🟡 point, en jeu, faute ; faute et contrée regroupées |
| V1-STA-06 | Contre : point, touché en jeu, faute (filet, invasion) | Indispensable | ✅ |
| V1-STA-07 | Défense : réussie ou ratée | Important | ✅ |
| V1-STA-08 | Passe : faute de passe (double, porté) | Important | ✅ |
| V1-STA-09 | Fautes adverses (service, attaque, filet) pour que le score reste juste | Indispensable | 🟡 un bouton « faute adverse », sans le type de faute |
| V1-STA-10 | Zone d'attaque ou de service en touchant le terrain | Confort | ⬜ |
| V1-STA-11 | Choisir le mode simple ou complet par match, et changer en cours de match | Important | ✅ choisi dans E03, modifiable dans E05 |

### Statistiques en direct (LIV)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-LIV-01 | Tableau par joueuse : points marqués, fautes, aces, attaques, réceptions | Indispensable | ✅ |
| V1-LIV-02 | Efficacité en attaque ((points − fautes − contrées) / tentatives) | Indispensable | ✅ en saisie complète |
| V1-LIV-03 | Qualité moyenne de réception par joueuse et par équipe | Indispensable | ✅ en saisie complète |
| V1-LIV-04 | Taux de side-out (points gagnés en réception) et de break (points gagnés au service) | Important | ✅ affiché dans E07 |
| V1-LIV-05 | Points gagnés et perdus par rotation, rotation la plus faible mise en avant | Important | ✅ barres par rotation, la plus faible mise en avant |
| V1-LIV-06 | Filtre par set ou pour tout le match | Important | ✅ |
| V1-LIV-07 | Origine des points : nos points marqués contre fautes adverses | Confort | ✅ |

### Tableau tactique (TAC)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-TAC-01 | Terrain vu du dessus avec 6 pions aux prénoms des joueuses | Indispensable | ✅ 6, 4 ou 2 pions selon le format |
| V1-TAC-02 | Pions pré-placés sur la rotation en cours du match | Indispensable | ✅ |
| V1-TAC-03 | Déplacer les pions au doigt | Indispensable | ✅ |
| V1-TAC-04 | Dessiner à main levée (flèches, zones, trajectoires) en 3 couleurs | Indispensable | ✅ |
| V1-TAC-05 | Effacer tout ou annuler le dernier trait | Indispensable | ✅ |
| V1-TAC-06 | Ajouter des pions adverses et un ballon | Important | ✅ |
| V1-TAC-07 | Enregistrer un schéma et le rappeler (bibliothèque) | Important | ✅ par équipe et par format |
| V1-TAC-08 | Schémas de réception pré-construits pour les 6 rotations en 4-2 et 5-1 | Important | ↪ abandonné (Yann, 2026-10-30) : chaque coach crée et enregistre les siens (TAC-07) |
| V1-TAC-09 | Basculer entre demi-terrain et terrain entier | Confort | ✅ |

### Temps mort et fin de match (TMO, FIN)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-TMO-01 | Bouton « Temps mort » : vue plein écran avec score, 3 chiffres clés du set et tableau tactique | Indispensable | ✅ side-out, break, fautes directes |
| V1-TMO-02 | Chronomètre de 30 secondes | Important | ✅ |
| V1-FIN-01 | Résumé automatique : score par set, meilleures joueuses par catégorie, chiffres clés | Indispensable | ✅ marqueuse, contre, service, réception (saisie complète) ; à retenir par rotation et fautes de service |
| V1-FIN-02 | Export du résumé en image et en PDF | Indispensable | ✅ |
| V1-FIN-03 | Partage du résumé (feuille de partage du téléphone : WhatsApp, email) | Indispensable | ✅ |
| V1-FIN-04 | Export des données brutes en CSV | Important | ✅ un événement par ligne |
| V1-FIN-05 | Historique des matchs de la saison, consultable et modifiable | Indispensable | ✅ par saison ; en cours / à venir / terminés, modifier les informations, résumé, supprimer |

### Technique et expérience (TEC)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V1-TEC-01 | Fonctionnement complet hors ligne pendant le match | Indispensable | ⬜ |
| V1-TEC-02 | Sauvegarde automatique après chaque action, aucune perte en cas de fermeture | Indispensable | ✅ SQLite, après chaque saisie et chaque annulation |
| V1-TEC-03 | Synchronisation avec le serveur dès que le réseau revient | Indispensable | ⬜ |
| V1-TEC-04 | Mise en page tablette en paysage et smartphone en portrait | Indispensable | ⬜ |
| V1-TEC-05 | Boutons d'au moins 56 px, contraste fort pour gymnase éclairé ou sombre | Indispensable | ⬜ |
| V1-TEC-06 | Écran maintenu allumé pendant le match | Indispensable | ✅ |
| V1-TEC-07 | Thème clair et sombre | Important | ⬜ |
| V1-TEC-08 | Installation comme application (PWA) depuis le navigateur | Indispensable | ↪ remplacé par apps natives |
| V1-TEC-09 | Données minimales sur les joueuses mineures, hébergement en France, suppression sur demande | Indispensable | 🟡 prénom et numéro seulement, suppression d'une joueuse ou d'une équipe sur l'appareil ; hébergement à faire avec la synchro |
| V1-TEC-10 | Retour haptique à chaque saisie (vibration courte) | Confort | ⬜ |

## V2 — L'équipe autour du match

### Convocations et calendrier (CON)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V2-CON-01 | Créer un événement : match, entraînement, tournoi, avec lieu et heure de rendez-vous | Indispensable | ⬜ |
| V2-CON-02 | Convoquer tout ou partie de l'effectif | Indispensable | ⬜ |
| V2-CON-03 | Réponse en un clic : présente, absente, incertaine, avec motif facultatif | Indispensable | ⬜ |
| V2-CON-04 | Relances automatiques des non-répondantes à J-3 et J-1 | Indispensable | ⬜ |
| V2-CON-05 | Entraînements récurrents (chaque mardi et jeudi) | Indispensable | ⬜ |
| V2-CON-06 | Organisation du covoiturage : places proposées et demandées | Important | ⬜ |
| V2-CON-07 | Adresse du gymnase avec lien vers l'itinéraire | Important | ⬜ |
| V2-CON-08 | Abonnement au calendrier de l'équipe (iCal) | Important | ⬜ |
| V2-CON-09 | Import du calendrier de championnat depuis un fichier | Confort | ⬜ |
| V2-CON-10 | Liste des présentes reprise automatiquement dans la préparation du match | Indispensable | ⬜ |

### Joueuses et parents (JOU)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V2-JOU-01 | Invitation des joueuses et des parents par lien | Indispensable | ⬜ |
| V2-JOU-02 | Joueuse mineure rattachée à un ou deux parents, consentement parental enregistré | Indispensable | ⬜ |
| V2-JOU-03 | Application joueuse et parent : convocations, calendrier, messages | Indispensable | ⬜ |
| V2-JOU-04 | Fiche personnelle de la joueuse orientée progrès (pas de classement entre joueuses) | Important | ⬜ |
| V2-JOU-05 | Coach qui choisit ce que chaque joueuse voit de ses stats | Important | ⬜ |
| V2-JOU-06 | Messages du coach à l'équipe, avec accusé de lecture | Indispensable | ⬜ |
| V2-JOU-07 | Contacts d'urgence et informations médicales utiles, visibles du seul coach | Important | ⬜ |
| V2-JOU-08 | Notifications push | Indispensable | ⬜ |

### Présence et temps de jeu (PRS)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V2-PRS-01 | Appel à l'entraînement en une page | Indispensable | ⬜ |
| V2-PRS-02 | Taux d'assiduité par joueuse sur la saison | Important | ⬜ |
| V2-PRS-03 | Sets et points joués par joueuse, calculés depuis les matchs | Indispensable | ⬜ |
| V2-PRS-04 | Alerte quand une joueuse joue nettement moins que les autres | Important | ⬜ |

### Appli web du coach (WEB)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V2-WEB-01 | Tableau de bord de la saison : bilan, sets, tendances | Indispensable | ⬜ |
| V2-WEB-02 | Progression d'une joueuse match après match (réception, attaque, service) | Indispensable | ⬜ |
| V2-WEB-03 | Comparaison de deux matchs ou de deux périodes | Important | ⬜ |
| V2-WEB-04 | Rendement par rotation sur la saison | Important | ⬜ |
| V2-WEB-05 | Bilan d'un adversaire déjà rencontré | Confort | ⬜ |
| V2-WEB-06 | Export de la saison en PDF et CSV | Important | ⬜ |
| V2-WEB-07 | Gestion des équipes, des effectifs et des réglages sur grand écran | Indispensable | ⬜ |

### Encadrement (STF)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V2-STF-01 | Inviter un coach adjoint avec les mêmes droits | Indispensable | ⬜ |
| V2-STF-02 | Rôle « saisie seule » pour un parent ou une joueuse blessée qui tient les stats | Important | ⬜ |
| V2-STF-03 | Journal des modifications : qui a changé quoi | Confort | ⬜ |

## V3 — Différenciation

### Saisie avancée (SAI)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V3-SAI-01 | Saisie à la voix (« Lucie, ace », « réception 2 Emma ») | Important | ⬜ |
| V3-SAI-02 | Deux appareils sur le même match en direct : un saisit, l'autre consulte | Important | ⬜ |
| V3-SAI-03 | Saisie partagée : un appareil pour l'attaque, un autre pour la réception | Confort | ⬜ |
| V3-SAI-04 | Mode scouting de l'adversaire (stats de l'autre équipe) | Important | ⬜ |

### Vidéo (VID)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V3-VID-01 | Lier une vidéo du match (fichier ou lien) et caler son départ sur le premier point | Important | ⬜ |
| V3-VID-02 | Chaque stat ouvre l'instant correspondant de la vidéo | Important | ⬜ |
| V3-VID-03 | Montages automatiques par joueuse ou par type d'action | Confort | ⬜ |
| V3-VID-04 | Partage d'une séquence à une joueuse | Confort | ⬜ |

### Assistant IA (IA)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V3-IA-01 | Résumé du match en langage clair, prêt à envoyer aux parents | Important | ⬜ |
| V3-IA-02 | Points faibles détectés et exercices proposés pour l'entraînement suivant | Important | ⬜ |
| V3-IA-03 | Fiche de préparation d'un adversaire déjà affronté | Confort | ⬜ |
| V3-IA-04 | Suggestion de composition selon la forme et l'adversaire | Confort | ⬜ |
| V3-IA-05 | Réponses aux questions du coach sur ses données (« qui réceptionne le mieux en rotation 3 ? ») | Important | ⬜ |

### Entraînement (ENT)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V3-ENT-01 | Bibliothèque d'exercices avec schéma animé sur le tableau tactique | Important | ⬜ |
| V3-ENT-02 | Planification d'une séance (échauffement, exercices, durées) | Important | ⬜ |
| V3-ENT-03 | Partage de séances entre coachs du club | Confort | ⬜ |
| V3-ENT-04 | Tests physiques et suivi (détente, vitesse) | Confort | ⬜ |

### Écosystème (ECO)

| ID | Fonctionnalité | Priorité | État |
|---|---|---|---|
| V3-ECO-01 | Beach-volley (2 contre 2, pas de rotation) | Important | ⬜ |
| V3-ECO-02 | « Pack sport » pour ouvrir d'autres sports à sets puis le handball et le basket | Important | ⬜ |
| V3-ECO-03 | Offre club : toutes les équipes, tableau de bord du responsable technique | Important | ⬜ |
| V3-ECO-04 | Paiement de cotisations et déplacements via HelloAsso | Confort | ⬜ |
| V3-ECO-05 | Lien avec les données fédérales (calendrier, licences) si la FFVolley les ouvre | Confort | ⬜ |
| V3-ECO-06 | Page publique du match avec score en direct pour les familles | Confort | ⬜ |
## Inventaire des écrans V1

| Écran | Rôle | Fonctionnalités | Tablette | Smartphone | Maquette |
|---|---|---|---|---|---|
| E01 Accueil | Prochain match, équipes, reprise d'un match en cours | EQU-06, MAT-12, FIN-05 | Deux colonnes | Liste | Non |
| E02 Effectif | Liste et fiche joueuse | EQU-03 à 08 | Liste + fiche | Liste puis fiche | Non |
| E03 Nouveau match | Adversaire, lieu, format | PRE-01, PRE-02 | Formulaire | Formulaire | Non |
| E04 Composition | Six de départ, libero, service, système | PRE-03 à 10 | Terrain + banc côte à côte | Terrain puis banc | Oui |
| E05 Match en direct | Score, rotation, saisie des stats | MAT-01 à 10, STA-01 à 11 | Terrain à gauche, saisie à droite | Score en haut, terrain, saisie en bas | Oui |
| E06 Remplacement | Sortante, entrante, compteur | MAT-04, MAT-05 | Panneau latéral | Feuille du bas | Non (panneau de E05) |
| E07 Stats en direct | Tableau par joueuse, rotations | LIV-01 à 07 | Tableau + rotations | Onglets | Oui |
| E08 Tableau tactique | Pions, dessin, schémas | TAC-01 à 09 | Terrain plein écran + outils | Terrain + barre d'outils | Oui |
| E09 Temps mort | Score, 3 chiffres clés, tactique | TMO-01, TMO-02 | Plein écran | Plein écran | Non (variante de E08) |
| E10 Résumé du match | Score par set, meilleures joueuses, partage | FIN-01 à 04 | Carte de résumé + actions | Carte + actions | Oui |
| E11 Historique | Matchs de la saison | FIN-05 | Liste | Liste | Non |
| E12 Réglages | Compte, thème, mode de saisie, données | TEC-07, TEC-09, STA-11 | Liste | Liste | Non |
