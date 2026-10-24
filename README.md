<div align="center">

# 🎮 Moonlight para Xbox · IPv6

**Jogue no seu Xbox a partir de um PC que está em outra rede. Sem port forwarding.**

[![Plataforma](https://img.shields.io/badge/plataforma-Xbox%20One%20%7C%20Series%20X%7CS-107C10?style=flat-square&logo=xbox&logoColor=white)](#-instala%C3%A7%C3%A3o)
[![IPv6](https://img.shields.io/badge/IPv6-suportado-0969da?style=flat-square)](#-como-conectar-por-ipv6)
[![Licença](https://img.shields.io/badge/licen%C3%A7a-GPL--3.0-blue?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/vvarcos/moonlight-xbox-ipv6?style=flat-square&label=release&color=2ea043)](../../releases)
[![Build](https://github.com/vvarcos/moonlight-xbox-ipv6/actions/workflows/msbuild.yml/badge.svg)](https://github.com/vvarcos/moonlight-xbox-ipv6/actions/workflows/msbuild.yml)

<sub>Fork de <a href="https://github.com/TheElixZammuto/moonlight-xbox">TheElixZammuto/moonlight-xbox</a></sub>

</div>

---

## 💡 Por que este fork existe

> O app original só entende **IPv4**. Quando o PC host **não está na mesma rede** que
> o Xbox, não existe endereço IPv4 alcançável — seria preciso mexer no roteador
> (NAT / port forwarding). Por **IPv6** (endereço global) isso simplesmente funciona.

Este fork adiciona **IPv6** ao campo de endereço do app, então o Xbox consegue
**parear, listar os aplicativos e fazer streaming** de um host em outra rede.

Fora o IPv6, o app é o mesmo do projeto original. O app publicado na Microsoft Store
é do projeto original e **não** tem esse suporte.

## 🚀 Início rápido

**No PC (host)**

1. Rode o **[Sunshine](https://github.com/LizardByte/sunshine)** (ou o fork Apollo).
   O GeForce Experience da NVIDIA **não** escuta em IPv6.
2. Em `sunshine.conf`, habilite IPv6:

   ```ini
   address_family = both    # o padrão é "ipv4"!
   ```

3. Anote o **endereço IPv6 global** do PC — rode `ipconfig` e procure algo como
   `2804:...`.

**No Xbox**

4. Instale o app em [modo desenvolvedor](#-instalação).
5. Toque em **`+`** (*Add new Host*), digite o endereço IPv6 e pareie.

## 🔌 Como conectar por IPv6

### No Xbox

Toque em **`+`** na tela inicial. O diálogo tem **uma única caixa de texto** — não
existe campo separado de porta. Escreva o endereço assim:

```text
2001:db8:1234:5678::1             ✅  host IPv6, porta padrão (47989) ← recomendado
[2001:db8:1234:5678::1]           ✅  igual (colchetes opcionais sem porta)
[2001:db8:1234:5678::1]:47989     ✅  IPv6 + porta (colchetes obrigatórios)
2001:db8:1234:5678::1:47989       ❌  sem colchetes o app acha que tudo é o host
```

| Regra | Detalhe |
| --- | --- |
| **Porta** | O número informado é a porta **HTTP** (padrão `47989`); a HTTPS é derivada dela (`porta − 5` → `47984`). Se o host está no padrão, **não coloque porta**. |
| **Link-local** | `fe80::…%12` **não funciona** (o `%` do escopo quebra na URL). Use o endereço **global**. |
| **Teclado** | Digitar IPv6 no teclado virtual do Xbox é bem ruim — vale plugar um **teclado USB**. |

Se o endereço não for alcançável, o próprio diálogo mostra
`Failed to Connect to <endereço>`.

### No PC (host)

1. **Use um host que escute em IPv6.** O [Sunshine](https://github.com/LizardByte/sunshine)
   suporta IPv6 desde a v0.21.0. Confira que existe um socket `[::]` em escuta:

   ```powershell
   Get-NetTCPConnection -State Listen |
     Where-Object { $_.LocalPort -in 47984, 47989, 48010 } |
     Select-Object LocalAddress, LocalPort
   ```

2. **Endereço global** (dentro de `2000::/3`). **Não** serve `fe80::` (link-local)
   nem `fd00::/8` (ULA) — esses só funcionam no mesmo enlace. Teste a conectividade
   IPv6 a partir da rede do Xbox em <https://test-ipv6.com/>.
3. **Firewall** — portas no PC e, se as redes forem diferentes, também no roteador
   entre elas:

   | Porta | Protocolo | Uso |
   | --- | --- | --- |
   | 47984 | TCP | HTTPS (pareamento / API) |
   | 47989 | TCP | HTTP (pareamento / API) |
   | 48010 | TCP | RTSP (sessão) |
   | 47998 | UDP | Vídeo |
   | 47999 | UDP | Áudio |
   | 48000 | UDP | Controle (input) |
   | 47990 | TCP | Web UI (opcional) |

   No IPv6 normalmente **não há NAT/port forwarding**: o que se configura é uma
   exceção (*pinhole*) no firewall.

> 📄 Passo a passo completo de host, testes e limitações técnicas: **[IPV6.md](IPV6.md)**

## 📦 Instalação

O app não é distribuído na Store com IPv6, então ele é instalado pelo **modo
desenvolvedor** do Xbox.

1. Ative o **Dev Mode** no console:
   <https://learn.microsoft.com/windows/uwp/xbox-apps/devkit-activation>
2. Baixe os arquivos na página de **[Releases](../../releases)**:

   | Arquivo | Para que serve |
   | --- | --- |
   | `moonlight-xbox-..._x64.msixbundle` | o aplicativo |
   | `Microsoft.UI.Xaml.2.7.appx` | dependência (framework) |
   | `Microsoft.VCLibs.x64.14.00.appx` | dependência (framework) |

3. Abra o **Device Portal** (`https://<IP-do-Xbox>:11443`) e instale **primeiro as
   duas dependências**. Elas são assinadas pela Microsoft e instalam como pacote
   normal, sem precisar confiar em nenhum certificado extra.
4. Instale o aplicativo. Duas opções:
   - **Loose / register (modo dev)** — extraia o
     `moonlight-xbox-dx_1.18.3.0_x64.msix` de dentro do `.msixbundle` (o bundle é um
     arquivo zip), copie a pasta para o console e registre o `AppxManifest.xml`.
     Neste caminho **não há verificação de assinatura** — não precisa de certificado.
   - **Pacote assinado** — instale o `.msixbundle` direto, caso o certificado que
     assinou o pacote seja confiável no console.

   > O certificado **não** é publicado nas Releases. Se precisar dele, dá para
   > extrair da assinatura do próprio pacote: botão direito no `.msixbundle` →
   > **Propriedades** → **Assinaturas Digitais** → selecionar a assinatura →
   > **Detalhes** → **Exibir Certificado** → **Detalhes** → **Copiar para Arquivo…**

## ✅ O que funciona

- Conexão e pareamento — **inclusive por IPv6**
- Lista de aplicativos do host
- Streaming de vídeo (resolução, bitrate e fps por host)
- Áudio e **HDR**
- Controle (com rumble e modo mouse pelo gamepad)
- Teclado (virtual e USB)
- Desconexão limpa
- Histórico de hosts salvos

## ❌ O que não funciona

- **Descoberta automática por IPv6** — o mDNS do app só procura hosts IPv4. Hosts em
  outra rede precisam ser adicionados **manualmente** (o que já seria o caso).
- **Mouse de hardware** (limitação do UWP).
- Qualquer outra coisa não listada acima.

## 🔧 Compilando

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

## 🙏 Créditos e licença

- Projeto original: [TheElixZammuto/moonlight-xbox](https://github.com/TheElixZammuto/moonlight-xbox)
- [Moonlight](https://moonlight-stream.org/) e [moonlight-common-c](https://github.com/moonlight-stream/moonlight-common-c)
- Distribuído sob a **GPLv3** ([LICENSE](LICENSE)), a mesma licença do projeto original.
