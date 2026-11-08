# Rapport d'audit EtherShield

- Version : 1.0
- Date : novembre 2026
- Périmètre : `src/vulnerable/` et `src/fixed/`
- Réseau de validation : Anvil local `127.0.0.1:8545`
- Outils : Forge, Anvil, Slither `0.11.6`, Solidity `0.8.24`

## 1. Résumé exécutif

EtherShield est un laboratoire pédagogique qui reproduit six familles de
vulnérabilités Solidity, puis les corrige. Chaque faille est démontrée par un
test automatisé et par un script exécutable sur Anvil.

L'audit confirme :

- 6 failles intentionnelles dans les contrats vulnérables ;
- 1 scénario avancé qui combine deux failles ;
- 46 tests automatisés, dont 18 tests d'exploitation et de non-régression ;
- 18 résultats Slither sur les contrats vulnérables, dont 6 occurrences de
  failles intentionnelles et 12 faux positifs ou informations ;
- 13 résultats Slither sur les contrats corrigés, tous classés faux positifs ou
  informations ;
- aucune faille critique non corrigée dans le périmètre du laboratoire.

Les correctifs reposent sur Checks-Effects-Interactions, `ReentrancyGuard`,
`AccessControl`, `Ownable`, EIP-712 avec nonce et expiration, commit-reveal et
paiements « pull ». Les tests de non-régression vérifient que chaque exploit
échoue sur la version corrigée.

## 2. Périmètre

### Inclus

- `src/vulnerable/EtherVault.sol`
- `src/vulnerable/ShieldToken.sol`
- `src/vulnerable/LabGovernance.sol`
- `src/vulnerable/SignatureAirdrop.sol`
- `src/vulnerable/FrontRunLottery.sol`
- `src/vulnerable/RefundPool.sol`
- `src/vulnerable/AdvancedTreasury.sol`
- Les contrats correspondants dans `src/fixed/`
- Les scripts de déploiement et d'exploitation dans `script/`
- Les tests dans `test/exploits/` et `test/fixed/`

### Hors périmètre

- Les contrats de `src/attackers/` et `src/examples/` : ils servent à la
  démonstration et aux fondamentaux, pas à la production.
- Les dépendances OpenZeppelin et Forge : elles sont supposées fiables.
- Le front-end, l'infrastructure, les clés privées et les réseaux publics.
- La sécurité opérationnelle de GitHub et des comptes de déploiement.

### Modèle de menace

L'attaquant contrôle un compte Anvil, peut déployer des contrats, observer le
mempool local et envoyer des transactions. Il ne contrôle pas Anvil lui-même,
ne connaît pas les clés privées des autres comptes et n'a pas accès à un réseau
public. Les scénarios restent strictement locaux.

## 3. Méthodologie

1. Revue manuelle du code et des intentions métier.
2. Analyse statique avec Slither.
3. Reproduction de chaque faille avec un contrat attaquant et un test Forge.
4. Exécution des scripts sur Anvil pour vérifier le comportement réel.
5. Correction avec des primitives OpenZeppelin et des patterns reconnus.
6. Tests de non-régression, fuzz et invariants sur les contrats corrigés.
7. Triage des résultats Slither dans `audit/TRIAGE.md`.

Commandes principales :

```bash
forge test
forge test --match-path 'test/exploits/*' -vv
forge test --match-path 'test/fixed/*'
forge test --match-path 'test/fixed/*' --match-test 'testFuzz|invariant' -vvv
make slither
```

## 4. Synthèse des vulnérabilités

| # | Vulnérabilité | Contrat vulnérable | Sévérité | Impact | Preuve | Correctif |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Réentrance | `EtherVault` | Critique | Drain de tous les ETH du coffre | `test_Exploit_Reentrancy_Succeeds` | `EtherVaultFixed` : CEI + `nonReentrant` |
| 2 | Contrôle d'accès absent | `ShieldToken` | Critique | Création illimitée de jetons | `test_Exploit_AccessControl_Succeeds` | `ShieldTokenFixed` : `AccessControl` + `MINTER_ROLE` |
| 3 | Authentification par `tx.origin` | `LabGovernance` | Élevée | Prise de contrôle via phishing | `test_Exploit_TxOrigin_Succeeds` | `LabGovernanceFixed` : `Ownable` + `msg.sender` |
| 4 | Rejeu de signature | `SignatureAirdrop` | Élevée | Réclamation multiple d'un airdrop | `test_Exploit_SignatureReplay_Succeeds` | `SignatureAirdropFixed` : EIP-712 + nonce + expiration |
| 5 | Front-running | `FrontRunLottery` | Moyenne | Vol du prix par copie de la réponse | `test_Exploit_FrontRunning_Succeeds` | `CommitRevealLottery` : commit-reveal |
| 6 | Déni de service | `RefundPool` | Élevée | Blocage de tous les remboursements | `test_Exploit_DoS_Succeeds` | `RefundPoolFixed` : paiements « pull » |
| 7 | Combinaison contrôle d'accès + réentrance | `AdvancedTreasury` | Critique | Drain de la trésorerie | `test_Exploit_Advanced_Succeeds` | `AdvancedTreasuryFixed` : `Ownable` + `nonReentrant` + CEI |

