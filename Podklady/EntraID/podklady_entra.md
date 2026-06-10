# Integrace EntraID do UOIS

Prozatím je autentizace řešena na úrovni frontendu jako tomu bylo vždycky...

Každá instance frontendu si vytvoří vlastní klíče a drží vlastní sessions. To není úplně žádoucí pro kubernetes cluster, kde těch frontendů je několik a je potřeba být schopný se autentizovat ke všem, aby se netrhali relace.

Kvůli nasazení v Azure jsme zvolili EntraID, která by měla nahradit současný middleware frontendu.

## 1. Příprava v Azure Portálu

V rámci studentského předplatného je potřeba:

### Vytvoření tenanta

Pokud nemáš vlastní tenant, vytvoř si nový v Azure Portálu (Microsoft Entra ID -> Manage tenants -> Create).

### Registrace aplikace (App Registration)

1. Přejdi do **Microsoft Entra ID** -> **App registrations** -> **New registration**.
2. **Název:** Např. `UOIS-Frontend`.
3. **Supported account types:** "Accounts in this organizational directory only" (Single tenant).
4. **Redirect URI:** Vyber "Web" a zadej URL, který je definovaný v Ingressu v Kubernetes.
5. Ulož si **Application (client) ID** a **Directory (tenant) ID**.

### Konfigurace Authentication

V sekci **Authentication** u tvé registrace:

- Ujisti se, že je povolen **Implicit grant and hybrid flows** (pokud to vyžaduje tvá implementace, ale náš router používá Authorization Code Flow, takže stačí mít správně Redirect URI).
- V sekci **Implicit grant and hybrid flows** zaškrtni "ID tokens" (pro OpenID Connect).

### Certificates & Secrets

1. Přejdi do **Certificates & secrets** -> **Client secrets** -> **New client secret**.
2. Poznamenej si **Value** (tajný klíč), uvidíš ho jen jednou!

### API Permissions

Ujisti se, že máš přiděleny delegované oprávnění pro Microsoft Graph: `User.Read`, `email`, `openid`, `profile`.

---

## 2. Úprava Frontend aplikace (FastAPI)

Podklady pro implementaci se nacházejí ve složce `Podklady/EntraID/Auth/easyauth`.

Příklad použití:

```python
from fastapi import FastAPI
from easyauth import create_entra_router, EntraEasyAuthMiddleware, EntraIDClient

app = FastAPI()

entra_client = EntraIDClient(tenant_id=AZURE_TENANT_ID, audience=None)

app.add_middleware(
    EntraEasyAuthMiddleware,
    entra_client=entra_client,
    pass_through=("/public", "/health", "/login", "/auth", "/login/", "/auth/"),
    login_path="/login",  # nebo jméno route, pokud používáš url_for("entra_login")
    # external_base_url="https://app.example.com",  # za reverse proxy
    redirect_on_unauth=True,
)

app.include_router(entra_router)
```

---

## 3. Nasazení v Kubernetes

Je potřeba aktualizovat environmentální proměnné pro frontend.

1. Uprav `UOIS/kubernetes/common.env` nebo vytvoř Secret pro citlivé údaje:

```env
AZURE_TENANT_ID=
...
```

2. Aktualizuj `frontend-deployment.yaml`, aby tyto proměnné načítal:

```yaml
- name: AZURE_TENANT_ID
  valueFrom:
    configMapKeyRef:
      key: AZURE_TENANT_ID
      name: common-env
# ... a další
```

---
