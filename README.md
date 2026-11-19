# Sistema de Gestão de Estatísticas Esportivas

**Dupla** Kerllon Leonardo Costa Pinto e Luis Fernando Correa Teixeira Xavier  
**Curso** Engenharia da Computação, 6º semestre · **Disciplina** Banco de Dados · **Instituição** AFYA Centro Universitário

Banco relacional em SQL para registrar competições, clubes, vínculos, partidas e desempenho no futebol brasileiro. O projeto se inspira no domínio do Sofascore e usa uma amostra didática de 2025 e 2026, com Brasileirão Série A, Série B, Copa do Brasil e outras competições cadastradas.

**9 tabelas · 49 atributos · 11 FKs · 9 gatilhos · 10 consultas · 2.278 registros iniciais**

![DER físico do projeto](diagramas/02_der_fisico.png)

## Modelo e integridade

| Tabela | Finalidade |
| --- | --- |
| `liga` | Cadastro das competições. |
| `edicao` | Edição anual e calendário da competição. |
| `clube` | Identificação, cidade e fundação dos clubes. |
| `atleta` | Cadastro individual dos atletas. |
| `inscricao` | Clubes participantes de cada edição. |
| `vinculo` | Histórico do atleta no clube, com datas de vigência. |
| `partida` | Mandante, visitante, edição, rodada, data e status. |
| `resumo_partida` | Placar, finalizações e posse dos jogos encerrados. |
| `estatistica_atleta` | Minutos, gols, assistências, passes e nota por jogo e vínculo. |

As chaves compostas verificam a inscrição dos dois clubes na edição. As restrições delimitam valores de datas e métricas. Os gatilhos verificam o calendário, impedem sobreposição de vínculos e comparam os totais individuais com o placar. O [relatório](docs/relatorio_tecnico.pdf) reúne as regras e os exemplos de consulta.

O cadastro usa nomes de referência. A amostra também contém atributos de atletas gerados por fórmula e registros esportivos didáticos. Veja a [origem dos dados](docs/relatorio_tecnico.pdf).

## Como executar

Use MySQL Server 8.0.16 ou superior e uma conta com permissão para criar o banco, as tabelas e os gatilhos. A implementação usa SQL, InnoDB e `utf8mb4`. O arquivo editável do DER abre no diagrams.net.

1. Conecte-se a uma instância MySQL de estudo. Se já houver um banco `estatisticas_esportivas`, use outra instância para executar a carga inicial.
2. Execute [01_banco_completo.sql](sql/01_banco_completo.sql) para criar o banco e inserir os dados.
3. Execute [02_consultas.sql](sql/02_consultas.sql) para rodar o catálogo na ordem Q01 a Q10.

No terminal, inicie na raiz do repositório e use uma conta com permissões de criação. Exemplo para a configuração local:

```text
mysql --default-character-set=utf8mb4 -u root -p
```

```sql
SOURCE sql/01_banco_completo.sql;
SOURCE sql/02_consultas.sql;
```

O banco e as 10 consultas foram executados em uma instância isolada do MySQL 8.4.13. O [catálogo](docs/relatorio_tecnico.pdf) traz amostras e totais obtidos nessa execução.

## Estrutura

```text
Sistema-Estatisticas-Esportivas/
├── README.md
├── .gitignore
├── sql/
│   ├── 01_banco_completo.sql
│   └── 02_consultas.sql
├── diagramas/
│   ├── 01_der_fisico.drawio
│   └── 02_der_fisico.png
└── docs/
    ├── relatorio_tecnico.pdf
│   ├── dicionario_dados.md
│   └── apresentacao/
│       └── Apresentacao_Estatisticas_Esportivas.pptx
```