## 5. Vulnérabilités détaillées

### 5.1 Réentrance dans `EtherVault`

**Sévérité : critique.**

**Emplacement :** `src/vulnerable/EtherVault.sol:32-41`.

**Description.** `withdraw` envoie les ETH avec `msg.sender.call{value:
amount}()` avant de remettre le solde à zéro. Un contrat attaquant peut
réentrer dans `withdraw` depuis son `receive` et retirer plusieurs fois le même
solde.

**Cause racine.** Violation de Checks-Effects-Interactions : l'interaction
externe précède l'effet comptable.

**Scénario.** L'attaquant dépose 1 ETH, appelle `withdraw`, puis réentre jusqu'à
ce que le coffre soit vide. Le contrat `EtherVaultAttacker` reçoit les fonds et
les transfère à son opérateur.

**Preuve.**

```bash
forge test --match-test test_Exploit_Reentrancy_Succeeds -vv
make exploit-reentrancy
```

Résultat observé : solde du coffre `0`, solde du contrat attaquant
`6000000000000000000` wei.

**Impact.** Perte totale des fonds déposés par tous les utilisateurs.

**Correctif.** `EtherVaultFixed` applique CEI : le solde est mis à zéro avant
l'appel, puis `nonReentrant` bloque toute réentrance. L'appel vérifie aussi le
succès du transfert.

**Validation.** `test_Fixed_Reentrancy_ExploitReverts` et l'invariant
`invariant_VaultBalanceCoversRecordedBalances` passent.

**Limites résiduelles.** Le garde ajoute du gas. Un propriétaire compromis ou un
changement futur du code peut réintroduire le motif. Le contrat reste dépendant
de la correction des autres contrats qui l'appellent.

### 5.2 Contrôle d'accès absent sur `ShieldToken.mint`

**Sévérité : critique.**

**Emplacement :** `src/vulnerable/ShieldToken.sol:21`.

**Description.** `mint` est `external` sans modificateur d'autorisation. Tout
compte peut créer des jetons pour n'importe quelle adresse.

**Cause racine.** Absence de politique d'autorisation sur une fonction
privilégiée.

**Scénario.** L'attaquant appelle `mint(attacker, 1_000_000e18)` et devient
détenteur d'un million de jetons.

**Preuve.**

```bash
forge test --match-test test_Exploit_AccessControl_Succeeds -vv
make exploit-access-control
```

Résultat observé : solde attaquant `1000000000000000000000000`, offre totale
`2000000000000000000000000`.

**Impact.** Inflation arbitraire, dilution des détenteurs, effondrement de la
valeur du jeton.

**Correctif.** `ShieldTokenFixed` utilise `AccessControl`, définit
`MINTER_ROLE` et applique `onlyRole(MINTER_ROLE)` à `mint`. Le rôle est accordé
au déployeur dans le constructeur.

**Validation.** `test_Fixed_AccessControl_ExploitReverts` et
`testFuzz_NonMinterCannotMint` passent.

**Limites résiduelles.** Le compte administrateur du rôle reste un point de
confiance. Une gouvernance ou un timelock serait nécessaire en production.

### 5.3 Authentification par `tx.origin` dans `LabGovernance`

**Sévérité : élevée.**

**Emplacement :** `src/vulnerable/LabGovernance.sol:34-49`.

**Description.** `transferOwnership` et `setTreasury` vérifient
`tx.origin == owner`. Un contrat intermédiaire appelé par le propriétaire peut
donc agir au nom de celui-ci.

**Cause racine.** Utilisation de `tx.origin` pour l'autorisation au lieu de
`msg.sender`.

**Scénario.** L'attaquant déploie `TxOriginPhishing`. Le propriétaire appelle
la fonction d'appât ; le contrat de phishing appelle `transferOwnership` et
devient propriétaire.

**Preuve.**

```bash
forge test --match-test test_Exploit_TxOrigin_Succeeds -vv
make exploit-tx-origin
```

Résultat observé : le propriétaire de la gouvernance devient le compte Anvil
n°1, contrôlé par l'attaquant.

**Impact.** Prise de contrôle complète de la gouvernance et de la trésorerie.

**Correctif.** `LabGovernanceFixed` hérite de `Ownable` et utilise
`onlyOwner`, donc `msg.sender`. Un contrat intermédiaire ne peut plus agir au
nom du propriétaire.

