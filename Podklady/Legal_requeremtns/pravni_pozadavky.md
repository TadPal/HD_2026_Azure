# Zadání

Zjisit zda a jak by mohl UNOB, jakožto státní vysoká škola přesunout svůj informační systém (uois) na cloud Azure a jaká by byla omezení.

Optionally: Co již teď aktuální IS UNOB - unob.sharepoint provádí (zpracování GDPR, digitální archivní služba, zákon o vysokých školách, podepisování smluv přes digitální podpis, atd.. )

# Doporučení z hlediska právních požadavků

Z pohledu státní vysoké školy existujě několik restirkcí vůči cloudu, vemte v potaz že systém se používá pro většinu dat a operací v rámci IS na Unobu a jsou zde různá data vztahující se na GDPR, jakžto zpracovatele.

Co je důležité zjistit:
- Co již UNOB používá za služby v rámci unob.sharepoint
- Zda je možné nasadit UOIS na Azure (zda je v katalogu pro požadované parametry UOIS, atd..)
- Podle jaké legistaltivy je nutné se držet

## 1. Cloud computing ve veřejné správě
Jelikož vysoké školy zřízené zákonem mohou pro vybrané agendy spadat do definice orgánů veřejné moci (OVM), doporučuje se řídit pravidly **Zákona č. 365/2000 Sb. (o informačních systémech veřejné správy)** a **Vyhlášky o cloud computingu (č. 316/2021 Sb.)**.

*   **Doporučení**: Vybírejte služby od cloudových poskytovatelů, kteří jsou zapsáni v **Katalogu cloud computingu** vedeném Digitální a informační agenturou (DIA) / NÚKIB. Globální platformy jako Microsoft Azure tyto certifikace standardně splňují.
*   **Doporučení**: Před nasazením proveďte kategorizaci (skórování rizikovosti) daného informačního systému, aby se potvrdilo, že odpovídá certifikované bezpečnostní hladině vybraného cloudu.

Katalog: https://app.powerbi.com/view?r=eyJrIjoiMTkwMTAyYzAtNWI5My00N2M1LWI0ZmItZjA5YTkwNTk5NmIxIiwidCI6IjViNmI4NWNkLTQ0ZWYtNGQ2Ni04NmQ0LTYwM2RkMjE2MDc4MCIsImMiOjl9

## 2. Zákon o kybernetické bezpečnosti (ZKB) a směrnice NIS2
Mnoho univerzit je nebo v nejbližší době bude v pozici povinné osoby.

*   **Doporučení k řízení rizik**: Zavedení systému musí předcházet formální **analýza kybernetických rizik**. Návrh architektury by měl minimalizovat hrozby z hlediska ztráty dostupnosti, integrity a důvěrnosti (např. odstíněním interních databází z veřejného internetu).
*   **Doporučení k dodavatelskému řetězci**: Vztahy s poskytovatelem cloudu i s případnými implementačními partnery musí být ošetřeny z hlediska bezpečnostních požadavků dle vyhlášky o kybernetické bezpečnosti.

## 3. Ochrana osobních údajů (GDPR)
Při provozování agendových, personálních nebo studijních systémů dochází ke zpracování rozsáhlého množství osobních údajů (studentů, zaměstnanců, uchazečů).

*   **Doporučení k lokalizaci dat**: Vždy explicitně volte regiony datacenter nacházející se **výhradně na území Evropské unie** (např. West Europe, North Europe, Sweden Central). Předejdete tím složitým legislativním překážkám souvisejícím s předáváním dat do třetích zemí.
*   **Doporučení ke zpracovatelským smlouvám (DPA)**: Zabezpečte, že k využívanému tenantu má škola uzavřenou standardní DPA (Data Processing Agreement) smlouvu definující odpovědnosti poskytovatele. U velkých cloudových providerů se realizuje v rámci akceptace všeobecných podmínek pro online služby (OST).

## 4. Zadávání veřejných zakázek (ZZVZ)
Cloudové kapacity a související licence nelze zpravidla nakupovat přímo bez soutěže (v závislosti na finančním objemu).
