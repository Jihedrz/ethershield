# Triage des résultats Slither

## Méthodologie

- Outil : Slither `0.11.6`.
- Compilateur : Solidity `0.8.24`.
- Build : Foundry (`forge build`).
- Rapports bruts :
  - `audit/slither-vulnerable.txt` et `audit/slither-vulnerable.json`
  - `audit/slither-fixed.txt` et `audit/slither-fixed.json`
- Les dépendances (`lib/`) et les contrats de test/attaque sont exclus de
  l'analyse avec `--filter-paths` et `--exclude-dependencies`.

Slither produit des résultats de trois natures :

1. **Failles intentionnelles confirmées** : elles correspondent à un scénario
   du laboratoire et sont reproduites par un test.
2. **Faux positifs** : le détecteur signale un motif qui est ici le comportement
   attendu du contrat.
3. **Informations** : remarques de qualité ou de robustesse sans impact direct
   dans le périmètre du laboratoire.

## Synthèse

| Rapport | Nombre de résultats | Failles intentionnelles | Faux positifs / informations |
| --- | ---: | ---: | ---: |
| Contrats vulnérables | 18 | 6 | 12 |
| Contrats corrigés | 13 | 0 | 13 |

Les nombres ci-dessus correspondent aux occurrences listées dans les rapports
texte. Un même détecteur peut produire plusieurs occurrences.

## Résultats sur les contrats vulnérables

| Détecteur | Emplacement | Classification | Justification |
| --- | --- | --- | --- |
| `reentrancy-eth` | `EtherVault.withdraw` | Confirmé, intentionnel | Appel externe avant remise à zéro du solde ; exploité par `test_Exploit_Reentrancy_Succeeds`. |
| `reentrancy-eth` | `AdvancedTreasury.withdraw` | Confirmé, intentionnel | Même motif, combiné à `setHook` sans contrôle d'accès ; exploité par `test_Exploit_Advanced_Succeeds`. |
| `reentrancy-eth` | `RefundPool.refundAll` | Confirmé, secondaire | Le détecteur voit l'écriture après l'appel ; la faille principale reste le déni de service par paiement push. |
| `tx-origin` | `LabGovernance.transferOwnership`, `setTreasury` | Confirmé, intentionnel | Authentification par `tx.origin`, exploitée par le contrat de phishing. |
| `calls-loop` | `RefundPool.refundAll` | Confirmé, intentionnel | Boucle non bornée avec appels externes ; un destinataire qui revert bloque tout le monde. |
| `arbitrary-send-eth` | `FrontRunLottery.solve` | Faux positif | Envoyer le prix à `msg.sender` est le comportement attendu ; la faille réelle est l'ordre des transactions. |
| `arbitrary-send-eth` | `SignatureAirdrop.claim` | Faux positif | Payer le destinataire signé est attendu ; la faille réelle est l'absence de nonce et de domaine. |
| `reentrancy-events` | `EtherVault.withdraw`, `RefundPool.refundAll`, `FrontRunLottery.solve`, `SignatureAirdrop.claim` | Informationnel | L'émission d'événements après un appel externe est signalée ; elle n'est pas la cause racine, sauf pour la réentrance déjà couverte par `reentrancy-eth`. |
| `missing-zero-check` | `SignatureAirdrop.claim` | Informationnel | L'absence de contrôle de l'adresse nulle peut brûler des fonds mais ne permet pas de contourner l'autorisation. |
| `low-level-calls` | Plusieurs contrats | Informationnel | Les `call` bas niveau sont utilisés volontairement avec vérification du booléen de succès. |

## Résultats sur les contrats corrigés

| Détecteur | Emplacement | Classification | Justification |
| --- | --- | --- | --- |
| `arbitrary-send-eth` | `SignatureAirdropFixed.claim` | Faux positif | Le paiement au destinataire est le comportement attendu ; la signature EIP-712, le nonce et l'expiration protègent l'appel. |
| `missing-zero-check` | `SignatureAirdropFixed.claim` | Informationnel | Un contrôle d'adresse nulle serait une amélioration, sans lien avec le rejeu de signature. |
| `reentrancy-events` | `SignatureAirdropFixed.claim`, `RefundPoolFixed.refund`, `CommitRevealLottery.reveal` | Informationnel | Les états sont mis à jour avant l'appel (CEI) et/ou protégés par un garde ; l'ordre des événements n'introduit pas d'incohérence. |
| `timestamp` | `CommitRevealLottery.commit`, `CommitRevealLottery.reveal`, `SignatureAirdropFixed.claim` | Informationnel | Les délais ont besoin de `block.timestamp`. La manipulation par un validateur reste bornée et n'est pas le modèle de menace principal du laboratoire. |
| `low-level-calls` | `EtherVaultFixed.withdraw`, `RefundPoolFixed.refund`, `SignatureAirdropFixed.claim`, `CommitRevealLottery.reveal`, `AdvancedTreasuryFixed.withdraw` | Informationnel | Appels bas niveau nécessaires pour transférer l'ETH, avec vérification systématique du succès. |