**Validation.** `test_Fixed_TxOrigin_ExploitReverts` et
`test_Fixed_TxOrigin_DirectCallerMustBeOwner` passent.

**Limites résiduelles.** Le propriétaire peut toujours signer une transaction
malveillante s'il est trompé directement. La protection contre le phishing
repose aussi sur l'éducation et la vérification des transactions.

### 5.4 Rejeu de signature dans `SignatureAirdrop`

**Sévérité : élevée.**

**Emplacement :** `src/vulnerable/SignatureAirdrop.sol:35-44`.

**Description.** Le contrat vérifie une signature sur `(recipient, amount)`
mais ne stocke pas de nonce, n'utilise pas de domaine EIP-712 et n'impose pas
d'expiration. Une signature valide peut être rejouée indéfiniment.

**Cause racine.** Absence de protection contre le rejeu : pas de nonce par
destinataire, pas de chaîne/contrat dans le message signé, pas de deadline.

**Scénario.** L'attaquant obtient une signature pour 1 ETH, l'utilise une
première fois, puis la rejoue. L'airdrop paie deux fois.

**Preuve.**

```bash
forge test --match-test test_Exploit_SignatureReplay_Succeeds -vv
make exploit-signature-replay
```

Résultat observé : le solde de l'airdrop passe de 100 ETH à 98 ETH pour deux
réclamations de 1 ETH avec une seule signature.

**Impact.** Épuisement du budget de l'airdrop et paiements non autorisés.

**Correctif.** `SignatureAirdropFixed` utilise EIP-712 avec un domaine qui
contient le nom, la version, `chainId` et l'adresse du contrat. Le message
contient `recipient`, `amount`, `nonce` et `deadline`. Le nonce est marqué
comme utilisé avant le transfert, et `ECDSA.recover` vérifie le signataire.

**Validation.** `test_Fixed_SignatureReplay_ExploitReverts`,
`test_Fixed_SignatureReplay_CrossContractReverts`,
`test_Fixed_SignatureReplay_ExpiredReverts` et
`testFuzz_ValidClaimPaysOnce` passent.

**Limites résiduelles.** La clé du signataire reste un point de confiance. Une
signature peut être retardée jusqu'à sa deadline. La révocation des nonces
n'est pas implémentée.

### 5.5 Front-running dans `FrontRunLottery`

**Sévérité : moyenne.**

**Emplacement :** `src/vulnerable/FrontRunLottery.sol:35-45`.

**Description.** La réponse `42` est visible dans la transaction publique. Un
attaquant peut copier la transaction, payer un gas plus élevé et être inclus
avant le participant honnête.

**Cause racine.** La condition de victoire est révélée avant l'inclusion et le
premier appel gagnant est récompensé.

**Scénario.** Le participant honnête soumet `solve(42)`. L'attaquant observe la
transaction dans le mempool et soumet `solve(42)` avec un gas supérieur. Il est
inclus en premier et reçoit le prix.

**Preuve.**

```bash
forge test --match-test test_Exploit_FrontRunning_Succeeds -vv
make exploit-front-running
```

Résultat observé : le solde de l'attaquant augmente de 10 ETH et la loterie
passe à `0`.

**Impact.** Vol du prix et perte de confiance dans le mécanisme de loterie.

**Correctif.** `CommitRevealLottery` impose deux phases. L'utilisateur engage
`keccak256(abi.encode(answer, salt, msg.sender))`, puis révèle après la
`commitDeadline`. Le premier commit valide est enregistré, et le premier reveal
correct gagne.

**Validation.** `test_Fixed_FrontRunning_ExploitReverts`,
`test_Fixed_FrontRunning_LateCommitReverts` et
`testFuzz_CommitRevealWinsPrize` passent.

**Limites résiduelles.** Le commit-reveal ne protège pas contre la censure, le
non-reveal, la collusion ou un mempool privé. Il ajoute aussi de la latence et
du gas. La confidentialité des transactions reste dépendante de
l'infrastructure.

### 5.6 Déni de service dans `RefundPool`

**Sévérité : élevée.**

**Emplacement :** `src/vulnerable/RefundPool.sol:35-45`.

**Description.** `refundAll` parcourt tous les contributeurs et envoie les ETH
avec `call`. Si un destinataire revert, toute la boucle revert et personne ne
peut être remboursé.

**Cause racine.** Paiement « push » dans une boucle non bornée, sans isolation
des échecs par destinataire.

**Scénario.** L'attaquant contribue depuis un contrat dont `receive` revert. Le
propriétaire appelle `refundAll` ; l'appel échoue et les autres contributeurs
ne reçoivent rien.

**Preuve.**

```bash
forge test --match-test test_Exploit_DoS_Succeeds -vv
make exploit-dos
```

Résultat observé : `refundAll` retourne `false` et le solde de la victime ne
change pas.

