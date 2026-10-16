# Moonlight para Xbox — fork com suporte a IPv6

Cliente [Moonlight](https://moonlight-stream.org/) para **Xbox One / Xbox Series X|S**,
para jogar em streaming a partir do PC (GeForce Experience ou
[Sunshine](https://github.com/LizardByte/sunshine) / Apollo).

Este repositório é um **fork** de
[TheElixZammuto/moonlight-xbox](https://github.com/TheElixZammuto/moonlight-xbox).

---

## Sobre este fork

> **O motivo deste fork é um só: permitir conectar a um host por IPv6.**

O app original só entende endereços **IPv4**. Isso é um problema quando o PC host
**não está na mesma rede** que o Xbox: fora da rede local, a única forma de alcançar
o PC costuma ser por um **endereço IPv6 global** (no IPv4 seria preciso NAT/port
forward no roteador, enquanto no IPv6 basta liberar o firewall).

Com este fork o campo de endereço do app aceita IPv6, então o Xbox consegue
**parear, listar os aplicativos e fazer streaming** de um host em outra rede.

Fora o IPv6, o app é o mesmo do projeto original — e o app publicado na
**Microsoft Store é do projeto original, sem suporte a IPv6**.

## Como conectar por IPv6

### 1) No PC (host)

1. Use **[Sunshine](https://github.com/LizardByte/sunshine)** (ou o fork Apollo).
   O GeForce Experience do NVIDIA **não escuta em IPv6** e está descontinuado.
2. Habilite IPv6 no Sunshine, em `sunshine.conf`:

   ```ini
   # O padrão é "ipv4": sem isto o Sunshine não abre nenhum socket IPv6.
   address_family = both
   ```

3. Confirme que o PC tem um **endereço IPv6 global** (rode `ipconfig` e procure algo
   como `2804:...`). Endereço **link-local** (`fe80::`) ou **ULA** (`fd00::`) **não
   serve** para redes diferentes.
4. Libere no firewall as portas necessárias (47984, 47989, 48010/TCP e
   47998, 47999, 48000/UDP) e, se as redes forem diferentes, libere também no
   roteador/firewall entre elas.

Detalhes completos de configuração do host: **[IPV6.md](IPV6.md)**.

### 2) No Xbox

1. Abra o Moonlight e toque em **`+`** (*Add new Host*). O diálogo tem **uma única
   caixa de texto** — não existe campo separado de porta.
2. Digite o endereço IPv6:

   | O que digitar | Resultado |
   | --- | --- |
   | `2001:db8:1234:5678::1` | host IPv6, porta padrão (47989) — **recomendado** |
   | `[2001:db8:1234:5678::1]` | igual (colchetes opcionais quando não há porta) |
   | `[2001:db8:1234:5678::1]:47989` | host + porta explícita — aqui os **colchetes são obrigatórios** |

   - **Não** digite `2001:db8::1:47989` sem colchetes: o app vê vários `:` e entende
     que tudo é o host.
   - A porta informada é a **HTTP** (padrão `47989`); a HTTPS é derivada dela
     (`porta − 5` → `47984`). Se o host está no padrão, **não coloque porta**.
   - Endereço **link-local** (`fe80::…%12`) não funciona: o `%` do escopo quebra na
     URL. Use o endereço global.
   - Dica: digitar IPv6 no teclado virtual do Xbox com o controle é bem ruim —
     vale plugar um **teclado USB**.

3. Toque em **Ok** e **pareie** quando solicitado (o PIN aparece no PC).
4. Escolha o aplicativo na lista e jogue.

Se o endereço não for alcançável, o próprio diálogo mostra
`Failed to Connect to <endereço>`.

## Instalação (modo desenvolvedor)

O app não é distribuído na Store com IPv6, então ele é instalado pelo **modo
desenvolvedor** do Xbox.

1. Ative o **Dev Mode** no console:
   <https://learn.microsoft.com/windows/uwp/xbox-apps/devkit-activation>
2. Baixe os arquivos na página de **[Releases](../../releases)**:

   | Arquivo | Para que serve |
   | --- | --- |
   | `moonlight-xbox-dx_1.18.3.0_x64.msixbundle` | o aplicativo |
   | `Microsoft.UI.Xaml.2.7.appx` | dependência (framework) |
   | `Microsoft.VCLibs.x64.14.00.appx` | dependência (framework) |

3. Abra o **Device Portal** (`https://<IP-do-Xbox>:11443`) e instale **primeiro as
   duas dependências**. Elas são assinadas pela Microsoft e instalam como pacote
   normal, sem precisar confiar em nenhum certificado extra.
4. Instale o aplicativo. Duas opções:
   - **Loose / register (modo dev):** extraia o
     `moonlight-xbox-dx_1.18.3.0_x64.msix` de dentro do `.msixbundle` (o bundle é um
     arquivo zip), copie a pasta para o console e registre o `AppxManifest.xml`.
     Nesse caminho **não há verificação de assinatura** — não precisa de certificado.
   - **Pacote assinado:** instale o `.msixbundle` diretamente, caso o certificado
     que assinou o pacote seja confiável no console.

   > O certificado **não** é publicado nas Releases. Se precisar dele, é possível
   > extraí-lo da assinatura do próprio pacote (no PC: botão direito no
   > `.msixbundle` → **Propriedades** → **Assinaturas Digitais** → selecionar a
   > assinatura → **Detalhes** → **Exibir Certificado** → **Detalhes** →
   > **Copiar para Arquivo…**).

## O que funciona

- Conexão e pareamento — **inclusive por IPv6**
- Lista de aplicativos do host
- Streaming de vídeo (resolução, bitrate e fps configuráveis por host)
- Áudio e **HDR**
- Controle (com rumble e modo mouse pelo gamepad)
- Teclado (virtual e USB)
- Desconexão limpa
- Histórico de hosts salvos

## O que não funciona

- **Wake-on-LAN por IPv6** — o pacote mágico usa broadcast, que é IPv4. Se o host só
  responde por IPv6, ligue-o manualmente.
- **Descoberta automática por IPv6** — o mDNS do app só procura hosts IPv4. Hosts em
  outra rede precisam ser adicionados **manualmente** (o que já seria o caso).
- **Mouse de hardware** (limitação do UWP)
- Qualquer outra coisa não listada acima

## Compilando

O build é feito pelo **GitHub Actions** (`.github/workflows/msbuild.yml`): qualquer
push gera um artifact `moonlight-uwp`, e uma tag `v*` publica um **Release**.

Para compilar localmente são necessários Windows 10/11, **Visual Studio 2022** com o
workload **Desenvolvimento para Plataforma Universal do Windows (UWP)** e o
**Windows 10 SDK (10.0.19041.0)**, além do vcpkg. Depois:

```powershell
git submodule update --init --recursive
./setup-dev.ps1
```

Abra `moonlight-xbox-dx.sln` no Visual Studio e compile a solução (o script já gera
os projetos de terceiros, baixa as dependências do vcpkg e cria o certificado).

## Documentação técnica

- **[IPV6.md](IPV6.md)** — o que mudou no código para suportar IPv6, como configurar o
  host (Sunshine/Apollo), firewall, testes e limitações.

## Créditos e licença

- Projeto original: [TheElixZammuto/moonlight-xbox](https://github.com/TheElixZammuto/moonlight-xbox)
- [Moonlight](https://moonlight-stream.org/) e [moonlight-common-c](https://github.com/moonlight-stream/moonlight-common-c)
- Distribuído sob a **GPLv3** ([LICENSE](LICENSE)), a mesma licença do projeto original.
