# Zadání

Určit cenu běhu informačního systému nasazeného v Azure, podle vlastních definovaných parametrů. (Parametry jako běh 24/7, velikost uložených dat pro univerzitu, podpora atd.) 

Optionally: Navrhněte opatření pro snížení cenové náročnosti nasazené infrastruktury.

# Doporučení pro Cost Management v Azure

Tento dokument obsahuje obecná doporučení a postup, jak přistupovat k řízení nákladů při nasazování cloudové infrastruktury (typicky Kubernetes clusterů a spravovaných databází) v prostředí Microsoft Azure, s důrazem na specifika státních vysokých škol v ČR.

Co je důležité zjistit:
- Jaké resources náš nasazený UOIS spotřebovává (analýza terraform)
- Jak často a kolik služeb může běžet (při nizkém / vysokém zatížení, vytvořte vlastní scénář)

## 1. Postup nacenění (Jak zjistit odhadovanou cenu)

Cena za cloudové služby je variabilní a odvíjí se od skutečné spotřeby a zvoleného výkonu. Pro spolehlivý odhad vždy využívejte oficiální nástroj:

*   **[Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)**: 
    1.  Vyberte a přidejte požadované komponenty (např. *Azure Kubernetes Service (AKS)*, *Azure Database for PostgreSQL*).
    2.  Nezapomeňte zahrnout doprovodné služby: *Virtual Network* (případný Egress), *Public IP Addresses* (pro Ingress/Load Balancer), případně *Log Analytics Workspace* pro ukládání logů.(Důležité mít přehled o práci ostatních a jejich požadavcích na resourcess)
    3.  U služeb jako AKS se neplatí za samotnou řídící vrstvu (Control Plane ve Free tieru), ale účtují se spotřebované výpočetní uzly (VMs) a jejich připojené disky.

## 2. Doporučení v rámci univerzitního prostředí 

*   **Rámcové smlouvy a slevy (např. OCRE/CESNET)**: Zapojení do akademických rámcových dohod přináší výrazné slevy z ceníkových cen. Vždy se informujte u vašeho IT/nákupního oddělení o aktuálních podmínkách.
*   **Data Egress Waiver**: Standardní akademické smlouvy s poskytovateli často obsahují odpuštění poplatků za odchozí data směrem ven do internetu, což je jinak v cloudu nezanedbatelná položka.
*   **Akademické licence**: Využijte existující tenanty pro vzdělávání nebo výzkumné kredity, pokud je daný projekt kvalifikován jako akademický či výzkumný.

## 3. Strategie pro optimalizaci nákladů

Pro zajištění hospodárného provozu produkčních i testovacích prostředí zkuste navrhnout opatření 

*   **Rezervace kapacity (Reserved Instances)**: U infrastrukturních prvků běžících 24/7 (hlavní nodepooly AKS, databáze) lze zakoupením rezervace na 1 nebo 3 roky dosáhnout úspory v řádu desítek procent.
*   **Automatické škálování (Auto-scaling)**: 
    *   Na úrovni aplikací zapínejte HPA (Horizontal Pod Autoscaler).
    *   Na úrovni infrastruktury využívejte Cluster Autoscaler, aby se výpočetní uzly přidávaly jen při zátěži a odstraňovaly mimo špičku (např. v noci).
*   **Spot Instances pro neprodukční zátěž**: Uvažujte o využití tzv. Spot virtuálních strojů s masivní slevou pro dočasné nebo dávkové (batch) úlohy u kterých nevadí případné náhlé ukončení stroje.
*   **Budgets & Alerts (Rozpočty a upozornění)**: V nástroji *Azure Cost Management + Billing* na úrovni resource groupy či celé subskripce lze proaktivně natavit finanční rozpočty a e-mailová upozornění (např. při dosažení 80 % plánovaných nákladů). Zkuste navrhnout upozornění pro zabránění vyčerpání zdrojů.