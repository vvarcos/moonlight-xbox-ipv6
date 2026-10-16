# Suporte a IPv6 (fork pessoal)

Este fork adiciona suporte a hosts IPv6 ao cliente Moonlight para Xbox.

## O que mudou

A maior parte da pilha já era capaz de IPv6: o `enet` (fork `cgutman/enet`) e o
`moonlight-common-c` (`resolveHostName` com `AF_UNSPEC`, `enet_host_create` usando
`ss_family`) já tratavam `AF_INET6`. O que impedia o funcionamento eram detalhes na
camada do app e no `libgamestream`:

1. **`State/MoonlightClient.cpp` (`Connect`)**
   O endereço era dividido no *primeiro* `:` para separar host e porta. Como um IPv6
   possui vários `:`, isso corrompia o endereço. Agora o parsing reconhece:
   - `[2001:db8::1]:47989` -> host `2001:db8::1`, porta `47989`
   - `[2001:db8::1]` -> host `2001:db8::1`
   - `2001:db8::1` -> host `2001:db8::1`
   - `192.168.1.10:47989` / `meu-pc:47989` / `192.168.1.10` (inalterado)

2. **`libgamestream/client.c` / `client.h`**
   As URLs HTTP/HTTPS eram montadas como `https://HOST:porta/...`. Um literal IPv6
   precisa de colchetes (RFC 3986). Foi adicionado o campo `urlHost` (preenchido em
   `gs_init`) que aplica os colchetes apenas quando o endereço é IPv6, mantendo
   `serverInfo.address` sem colchetes para a resolução de DNS do `moonlight-common-c`.

3. **`State/ApplicationState.cpp` (`Split_IP_Address`)**
   Passou a entender a forma `[addr]:porta` e literais IPv6 sem porta.

4. **`State/ApplicationState.cpp` (`Build_Unique_Addresses`)**
   O Wake-on-LAN usa broadcast UDP (só IPv4). Endereços IPv6 agora são ignorados nessa
   lista em vez de gerar um envio inválido.

## Como usar

Na tela inicial, toque em `+` (Add new Host) e informe o endereço do PC host:

- **IPv4:** `192.168.1.10` (porta padrão) ou `192.168.1.10:47989`
- **IPv6:** `2001:db8::1234` (recomendado) ou, se precisar indicar a porta,
  `[2001:db8::1234]:47989`

Detalhes do parsing:

- Sem porta, o endereço IPv6 pode ser escrito **com ou sem** colchetes.
- **Com** porta, os colchetes são **obrigatórios** (sem eles o app entende que tudo é
  o host). Nunca use `2001:db8::1234:47989`.
- A porta informada é a **HTTP** (padrão `47989`); a HTTPS é derivada dela
  (`porta − 5` → `47984`).
- Endereço **link-local** (`fe80::…%12`) não funciona (o `%` do escopo quebra na
  URL). Use um endereço global.

Ao parear/abrir a lista de apps, o cliente monta as URLs com colchetes
automaticamente.

## Como compilar

### Opção A — GitHub Actions (não precisa instalar nada)

1. Em `Actions`, rode o workflow `MSBuild` (ou dê push para `master` do fork).
2. Baixe o artefato `moonlight-uwp` (contém o `.msixbundle`), ou use a página de
   **Release** (download sem precisar de login).
3. No Xbox (modo dev), instale as dependências e depois o app — veja a seção
   **Instalação** do [README](README.md).

> O workflow gera um certificado de teste automaticamente quando roda fora do
> repositório original, o que permite assinar o pacote. Ao empurrar uma tag `v*` ele
> também publica um **Release** com o `.msixbundle` e as dependências (Microsoft.UI.Xaml
> e Microsoft.VCLibs). O **certificado não é publicado**: em modo desenvolvedor o app
> é registrado a partir dos arquivos soltos (*loose*), caminho que não verifica
> assinatura; se o pacote assinado for necessário, o certificado pode ser extraído da
> assinatura do próprio `.msixbundle`.

### Opção B — Build local

Requer Visual Studio 2022 com o workload **Desenvolvimento para Plataforma Universal
do Windows (UWP)** e o **Windows 10 SDK (10.0.19041 ou mais novo)**. Depois:

```powershell
git submodule update --init --recursive
./setup-dev.ps1
```

Abra `moonlight-xbox-dx.sln` no Visual Studio e compile a solução (o script já gera
os projetos de terceiros, baixa as dependências do vcpkg e cria o certificado).

## Configuração do host (PC)

Para o Xbox conectar via IPv6, o **host** também precisa aceitar conexões IPv6.

### Use o Sunshine (não o GeForce Experience)

O NVIDIA GeForce Experience/GameStream **não escuta em IPv6** (apenas IPv4) e está
descontinuado. Para IPv6 use o [Sunshine](https://github.com/LizardByte/Sunshine),
que suporta IPv6 desde a v0.21.0.

No arquivo `sunshine.conf`:

```ini
# O padrão é "ipv4"! Sem isto o Sunshine não abre nenhum socket IPv6.
address_family = both

# Opcional: fixa a interface/endereço IPv6 (requer address_family = both).
# bind_address = 2001:db8::1234
```

Confirme que existe um socket IPv6 em escuta (deve aparecer `[::]` ou o endereço
global, e não apenas `0.0.0.0`):

```powershell
Get-NetTCPConnection -State Listen |
  Where-Object { $_.LocalPort -in 47984, 47989, 48010 } |
  Select-Object LocalAddress, LocalPort
```

### Endereço IPv6 global (obrigatório para redes diferentes)

- Precisa ser **global/roteável** (dentro de `2000::/3`). **Não** serve `fe80::`
  (link-local) nem `fd00::/8` (ULA) — esses só funcionam no mesmo enlace.
- Veja o endereço com `ipconfig` (procure "Endereço IPv6", algo como `2804:...`).
- Teste a conectividade IPv6 a partir da rede do **Xbox** em
  <https://test-ipv6.com/> (idealmente 10/10).

### Firewall

O instalador do Sunshine normalmente já cria as regras no Windows Firewall. Caso
precisa criá-las manualmente:

| Porta | Protocolo | Uso |
| --- | --- | --- |
| 47984 | TCP | HTTPS (pareamento / API) |
| 47989 | TCP | HTTP (pareamento / API) |
| 48010 | TCP | RTSP (sessão) |
| 47998 | UDP | Vídeo |
| 47999 | UDP | Áudio |
| 48000 | UDP | Controle (input) |
| 47990 | TCP | Web UI (opcional, só para configurar) |

Como o PC e o Xbox estão em **redes diferentes**, o roteador/firewall **entre** as
redes também precisa permitir esses fluxos de entrada para o IPv6 do PC. Diferente do
IPv4, no IPv6 normalmente **não há NAT/port-forward**: o que se configura é uma
exceção (pinhole) no firewall.

### Teste rápido

De outra máquina na rede do Xbox:

```powershell
Test-NetConnection -ComputerName 2001:db8::1234 -Port 47989
Invoke-WebRequest "http://[2001:db8::1234]:47989/serverinfo"
```

## Limitações

- **Wake-on-LAN não funciona via IPv6** (o broadcast é IPv4). Se o host estiver
  desligado e só acessível por IPv6, ligue-o manualmente.
- **Descoberta automática (mDNS)** só procura hosts IPv4. Um host remoto em outra
  rede não seria descoberto de qualquer forma; adicione-o manualmente.
- O host (Sunshine) precisa estar **escutando em IPv6** (`address_family = both`) e
  ter um endereço IPv6 **global** (não apenas link-local `fe80::`).