**Impact.** Blocage des remboursements et fonds immobilisés.

**Correctif.** `RefundPoolFixed` remplace le remboursement global par un
paiement « pull » : chaque contributeur appelle `refund()` pour son propre
solde. Le contrat applique CEI et vérifie le succès du transfert.

**Validation.** `test_Fixed_DoS_ExploitReverts`,
`testFuzz_ContributeRefundRoundTrip` et
`invariant_BalanceCoversContributions` passent.

**Limites résiduelles.** Chaque utilisateur doit agir et payer le gas. Un
utilisateur qui perd sa clé ne peut pas récupérer ses fonds. Le contrat ne
garantit pas un remboursement automatique.

### 5.7 Scénario avancé : contrôle d'accès + réentrance dans `AdvancedTreasury`

**Sévérité : critique.**

**Emplacement :** `src/vulnerable/AdvancedTreasury.sol:34-51`.

**Description.** `setHook` est public et permet à n'importe qui de remplacer le
hook appelé par `withdraw`. `withdraw` envoie les ETH au hook avant de mettre à
jour le solde, ce qui permet une réentrance.

**Cause racine.** Combinaison d'une fonction privilégiée non protégée et d'une
interaction externe avant l'effet comptable.

**Scénario.** L'attaquant appelle `setHook(attackerContract)`, dépose 1 ETH,
puis appelle `withdraw`. Le hook réentre et vide la trésorerie.

**Preuve.**

```bash
forge test --match-test test_Exploit_Advanced_Succeeds -vv
make exploit-advanced
```

Résultat observé : la trésorerie passe à `0` et le contrat attaquant détient
`6000000000000000000` wei.

**Impact.** Drain complet de la trésorerie.

**Correctif.** `AdvancedTreasuryFixed` protège `setHook` avec `onlyOwner`,
applique CEI dans `withdraw` et ajoute `nonReentrant`. Le hook est appelé après
la mise à jour du solde.

**Validation.** `test_Fixed_Advanced_ExploitReverts`,
`testFuzz_NonOwnerCannotSetHook` et
`testFuzz_DepositWithdrawRoundTrip` passent.

**Limites résiduelles.** Le propriétaire peut toujours configurer un hook
malveillant. La confiance dans l'administrateur reste nécessaire. Un timelock
et une gouvernance réduiraient ce risque.

## 6. Résultats Slither

Les rapports complets sont dans `audit/slither-vulnerable.txt` et
`audit/slither-fixed.txt`. Le triage détaillé est dans `audit/TRIAGE.md`.

### Contrats vulnérables

- `reentrancy-eth` : `EtherVault.withdraw`, `AdvancedTreasury.withdraw`,
  `RefundPool.refundAll` — confirmé.
- `tx-origin` : `LabGovernance.transferOwnership`, `setTreasury` — confirmé.
- `calls-loop` : `RefundPool.refundAll` — confirmé.
- `arbitrary-send-eth` : `FrontRunLottery.solve`, `SignatureAirdrop.claim` —
  faux positifs, le paiement est attendu.
- `reentrancy-events`, `missing-zero-check`, `low-level-calls` —
  informationnels.

### Contrats corrigés

- `arbitrary-send-eth` sur `SignatureAirdropFixed.claim` — faux positif.
- `missing-zero-check`, `reentrancy-events`, `timestamp`, `low-level-calls` —
  informationnels.

### Angles morts

Slither ne détecte pas le contrôle d'accès absent sur `ShieldToken.mint` et
`AdvancedTreasury.setHook`, le rejeu de signature ni le front-running. Ces
failles nécessitent une revue manuelle et des tests d'exploitation.

## 7. Validation

```bash
forge build
forge test
forge test --match-path 'test/exploits/*' -vv
forge test --match-path 'test/fixed/*'
forge test --match-path 'test/fixed/*' --match-test 'testFuzz|invariant' -vvv
make slither
```

Résultats attendus :

- compilation sans erreur ;
- 46 tests passés ;
- 18 tests d'exploitation et de non-régression ;
- 21 tests dans `test/fixed/` ;
- invariants et fuzz sans échec ;
- 18 résultats Slither sur les contrats vulnérables ;
- 13 résultats Slither sur les contrats corrigés.

## 8. Conclusion

Les six vulnérabilités demandées sont présentes, documentées, exploitables
localement et corrigées. Le scénario avancé montre qu'une combinaison de
failles peut être plus grave que chacune prise séparément. Les tests de
non-régression, le fuzz et les invariants donnent une preuve reproductible de la
correction.

Le laboratoire ne remplace pas un audit de production : il n'inclut pas de
vérification formelle, de test d'intégration avec un front-end, ni de revue des
clés opérationnelles. Les limites résiduelles sont documentées pour chaque
correctif.
