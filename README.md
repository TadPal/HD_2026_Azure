# Návod na nasazení architektury UOIS v prostředí Azure (AKS)

Tento návod je určen pro seznámení s technologiemi **Kubernetes** a **Azure**. Cílem je nasadit komplexní mikroslužbovou architekturu projektu UOIS pomocí nástroje **Terraform** pro infrastrukturu a **kubectl** pro správu clusteru.

---

## 1. Co budeme nasazovat?

Architektura se skládá z několika částí:

- **Frontend**: Uživatelské rozhraní.
- **Apollo Federation**: Brána (Gateway), která sjednocuje přístup k jednotlivým mikroslužbám.
- **GQL Mikroslužby**: Jednotlivé služby (UG, Office, Granting, Projects) komunikující přes GraphQL.
- **pgAdmin**: Nástroj pro správu databáze.
- **Ingress Controller**: Zajišťuje přístup k aplikaci z internetu přes doménová jména.
- **HPA (Horizontal Pod Autoscaler)**: Automaticky škáluje počet instancí služeb podle zátěže CPU.

---

## 2. Prerekvizity a Instalace nástrojů

Před začátkem musíte mít nainstalované základní nástroje. Postupujte podle svého operačního systému.

### Windows

Otevřete PowerShell jako administrátor a spusťte:

```powershell
# Instalace AzureCLI (nástroj pro ovládání Azure z příkazové řádky)
winget install --exact --id Microsoft.AzureCLI

# Instalace Terraform (nástroj pro definici infrastruktury kódem)
winget install HashiCorp.Terraform

# Instalace kubectl (nástroj pro ovládání Kubernetes clusteru)
winget install -e --id Kubernetes.kubectl
```

### Ubuntu/Debian

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).+' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubectl
```

---

## 3. Příprava Azure a Terraformu

Než začnete, musíte se přihlásit ke svému Azure účtu (je potřeba aktivovat předplatné pro studenty):

```bash
az login
```

Prohlížeč vás vyzve k přihlášení. Poté přejděte do složky s Terraform konfigurací:

```bash
cd /Terraform  # Cesta k vašim .tf souborům
terraform init    # Inicializace (stáhne potřebné pluginy)
terraform plan    # Kontrola toho, co se v Azure vytvoří
terraform apply   # Samotné vytvoření infrastruktury (vyžaduje potvrzení 'yes')
```

_Poznámka: Jako db_password zadejte při dotazu `example`. Terraform vytvoří v Azure službu AKS (Azure Kubernetes Service) / Azure Managed Cluster_

---

## 4. Připojení k Kubernetes clusteru

Po dokončení `terraform apply` získáte přístupové údaje ke clusteru. Ty je potřeba nastavit pro nástroj `kubectl`:

_Poznámka: Názvy proměnných jsou v souboru /Terraform/variables.tf -> jméno skupiny (resource group): aks-resource-group, jméno clusteru: uois-cluster_

```powershell
# Propojení kubectl s vaším novým clusterem v Azure
az aks get-credentials --resource-group <jmeno-vasi-skupiny> --name <jmeno-clusteru>

# Ověření funkčnosti (měli byste vidět běžící uzly)
kubectl get nodes
```

---

## 5. Úprava clusteru

Cluster si udržuje paměť objektů, při úpravě části provede změny pouze tam kde je potřeba tomu se říká **idempotence**.

### Konfigurace (ConfigMap) environment variables

Aplikace potřebuje proměnné prostředí (např. připojení k databázi). Úpravu provádíme v souboru `/UOIS/Kubernetes/common.env` a pak aplikujeme na cluster:

```bash
cd UOIS/kubernetes
kubectl create configmap common-env --from-env-file=common.env
```

### Úprava služeb

Služby upravujeme v souborech (manifestech) ve složce `/UOIS/kubernetes/manifests` a poté opět aplikujeme na cluster:

```bash
kubectl apply -f manifests/
```

### Síťové nastavení (Ingress)

Aby byla aplikace dostupná zvenku, je nasatvený vstupní Ingress node v souboru `/UOIS/kubernetes/k8s_extras/ingress-controller.yaml`:

```bash
kubectl apply -f k8s_extras/ingress-controller.yaml
```

---

## 6. Práce s clusterem a monitoring

Zde jsou užitečné příkazy pro kontrolu stavu:

```bash
# Zkontroluje stav všech podů (instancí aplikací)
kubectl get pods

# Detailní výpis, pokud pod neběží (např. CrashLoopBackOff)
kubectl describe pod <jmeno-podu>

# Sledování logů aplikace
kubectl logs -f <jmeno-podu>

# Zjištění veřejné IP adresy aplikace (hledejte EXTERNAL-IP)
kubectl get service ingress-nginx-controller -n ingress-nginx
```

---

## 7. Škálování a odolnost

V souborech `*-hpa.yaml` je definováno automatické škálování. Pokud procesor (CPU) některé služby přesáhne např. 70 % zátěže, Kubernetes automaticky spustí další instance.

Můžete také škálovat ručně:

```bash
kubectl scale --replicas=3 deployment/<název-služby>
```

---

## 8. Smazání prostředků

Až přestanete s aplikací pracovat, je **důležité** prostředky v Azure smazat, aby vám nebyly účtovány poplatky:

```bash
cd /Terraform
terraform apply -destroy
```

---

## 9. Přítup ke službám

Abychom mohli přistoupit ke službám UOIS je potřeba získat IP adresu, kterou nám přidelil Azure.

```bash
# Zjištění veřejné IP adresy aplikace (hledejte EXTERNAL-IP)
kubectl get service ingress-nginx-controller -n ingress-nginx
```

Zjištěnou IP adresu je potřeba přidat do jako lokální záznam pro doménu _uois_ jak je definováno v Ingress controlleru.

Záznam přidat do hosts (Windows: `"C:\Windows\System32\drivers\etc\hosts"`, Linux: `/etc/hosts`):

```bash
# Příklad záznamu
51.12.144.212 uois
51.12.144.212 pgadmin.uois
```
