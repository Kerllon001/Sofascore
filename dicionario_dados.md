# Dicionário de dados

As nove tabelas usam `InnoDB` e `utf8mb4` com collation `utf8mb4_unicode_ci`. PK identifica a chave primária; FK identifica chave estrangeira. Nas PKs, `NOT NULL` é implícito. Todas as FKs declaram `ON UPDATE RESTRICT ON DELETE RESTRICT` para preservar o histórico. Datas finais de vínculo são inclusivas.

## liga

Competição de futebol e seu país ou região de organização.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_liga` | `INT` | PK AUTO_INCREMENT | Identificador da liga. |
| `nome` | `VARCHAR(100)` | NOT NULL UNIQUE | Nome da competição. |
| `pais` | `VARCHAR(60)` | NOT NULL | País ou região de organização, como Brasil ou América do Sul. |

Restrições de tabela

```sql
-- Sem restrições adicionais às colunas.
```

## edicao

Edição anual de uma liga.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_edicao` | `INT` | PK AUTO_INCREMENT | Identificador da edição. |
| `id_liga` | `INT` | NOT NULL FK | Liga organizadora. |
| `ano` | `SMALLINT` | NOT NULL | Ano da edição. |
| `data_inicio` | `DATE` | NOT NULL | Primeiro dia da edição. |
| `data_fim` | `DATE` | NOT NULL | Último dia da edição. |

Restrições de tabela

```sql
CONSTRAINT uq_edicao UNIQUE (id_liga, ano);
CONSTRAINT ck_edicao_ano CHECK (ano BETWEEN 1900 AND 2100);
CONSTRAINT ck_edicao_datas CHECK (data_fim >= data_inicio);
CONSTRAINT fk_edicao_liga FOREIGN KEY (id_liga) REFERENCES liga(id_liga) ON UPDATE RESTRICT ON DELETE RESTRICT;
```

## clube

Cadastro de clubes, independente da liga disputada.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_clube` | `INT` | PK AUTO_INCREMENT | Identificador do clube. |
| `nome` | `VARCHAR(100)` | NOT NULL UNIQUE | Nome completo do clube. |
| `sigla` | `CHAR(3)` | NOT NULL UNIQUE | Abreviação de três caracteres. |
| `cidade` | `VARCHAR(80)` | NOT NULL | Cidade de origem. |
| `fundacao` | `DATE` | NOT NULL | Data de fundação. |

Restrições de tabela

```sql
-- Sem restrições adicionais às colunas.
```

## atleta

Cadastro individual sem atribuir um clube atual ao atleta.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_atleta` | `INT` | PK AUTO_INCREMENT | Identificador do atleta. |
| `nome` | `VARCHAR(120)` | NOT NULL | Nome; homônimos são permitidos. |
| `data_nascimento` | `DATE` | NOT NULL | Data de nascimento. |
| `nacionalidade` | `VARCHAR(60)` | NOT NULL | Nacionalidade declarada. |
| `posicao` | `VARCHAR(3)` | NOT NULL | GOL, DEF, MEI ou ATA. |
| `pe_dominante` | `CHAR(1)` | NOT NULL DEFAULT 'D' | D direito, E esquerdo ou A ambidestro. |

Restrições de tabela

```sql
CONSTRAINT ck_atleta_posicao CHECK (posicao IN ('GOL','DEF','MEI','ATA'));
CONSTRAINT ck_atleta_pe CHECK (pe_dominante IN ('D','E','A'));
```

## inscricao

