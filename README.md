# EtherShield

EtherShield est un laboratoire pédagogique de sécurité des smart contracts
Ethereum. Il permet de développer, auditer, exploiter et corriger des contrats
Solidity dans un environnement entièrement local.

> **Périmètre de sécurité** : toutes les manipulations se font sur un réseau
> Anvil local (`127.0.0.1:8545`) avec les comptes de test par défaut d'Anvil.
> Aucun RPC public, testnet, mainnet, fork ou clé réelle n'est utilisé. Les
> contrats vulnérables portent tous la mention
> `// VULNERABLE BY DESIGN - LAB USE ONLY` et vivent dans `src/vulnerable/`.

## Équipe et format

- Public : étudiants en cybersécurité.
- Durée : 6 à 8 semaines.
- Équipe : 3 à 4 personnes.
- Objectif : comprendre l'EVM, reproduire six familles de vulnérabilités,
  auditer avec Slither, corriger et prouver la correction par des tests.

## Stack

- Anvil (Foundry) comme blockchain locale.
- Solidity `^0.8.24`.
- Forge pour la compilation, les tests, le fuzz et les invariants.
- Slither pour l'analyse statique.
- OpenZeppelin Contracts pour les protections (`ReentrancyGuard`, `Ownable`,
  `AccessControl`, `EIP712`, `ECDSA`).
- Git et GitHub pour le versionnement.

## Prérequis

- Foundry (`forge`, `anvil`, `cast`).
- Python 3 et `pip`.
- Git.

## Installation et vérification

```bash
make install
make build
make test
```

`make install` installe `forge-std`, OpenZeppelin Contracts, Slither et le
compilateur Solidity `0.8.24` si nécessaire.

## Démarrage rapide

Dans un premier terminal :

```bash
make anvil
```

Dans un second terminal :

```bash
make deploy-vuln      # déploie les contrats vulnérables
make exploit          # exécute les sept scénarios d'attaque sur Anvil
forge test            # 46 tests : exploits, corrections, fuzz, invariants
make deploy-fixed     # déploie les contrats corrigés
make fixed            # tests de non-régression, fuzz et invariants
make slither          # rapports Slither dans audit/
```

La démonstration complète automatisée s'exécute avec :

```bash
make demo
```

## Architecture logique

```text
réseau Ethereum local (Anvil)
        |
        v
contrats vulnérables / contrats corrigés
        |
        v
scripts de test et scénarios d'exploitation
        |
        v
rapports d'audit et tests de non-régression
```

## Organisation du dépôt

```text
src/vulnerable/   contrats vulnérables
src/fixed/        contrats corrigés
src/attackers/    contrats attaquants utilisés par les exploits
src/examples/     exemples M1 (EVM, gas, stockage, événements, signatures)
test/exploits/    tests qui reproduisent chaque faille
test/fixed/       non-régression, fuzz et invariants des contrats corrigés
test/examples/    tests des fondamentaux Ethereum
script/           scripts Deploy*.s.sol et Exploit*.s.sol pour Anvil
audit/            rapports Slither, TRIAGE.md, RAPPORT_AUDIT.md
docs/             REPRODUCTION.md, DEMO.md
deployments/      adresses des contrats déployés (générées localement)
```

## Contrats et vulnérabilités

| Famille | Contrat vulnérable | Faille | Contrat corrigé | Test d'exploit |
| --- | --- | --- | --- | --- |
| Coffre-fort | `EtherVault` | Réentrance lors du retrait | `EtherVaultFixed` | `test/exploits/Reentrancy.t.sol` |
| Jeton | `ShieldToken` | Contrôle d'accès absent sur `mint` | `ShieldTokenFixed` | `test/exploits/AccessControl.t.sol` |
| Gouvernance | `LabGovernance` | Authentification par `tx.origin` | `LabGovernanceFixed` | `test/exploits/TxOrigin.t.sol` |
| Airdrop signé | `SignatureAirdrop` | Rejeu de signature | `SignatureAirdropFixed` | `test/exploits/SignatureReplay.t.sol` |
| Loterie | `FrontRunLottery` | Front-running / MEV | `CommitRevealLottery` | `test/exploits/FrontRunning.t.sol` |
| Pool de remboursement | `RefundPool` | Déni de service par appel externe | `RefundPoolFixed` | `test/exploits/Dos.t.sol` |
| Scénario avancé | `AdvancedTreasury` | Contrôle d'accès absent + réentrance | `AdvancedTreasuryFixed` | `test/exploits/Advanced.t.sol` |

Chaque test d'exploit suit la convention :

- `test_Exploit_<Vuln>_Succeeds` : l'attaque aboutit sur le contrat vulnérable.
- `test_Fixed_<Vuln>_ExploitReverts` : l'attaque échoue sur le contrat corrigé.

