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
- **IPv6:** `2001:db8::1234` ou, se precisar indicar a porta, `[2001:db8::1234]:47989`

Ao parear/abrir a lista de apps, o cliente monta as URLs com colchetes
automaticamente.

## Limitações

- **Wake-on-LAN não funciona via IPv6** (broadcast é IPv4). Se o host estiver
  desligado e só acessível por IPv6, ligue-o manualmente.
- **Descoberta automática (mDNS)** só procura hosts IPv4. Um host remoto em outra
  rede não seria descoberto de qualquer forma; adicione-o manualmente.
- O host (Sunshine/GeForce Experience) também precisa estar **escutando em IPv6**.
  No Sunshine, verifique `origin_web_ui_allowed`/binds e que a máquina tem um
  endereço IPv6 global (não apenas link-local `fe80::`).

## Aviso sobre "duas redes"

Para o PC e o Xbox em redes diferentes, o endereço IPv6 precisa ser **global/roteável**
entre eles. Endereços `fe80::` (link-local) ou ULA (`fd00::/8`) só funcionam dentro do
mesmo enlace. Além disso as portas do host (47984, 47989, 48010, 47998-48010, etc.)
precisam estar liberadas no firewall.