Associação N para N entre clubes e edições.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_edicao` | `INT` | PK FK NOT NULL | Edição disputada. |
| `id_clube` | `INT` | PK FK NOT NULL | Clube inscrito. |

Restrições de tabela

```sql
PRIMARY KEY (id_edicao, id_clube);
CONSTRAINT fk_inscricao_edicao FOREIGN KEY (id_edicao) REFERENCES edicao(id_edicao) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT fk_inscricao_clube FOREIGN KEY (id_clube) REFERENCES clube(id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT;
```

## vinculo

Associação N para N temporal entre atletas e clubes.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_vinculo` | `INT` | PK AUTO_INCREMENT | Identificador do período contratual. |
| `id_atleta` | `INT` | NOT NULL FK | Atleta contratado. |
| `id_clube` | `INT` | NOT NULL FK | Clube do período. |
| `data_inicio` | `DATE` | NOT NULL | Primeiro dia do vínculo, inclusive. |
| `data_fim` | `DATE` | NULL | Último dia inclusive; NULL significa vínculo aberto. |

Restrições de tabela

```sql
CONSTRAINT uq_vinculo_inicio UNIQUE (id_atleta, data_inicio);
CONSTRAINT ck_vinculo_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio);
CONSTRAINT fk_vinculo_atleta FOREIGN KEY (id_atleta) REFERENCES atleta(id_atleta) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT fk_vinculo_clube FOREIGN KEY (id_clube) REFERENCES clube(id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT;
```

## partida

Jogo de uma edição, com mandante e visitante inscritos.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_partida` | `INT` | PK AUTO_INCREMENT | Identificador do jogo. |
| `id_edicao` | `INT` | NOT NULL FK | Edição do jogo. |
| `id_mandante` | `INT` | NOT NULL FK composta | Clube mandante, validado pela inscrição. |
| `id_visitante` | `INT` | NOT NULL FK composta | Clube visitante, validado pela inscrição. |
| `data_hora` | `DATETIME` | NOT NULL | Data e hora de referência da partida. O tipo DATETIME armazena o valor sem fuso horário. |
| `rodada` | `SMALLINT` | NOT NULL | Número da rodada. |
| `status` | `VARCHAR(10)` | NOT NULL DEFAULT 'AGENDADA' | AGENDADA ou ENCERRADA. |

Restrições de tabela

```sql
CONSTRAINT uq_partida UNIQUE (id_edicao, id_mandante, id_visitante, rodada);
CONSTRAINT ck_partida_clubes CHECK (id_mandante <> id_visitante);
CONSTRAINT ck_partida_rodada CHECK (rodada > 0);
CONSTRAINT ck_partida_status CHECK (status IN ('AGENDADA','ENCERRADA'));
CONSTRAINT fk_partida_edicao FOREIGN KEY (id_edicao) REFERENCES edicao(id_edicao) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT fk_partida_mandante FOREIGN KEY (id_edicao, id_mandante) REFERENCES inscricao(id_edicao, id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT fk_partida_visitante FOREIGN KEY (id_edicao, id_visitante) REFERENCES inscricao(id_edicao, id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT;
```

## resumo_partida

Extensão 1 para 1 opcional da partida com métricas coletivas.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_partida` | `INT` | PK FK | Mesma chave da partida. |
| `gols_mandante` | `SMALLINT` | NOT NULL DEFAULT 0 | Gols do mandante. |
| `gols_visitante` | `SMALLINT` | NOT NULL DEFAULT 0 | Gols do visitante. |
| `chutes_mandante` | `SMALLINT` | NOT NULL | Finalizações do mandante. |
| `chutes_visitante` | `SMALLINT` | NOT NULL | Finalizações do visitante. |
| `no_alvo_mandante` | `SMALLINT` | NOT NULL | Finalizações no alvo do mandante. |
| `no_alvo_visitante` | `SMALLINT` | NOT NULL | Finalizações no alvo do visitante. |
| `posse_mandante` | `DECIMAL(5,2)` | NOT NULL | Percentual do mandante; visitante = 100 menos este valor. |

Restrições de tabela

```sql
CONSTRAINT fk_resumo_partida FOREIGN KEY (id_partida) REFERENCES partida(id_partida) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT ck_resumo_gols CHECK (gols_mandante >= 0 AND gols_visitante >= 0);
CONSTRAINT ck_resumo_chutes CHECK (chutes_mandante >= no_alvo_mandante AND no_alvo_mandante >= gols_mandante AND chutes_visitante >= no_alvo_visitante AND no_alvo_visitante >= gols_visitante);
CONSTRAINT ck_resumo_posse CHECK (posse_mandante BETWEEN 0 AND 100);
```

## estatistica_atleta

Desempenho de um atleta vinculado em uma partida com resumo.

| Atributo | Tipo MySQL | Restrições | Descrição |
|---|---|---|---|
| `id_partida` | `INT` | PK FK NOT NULL | Partida encerrada com resumo coletivo. |
| `id_vinculo` | `INT` | PK FK NOT NULL | Vínculo válido no dia da partida. |
| `minutos` | `SMALLINT` | NOT NULL | Minutos jogados, entre 1 e 90. |
| `gols` | `SMALLINT` | NOT NULL DEFAULT 0 | Gols individuais, excluindo gols contra. |
| `assistencias` | `SMALLINT` | NOT NULL DEFAULT 0 | Passes para gol. |
| `passes_tentados` | `SMALLINT` | NOT NULL | Tentativas de passe. |
| `passes_certos` | `SMALLINT` | NOT NULL | Passes completados. |
| `nota` | `DECIMAL(3,1)` | NOT NULL | Nota didática de desempenho de 0 a 10. |

Restrições de tabela

```sql
PRIMARY KEY (id_partida, id_vinculo);
CONSTRAINT fk_estatistica_resumo FOREIGN KEY (id_partida) REFERENCES resumo_partida(id_partida) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT fk_estatistica_vinculo FOREIGN KEY (id_vinculo) REFERENCES vinculo(id_vinculo) ON UPDATE RESTRICT ON DELETE RESTRICT;
CONSTRAINT ck_estatistica_minutos CHECK (minutos BETWEEN 1 AND 90);
CONSTRAINT ck_estatistica_gols CHECK (gols >= 0 AND assistencias >= 0);
CONSTRAINT ck_estatistica_passes CHECK (passes_tentados >= passes_certos AND passes_certos >= 0);
CONSTRAINT ck_estatistica_nota CHECK (nota BETWEEN 0 AND 10);
```

## Regras entre registros

| Gatilho | Operação | Regra |
|---|---|---|
| `trg_vinculo_insert` | INSERT em vínculo | Impede sobreposição de períodos inclusivos por atleta. |
| `trg_vinculo_update` | UPDATE em vínculo | Impede sobreposição e protege atleta, clube e datas de estatísticas históricas. |
| `trg_partida_insert` | INSERT em partida | Exige data dentro do período da edição. |
| `trg_partida_update` | UPDATE em partida | Valida calendário e protege os dados históricos quando já existe resumo. |
| `trg_edicao_update` | UPDATE em edição | Impede excluir partidas existentes do novo período. |
| `trg_resumo_insert` | INSERT em resumo | Exige partida encerrada. |
| `trg_resumo_update` | UPDATE em resumo | Exige partida encerrada e placar compatível com gols e assistências existentes. |
| `trg_estatistica_insert` | INSERT em estatística | Exige resumo e valida clube, período, unicidade do atleta no jogo e totais de gols e assistências. |
| `trg_estatistica_update` | UPDATE em estatística | Exige resumo e reaplica as validações, excluindo a linha antiga dos totais. |

Somente `vinculo.data_fim` aceita NULL. A assistência representa o último passe para um gol e cada gol admite no máximo uma assistência. A soma das assistências do elenco acompanhado pode ser menor que o placar, nunca maior. A posse visitante é derivada de 100 menos a posse mandante.

Ao encerrar um jogo, insira o resumo e as estatísticas na mesma transação. A exclusão explícita de dependentes pode criar lacunas no histórico.

Para concorrência real, adotar bloqueios por atleta e por partida e validar novamente com leituras atuais dentro da transação. A implementação atual valida operações sequenciais. Garantir a integridade entre sessões exige bloqueios e testes de concorrência.
