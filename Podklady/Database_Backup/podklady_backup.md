# Lokální zálohování Azure Database for PostgreSQL

## 1. Současný stav infrastruktury

- **Typ databáze:** Azure Database for PostgreSQL Flexible Server
- **Sítě:** Databáze je umístěna v privátní síti (VNet) a nemá povolen veřejný přístup (`public_network_access_enabled = false`).
- **Databáze k zálohování:** `data` a `credentials`.
- **Dostupnost:** Databáze je přístupná z AKS clusteru, který je ve stejném VNetu.

## 2. Navrhované strategie zálohování

### Příklad A: Kubernetes CronJob (Doporučeno)

Vytvoření pravidelné úlohy přímo v AKS, která provede dump databáze a odešle ho _někam_.

**Výhody:**

- Běží v rámci stávající infrastruktury.
- Má přímý síťový přístup k databázi.
- Snadná správa pomocí Kubernetes manifestů.

**Příklad implementace (zjednodušeně):**

1. Použít image s `postgresql-client`.
2. Spustit `pg_dump` s parametry z `common-env`.
3. Výsledek komprimovat a nahrát do cílového úložiště.

### Příklad B: Azure CLI / Azure Automation

Využití nativních nástrojů Azure pro export databáze.

**Výhody:**

- Bezúdržbové
- Možnost integrace s Azure Backup

### Příklad C: Lokální skript přes Jump Host (VPN)

Záloha přes příme připojení na VM

1. Připojení k Azure VNet pomocí VPN nebo SSH tunelu (ssh klíče pro cluster node, který má přístup do VNetu databáze jsou generovány v `/Terraform/main.tf` a lze je získat přes AzureCLI).
2. Spuštění `pg_dump` lokálně s nasměrováním na privátní FQDN databáze.

---

## 3. Technické detaily pro realizaci

### Potřebné údaje (z `common-env`)

- **Host:** `uois-db-...-.postgres.database.azure.com`
- **User:** `postgres`
- **Heslo:** `example`
- **SSL:** Vyžadováno (`PGSSLMODE=require`)

### Příklad příkazu pro zálohu

```bash
pg_dump "host=uois-db-...-.postgres.database.azure.com \
        port=5432 \
        dbname=data \
        user=postgres \
        password=VASE_HESLO \
        sslmode=require" > data_backup_$(date +%Y%m%d).sql
```

## 4. Doporučení pro tým

1.  **Automatizace:** Implementujte zálohování jako Kubernetes CronJob.
2.  **Bezpečnost:** Nikdy neukládejte hesla v prostém textu do skriptů. Použijte Kubernetes Secrets.
3.  **Monitoring:** Nastavte notifikace o (ne)úspěchu zálohy (např. pomocí liveness/readiness sond nebo externího monitoringu).
4.  **Retence:** Definujte politiku rotace záloh (např. uchovávat denní zálohy po dobu 7 dní).
5.  **Testování obnovy:** Záloha je užitečná pouze tehdy, pokud z ní lze data obnovit. Naplánujte pravidelné testy obnovy.
