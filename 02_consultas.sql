USE estatisticas_esportivas;

-- Q01 | Simples | Clubes com "Esporte Clube" no nome cadastrado
-- Pergunta: Quais clubes cadastrados possuem "Esporte Clube" no nome?
-- Retorna: Identificador, nome cadastrado e cidade-sede dos clubes filtrados, em ordem alfabética.
SELECT id_clube, nome, cidade
FROM clube
WHERE nome LIKE '%Esporte Clube%'
ORDER BY nome;

-- Q02 | Simples | Atletas por faixa de nascimento
-- Pergunta: Quais atletas cadastrados nasceram na década de 1990?
-- Retorna: Identificador, nome e data de nascimento dos atletas nascidos entre 1990 e 1999.
SELECT id_atleta, nome, data_nascimento
FROM atleta
WHERE data_nascimento BETWEEN '1990-01-01' AND '1999-12-31'
ORDER BY data_nascimento, id_atleta;

-- Q03 | Simples | Meias e atacantes disponíveis no cadastro
-- Pergunta: Quais atletas estão classificados como meio-campistas ou atacantes?
-- Retorna: Identificador, nome e posição dos atletas MEI e ATA ordenados pelo nome.
SELECT id_atleta, nome, posicao
FROM atleta
WHERE posicao IN ('MEI', 'ATA')
ORDER BY nome, id_atleta;

-- Q04 | Simples | Cidades-sede dos clubes
-- Pergunta: Em quais cidades brasileiras estão sediados os clubes cadastrados?
-- Retorna: Lista distinta de cidades em ordem alfabética.
SELECT DISTINCT cidade
FROM clube
ORDER BY cidade;

-- Q05 | Simples | Cinco clubes mais antigos
-- Pergunta: Quais são os cinco clubes cadastrados com fundação mais antiga?
-- Retorna: Nome cadastrado e data de fundação dos 5 clubes mais antigos do banco.
SELECT nome, fundacao
FROM clube
ORDER BY fundacao, id_clube
LIMIT 5;

-- Q06 | INNER JOIN | Placar de Cruzeiro x Atlético Mineiro
-- Pergunta: Qual foi o placar de Cruzeiro x Atlético Mineiro na Copa do Brasil em 11/09/2025?
-- Retorna: Identificador, competição, data, clubes e placar da partida 48.
SELECT p.id_partida, l.nome AS liga, DATE(p.data_hora) AS data_partida,
       m.nome AS mandante, r.gols_mandante,
       r.gols_visitante, v.nome AS visitante
FROM partida p
INNER JOIN edicao e ON e.id_edicao = p.id_edicao
INNER JOIN liga l ON l.id_liga = e.id_liga
INNER JOIN clube m ON m.id_clube = p.id_mandante
INNER JOIN clube v ON v.id_clube = p.id_visitante
INNER JOIN resumo_partida r ON r.id_partida = p.id_partida
WHERE p.id_partida = 48 AND p.status = 'ENCERRADA';

-- Q07 | INNER JOIN | Artilharia de Kaio Jorge pelo Cruzeiro em 2025
-- Pergunta: Quantos gols Kaio Jorge marcou pelo Cruzeiro nos jogos registrados em 2025?
-- Retorna: Identificador, atleta, clube, total de jogos, gols e média de nota.
SELECT a.id_atleta, a.nome AS atleta, c.nome AS clube, COUNT(*) AS jogos,
       SUM(s.gols) AS gols, ROUND(AVG(s.nota), 2) AS media_nota
FROM atleta a
INNER JOIN vinculo v ON v.id_atleta = a.id_atleta
INNER JOIN clube c ON c.id_clube = v.id_clube
INNER JOIN estatistica_atleta s ON s.id_vinculo = v.id_vinculo
INNER JOIN partida p ON p.id_partida = s.id_partida
INNER JOIN edicao e ON e.id_edicao = p.id_edicao
WHERE e.ano = 2025
  AND a.nome = 'Kaio Jorge' AND c.nome = 'Cruzeiro Esporte Clube'
GROUP BY a.id_atleta, a.nome, c.id_clube, c.nome
HAVING COUNT(*) >= 2 AND SUM(s.gols) > 0;

-- Q08 | INNER JOIN | Desempenho coletivo do Bahia em 2025
-- Pergunta: Quantos gols o Bahia marcou e sofreu nos jogos encerrados que constam na base em 2025?
-- Retorna: Identificador, nome do clube, número de jogos encerrados, gols pró e gols contra.
SELECT c.id_clube, c.nome, COUNT(*) AS jogos,
       SUM(CASE WHEN p.id_mandante = c.id_clube
           THEN r.gols_mandante ELSE r.gols_visitante END) AS gols_pro,
       SUM(CASE WHEN p.id_mandante = c.id_clube
           THEN r.gols_visitante ELSE r.gols_mandante END) AS gols_contra
FROM clube c
INNER JOIN partida p ON c.id_clube IN (p.id_mandante, p.id_visitante)
INNER JOIN resumo_partida r ON r.id_partida = p.id_partida
INNER JOIN edicao e ON e.id_edicao = p.id_edicao
WHERE p.status = 'ENCERRADA' AND e.ano = 2025 AND c.nome = 'Esporte Clube Bahia'
GROUP BY c.id_clube, c.nome
HAVING COUNT(*) >= 2;

-- Q09 | INNER JOIN | Volume de finalizações por competição em 2025
-- Pergunta: Qual o volume médio e quais os extremos de finalizações nas competições com dois ou mais jogos encerrados em 2025?
-- Retorna: Identificador e nome da competição, total de jogos e média, mínimo e máximo de chutes por partida.
SELECT l.id_liga, l.nome, COUNT(*) AS jogos,
       ROUND(AVG(r.chutes_mandante + r.chutes_visitante), 2) AS media_chutes,
       MIN(r.chutes_mandante + r.chutes_visitante) AS minimo_chutes,
       MAX(r.chutes_mandante + r.chutes_visitante) AS maximo_chutes
FROM liga l
INNER JOIN edicao e ON e.id_liga = l.id_liga
INNER JOIN partida p ON p.id_edicao = e.id_edicao
INNER JOIN resumo_partida r ON r.id_partida = p.id_partida
WHERE p.status = 'ENCERRADA' AND e.ano = 2025
GROUP BY l.id_liga, l.nome
HAVING COUNT(*) >= 2
ORDER BY media_chutes DESC, l.id_liga;

-- Q10 | INNER JOIN | Participação dos clubes em diferentes edições
-- Pergunta: Quais clubes estão inscritos em duas ou mais edições de uma mesma competição?
-- Retorna: Identificador e nome do clube, nome da competição, total de edições e anos inicial e final.
SELECT c.id_clube, c.nome AS clube, l.nome AS liga,
       COUNT(*) AS edicoes, MIN(e.ano) AS primeiro_ano, MAX(e.ano) AS ultimo_ano
FROM clube c
INNER JOIN inscricao i ON i.id_clube = c.id_clube
INNER JOIN edicao e ON e.id_edicao = i.id_edicao
INNER JOIN liga l ON l.id_liga = e.id_liga
GROUP BY c.id_clube, c.nome, l.id_liga, l.nome
HAVING COUNT(*) >= 2
ORDER BY c.id_clube, l.id_liga;
