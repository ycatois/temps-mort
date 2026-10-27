---
description: Faire le point mensuel sur l'acquisition (blog, Facebook, inscrits bêta)
---
1. Demande à Yann les chiffres du mois qu'il ne peut pas te transmettre autrement : visites Matomo, impressions Search Console, abonnés et portée Facebook, coût par inscription Meta Ads.
2. Compte les inscrits bêta du mois par source avec une requête en lecture seule sur `beta_signups` (Yann l'exécute sur o2switch : `SELECT source, COUNT(*) FROM beta_signups WHERE created_at >= '<début du mois>' GROUP BY source;`).
3. Compare aux seuils du plan (3 mois : 30 inscrits/semaine, 800 visites/mois, 2 % de conversion ; 6 mois : 60, 3 000, 3 %).
4. Écris `marketing/bilans/AAAA-MM.md` : chiffres, ce qui marche, ce qui ne marche pas, 3 décisions pour le mois suivant (sujets à prioriser, posts à refaire, budget pub).