## Module M1 : fondamentaux Ethereum

Les exemples de `src/examples/` sont documentés et testés :

| Concept | Contrat | Test |
| --- | --- | --- |
| EVM et gas | `GasExample` | `test/examples/GasExample.t.sol` |
| Stockage et slots | `StorageExample` | `test/examples/StorageExample.t.sol` |
| Événements indexés | `EventExample` | `test/examples/EventExample.t.sol` |
| Signatures ECDSA | `SignatureExample` | `test/examples/SignatureExample.t.sol` |
| `payable`, `msg.sender`, transactions | `PaymentExample` | `test/examples/PaymentExample.t.sol` |

Les tests mesurent le gas avec `gasleft()`, lisent les slots avec `vm.load`,
vérifient les événements avec `vm.expectEmit` et récupèrent un signataire avec
`vm.sign` / `ECDSA.recover`. Le détail est dans `docs/REPRODUCTION.md`.

## Audit et remédiation

- `audit/slither-vulnerable.txt` et `.json` : analyse des contrats vulnérables.
- `audit/slither-fixed.txt` et `.json` : analyse des contrats corrigés.
- `audit/TRIAGE.md` : classification des résultats, faux positifs documentés et
  angles morts de Slither.
- `audit/RAPPORT_AUDIT.md` : rapport final en français, avec sévérité, impact,
  cause racine, preuve, correctif, validation et limites résiduelles.

Les protections ajoutées sont notamment :

- Checks-Effects-Interactions et `ReentrancyGuard` pour les retraits.
- `AccessControl` avec `MINTER_ROLE` pour le jeton.
- `msg.sender` pour l'authentification de la gouvernance.
- EIP-712, nonce par destinataire, expiration et séparation de domaine pour les
  signatures.
- Commit-reveal avec sel, délai d'engagement et délai de révélation.
- Paiements « pull » pour isoler les destinataires qui rejettent les transferts.
- `Ownable`, `nonReentrant` et CEI pour le scénario avancé.

## Mapping des critères d'évaluation

| Critère | Points | Fichiers qui le démontrent |
| --- | --- | --- |
| Compréhension Ethereum / EVM | 2 | `src/examples/`, `test/examples/`, `docs/REPRODUCTION.md` |
| Qualité des contrats vulnérables | 3 | `src/vulnerable/`, NatSpec et commentaires de cause racine |
| Démonstration contrôlée des vulnérabilités | 5 | `src/attackers/`, `test/exploits/`, `script/Exploit*.s.sol`, `docs/DEMO.md` |
| Audit et identification des causes racines | 3 | `audit/slither-*`, `audit/TRIAGE.md`, `audit/RAPPORT_AUDIT.md` |
| Correctifs et mécanismes de défense | 4 | `src/fixed/`, `test/fixed/`, `Makefile`, `docs/REPRODUCTION.md` |
| Tests automatisés et défense | 3 | `test/exploits/`, `test/fixed/`, cibles `test`, `fixed`, `fuzz`, `demo` |

## Commandes Makefile

| Commande | Effet |
| --- | --- |
| `make install` | Installe les dépendances et Slither |
| `make build` | Compile tous les contrats |
| `make anvil` | Démarre Anvil sur `127.0.0.1:8545` |
| `make deploy-vuln` | Déploie tous les contrats vulnérables |
| `make deploy-fixed` | Déploie tous les contrats corrigés |
| `make test` | Lance toute la suite de tests |
| `make exploit` | Lance tous les scripts d'exploitation sur Anvil |
| `make fixed` | Lance les tests des contrats corrigés |
| `make fuzz` | Lance les tests fuzz et invariants |
| `make slither` | Produit les rapports Slither |
| `make demo` | Exécute la démonstration complète |
| `make coverage` | Résumé de couverture Forge |
| `make exploit-<nom>` | Exploite une seule vulnérabilité |
| `make deploy-<nom>` | Déploie une seule famille de contrats |

Les noms disponibles sont : `reentrancy`, `access-control`, `tx-origin`,
`signature-replay`, `front-running`, `dos`, `advanced`.

## Documentation

- `docs/REPRODUCTION.md` : reproduction depuis un clone propre.
- `docs/DEMO.md` : démonstration live de 10 à 15 minutes.
- `audit/RAPPORT_AUDIT.md` : rapport d'audit final.
- `audit/TRIAGE.md` : triage des résultats Slither.

## Rappel de sécurité

Les clés présentes dans les scripts sont les clés de test publiques d'Anvil.
Elles ne doivent jamais être utilisées sur un réseau réel. Les scénarios
d'attaque sont strictement limités aux contrats de ce dépôt et au réseau local.
