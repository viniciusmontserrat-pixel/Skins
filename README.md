# Rainmeter Skins

Colecao de skins Rainmeter com configuracoes para desktop, incluindo os conjuntos
`Sonder` e `illustro`.

## Conteudo

- `Skins/Sonder/`: skins customizadas para calendario, relogio, reunioes,
  musica, configuracoes e previsao do tempo.
- `Skins/illustro/`: skins base do Rainmeter para relogio, disco, Google,
  rede, lixeira, sistema e tela de boas-vindas.
- `.gitignore`: regras para evitar versionar instaladores, backups, caches,
  pacotes, fontes, executaveis e credenciais locais.

## Instalacao

1. Instale o Rainmeter no Windows.
2. Copie a pasta `Skins` deste repositorio para a pasta local do Rainmeter,
   normalmente em `Documents/Rainmeter/Skins`.
3. Abra o Rainmeter.
4. Atualize a lista de skins.
5. Carregue os arquivos `.ini` desejados.

## Configuracao

As variaveis principais ficam em:

```text
Skins/Sonder/@Resources/Variables.inc
```

Pontos comuns de ajuste:

- `Language`: idioma usado pela skin.
- `Location`: codigo de localizacao usado pelas skins que dependem de clima.
- `Unit`: unidade de medida.
- `Player`: player usado pelas skins de musica.
- `Color1`, `Color2`, `Color3`: cores principais.

## Previsao do tempo

A skin de previsao usa a API publica Open-Meteo:

```text
Skins/Sonder/Weather Forecast/Weather Forecast.ini
```

Por padrao, latitude e longitude estao configuradas como `0`. Ajuste `Lat` e
`Lon` no arquivo da skin ou adapte a configuracao para sua localizacao.

## Reunioes

A skin de reunioes fica em:

```text
Skins/Sonder/Meetings/Meetings.ini
```

O endpoint padrao e apenas um exemplo:

```text
https://example.com/webhook/rainmeter-meetings-v1
```

Substitua por um endpoint proprio se for usar essa integracao. Nao versione
URLs privadas, tokens ou credenciais reais.

## Arquivos ignorados

Este repositorio evita versionar arquivos locais ou sensiveis, incluindo:

- instaladores e executaveis (`*.exe`, `*.msi`, `*.dll`);
- pacotes exportados (`*.rmskin`, `*.zip`, `*.rar`, `*.7z`);
- caches, logs e temporarios;
- arquivos `.env`;
- chaves, certificados e credenciais;
- fontes (`*.ttf`, `*.otf`, `*.woff`, `*.woff2`) sem validacao explicita de
  licenca;
- backups locais do Rainmeter.

## Observacoes

Antes de publicar novas alteracoes, revise o diff e confirme que nao ha
credenciais, dados pessoais, arquivos gerados ou binarios desnecessarios no
commit.
