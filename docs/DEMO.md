# Démonstration EtherShield

Cette démonstration dure 10 à 15 minutes. Elle se déroule entièrement sur
Anvil local. Les contrats vulnérables sont clairement identifiés et aucune
transaction ne part vers un réseau public.

## Préparation

Terminal 1 :

```bash
cd ethershield
make anvil
```

Terminal 2 :

```bash
cd ethershield
forge --version
cast block-number --rpc-url http://127.0.0.1:8545
```

Si Anvil tourne déjà, `make demo` réinitialise son état avec
`cast rpc anvil_reset`. Sinon, le script démarre un Anvil temporaire et l'arrête
à la fin.

## Option A : démonstration automatisée

```bash
make demo
```

Le script enchaîne :

1. déploiement des contrats vulnérables ;
2. exécution des sept scénarios d'exploitation ;
3. tests d'exploitation et de non-régression (18 tests) ;
4. déploiement des contrats corrigés ;
5. tests des correctifs, fuzz et invariants (21 tests) ;
6. analyse Slither et écriture des rapports.

Sortie finale attendue :

```text
[demo] complete
```

## Option B : démonstration commentée

### 0:00–1:30 — Introduction et périmètre

```bash
pwd
forge --version
cast block-number --rpc-url http://127.0.0.1:8545
```

Message à présenter :

- EtherShield est un laboratoire local.
- Les contrats vulnérables portent `// VULNERABLE BY DESIGN - LAB USE ONLY`.
- Aucun RPC public, aucune clé réelle, aucun testnet.
- Les clés des scripts sont les clés publiques de test d'Anvil.

### 1:30–3:00 — Fondamentaux Ethereum (optionnel)

```bash
forge test --match-path 'test/examples/*' -vv
```

Résultat attendu :

```text
Ran 5 test suites: 7 tests passed, 0 failed
```

Commenter rapidement :

- `GasExample` mesure le gas avec `gasleft()`.
- `StorageExample` lit les slots avec `vm.load` et montre le packing.
- `EventExample` vérifie un événement indexé avec `vm.expectEmit`.
- `SignatureExample` signe hors chaîne et récupère l'adresse avec `ECDSA`.
- `PaymentExample` illustre `payable`, `msg.sender` et `receive`.

### 3:00–4:30 — Déploiement des contrats vulnérables

```bash
make deploy-vuln
```

Sortie attendue :

```text
EtherVault 0x5FbDB2315678afecb367f032d93F642f64180aa3
ShieldToken 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
LabGovernance 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
SignatureAirdrop 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
FrontRunLottery 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
RefundPool 0x0165878A594ca255338adfa4d48449f69242Eb8F
AdvancedTreasury 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
```

Les adresses sont aussi dans `deployments/*.json`.

### 4:30–8:00 — Exploitation des six vulnérabilités

#### Réentrance

```bash
make exploit-reentrancy
```

```text
vault balance after attack 0
attacker contract balance 6000000000000000000
```

Le coffre est vidé par réentrance dans `withdraw`.

#### Contrôle d'accès

```bash
make exploit-access-control
```

```text
attacker token balance 1000000000000000000000000
total supply 2000000000000000000000000
```

`ShieldToken.mint` n'a aucune autorisation : l'attaquant crée un million de
jetons.

#### `tx.origin`

```bash
make exploit-tx-origin
```

```text
governance owner 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

Le propriétaire devient le compte Anvil n°1, contrôlé par l'attaquant, via un
contrat de phishing.

#### Rejeu de signature

```bash
make exploit-signature-replay
```

```text
attacker ETH balance 10000998908484000000000
airdrop balance 98000000000000000000
```

Une seule signature est utilisée deux fois : l'airdrop perd 2 ETH.

#### Front-running

```bash
make exploit-front-running
```

```text
attacker ETH balance 10010998763584000000000
lottery balance 0
```

L'attaquant copie la réponse publique et prend le prix.

#### Déni de service

```bash
make exploit-dos
```

```text
refundAll succeeded false
victim ETH balance 9993999910088000000000
pool balance 1000000000000000001
```

Un contrat qui revert dans `receive` bloque le remboursement de tous.

#### Scénario avancé

```bash
make exploit-advanced
```

```text
treasury balance after attack 0
attacker contract balance 6000000000000000000
```

L'attaquant remplace le hook via `setHook`, puis vide la trésorerie par
réentrance.

### 8:00–9:30 — Tests automatisés des exploits

```bash
forge test --match-path 'test/exploits/*' -vv
```

Résultat attendu :

```text
Ran 7 test suites: 18 tests passed, 0 failed
```

Chaque famille contient `test_Exploit_<Vuln>_Succeeds` et
`test_Fixed_<Vuln>_ExploitReverts`.

### 9:30–11:00 — Déploiement des contrats corrigés

```bash
make deploy-fixed
```

Sortie attendue :

```text
EtherVaultFixed 0x610178dA211FEF7D417bC0e6FeD39F05609AD788
ShieldTokenFixed 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
LabGovernanceFixed 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0
SignatureAirdropFixed 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82
CommitRevealLottery 0x0B306BF915C4d645ff596e518fAf3F9669b97016
RefundPoolFixed 0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1
AdvancedTreasuryFixed 0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE
```

### 11:00–12:30 — Non-régression, fuzz et invariants

```bash
forge test --match-path 'test/fixed/*' -vv
```

Résultat attendu :

```text
Ran 9 test suites: 21 tests passed, 0 failed
```

Les tests vérifient que les exploits échouent et que les invariants tiennent :

- le coffre couvre les soldes enregistrés ;
- `totalDeposits` correspond à la somme des dépôts ;
- le pool couvre les contributions.

### 12:30–14:00 — Audit Slither

```bash
make slither
```

Résultat attendu :

```text
[slither] reports written to audit/slither-vulnerable.txt and audit/slither-fixed.txt
```

Points à commenter :

- `reentrancy-eth`, `tx-origin` et `calls-loop` sont détectés ;
- `arbitrary-send-eth` sur les airdrops est un faux positif ;
- le contrôle d'accès absent sur `mint` et `setHook`, le rejeu de signature et
  le front-running ne sont pas détectés par Slither ;
- le triage complet est dans `audit/TRIAGE.md`.

### 14:00–15:00 — Conclusion

```bash
forge test
```

Résultat attendu :

```text
Ran 21 test suites: 46 tests passed, 0 failed
```

Message final :

- six failles reproduites et corrigées ;
- un scénario avancé ;
- des tests d'exploitation et de non-régression ;
- un audit statique trié ;
- un périmètre strictement local.

## En cas de problème

- `Anvil is not running` : relancer `make anvil`.
- `Address not found` : relancer `make deploy-vuln`.
- `nonce too low` : réinitialiser avec `cast rpc anvil_reset`, puis redéployer.
- Les commandes `make deploy-*` et `make exploit-*` utilisent des transactions
  legacy avec un prix de gas fixe pour rester stables sur Anvil.