## Faux positifs documentés

### 1. `arbitrary-send-eth` sur `SignatureAirdrop` et `SignatureAirdropFixed`

Slither signale qu'une fonction envoie de l'ETH à une adresse arbitraire. Dans
ce laboratoire, le paiement au destinataire est précisément la fonctionnalité de
l'airdrop. Le problème de sécurité n'est pas la destination du paiement mais,
pour la version vulnérable, l'absence de nonce, d'expiration et de séparation de
domaine. La version corrigée conserve donc ce motif tout en étant protégée
contre le rejeu. Le résultat est classé faux positif au regard de la faille
étudiée.

### 2. `arbitrary-send-eth` sur `FrontRunLottery`

Le prix doit être versé au premier participant qui fournit la bonne réponse.
Slither voit un transfert vers `msg.sender` et le signale, mais la faille
étudiée est le front-running : la réponse est publique avant inclusion et un
observateur peut copier la transaction. Le correctif ne supprime pas l'envoi
d'ETH ; il change le protocole en commit-reveal.

### 3. `missing-zero-check` sur les fonctions de réclamation

L'absence de contrôle `address(0)` est signalée comme informationnelle. Un
destinataire nul ferait perdre les fonds, mais cela ne permet ni de rejouer une
signature ni de contourner le contrôle d'accès. Ce n'est pas une faille du
scénario, seulement une robustesse perfectible.

### 4. `reentrancy-events` sur les contrats corrigés

Le détecteur considère qu'un événement émis après un appel externe peut être
réordonné. Dans les contrats corrigés, les effets comptables sont appliqués
avant l'appel et les retraits sensibles sont protégés par `nonReentrant`. Un
observateur ne peut pas exploiter l'ordre des journaux pour modifier l'état.
Résultat classé informationnel.

### 5. `timestamp` sur les délais

Les délais de signature et les phases commit-reveal utilisent nécessairement
`block.timestamp`. Un validateur peut décaler légèrement l'horloge, mais les
marges du laboratoire et l'absence d'enjeu réel rendent ce risque résiduel. Le
détecteur ne distingue pas cet usage légitime d'une loterie dépendante du temps.

## Failles intentionnelles que Slither ne détecte pas

Slither ne comprend pas les intentions métier. Il ne peut donc pas signaler
certaines failles du laboratoire :

| Faille | Contrat | Pourquoi Slither la manque |
| --- | --- | --- |
| Contrôle d'accès absent sur `mint` | `ShieldToken` | Aucun détecteur ne sait qu'une fonction de mint devrait être réservée à un rôle. Slither ne voit qu'un appel interne à `_mint`. |
| Contrôle d'accès absent sur `setHook` | `AdvancedTreasury` | Le changement de paramètre critique est syntaxiquement valide ; seule une politique d'autorisation permet de le qualifier. |
| Rejeu de signature | `SignatureAirdrop` | Slither ne modélise pas la sémantique « nonce + expiration + domaine ». Il signale le transfert, pas la réutilisation d'une signature valide. |
| Front-running / MEV | `FrontRunLottery` | Le détecteur est statique et ne voit pas le mempool ni l'ordre d'inclusion des transactions. |
| Impact exact du déni de service | `RefundPool` | Slither détecte `calls-loop`, mais ne prouve pas qu'un destinataire qui revert bloque tous les autres remboursements. |

## Conclusion du triage

Les failles de réentrance, de `tx.origin` et la boucle d'appels sont bien
détectées par Slither. Les failles de contrôle d'accès, de rejeu de signature
et de front-running nécessitent une revue manuelle et des tests d'exploitation.
Les résultats restants sur les contrats corrigés sont des faux positifs ou des
informations de robustesse, justifiés ci-dessus.
