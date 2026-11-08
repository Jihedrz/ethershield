# Reproduction EtherShield

Ce document décrit la reproduction complète du laboratoire depuis un clone
propre. Toutes les commandes supposent un réseau Anvil local sur
`http://127.0.0.1:8545` et n'utilisent que les comptes de test publics d'Anvil.

## 1. Prérequis

```bash
forge --version
anvil --version
slither --version
solc --version
```

Si Foundry n'est pas installé :

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Le projet compile avec Solidity `0.8.24`. `make install` installe aussi
`slither-analyzer` et `solc-select` si nécessaire.

## 2. Installation depuis un clone propre

```bash
git clone <url-du-depot> ethershield
cd ethershield
make install
make build
make test
```

Résultat attendu : compilation réussie et `46 tests passed, 0 failed`.

## 3. Module M1 : fondamentaux Ethereum

```bash
forge test --match-path 'test/examples/*' -vv
```

Les tests couvrent :

- `GasExample` : comparaison du coût des écritures de stockage et du travail en
  mémoire, mesure avec `gasleft()`.
- `StorageExample` : lecture directe des slots 0, 1 et 2 avec `vm.load` et
  vérification du packing de deux `uint128` dans le slot 1.
- `EventExample` : vérification d'un événement indexé avec `vm.expectEmit`.
- `SignatureExample` : signature hors chaîne avec `vm.sign` et récupération avec
  `ECDSA.recover`.
- `PaymentExample` : `payable`, `msg.sender`, appel explicite et transfert ETH
  direct via `receive`.

Résultat attendu :

```text
Ran 7 tests for test/examples/...: 7 tests passed
```

## 4. Démarrage du réseau local

Terminal 1 :

```bash
make anvil
```

Anvil affiche une liste de comptes de test et écoute sur
`http://127.0.0.1:8545`. Ne pas fermer ce terminal.

Terminal 2, à la racine du dépôt :

```bash
cast block-number --rpc-url http://127.0.0.1:8545
```

La commande doit retourner un nombre. Si elle échoue, Anvil n'est pas démarré.

## 5. Déploiement des contrats vulnérables

```bash
make deploy-vuln
```

Exemple de sortie sur un Anvil neuf :

```text
EtherVault 0x5FbDB2315678afecb367f032d93F642f64180aa3
ShieldToken 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
LabGovernance 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
SignatureAirdrop 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
FrontRunLottery 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
RefundPool 0x0165878A594ca255338adfa4d48449f69242Eb8F
AdvancedTreasury 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
```

Les adresses sont aussi écrites dans `deployments/*.json` pour être lues par
les scripts d'exploitation.

## 6. Exploitation des six vulnérabilités

Chaque commande cible le contrat déjà déployé sur Anvil.

### 6.1 Réentrance

```bash
make exploit-reentrancy
```

Le script dépose 5 ETH pour la victime, puis l'attaquant dépose 1 ETH et
réentre dans `withdraw`. Sortie attendue :

```text
vault balance after attack 0
attacker contract balance 6000000000000000000
```

### 6.2 Contrôle d'accès

```bash
make exploit-access-control
```

Sortie attendue :

```text
attacker token balance 1000000000000000000000000
total supply 2000000000000000000000000
```

### 6.3 `tx.origin`

```bash
make exploit-tx-origin
```

Le propriétaire est amené à appeler un contrat de phishing. Sortie attendue :

```text
governance owner 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

Cette adresse est celle du compte Anvil n°1, contrôlé par l'attaquant.

### 6.4 Rejeu de signature

```bash
make exploit-signature-replay
```

La même signature est utilisée deux fois. Sortie attendue :

```text
attacker ETH balance <solde supérieur au solde initial>
airdrop balance 98000000000000000000
```

Le contrat d'airdrop passe de 100 ETH à 98 ETH : deux retraits de 1 ETH ont été
payés avec une seule signature.

### 6.5 Front-running / MEV

```bash
make exploit-front-running
```

Sortie attendue :

```text
attacker ETH balance <solde augmenté de 10 ETH>
lottery balance 0
```

L'attaquant copie la réponse publique `42` et prend le prix avant le
participant honnête.

### 6.6 Déni de service

```bash
make exploit-dos
```

Un attaquant contribue depuis un contrat dont `receive` revert. Sortie
attendue :

```text
refundAll succeeded false
victim ETH balance <solde inchangé>
pool balance 1000000000000000001
```

Le remboursement global est bloqué pour tous.

### 6.7 Scénario avancé

```bash
make exploit-advanced
```

Le contrat attaquant combine l'absence de contrôle d'accès sur `setHook` et la
réentrance de `withdraw`. Sortie attendue :

```text
treasury balance after attack 0
attacker contract balance 6000000000000000000
```

## 7. Tests automatisés des exploits

```bash
forge test --match-path 'test/exploits/*' -vv
```

Chaque fichier contient les deux tests demandés :

- `test_Exploit_<Vuln>_Succeeds`
- `test_Fixed_<Vuln>_ExploitReverts`

Résultat attendu : `18 tests passed, 0 failed`.

## 8. Déploiement des contrats corrigés

```bash
make deploy-fixed
```

Exemple de sortie :

```text
EtherVaultFixed 0x610178dA211FEF7D417bC0e6FeD39F05609AD788
ShieldTokenFixed 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
LabGovernanceFixed 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0
SignatureAirdropFixed 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82
CommitRevealLottery 0x0B306BF915C4d645ff596e518fAf3F9669b97016
RefundPoolFixed 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1
AdvancedTreasuryFixed 0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE
```

## 9. Non-régression, fuzz et invariants

```bash
make fixed
make fuzz
```

`make fixed` lance les tests de comportement normal et les tests d'exploit
corrigés. `make fuzz` lance les campagnes de fuzz (1000 exécutions) et les
invariants (256 séquences, profondeur 64).

Invariants vérifiés :

- `EtherVaultFixed` : le solde physique du coffre couvre la somme des soldes
  enregistrés, et `totalDeposits` reste égal à cette somme.
- `RefundPoolFixed` : le solde du pool couvre la somme des contributions
  enregistrées.

Résultat attendu : tous les tests et invariants passent.

## 10. Audit Slither

```bash
make slither
```

Rapports produits :

- `audit/slither-vulnerable.txt`
- `audit/slither-vulnerable.json`
- `audit/slither-fixed.txt`
- `audit/slither-fixed.json`

Le triage et la justification des faux positifs sont dans `audit/TRIAGE.md`.
Le rapport final est dans `audit/RAPPORT_AUDIT.md`.

## 11. Couverture

```bash
make coverage
```

Le résumé de couverture est affiché dans le terminal. Il sert à vérifier que les
scénarios d'exploitation et les correctifs sont bien exercés.

## 12. Démonstration complète

```bash
make demo
```

Cette cible démarre ou réinitialise Anvil, déploie les contrats vulnérables,
exécute tous les exploits, lance les tests, déploie les contrats corrigés,
rejoue les tests de défense et termine par Slither.

## 13. Dépannage

- `Anvil is not running` : lancer `make anvil` dans un autre terminal.
- `Address ... not found` : exécuter d'abord `make deploy-vuln` ou
  `make deploy-<nom>`.
- `nonce too low` : réinitialiser Anvil (`cast rpc anvil_reset`) puis redéployer.
- Slither échoue à compiler : vérifier `solc-select use 0.8.24` et relancer
  `make install`.
- Les scripts d'exploitation sont idempotents autant que possible, mais un
  redémarrage d'Anvil garantit un état propre.
