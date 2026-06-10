# Zadání

Zajištění provozního a bezpečnostního monitoringu a logů, pro zajištění informovnosti o stavu služeb, jejich zdraví a bezpečnosti.
Při sběru logů vytvořit centralizované uložiště pro možné napojení na SIEM. Napojení nástoroje na SIEM. 

# Doporučení pro bezpečnostní monitoring a detekci

Tento dokument obsahuje metodická doporučení pro zavedení robustního bezpečnostního monitoringu a detekce hrozeb (Security Monitoring & Detection) při provozování cloudové infrastruktury (Kontejnery/Kubernetes, Databáze) v prostředí Microsoft Azure.

---

## 1. Architektura sběru bezpečnostních dat (Logování)

Základem pro efektivní detekci hrozeb je centrální sběr relevantních bezpečnostních logů. Data z různých vrstev infrastruktury nesmí zůstávat izolovaná.

*   **Centrální úložiště (Log Analytics Workspace)**:
    *   Doporučujeme všechny auditní, bezpečnostní a síťové logy směrovat do centrálního repozitáře (Log Analytics), který slouží jako základna pro vyhodnocování hrozeb a případné napojení na SIEM.
*   **Sběr na úrovni Identit (Microsoft Entra ID)**:
    *   Monitorujte Sign-in logy a Audit logy. Zaměřte se na detekci anomálního chování (např. přihlášení z neobvyklých lokací, "Impossible travel" anomálie).
*   **Sběr na úrovni Infrastruktury a Sítě**:
    *   *NSG Flow Logs*: Logujte síťový provoz (povolený i odepřený) procházející virtuálními sítěmi (VNet) pro forenzní analýzu.
    *   *Control Plane Logy (AKS)*: U Kubernetes clusterů zapněte sběr logů z API serveru (Kube-audit). Tím získáte viditelnost do toho, kdo a jaké příkazy spouští v rámci clusteru.
*   **Sběr na úrovni Databáze**:
    *   Aktivujte auditní logy databáze (např. v PostgreSQL `pgaudit`) pro sledování neoprávněných pokusů o přístup k citlivým tabulkám nebo nestandardních SQL dotazů.

## 2. Nástroje pro aktivní detekci hrozeb

Nestačí data pouze ukládat, je nutné nad nimi automatizovaně vyhledávat vzorce útoků a zranitelností.

*   **Microsoft Defender for Cloud (Cloud Security Posture Management)**:
    *   *Základní doporučení*: Nasadit tento nástroj pro neustálé vyhodnocování zranitelností a bezpečnostní konfigurace (shoda s ISO 27001 nebo CIS benchmarks).
    *   *Defender for Containers*: Aktivně skenuje repozitáře (Container Registries) a běžící kontejnery na výskyt známých zranitelností (CVE). Detekuje podezřelé chování přímo uvnitř kontejnerů (např. nečekané spouštění shellu nebo těžbu kryptoměn).
    *   *Defender for Databases*: Analyzuje komunikaci s databázemi a automaticky detekuje útoky typu SQL Injection, brute-force útoky na přihlášení nebo exfiltraci dat.
*   **SIEM / SOAR řešení (např. Microsoft Sentinel)**:
    *   Pro pokročilý bezpečnostní monitoring doporučujeme integraci Log Analytics s řešením typu SIEM (Security Information and Event Management). Slouží ke korelaci událostí napříč identitami, sítí, infrastrukturou a k automatizované reakci (SOAR) na bezpečnostní incidenty.

## 3. Na co se zaměřit při detekci a alertování (Use-cases)

Nastavení bezpečnostních pravidel by mělo upozornit bezpečnostní tým (SOC) nebo administrátory na konkrétní pokusy o narušení.

### Příklady bezpečnostních alertů (Co detekovat):
1.  **Pokusy o průnik a lateral movement (Síť & Identity)**:
    *   Opakované neúspěšné pokusy o přihlášení na administrátorské účty následované úspěšným přihlášením.
    *   Přístupy z anonymizátorů (Tor sítě) nebo IP adres spojených s botnety (využití Threat Intelligence).
2.  **Kompromitace výpočetních zdrojů (Kubernetes/AKS)**:
    *   Spuštění kontejneru s neoprávněnými oprávněními (např. `--privileged` mód).
    *   Odchozí síťový provoz z kontejnerů na neznámé nebo škodlivé externí IP adresy (Command & Control servery).
    *   Modifikace kritických konfiguračních souborů (`/etc/shadow`, `/etc/kubernetes`) uvnitř kontejnerů.
3.  **Úniky a manipulace s daty (Databáze)**:
    *   Náhlý export neobvykle velkého objemu dat (Data Exfiltration).
    *   Úprava oprávnění a vytváření nových privilegovaných uživatelů přímo v databázi mimo standardní CI/CD procesy.

## 4. Reakce na incidenty (Incident Response)
Součástí bezpečnostního monitoringu musí být i předem definované procesy reakce:
*   Mít jasně definovanou matici odpovědností: Kdo je notifikován při spuštění bezpečnostního alertu s vysokou prioritou.
*   Zajistit možnost rychlé izolace (např. odpojení napadeného nodu z Kubernetes clusteru, rotace kompromitovaných klíčů v Key Vaultu).