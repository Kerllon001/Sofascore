-- Sistema de Gestão de Estatísticas Esportivas
-- Base didática inspirada no futebol brasileiro em 2025 e 2026.
-- Kerllon Leonardo Costa Pinto e Luis Fernando Correa Teixeira Xavier

-- Execute em uma instância de teste ou onde o banco abaixo ainda não exista.
CREATE DATABASE estatisticas_esportivas CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE estatisticas_esportivas;
SET NAMES utf8mb4;
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE TABLE liga (
  id_liga INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL UNIQUE,
  pais VARCHAR(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE edicao (
  id_edicao INT AUTO_INCREMENT PRIMARY KEY,
  id_liga INT NOT NULL,
  ano SMALLINT NOT NULL,
  data_inicio DATE NOT NULL,
  data_fim DATE NOT NULL,
  CONSTRAINT uq_edicao UNIQUE (id_liga, ano),
  CONSTRAINT ck_edicao_ano CHECK (ano BETWEEN 1900 AND 2100),
  CONSTRAINT ck_edicao_datas CHECK (data_fim >= data_inicio),
  CONSTRAINT fk_edicao_liga FOREIGN KEY (id_liga) REFERENCES liga(id_liga) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE clube (
  id_clube INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL UNIQUE,
  sigla CHAR(3) NOT NULL UNIQUE,
  cidade VARCHAR(80) NOT NULL,
  fundacao DATE NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE atleta (
  id_atleta INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(120) NOT NULL,
  data_nascimento DATE NOT NULL,
  nacionalidade VARCHAR(60) NOT NULL,
  posicao VARCHAR(3) NOT NULL,
  pe_dominante CHAR(1) NOT NULL DEFAULT 'D',
  CONSTRAINT ck_atleta_posicao CHECK (posicao IN ('GOL','DEF','MEI','ATA')),
  CONSTRAINT ck_atleta_pe CHECK (pe_dominante IN ('D','E','A'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inscricao (
  id_edicao INT NOT NULL,
  id_clube INT NOT NULL,
  PRIMARY KEY (id_edicao, id_clube),
  CONSTRAINT fk_inscricao_edicao FOREIGN KEY (id_edicao) REFERENCES edicao(id_edicao) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_inscricao_clube FOREIGN KEY (id_clube) REFERENCES clube(id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE vinculo (
  id_vinculo INT AUTO_INCREMENT PRIMARY KEY,
  id_atleta INT NOT NULL,
  id_clube INT NOT NULL,
  data_inicio DATE NOT NULL,
  data_fim DATE NULL,
  CONSTRAINT uq_vinculo_inicio UNIQUE (id_atleta, data_inicio),
  CONSTRAINT ck_vinculo_datas CHECK (data_fim IS NULL OR data_fim >= data_inicio),
  CONSTRAINT fk_vinculo_atleta FOREIGN KEY (id_atleta) REFERENCES atleta(id_atleta) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_vinculo_clube FOREIGN KEY (id_clube) REFERENCES clube(id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE partida (
  id_partida INT AUTO_INCREMENT PRIMARY KEY,
  id_edicao INT NOT NULL,
  id_mandante INT NOT NULL,
  id_visitante INT NOT NULL,
  data_hora DATETIME NOT NULL,
  rodada SMALLINT NOT NULL,
  status VARCHAR(10) NOT NULL DEFAULT 'AGENDADA',
  CONSTRAINT uq_partida UNIQUE (id_edicao, id_mandante, id_visitante, rodada),
  CONSTRAINT ck_partida_clubes CHECK (id_mandante <> id_visitante),
  CONSTRAINT ck_partida_rodada CHECK (rodada > 0),
  CONSTRAINT ck_partida_status CHECK (status IN ('AGENDADA','ENCERRADA')),
  CONSTRAINT fk_partida_edicao FOREIGN KEY (id_edicao) REFERENCES edicao(id_edicao) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_partida_mandante FOREIGN KEY (id_edicao, id_mandante) REFERENCES inscricao(id_edicao, id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_partida_visitante FOREIGN KEY (id_edicao, id_visitante) REFERENCES inscricao(id_edicao, id_clube) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE resumo_partida (
  id_partida INT PRIMARY KEY,
  gols_mandante SMALLINT NOT NULL DEFAULT 0,
  gols_visitante SMALLINT NOT NULL DEFAULT 0,
  chutes_mandante SMALLINT NOT NULL,
  chutes_visitante SMALLINT NOT NULL,
  no_alvo_mandante SMALLINT NOT NULL,
  no_alvo_visitante SMALLINT NOT NULL,
  posse_mandante DECIMAL(5,2) NOT NULL,
  CONSTRAINT fk_resumo_partida FOREIGN KEY (id_partida) REFERENCES partida(id_partida) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_resumo_gols CHECK (gols_mandante >= 0 AND gols_visitante >= 0),
  CONSTRAINT ck_resumo_chutes CHECK (chutes_mandante >= no_alvo_mandante AND no_alvo_mandante >= gols_mandante AND chutes_visitante >= no_alvo_visitante AND no_alvo_visitante >= gols_visitante),
  CONSTRAINT ck_resumo_posse CHECK (posse_mandante BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE estatistica_atleta (
  id_partida INT NOT NULL,
  id_vinculo INT NOT NULL,
  minutos SMALLINT NOT NULL,
  gols SMALLINT NOT NULL DEFAULT 0,
  assistencias SMALLINT NOT NULL DEFAULT 0,
  passes_tentados SMALLINT NOT NULL,
  passes_certos SMALLINT NOT NULL,
  nota DECIMAL(3,1) NOT NULL,
  PRIMARY KEY (id_partida, id_vinculo),
  CONSTRAINT fk_estatistica_resumo FOREIGN KEY (id_partida) REFERENCES resumo_partida(id_partida) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT fk_estatistica_vinculo FOREIGN KEY (id_vinculo) REFERENCES vinculo(id_vinculo) ON UPDATE RESTRICT ON DELETE RESTRICT,
  CONSTRAINT ck_estatistica_minutos CHECK (minutos BETWEEN 1 AND 90),
  CONSTRAINT ck_estatistica_gols CHECK (gols >= 0 AND assistencias >= 0),
  CONSTRAINT ck_estatistica_passes CHECK (passes_tentados >= passes_certos AND passes_certos >= 0),
  CONSTRAINT ck_estatistica_nota CHECK (nota BETWEEN 0 AND 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
CREATE TRIGGER trg_vinculo_insert BEFORE INSERT ON vinculo
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM vinculo v WHERE v.id_atleta = NEW.id_atleta 
      AND v.data_inicio <= COALESCE(NEW.data_fim, '9999-12-31')
      AND NEW.data_inicio <= COALESCE(v.data_fim, '9999-12-31')
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Periodos de vinculo do atleta nao podem se sobrepor';
  END IF;
END$$

CREATE TRIGGER trg_resumo_insert BEFORE INSERT ON resumo_partida
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM partida p WHERE p.id_partida = NEW.id_partida
    AND p.status = 'ENCERRADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resumo exige partida encerrada';
  END IF;
END$$

CREATE TRIGGER trg_estatistica_insert BEFORE INSERT ON estatistica_atleta
FOR EACH ROW
BEGIN
  DECLARE clube_atleta INT;
  DECLARE atleta_atual INT;
  DECLARE limite_gols INT;
  DECLARE gols_outros INT DEFAULT 0;
  DECLARE assistencias_outros INT DEFAULT 0;
  IF NOT EXISTS (
    SELECT 1 FROM vinculo v INNER JOIN partida p ON p.id_partida = NEW.id_partida
    WHERE v.id_vinculo = NEW.id_vinculo AND p.status = 'ENCERRADA'
      AND v.id_clube IN (p.id_mandante, p.id_visitante)
      AND DATE(p.data_hora) >= v.data_inicio
      AND (v.data_fim IS NULL OR DATE(p.data_hora) <= v.data_fim)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vinculo fora da data ou dos clubes da partida';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM resumo_partida r WHERE r.id_partida = NEW.id_partida) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resumo da partida deve ser cadastrado antes das estatisticas individuais';
  END IF;
  SELECT v.id_clube, v.id_atleta,
         CASE WHEN v.id_clube = p.id_mandante
              THEN r.gols_mandante ELSE r.gols_visitante END
    INTO clube_atleta, atleta_atual, limite_gols
  FROM vinculo v
  INNER JOIN partida p ON p.id_partida = NEW.id_partida
  INNER JOIN resumo_partida r ON r.id_partida = p.id_partida
  WHERE v.id_vinculo = NEW.id_vinculo;
  IF EXISTS (
    SELECT 1 FROM estatistica_atleta s
    INNER JOIN vinculo v ON v.id_vinculo = s.id_vinculo
    WHERE s.id_partida = NEW.id_partida AND v.id_atleta = atleta_atual
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atleta ja possui estatistica nesta partida';
  END IF;
  SELECT COALESCE(SUM(s.gols), 0), COALESCE(SUM(s.assistencias), 0)
    INTO gols_outros, assistencias_outros
  FROM estatistica_atleta s
  INNER JOIN vinculo v ON v.id_vinculo = s.id_vinculo
  WHERE s.id_partida = NEW.id_partida AND v.id_clube = clube_atleta;
  IF gols_outros + NEW.gols > limite_gols
      OR assistencias_outros + NEW.assistencias > limite_gols THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gols ou assistencias individuais excedem placar do clube';
  END IF;
END$$

CREATE TRIGGER trg_vinculo_update BEFORE UPDATE ON vinculo
FOR EACH ROW
BEGIN
  IF (NEW.id_atleta <> OLD.id_atleta OR NEW.id_clube <> OLD.id_clube)
      AND EXISTS (SELECT 1 FROM estatistica_atleta WHERE id_vinculo = OLD.id_vinculo) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atleta e clube do vinculo historico estao protegidos';
  END IF;
  IF EXISTS (
    SELECT 1 FROM estatistica_atleta s
    INNER JOIN partida p ON p.id_partida = s.id_partida
    WHERE s.id_vinculo = OLD.id_vinculo
      AND (DATE(p.data_hora) < NEW.data_inicio
        OR (NEW.data_fim IS NOT NULL AND DATE(p.data_hora) > NEW.data_fim))
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Novas datas excluem estatisticas existentes do vinculo';
  END IF;
  IF EXISTS (
    SELECT 1 FROM vinculo v WHERE v.id_atleta = NEW.id_atleta AND v.id_vinculo <> OLD.id_vinculo
      AND v.data_inicio <= COALESCE(NEW.data_fim, '9999-12-31')
      AND NEW.data_inicio <= COALESCE(v.data_fim, '9999-12-31')
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Periodos de vinculo do atleta nao podem se sobrepor';
  END IF;
END$$

CREATE TRIGGER trg_resumo_update BEFORE UPDATE ON resumo_partida
FOR EACH ROW
BEGIN
  IF NOT EXISTS (SELECT 1 FROM partida p WHERE p.id_partida = NEW.id_partida
    AND p.status = 'ENCERRADA') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resumo exige partida encerrada';
  END IF;
  IF EXISTS (
    SELECT v.id_clube FROM estatistica_atleta s
    INNER JOIN vinculo v ON v.id_vinculo = s.id_vinculo
    INNER JOIN partida p ON p.id_partida = s.id_partida
    WHERE s.id_partida = OLD.id_partida
    GROUP BY v.id_clube, p.id_mandante
    HAVING SUM(s.gols) > CASE WHEN v.id_clube = p.id_mandante
             THEN NEW.gols_mandante ELSE NEW.gols_visitante END
       OR SUM(s.assistencias) > CASE WHEN v.id_clube = p.id_mandante
             THEN NEW.gols_mandante ELSE NEW.gols_visitante END
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Placar inferior aos gols ou assistencias ja registrados';
  END IF;
END$$

CREATE TRIGGER trg_estatistica_update BEFORE UPDATE ON estatistica_atleta
FOR EACH ROW
BEGIN
  DECLARE clube_atleta INT;
  DECLARE atleta_atual INT;
  DECLARE limite_gols INT;
  DECLARE gols_outros INT DEFAULT 0;
  DECLARE assistencias_outros INT DEFAULT 0;
  IF NOT EXISTS (
    SELECT 1 FROM vinculo v INNER JOIN partida p ON p.id_partida = NEW.id_partida
    WHERE v.id_vinculo = NEW.id_vinculo AND p.status = 'ENCERRADA'
      AND v.id_clube IN (p.id_mandante, p.id_visitante)
      AND DATE(p.data_hora) >= v.data_inicio
      AND (v.data_fim IS NULL OR DATE(p.data_hora) <= v.data_fim)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vinculo fora da data ou dos clubes da partida';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM resumo_partida r WHERE r.id_partida = NEW.id_partida) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Resumo da partida deve ser cadastrado antes das estatisticas individuais';
  END IF;
  SELECT v.id_clube, v.id_atleta,
         CASE WHEN v.id_clube = p.id_mandante
              THEN r.gols_mandante ELSE r.gols_visitante END
    INTO clube_atleta, atleta_atual, limite_gols
  FROM vinculo v
  INNER JOIN partida p ON p.id_partida = NEW.id_partida
  INNER JOIN resumo_partida r ON r.id_partida = p.id_partida
  WHERE v.id_vinculo = NEW.id_vinculo;
  IF EXISTS (
    SELECT 1 FROM estatistica_atleta s
    INNER JOIN vinculo v ON v.id_vinculo = s.id_vinculo
    WHERE s.id_partida = NEW.id_partida AND v.id_atleta = atleta_atual
      AND NOT (s.id_partida = OLD.id_partida AND s.id_vinculo = OLD.id_vinculo)
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atleta ja possui estatistica nesta partida';
  END IF;
  SELECT COALESCE(SUM(s.gols), 0), COALESCE(SUM(s.assistencias), 0)
    INTO gols_outros, assistencias_outros
  FROM estatistica_atleta s
  INNER JOIN vinculo v ON v.id_vinculo = s.id_vinculo
  WHERE s.id_partida = NEW.id_partida AND v.id_clube = clube_atleta
      AND NOT (s.id_partida = OLD.id_partida AND s.id_vinculo = OLD.id_vinculo);
  IF gols_outros + NEW.gols > limite_gols
      OR assistencias_outros + NEW.assistencias > limite_gols THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Gols ou assistencias individuais excedem placar do clube';
  END IF;
END$$

CREATE TRIGGER trg_partida_update BEFORE UPDATE ON partida
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM edicao e WHERE e.id_edicao = NEW.id_edicao
      AND DATE(NEW.data_hora) BETWEEN e.data_inicio AND e.data_fim
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Partida fora do periodo da edicao';
  END IF;
  IF (NEW.id_edicao <> OLD.id_edicao OR NEW.id_mandante <> OLD.id_mandante
    OR NEW.id_visitante <> OLD.id_visitante OR NEW.data_hora <> OLD.data_hora
    OR NEW.status <> OLD.status)
    AND EXISTS (SELECT 1 FROM resumo_partida WHERE id_partida = OLD.id_partida) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Partida com resumo tem dados historicos protegidos';
  END IF;
END$$

CREATE TRIGGER trg_partida_insert BEFORE INSERT ON partida
FOR EACH ROW
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM edicao e WHERE e.id_edicao = NEW.id_edicao
      AND DATE(NEW.data_hora) BETWEEN e.data_inicio AND e.data_fim
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Partida fora do periodo da edicao';
  END IF;
END$$

CREATE TRIGGER trg_edicao_update BEFORE UPDATE ON edicao
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM partida p WHERE p.id_edicao = OLD.id_edicao
      AND DATE(p.data_hora) NOT BETWEEN NEW.data_inicio AND NEW.data_fim
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Periodo da edicao exclui partidas existentes';
  END IF;
END$$
DELIMITER ;

-- Povoamento didático. Competições e clubes usam nomes de referência.
-- Calendário, elencos, vínculos, atributos e resultados demonstram o esquema.
-- Use fontes oficiais para confirmar registros e números de partidas.
START TRANSACTION;

INSERT INTO liga (id_liga, nome, pais) VALUES
(1,'Brasileirão Série A','Brasil'),(2,'Brasileirão Série B','Brasil'),(3,'Copa do Brasil','Brasil'),
(4,'Brasileirão Série C','Brasil'),(5,'Supercopa do Brasil','Brasil'),(6,'Copa do Nordeste','Brasil'),
(7,'Copa Verde','Brasil'),(8,'Campeonato Paulista','Brasil'),(9,'Campeonato Carioca','Brasil'),
(10,'Campeonato Mineiro','Brasil'),(11,'Campeonato Gaúcho','Brasil'),(12,'Campeonato Baiano','Brasil'),
(13,'Campeonato Paranaense','Brasil'),(14,'CONMEBOL Libertadores','América do Sul'),(15,'CONMEBOL Sul-Americana','América do Sul');

INSERT INTO edicao (id_edicao, id_liga, ano, data_inicio, data_fim) VALUES
(1,1,2025,'2025-03-29','2025-12-21'),(2,2,2025,'2025-04-04','2025-11-23'),(3,3,2025,'2025-02-18','2025-12-21'),
(4,4,2025,'2025-04-12','2025-10-26'),(5,5,2025,'2025-02-02','2025-02-02'),(6,6,2025,'2025-01-21','2025-09-07'),
(7,7,2025,'2025-01-22','2025-04-23'),(8,8,2025,'2025-01-15','2025-03-27'),(9,9,2025,'2025-01-11','2025-03-16'),
(10,10,2025,'2025-01-18','2025-03-15'),(11,11,2025,'2025-01-22','2025-03-16'),(12,12,2025,'2025-01-11','2025-03-23'),
(13,13,2025,'2025-01-11','2025-03-29'),(14,14,2025,'2025-02-04','2025-11-29'),(15,15,2025,'2025-03-04','2025-11-22'),
(16,1,2026,'2026-01-01','2026-12-31'),(17,2,2026,'2026-01-01','2026-12-31'),(18,3,2026,'2026-01-01','2026-12-31'),
(19,14,2026,'2026-01-01','2026-12-31'),(20,15,2026,'2026-01-01','2026-12-31');

INSERT INTO clube (id_clube, nome, sigla, cidade, fundacao) VALUES
(1,'Clube Atlético Mineiro','CAM','Belo Horizonte','1908-03-25'),
(2,'Esporte Clube Bahia','BAH','Salvador','1931-01-01'),
(3,'Botafogo de Futebol e Regatas','BOT','Rio de Janeiro','1904-08-12'),
(4,'Ceará Sporting Club','CEA','Fortaleza','1914-06-02'),
(5,'Sport Club Corinthians Paulista','COR','São Paulo','1910-09-01'),
(6,'Cruzeiro Esporte Clube','CRU','Belo Horizonte','1921-01-02'),
(7,'Clube de Regatas do Flamengo','FLA','Rio de Janeiro','1895-11-17'),
(8,'Fluminense Football Club','FLU','Rio de Janeiro','1902-07-21'),
(9,'Fortaleza Esporte Clube','FOR','Fortaleza','1918-10-18'),
(10,'Grêmio Foot-Ball Porto Alegrense','GRE','Porto Alegre','1903-09-15'),
(11,'Sport Club Internacional','INT','Porto Alegre','1909-04-04'),
(12,'Esporte Clube Juventude','JUV','Caxias do Sul','1913-06-29'),
(13,'Mirassol Futebol Clube','MIR','Mirassol','1925-11-09'),
(14,'Sociedade Esportiva Palmeiras','PAL','São Paulo','1914-08-26'),
(15,'Red Bull Bragantino','RBB','Bragança Paulista','1928-01-08'),
(16,'Santos Futebol Clube','SAN','Santos','1912-04-14'),
(17,'São Paulo Futebol Clube','SAO','São Paulo','1930-01-25'),
(18,'Sport Club do Recife','SPO','Recife','1905-05-13'),
(19,'Club de Regatas Vasco da Gama','VAS','Rio de Janeiro','1898-08-21'),
(20,'Esporte Clube Vitória','VIT','Salvador','1899-05-13'),
(21,'Amazonas Futebol Clube','AMA','Manaus','2019-05-23'),
(22,'América Futebol Clube','AMG','Belo Horizonte','1912-04-30'),
(23,'Athletic Club','ATH','São João del-Rei','1909-06-27'),
(24,'Club Athletico Paranaense','CAP','Curitiba','1924-03-26'),
(25,'Atlético Clube Goianiense','ACG','Goiânia','1937-04-02'),
(26,'Avaí Futebol Clube','AVA','Florianópolis','1923-09-01'),
(27,'Botafogo Futebol Clube','BFC','Ribeirão Preto','1918-10-12'),
(28,'Associação Chapecoense de Futebol','CHA','Chapecó','1973-05-10'),
(29,'Coritiba Foot Ball Club','CFC','Curitiba','1909-10-12'),
(30,'Clube de Regatas Brasil','CRB','Maceió','1912-09-20'),
(31,'Criciúma Esporte Clube','CRI','Criciúma','1947-05-13'),
(32,'Cuiabá Esporte Clube','CUI','Cuiabá','2001-12-12'),
(33,'Associação Ferroviária de Esportes','FER','Araraquara','1950-04-12'),
(34,'Goiás Esporte Clube','GOI','Goiânia','1943-04-06'),
(35,'Grêmio Novorizontino','NOV','Novo Horizonte','2010-03-01'),
(36,'Operário Ferroviário Esporte Clube','OPE','Ponta Grossa','1912-05-01'),
(37,'Paysandu Sport Club','PAY','Belém','1914-02-02'),
(38,'Clube do Remo','REM','Belém','1905-02-05'),
(39,'Vila Nova Futebol Clube','VIL','Goiânia','1943-07-29'),
(40,'Volta Redonda Futebol Clube','VRE','Volta Redonda','1976-02-09'),
(41,'Centro Sportivo Alagoano','CSA','Maceió','1913-09-07'),
(42,'Retrô Futebol Clube Brasil','RET','Camaragibe','2016-02-15');

INSERT INTO atleta (id_atleta, nome, data_nascimento, nacionalidade, posicao, pe_dominante) VALUES
(1,'Guilherme Arana','1997-04-14','Brasil','DEF','E'),(2,'Gustavo Scarpa','1994-01-05','Brasil','MEI','E'),(3,'Hulk Paraíba','1986-07-25','Brasil','ATA','E'),
(4,'Santiago Arias','1992-01-13','Colômbia','DEF','D'),(5,'Éverton Ribeiro','1989-04-10','Brasil','MEI','E'),(6,'Luciano Rodríguez','2003-07-16','Uruguai','ATA','D'),
(7,'Alexander Barboza','1995-03-16','Argentina','DEF','E'),(8,'Marlon Freitas','1995-03-27','Brasil','MEI','D'),(9,'Igor Jesus','2001-02-25','Brasil','ATA','D'),
(10,'Matheus Bahia','1999-08-11','Brasil','DEF','E'),(11,'Lucas Mugni','1992-01-12','Argentina','MEI','E'),(12,'Pedro Raul','1996-11-05','Brasil','ATA','D'),
(13,'Gustavo Henrique','1993-03-24','Brasil','DEF','D'),(14,'Rodrigo Garro','1998-01-04','Argentina','MEI','E'),(15,'Yuri Alberto','2001-03-18','Brasil','ATA','D'),
(16,'William Furtado','1995-04-03','Brasil','DEF','D'),(17,'Matheus Pereira','1996-05-05','Brasil','MEI','E'),(18,'Kaio Jorge','2002-01-24','Brasil','ATA','D'),
(19,'Danilo Luiz','1991-07-15','Brasil','DEF','D'),(20,'Giorgian De Arrascaeta','1994-06-01','Uruguai','MEI','D'),(21,'Pedro Guilherme','1997-06-20','Brasil','ATA','D'),
(22,'Thiago Silva','1984-09-22','Brasil','DEF','D'),(23,'Paulo Henrique Ganso','1989-10-12','Brasil','MEI','E'),(24,'Germán Cano','1988-01-02','Argentina','ATA','D'),
(25,'Tinga Guilherme','1993-09-01','Brasil','DEF','D'),(26,'Tomás Pochettino','1996-02-01','Argentina','MEI','D'),(27,'Juan Martín Lucero','1991-10-10','Argentina','ATA','D'),
(28,'Walter Kannemann','1991-03-14','Argentina','DEF','E'),(29,'Franco Cristaldo','1996-08-15','Argentina','MEI','D'),(30,'Martin Braithwaite','1991-06-05','Dinamarca','ATA','D'),
(31,'Vitão Eduardo','2000-02-02','Brasil','DEF','D'),(32,'Alan Patrick','1991-05-13','Brasil','MEI','D'),(33,'Enner Valencia','1989-11-04','Equador','ATA','D'),
(34,'Alan Ruschel','1989-08-23','Brasil','DEF','E'),(35,'Jean Carlos','1992-02-15','Brasil','MEI','E'),(36,'Gilberto Oliveira','1989-06-05','Brasil','ATA','D'),
(37,'Reinaldo Manoel','1989-09-28','Brasil','DEF','E'),(38,'Danielzinho Sampaio','1994-11-04','Brasil','MEI','D'),(39,'Iury Castilho','1995-09-06','Brasil','ATA','D'),
(40,'Gustavo Gómez','1993-05-06','Paraguai','DEF','D'),(41,'Raphael Veiga','1995-06-19','Brasil','MEI','E'),(42,'Estêvão Willian','2007-04-24','Brasil','ATA','E'),
(43,'Juninho Capixaba','1997-07-06','Brasil','DEF','E'),(44,'Jhon Jhon','2002-09-09','Brasil','MEI','D'),(45,'Eduardo Sasha','1992-02-24','Brasil','ATA','D'),
(46,'Gonzalo Escobar','1997-03-16','Argentina','DEF','E'),(47,'Neymar Júnior','1992-02-05','Brasil','MEI','A'),(48,'Guilherme Augusto','1995-04-13','Brasil','ATA','D'),
(49,'Robert Arboleda','1991-10-22','Equador','DEF','D'),(50,'Lucas Moura','1992-08-13','Brasil','MEI','D'),(51,'Jonathan Calleri','1993-09-23','Argentina','ATA','D'),
(52,'Igor Cariús','1993-05-01','Brasil','DEF','E'),(53,'Lucas Lima','1990-07-09','Brasil','MEI','E'),(54,'Chrystian Barletta','2001-07-05','Brasil','ATA','E'),
(55,'Lucas Piton','2000-10-09','Brasil','DEF','E'),(56,'Philippe Coutinho','1992-06-12','Brasil','MEI','D'),(57,'Pablo Vegetti','1988-10-15','Argentina','ATA','D'),
(58,'Wagner Leonardo','1999-07-23','Brasil','DEF','E'),(59,'Matheuzinho França','1997-10-01','Brasil','MEI','E'),(60,'Alerrandro Barra','2000-01-12','Brasil','ATA','D'),
(61,'Fabiano Leismann','1991-11-18','Brasil','DEF','D'),(62,'Rafael Tavares','2000-07-12','Brasil','MEI','E'),(63,'Sassá Luiz','1994-01-11','Brasil','ATA','E'),
(64,'Ricardo Silva','1992-08-13','Brasil','DEF','D'),(65,'Martín Benítez','1994-06-17','Argentina','MEI','D'),(66,'Fabinho Gonçalves','1999-11-18','Brasil','ATA','E'),
(67,'Danilo Cardoso','1997-04-06','Brasil','DEF','D'),(68,'David Braga','2001-05-14','Brasil','MEI','D'),(69,'Neto Costa','1997-01-09','Brasil','ATA','D'),
(70,'Lucas Esquivel','2001-10-14','Argentina','DEF','E'),(71,'Bruno Zapelli','2002-05-17','Argentina','MEI','D'),(72,'Gonzalo Mastriani','1993-04-28','Uruguai','ATA','E'),
(73,'Alix Vinícius','1999-11-06','Brasil','DEF','D'),(74,'Shaylon Kallyson','1997-04-27','Brasil','MEI','E'),(75,'Derek Freitas','1997-12-02','Brasil','ATA','E'),
(76,'Tiago Pagnussat','1990-06-17','Brasil','DEF','D'),(77,'Giovanni Augusto','1989-09-05','Brasil','MEI','D'),(78,'Hygor Cléber','1992-08-13','Brasil','ATA','D'),
(79,'Ericson Silva','1999-05-12','Brasil','DEF','D'),(80,'Leandro Maciel','1995-12-29','Argentina','MEI','D'),(81,'Alexandre Jesus','2001-09-16','Brasil','ATA','D'),
(82,'Bruno Leonardo','1996-06-02','Brasil','DEF','D'),(83,'Giovanni Pavani','1996-11-22','Brasil','MEI','D'),(84,'Mário Sérgio','1995-09-02','Brasil','ATA','D'),
(85,'Maicon Pereira','1988-09-14','Brasil','DEF','D'),(86,'Sebastián Gómez','1996-06-03','Colômbia','MEI','E'),(87,'Gustavo Coutinho','1999-01-19','Brasil','ATA','D'),
(88,'Saimon Pains','1991-03-05','Brasil','DEF','D'),(89,'Gegê Gianechini','1994-01-28','Brasil','MEI','E'),(90,'Anselmo Ramon','1988-06-23','Brasil','ATA','D'),
(91,'Rodrigo Fagundes','1987-05-24','Brasil','DEF','D'),(92,'Fellipe Mateus','1991-02-12','Brasil','MEI','E'),(93,'Yannick Bolasie','1989-05-24','RD Congo','ATA','A'),
(94,'Marllon Gonçalves','1992-04-16','Brasil','DEF','D'),(95,'Fernando Sobral','1994-12-17','Brasil','MEI','D'),(96,'Isidro Pitta','1999-08-14','Paraguai','ATA','D'),
(97,'Gustavo Medina','2001-06-29','Brasil','DEF','D'),(98,'Ricardinho Oliveira','1989-09-04','Brasil','MEI','D'),(99,'Carlão Roberto','1992-08-01','Brasil','ATA','D'),
(100,'Lucas Ribeiro','1999-01-19','Brasil','DEF','D'),(101,'Marcão Silva','1991-04-22','Brasil','MEI','D'),(102,'Paulo Baya','1999-07-26','Brasil','ATA','D'),
(103,'César Martins','1992-12-28','Brasil','DEF','D'),(104,'Marlon Adriano','1990-11-26','Brasil','MEI','D'),(105,'Neto Pessoa','1994-05-16','Brasil','ATA','E'),
(106,'Willian Machado','1996-11-13','Brasil','DEF','E'),(107,'Índio Wilder','1996-02-28','Brasil','MEI','D'),(108,'Daniel Amorim','1989-09-15','Brasil','ATA','D'),
(109,'Wanderson Santos','1991-02-07','Brasil','DEF','D'),(110,'Robinho Róbson','1987-11-10','Brasil','MEI','D'),(111,'Nicolas Careca','1989-10-04','Brasil','ATA','D'),
(112,'Rafael Castro','1996-09-26','Brasil','DEF','D'),(113,'Jaderson Flores','2000-08-12','Brasil','MEI','E'),(114,'Pedro Rocha','1994-10-01','Brasil','ATA','D'),
(115,'Ralf Teles','1984-06-09','Brasil','DEF','D'),(116,'Igor Henrique','1991-12-20','Brasil','MEI','D'),(117,'Alesson Batista','1999-02-16','Brasil','ATA','D'),
(118,'Bruno Barra','1986-01-12','Brasil','DEF','D'),(119,'PK Patrick','1998-05-19','Brasil','MEI','E'),(120,'MV Marcos Vinícius','1998-03-26','Brasil','ATA','D'),
(121,'Eduardo Biazus','2001-04-12','Brasil','DEF','D'),(122,'Gustavo Nicola','1999-03-08','Brasil','MEI','D'),(123,'Tiago Marques','1988-03-03','Brasil','ATA','D'),
(124,'Dankler Luís','1992-01-24','Brasil','DEF','D'),(125,'Rômulo Caldeira','1987-05-22','Brasil','MEI','D'),(126,'Fernandinho Melo','1985-11-25','Brasil','ATA','E');

-- Cadastros adicionais com datas e atributos gerados pela fórmula abaixo.
INSERT INTO atleta (id_atleta, nome, data_nascimento, nacionalidade, posicao, pe_dominante)
SELECT 126 + (j.c - 1) * 16 + j.ord,
       j.nome,
       CASE WHEN j.ord <= 10
            THEN DATE_ADD('1991-01-10', INTERVAL ((j.c * 17 + j.ord * 29) MOD 3100) DAY)
            ELSE DATE_ADD('2000-01-15', INTERVAL ((j.c * 13 + j.ord * 23) MOD 1800) DAY)
       END,
       'Brasil',
       CASE WHEN j.ord IN (1, 2) THEN 'GOL'
            WHEN j.ord BETWEEN 3 AND 7 THEN 'DEF'
            WHEN j.ord BETWEEN 8 AND 12 THEN 'MEI'
            ELSE 'ATA'
       END,
       CASE WHEN j.ord IN (4, 9, 14) THEN 'E' ELSE 'D' END
FROM JSON_TABLE('[
{"c":1,"p":["Everson Felipe","Matheus Mendes","Renzo Saravia","Lyanco Vojnovic","Junior Alonso","Rubens Dias","Igor Rabello","Otávio Santos","Alan Franco","Fausto Vera","Bernard Duarte","Igor Gomes","Deyverson Silva","Cadu Santana","Brahian Palacios","Alisson Santana"]},
{"c":2,"p":["Marcos Felipe","Danilo Fernandes","Gabriel Xavier","Kanu Silva","Luciano Juba","Gilberto Moraes","David Duarte","Caio Alexandre","Jean Lucas","Cauly Oliveira","Rezende Júlio","Thaciano Mickael","Everaldo Stum","Ademir Santos","Biel Teixeira","Rafael Ratão"]},
{"c":3,"p":["John Victor","Gatito Fernández","Bastos Quissanga","Vitinho Lopes","Alex Telles","Cuiabano Soares","Lucas Halter","Gregore Magalhães","Tchê Tchê","Jefferson Savarino","Allan Marques","Danilo Barbosa","Luiz Henrique","Júnior Santos","Tiquinho Soares","Matheus Martins"]},
{"c":4,"p":["Richard Oliveira","Fernando Miguel","Rafael Ramos","Matheus Felipe","David Ricardo","Raí Ramos","Ramon Menezes","Lourenço Silva","Richardson Santos","Patrick De Lucca","Jorge Recalde","Jean Irmer","Erick Pulga","Saulo Mineiro","Aylon Darwin","Facundo Barceló"]},
{"c":5,"p":["Hugo Souza","Matheus Donelli","Félix Torres","André Ramalho","Matheuzinho Silva","Matheus Bidu","Cacá Nascimento","Raniele Almeida","José Martínez","Breno Bidon","André Carrillo","Igor Coronado","Memphis Depay","Ángel Romero","Talles Magno","Héctor Hernández"]},
{"c":6,"p":["Cássio Ramos","Anderson Paixão","João Marcelo","Lucas Villalba","Marlon Xavier","Zé Ivaldo","Wesley Gasolina","Lucas Romero","Matheus Henrique","Walace Souza","Álvaro Barreal","Ramiro Benetti","Gabriel Barbosa","Dudu Rodrigues","Lautaro Díaz","Juan Dinenno"]},
{"c":7,"p":["Agustín Rossi","Matheus Cunha","Léo Pereira","Léo Ortiz","Wesley França","Alex Sandro","Ayrton Lucas","Gerson Santos","Erick Pulgar","Nicolás De La Cruz","Carlos Alcaraz","Allan Souza","Bruno Henrique","Michael Delgado","Gonzalo Plata","Luiz Araújo"]},
{"c":8,"p":["Fábio Deivson","Vitor Eudes","Samuel Xavier","Ignácio Silva","Thiago Santos","Diogo Barbosa","Guga Rodrigues","Martinelli Lima","Facundo Bernal","Vinícius Lima","Nonato Santana","Renato Augusto","Jhon Arias","Kevin Serna","Kauã Elias","Keno Marcos"]},
{"c":9,"p":["João Ricardo","Santos Aderbar","Emanuel Brítez","Benjamín Kuscevic","Titi Cristian","Bruno Pacheco","Eros Mancuso","Hércules Pereira","Lucas Sasha","Zé Welison","Emmanuel Martínez","Calebe Gonçalves","Moisés Vieira","Yago Pikachu","Marinho Santos","Renato Kayzer"]},
{"c":10,"p":["Agustín Marchesín","Caíque Santos","João Pedro","Jemerson Nascimento","Reinaldo Silva","Rodrigo Ely","Fábio Silva","Mathías Villasanti","Dodi Douglas","Miguel Monsalve","Pepê João","Edenilson Andrade","Yeferson Soteldo","Cristian Pavón","Alexander Aravena","Matías Arezo"]},
{"c":11,"p":["Sergio Rochet","Anthoni Souza","Alexandro Bernabei","Bruno Gomes","Gabriel Mercado","Agustín Rogel","Renê Rodrigues","Fernando Reges","Thiago Maia","Bruno Tabata","Gabriel Carvalho","Rômulo Zwarg","Rafael Borré","Wesley Ribeiro","Wanderson Maciel","Lucas Alario"]},
{"c":12,"p":["Gabriel Vasconcelos","Mateus Claus","João Lucas","Danilo Boza","Zé Marcos","Lucas Freitas","Ewerthon Silva","Jadson Alves","Luís Oyama","Luís Mandaca","Nenê Carvalho","Ronaldo Silva","Lucas Barbosa","Erick Farias","Edson Carioca","Ronie Carrillo"]},
{"c":13,"p":["Alex Muralha","Vanderlei Farias","Lucas Ramon","João Victor","Luiz Otávio","Zeca José","Warley Silva","Neto Moura","Gabriel Santana","Chico Kim","Isaque Elias","Yago Felipe","Guilherme Dellatorre","Fernandinho José","Negueba Guilherme","Léo Gamalho"]},
{"c":14,"p":["Weverton Pereira","Marcelo Lomba","Murilo Cerqueira","Marcos Rocha","Joaquín Piquerez","Mayke Rocha","Vitor Reis","Aníbal Moreno","Richard Ríos","Maurício Magalhães","Zé Rafael","Felipe Anderson","Flaco López","Paulinho Filho","Rony Barbosa","Bruno Rodrigues"]},
{"c":15,"p":["Cleiton Schwengber","Lucão Silva","Pedro Henrique","Eduardo Santos","Lucas Cunha","Andrés Hurtado","Luan Cândido","Lucas Evangelista","Matheus Fernandes","Lincoln Henrique","Jadsom Silva","Eric Ramires","Vitinho Moura","Henry Mosquera","Vinicinho Souza","Thiago Borbas"]},
{"c":16,"p":["João Paulo","Gabriel Brazão","JP Chermont","Gil Nascimento","Jair Paula","Luan Peres","Souza João","João Schmidt","Diego Pituca","Giuliano Victor","Rómulo Otero","Tomás Rincón","Wendel Silva","Julio Furch","Willian Bigode","Pedrinho Silva"]},
{"c":17,"p":["Rafael Pires","Jandrei Chitolina","Alan Franco","Igor Vinícius","Welington Damascena","Rafinha Márcio","Sabino José","Alisson Castro","Luiz Gustavo","Pablo Maia","Marcos Antônio","Rodrigo Nestor","Luciano Neves","Ferreirinha Aldemir","André Silva","William Gomes"]},
{"c":18,"p":["Caíque França","Thiago Couto","Rafael Thyere","Chico Alves","Felipinho Sampaio","Dalbert Henrique","Leonél Di Plácido","Fabricio Domínguez","Felipe Carvalho","Tití Ortiz","Pedro Vilhena","Julián Fernández","Gustavo Coutinho","Zé Roberto","Wellington Silva","Lenny Lobato"]},
{"c":19,"p":["Léo Jardim","Keiller Silva","Paulo Henrique","João Victor","Léo Pelé","Maicon Marques","Puma Rodríguez","Hugo Moura","Mateus Carvalho","Dimitri Payet","Jair Rodrigues","Maxime Dominguez","David Corrêa","Adson Soares","Rayan Vitor","Emerson Rodríguez"]},
{"c":20,"p":["Lucas Arcanjo","Muriel Becker","Raúl Cáceres","Hueglo Neris","Lucas Esteves","Edu Ribeiro","Willean Lepo","Willian Oliveira","Luan Santos","Filipe Machado","Léo Naldi","Pepê Figueiredo","Osvaldo Lourenço","Janderson Silva","Carlos Eduardo","Everaldo Silva"]},
{"c":21,"p":["Marcão Oliveira","Edson Mardden","Ezequiel Miranda","Matheus Miranda","Iván Alvariño","Sidcley Ferreira","Renan Castro","Cauê Santos","Diego Torres","Cauan Barros","Jiménez Xavier","Anderson Pará","Luan Silva","Matheus Serafim","Ênio Sebastião","Jô Alves"]},
{"c":22,"p":["Dalberson Silva","Elias Martello","Éder Ferreira","Mateus Henrique","Marlon Lopes","Daniel Borges","Lucão Nascimento","Alê Evaristo","Juninho Valoura","Moisés Lima","Wallisson Luiz","Fernando Elizari","Renato Marques","Brenner Marlos","Rodriguinho Batista","Adyson Soares"]},
{"c":23,"p":["Glauco Tadeu","Jefferson Paulino","Yuri Silva","Sidimar Fernando","Edson Miranda","Douglas Pelé","Alason Carioca","Diego Fumaça","Djalma Silva","Wallisson Nunes","Rafael Toró","Robert Santos","Jonathas Jesus","Welinton Torrão","Paul Villero","Geovane Silva"]},
{"c":24,"p":["Mycael Pontes","Léo Linck","Kaique Rocha","Thiago Heleno","Leonardo Godoy","Mateo Gamarra","Fernando Moraes","Erick Carvalho","Fernandinho Rosa","Christian Roberto","João Cruz","Felipinho Mendes","Tomás Cuello","Nikão Maycon","Julimar Silva","Pablo Felipe"]},
{"c":25,"p":["Ronaldo Oliveira","Pedro Rangel","Adriano Martins","Guilherme Romão","Bruno Tubarão","Maguinho Silva","Luiz Felipe","Roni Medeiros","Gabriel Baralhas","Rhaldney Norberto","Alejo Cruz","Jorginho Pereira","Luiz Fernando","Emiliano Rodríguez","Janderson Costa","Jan Hurtado"]},
{"c":26,"p":["César Augusto","Igor Bohn","Marcos Vinícius","Gustavo Vilar","Mário Sérgio","Jonathan Costa","Natanael Pimienta","Zé Ricardo","Willian Maranhão","João Paulo","Pedro Castro","Judson Silva","Maurício Garcez","Vagner Love","William Pottker","Pedrinho Santos"]},
{"c":27,"p":["João Carlos","Victor Souza","Lucas Dias","Bernardo Schappo","Wallison Maia","Patrick Brey","Jean Victor","Matheus Barbosa","Gustavo Bochecha","Sabit Abdulai","Fillipe Soutto","Carlos Manuel","Douglas Baggio","Emerson Negueba","Victor Andrade","Jonas Toró"]},
{"c":28,"p":["Léo Vieira","Matheus Cavichioli","Marcelinho Souza","Eduardo Doma","Walter Mancha","Maílton Santos","João Paulo","Guilherme Foguinho","Tárik Boschetti","Rafael Carvalheira","Marlone Jonathan","Thomás Bedinelli","Marcinho Silva","Thayllon Santana","Pedro Perotti","Jenison Jesus"]},
{"c":29,"p":["Pedro Morisco","Gabriel Leite","Natanael Moreira","Marcelo Benevenuto","Bruno Melo","Jamerson Bahia","Rodrigo Gelado","Vini Paulista","Everton Morelli","Matheus Frizzo","Josué Pesqueira","Zé Gabriel","Lucas Ronier","Robson Fernandes","Júnior Brumado","Alef Manga"]},
{"c":30,"p":["Matheus Albino","Vitor Caetano","Diogo Hereda","Fábio Alemão","Willian Formiga","Ryan Silva","Gustavo Henrique","Lucas Falcão","João Pedro","Rômulo Oliveira","Chayene Oliveira","Marco Antônio","Léo Pereira","Mike Santos","Kleiton Pego","Facundo Labandeira"]},
{"c":31,"p":["Gustavo Silva","Alisson Santana","Claudinho Soares","Tobias Figueiredo","Marcelo Hermes","Miguel Trauco","Wilker Ángel","Higor Barreto","Newton Júnior","Ronald Lopes","Matheusinho Fogaça","Patrick de Paula","Allano Brendon","Arthur Caíke","Felipe Vizeu","Pedro Rocha"]},
{"c":32,"p":["Walter Leandro","Mateus Pasinato","Matheus Alexandre","Alan Empereur","Bruno Alves","Ramon Soares","Rikelme Hernandes","Lucas Mineiro","Denilson Alves","Max Alves","Filipe Augusto","Lucas Fernandes","Clayson Silva","Derik Lacerda","Jonathan Cafú","André Luís"]},
{"c":33,"p":["Saulo Soares","Léo Wall","Lucas Rodrigues","Jackson Souza","Ronaldo Alves","Igor Fernandes","Weverton Silva","Gabriel Xavier","Juninho Sávio","Zé Mateus","Cássio Gabriel","Thomaz Santos","Vitor Barreto","Juninho Quirino","Victor Silva","Ronaldo Silva"]},
{"c":34,"p":["Tadeu Ferreira","Thiago Rodrigues","Dieguinho Ferreira","Messias Rodrigues","David Braz","Sander Henrique","Douglas Caito","Juninho Aparecido","Rafael Gava","Régis Augusto","Edson Felipe","Nathan Melo","Welliton Matheus","Thiago Galhardo","Edu Júnior","Breno Herculano"]},
{"c":35,"p":["Jordi Martins","Airton Moraes","Luisão Matos","Rafael Donato","Patrick Borges","Rodrigo Soares","Reverson Silva","Geovane Meurer","Willian Farias","Eduardo Biasi","Dudu Santos","Léo Tocantins","Waguininho Silva","Rodolfo Bardella","Lucca Borges","Fabrício Daniel"]},
{"c":36,"p":["Rafael Santos","Gabriel Mesquita","Sávio Oliveira","Joseph Moreira","Allan Godói","Marcos Pará","Thales Oleques","Jacy Maranhão","Vinícius Diniz","Gabriel Boschilia","Pedro Lucas","Neto Paraíba","Maxwell Silva","Ronald Barcellos","Felipe Augusto","Nathan Fogaça"]},
{"c":37,"p":["Matheus Nogueira","Diogo Silva","Edilson Júnior","Lucas Maia","Yeferson Quintana","Kevyn Lucas","Bryan Borges","João Vieira","Netinho Borges","Matheus Trindade","Leandro Vilela","Juan Cazares","Esli García","Jean Dias","Benjamín Borasi","Paulinho Bóia"]},
{"c":38,"p":["Marcelo Rangel","Léo Lang","Sávio Alves","Ligger Malaquias","Bruno Bispo","Raimar Lopes","Diogo Batista","Paulinho Curuá","Giovanni Pavani","Marco Antônio","Matheus Anjos","Dodô Raphael","Ytalo José","Ribamar Lucas","Kelvin Mateus","Ronald Silva"]},
{"c":39,"p":["Dênis Júnior","Halls Queiroz","Elias Lira","Jemmes Bruno","Juan Quintero","Rhuan Santos","Eric Davis","Cristiano Silva","Arilson Carlos","João Vitor","Du Fernandes","Luciano Naninho","Henrique Almeida","Júnior Todinho","Emerson Urso","Gabriel Silva"]},
{"c":40,"p":["Jean Drosny","Avelino Silva","Wellington Silva","Lucas Souza","Fabrício Soares","José Sanchez","Juninho Monteiro","Henrique Silva","Robinho Róbson","Bruno Barra","Luciano Naninho","Rafinha Souza","Ítalo Carvalho","Berguinho Ribeiro","Douglas Skilo","Bruno Santos"]},
{"c":41,"p":["Georgemy Gonçalves","Deivity Santos","Raphinha Silva","Matheus Santos","Matheus Islan","Roberto Silva","Dal Pian","Buga Souza","Jean Cléber","Brayann Silva","Álvaro Santos","Juninho Valoura","Iury Tanque","Robinho Silva","Gustavinho Melo","Klenisson Silva"]},
{"c":42,"p":["Darley Ramon","Paulo Gianezini","Toty Silva","Rayne Martins","Guilherme Paraíba","Rennan Siqueira","Edson Lucas","Richard Franco","Rodrigo Alencar","Jonas Silva","Diego Guerra","Jean Silva","Giva Simplício","Franklin Mascote","Luisinho Silva","Israel Silva"]}
]', '$[*]' COLUMNS (
  c INT PATH '$.c',
  NESTED PATH '$.p[*]' COLUMNS (
    ord FOR ORDINALITY,
    nome VARCHAR(120) PATH '$'
  )
)) AS j
ORDER BY j.c, j.ord;

INSERT INTO inscricao (id_edicao, id_clube) VALUES
(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),(1,8),(1,9),(1,10),(1,11),(1,12),(1,13),(1,14),(1,15),(1,16),(1,17),(1,18),(1,19),(1,20),
(2,21),(2,22),(2,23),(2,24),(2,25),(2,26),(2,27),(2,28),(2,29),(2,30),(2,31),(2,32),(2,33),(2,34),(2,35),(2,36),(2,37),(2,38),(2,39),(2,40),
(3,1),(3,2),(3,3),(3,4),(3,5),(3,6),(3,7),(3,8),(3,9),(3,10),(3,11),(3,12),(3,13),(3,14),(3,15),(3,16),(3,17),(3,18),(3,19),(3,20),
(3,21),(3,22),(3,23),(3,24),(3,25),(3,26),(3,27),(3,28),(3,29),(3,30),(3,31),(3,32),(3,33),(3,34),(3,35),(3,36),(3,37),(3,38),(3,39),(3,40),(3,41),(3,42),
(4,41),(4,42),
(16,1),(16,2),(16,3),(16,5),(16,6),(16,7),(16,8),(16,10),(16,11),(16,13),(16,14),(16,15),(16,16),(16,17),(16,19),(16,20),(16,24),(16,28),(16,29),(16,38),
(17,4),(17,9),(17,12),(17,18),(17,21),(17,22),(17,23),(17,25),(17,26),(17,27),(17,30),(17,31),(17,32),(17,33),(17,34),(17,35),(17,36),(17,37),(17,39),(17,40),
(18,1),(18,2),(18,3),(18,4),(18,5),(18,6),(18,7),(18,8),(18,9),(18,10),(18,11),(18,12),(18,13),(18,14),(18,15),(18,16),(18,17),(18,18),(18,19),(18,20),
(18,21),(18,22),(18,23),(18,24),(18,25),(18,26),(18,27),(18,28),(18,29),(18,30),(18,31),(18,32),(18,33),(18,34),(18,35),(18,36),(18,37),(18,38),(18,39),(18,40),(18,41),(18,42);

-- A chave inicial do vínculo coincide com id_atleta para referenciar o seed.
INSERT INTO vinculo (id_vinculo, id_atleta, id_clube, data_inicio, data_fim)
SELECT id_atleta, id_atleta,
       CASE WHEN id_atleta <= 126 THEN CEIL(id_atleta / 3)
            ELSE CEIL((id_atleta - 126) / 16)
       END,
       '2025-01-01',
       '2025-12-31'
FROM atleta
ORDER BY id_atleta;

INSERT INTO vinculo (id_atleta, id_clube, data_inicio, data_fim) VALUES
(1,1,'2026-01-01',NULL),(2,1,'2026-01-01',NULL),(3,1,'2026-01-01',NULL),
(13,5,'2026-01-01',NULL),(14,5,'2026-01-01',NULL),(15,5,'2026-01-01',NULL),
(16,6,'2026-01-01',NULL),(17,6,'2026-01-01',NULL),(18,6,'2026-01-01',NULL),
(19,7,'2026-01-01',NULL),(20,7,'2026-01-01',NULL),(21,7,'2026-01-01',NULL),
(40,14,'2026-01-01',NULL),(41,14,'2026-01-01',NULL),(42,14,'2026-01-01',NULL),
(55,19,'2026-01-01',NULL),(56,19,'2026-01-01',NULL),(57,19,'2026-01-01',NULL),
(85,29,'2026-01-01',NULL),(86,29,'2026-01-01',NULL),(87,29,'2026-01-01',NULL),
(112,38,'2026-01-01',NULL),(113,38,'2026-01-01',NULL),(114,38,'2026-01-01',NULL);

INSERT INTO partida (id_partida, id_edicao, id_mandante, id_visitante, data_hora, rodada, status) VALUES
(1,1,1,6,'2025-05-18 18:30:00',9,'ENCERRADA'),(2,1,6,1,'2025-09-21 16:00:00',27,'ENCERRADA'),
(3,1,4,7,'2025-08-03 18:30:00',18,'ENCERRADA'),(4,1,7,4,'2025-12-03 21:30:00',37,'ENCERRADA'),
(5,1,14,5,'2025-04-12 18:30:00',3,'ENCERRADA'),(6,1,5,14,'2025-08-31 18:30:00',22,'ENCERRADA'),
(7,1,17,16,'2025-04-20 16:00:00',5,'ENCERRADA'),(8,1,16,17,'2025-09-14 18:30:00',25,'ENCERRADA'),
(9,1,3,19,'2025-05-04 16:00:00',7,'ENCERRADA'),(10,1,19,3,'2025-09-28 18:30:00',28,'ENCERRADA'),
(11,1,8,15,'2025-04-06 16:00:00',2,'ENCERRADA'),(12,1,15,8,'2025-08-24 11:00:00',21,'ENCERRADA'),
(13,1,10,11,'2025-04-19 21:00:00',5,'ENCERRADA'),(14,1,11,10,'2025-10-19 16:00:00',30,'ENCERRADA'),
(15,1,2,20,'2025-05-11 16:00:00',8,'ENCERRADA'),(16,1,20,2,'2025-10-05 18:30:00',29,'ENCERRADA'),
(17,1,9,18,'2025-04-27 18:30:00',6,'ENCERRADA'),(18,1,18,9,'2025-09-07 20:30:00',24,'ENCERRADA'),
(19,1,13,12,'2025-05-25 18:30:00',10,'ENCERRADA'),(20,1,12,13,'2025-10-26 16:00:00',31,'ENCERRADA'),
(21,2,29,24,'2025-06-28 18:30:00',14,'ENCERRADA'),(22,2,24,29,'2025-10-18 18:30:00',32,'ENCERRADA'),
(23,2,38,37,'2025-06-21 19:00:00',13,'ENCERRADA'),(24,2,37,38,'2025-10-14 21:30:00',31,'ENCERRADA'),
(25,2,34,39,'2025-04-17 19:00:00',3,'ENCERRADA'),(26,2,39,34,'2025-08-16 18:30:00',22,'ENCERRADA'),
(27,2,25,32,'2025-05-10 17:00:00',7,'ENCERRADA'),(28,2,32,25,'2025-09-06 19:00:00',25,'ENCERRADA'),
(29,2,26,27,'2025-07-28 19:00:00',19,'ENCERRADA'),(30,2,27,26,'2025-11-15 16:30:00',37,'ENCERRADA'),
(31,2,28,31,'2025-05-24 16:00:00',9,'ENCERRADA'),(32,2,31,28,'2025-09-20 17:00:00',27,'ENCERRADA'),
(33,2,22,23,'2025-06-07 19:00:00',11,'ENCERRADA'),(34,2,23,22,'2025-09-27 17:00:00',29,'ENCERRADA'),
(35,2,35,33,'2025-05-03 17:00:00',6,'ENCERRADA'),(36,2,33,35,'2025-08-30 17:00:00',24,'ENCERRADA'),
(37,2,36,40,'2025-06-14 16:00:00',12,'ENCERRADA'),(38,2,40,36,'2025-10-04 17:00:00',30,'ENCERRADA'),
(39,2,30,21,'2025-05-17 17:00:00',8,'ENCERRADA'),(40,2,21,30,'2025-09-13 18:00:00',26,'ENCERRADA'),
(41,3,41,19,'2025-07-30 19:00:00',5,'ENCERRADA'),(42,3,19,41,'2025-08-07 20:00:00',6,'ENCERRADA'),
(43,3,2,42,'2025-07-30 19:30:00',5,'ENCERRADA'),(44,3,42,2,'2025-08-06 19:30:00',6,'ENCERRADA'),
(45,3,5,14,'2025-07-30 21:30:00',5,'ENCERRADA'),(46,3,14,5,'2025-08-06 21:30:00',6,'ENCERRADA'),
(47,3,1,6,'2025-08-27 19:30:00',7,'ENCERRADA'),(48,3,6,1,'2025-09-11 19:30:00',8,'ENCERRADA'),
(49,3,5,19,'2025-12-17 21:30:00',11,'ENCERRADA'),(50,3,19,5,'2025-12-21 18:00:00',12,'ENCERRADA'),
(51,16,7,14,'2026-11-08 16:00:00',34,'AGENDADA'),(52,16,5,17,'2026-11-08 18:30:00',34,'AGENDADA'),
(53,16,29,24,'2026-11-08 18:30:00',34,'AGENDADA'),(54,16,38,28,'2026-11-08 20:00:00',34,'AGENDADA'),
(55,16,1,6,'2026-11-15 16:00:00',35,'AGENDADA'),(56,16,10,11,'2026-11-15 18:30:00',35,'AGENDADA'),
(57,17,4,9,'2026-11-07 17:00:00',35,'AGENDADA'),(58,17,18,12,'2026-11-07 19:00:00',35,'AGENDADA'),
(59,17,34,39,'2026-11-14 17:00:00',36,'AGENDADA'),(60,17,26,31,'2026-11-14 19:00:00',36,'AGENDADA'),
(61,18,5,7,'2026-11-18 21:30:00',9,'AGENDADA'),(62,18,6,14,'2026-11-18 21:30:00',9,'AGENDADA'),
(63,18,19,3,'2026-11-25 21:30:00',10,'AGENDADA'),(64,18,2,11,'2026-11-25 21:30:00',10,'AGENDADA'),
(65,18,1,17,'2026-12-02 21:30:00',11,'AGENDADA');

INSERT INTO resumo_partida (id_partida, gols_mandante, gols_visitante, chutes_mandante, chutes_visitante, no_alvo_mandante, no_alvo_visitante, posse_mandante) VALUES
(1,2,1,14,11,6,4,53.20),(2,0,0,12,10,4,3,51.40),(3,1,1,11,15,4,6,42.10),(4,1,0,18,7,7,2,62.50),
(5,2,0,16,9,6,3,54.80),(6,1,1,13,14,5,5,48.90),(7,2,1,15,10,6,4,55.30),(8,1,0,12,13,4,4,47.60),
(9,2,1,15,11,6,4,54.10),(10,1,1,13,12,5,4,49.50),(11,2,2,14,13,5,5,56.00),(12,1,0,13,11,4,3,48.20),
(13,1,1,12,13,4,5,46.80),(14,2,0,15,9,6,3,55.70),(15,2,0,16,10,6,3,57.40),(16,2,1,13,12,5,4,46.30),
(17,2,0,15,9,6,2,52.90),(18,1,1,12,11,4,4,49.10),(19,3,1,16,10,7,4,54.60),(20,1,2,11,13,4,5,47.80),
(21,1,0,13,11,5,3,51.20),(22,1,1,14,10,5,4,54.50),(23,2,1,15,11,6,4,52.30),(24,1,1,13,12,4,4,50.80),
(25,1,1,12,11,4,4,53.10),(26,2,0,13,9,5,2,48.70),(27,2,1,14,10,5,4,52.00),(28,1,0,12,10,4,3,50.40),
(29,5,0,19,6,9,2,58.60),(30,1,1,11,11,4,4,47.90),(31,2,1,13,11,5,4,49.30),(32,1,1,14,10,5,3,53.80),
(33,2,1,15,9,6,3,55.10),(34,1,1,11,12,4,4,46.50),(35,1,0,14,8,5,2,54.20),(36,0,2,9,13,3,5,45.80),
(37,2,0,13,8,5,2,52.70),(38,1,1,11,11,4,4,49.00),(39,2,0,14,9,5,3,53.40),(40,1,1,12,11,4,4,50.20),
(41,0,0,9,13,2,4,41.50),(42,3,1,16,8,7,3,59.20),(43,3,2,17,9,7,4,61.00),(44,0,0,10,12,3,4,43.40),
(45,1,0,12,11,4,3,48.50),(46,0,2,15,10,4,5,56.30),(47,0,2,13,11,3,5,54.00),(48,2,0,14,10,6,3,51.80),
(49,0,0,13,10,4,3,53.70),(50,1,2,14,12,5,6,52.10);

INSERT INTO estatistica_atleta (id_partida, id_vinculo, minutos, gols, assistencias, passes_tentados, passes_certos, nota) VALUES
(1,1,90,0,1,42,36,7.3),(1,2,84,1,0,45,39,7.6),(1,3,90,1,1,31,25,7.9),(1,16,90,0,0,38,32,6.6),(1,17,88,0,1,44,38,7.1),(1,18,90,1,0,27,21,7.2),
(2,16,90,0,0,40,35,6.8),(2,17,85,0,0,46,40,6.9),(2,18,78,0,0,26,20,6.5),(2,1,90,0,0,41,35,6.8),(2,2,82,0,0,43,37,6.7),(2,3,90,0,0,29,23,6.6),
(3,10,90,0,0,35,29,6.7),(3,11,80,0,1,41,35,7.1),(3,12,90,1,0,25,19,7.3),(3,19,90,0,0,48,43,6.9),(3,20,86,0,1,52,46,7.4),(3,21,90,1,0,30,25,7.5),
(4,19,90,0,0,54,49,7.4),(4,20,88,0,1,58,52,7.8),(4,21,90,1,0,33,28,8.0),(4,10,90,0,0,32,26,6.4),(4,11,76,0,0,36,30,6.5),(4,12,90,0,0,22,17,6.3),
(5,40,90,1,0,46,41,7.6),(5,41,84,0,1,49,43,7.4),(5,42,87,1,1,37,31,7.9),(5,13,90,0,0,39,33,6.3),(5,14,85,0,0,44,37,6.6),(5,15,90,0,0,26,20,6.4),
(6,13,90,0,0,41,35,6.8),(6,14,90,0,1,47,41,7.3),(6,15,90,1,0,29,23,7.5),(6,40,90,0,0,44,39,6.8),(6,41,82,0,1,46,40,7.2),(6,42,89,1,0,35,29,7.5),
(7,49,90,0,0,45,40,7.0),(7,50,86,1,1,42,36,7.7),(7,51,90,1,0,28,22,7.5),(7,46,90,0,0,37,31,6.5),(7,47,90,1,0,48,41,7.4),(7,48,81,0,1,29,23,6.9),
(8,46,90,0,0,39,33,6.9),(8,47,90,0,1,50,43,7.6),(8,48,85,1,0,30,24,7.4),(8,49,90,0,0,44,38,6.6),(8,50,83,0,0,40,34,6.7),(8,51,90,0,0,26,20,6.4),
(9,7,90,0,0,46,40,7.0),(9,8,90,1,1,51,45,7.7),(9,9,87,1,0,32,26,7.5),(9,55,90,0,1,40,34,7.0),(9,56,79,0,0,43,37,6.7),(9,57,90,1,0,27,21,7.3),
(10,55,90,0,1,42,36,7.1),(10,56,82,0,0,45,39,6.9),(10,57,90,1,0,28,22,7.4),(10,7,90,0,0,44,38,6.8),(10,8,90,0,1,49,43,7.2),(10,9,86,1,0,30,24,7.4),
(11,22,90,0,0,50,45,6.9),(11,23,81,1,1,53,47,7.6),(11,24,90,1,0,27,22,7.4),(11,43,90,0,1,39,33,7.0),(11,44,84,1,0,42,36,7.3),(11,45,88,1,0,29,23,7.3),
(12,43,90,0,1,41,35,7.2),(12,44,85,0,0,43,37,6.8),(12,45,90,1,0,30,24,7.4),(12,22,90,0,0,47,42,6.7),(12,23,78,0,0,49,43,6.6),(12,24,90,0,0,25,20,6.4),
(13,28,90,0,0,37,31,6.8),(13,29,84,0,1,42,36,7.1),(13,30,90,1,0,28,22,7.3),(13,31,90,0,0,43,38,6.8),(13,32,90,0,1,48,42,7.3),(13,33,87,1,0,29,23,7.4),
(14,31,90,0,0,46,41,7.2),(14,32,88,1,1,51,45,7.8),(14,33,90,1,0,31,25,7.5),(14,28,90,0,0,35,29,6.3),(14,29,80,0,0,39,33,6.5),(14,30,90,0,0,26,20,6.4),
(15,4,90,0,1,44,38,7.2),(15,5,85,1,0,50,44,7.6),(15,6,90,1,0,32,26,7.5),(15,58,90,0,0,36,30,6.4),(15,59,82,0,0,40,34,6.5),(15,60,90,0,0,27,21,6.4),
(16,58,90,1,0,38,32,7.3),(16,59,86,0,1,42,36,7.1),(16,60,90,1,0,29,23,7.4),(16,4,90,0,0,42,36,6.6),(16,5,84,0,1,48,42,7.0),(16,6,90,1,0,30,24,7.2),
(17,25,90,0,1,41,35,7.2),(17,26,86,1,0,45,39,7.5),(17,27,90,1,0,29,23,7.5),(17,52,90,0,0,36,30,6.4),(17,53,81,0,0,41,35,6.5),(17,54,88,0,0,27,21,6.4),
(18,52,90,0,0,38,32,6.8),(18,53,85,0,1,44,38,7.2),(18,54,90,1,0,28,22,7.3),(18,25,90,0,0,40,34,6.7),(18,26,83,0,1,43,37,7.1),(18,27,90,1,0,28,22,7.3),
(19,37,90,1,1,43,37,7.7),(19,38,87,1,1,47,41,7.6),(19,39,90,1,0,30,24,7.5),(19,34,90,0,0,35,29,6.3),(19,35,82,0,1,40,34,6.9),(19,36,90,1,0,27,21,7.1),
(20,34,90,0,0,37,31,6.6),(20,35,84,0,1,42,36,7.0),(20,36,90,1,0,28,22,7.2),(20,37,90,0,1,41,35,7.2),(20,38,86,1,0,45,39,7.4),(20,39,90,1,0,29,23,7.4),
(21,85,90,0,0,40,34,7.1),(21,86,88,0,1,46,40,7.3),(21,87,90,1,0,29,23,7.5),(21,70,90,0,0,38,32,6.6),(21,71,84,0,0,42,36,6.7),(21,72,90,0,0,27,21,6.5),
(22,70,90,0,1,41,35,7.1),(22,71,86,0,0,44,38,6.9),(22,72,90,1,0,28,22,7.3),(22,85,90,0,0,39,33,6.8),(22,86,87,0,1,45,39,7.2),(22,87,90,1,0,28,22,7.4),
(23,112,90,0,0,38,32,7.0),(23,113,85,1,1,43,37,7.6),(23,114,90,1,0,31,25,7.8),(23,109,90,0,0,36,30,6.5),(23,110,82,0,1,40,34,6.9),(23,111,90,1,0,27,21,7.1),
(24,109,90,0,0,37,31,6.8),(24,110,84,0,1,41,35,7.1),(24,111,90,1,0,28,22,7.3),(24,112,90,0,0,37,31,6.8),(24,113,86,0,1,42,36,7.2),(24,114,90,1,0,30,24,7.7),
(25,100,90,0,0,39,33,6.8),(25,101,85,0,1,43,37,7.1),(25,102,90,1,0,29,23,7.3),(25,115,90,0,0,38,32,6.8),(25,116,84,0,1,41,35,7.1),(25,117,90,1,0,28,22,7.3),
(26,115,90,0,0,40,34,7.1),(26,116,86,1,0,42,36,7.4),(26,117,90,1,1,30,24,7.6),(26,100,90,0,0,36,30,6.4),(26,101,82,0,0,39,33,6.5),(26,102,90,0,0,26,20,6.4),
(27,73,90,0,0,39,33,6.9),(27,74,86,1,1,44,38,7.5),(27,75,90,1,0,29,23,7.4),(27,94,90,0,0,37,31,6.5),(27,95,84,0,1,42,36,7.0),(27,96,90,1,0,28,22,7.2),
(28,94,90,0,0,39,33,7.0),(28,95,87,0,1,43,37,7.2),(28,96,90,1,0,29,23,7.4),(28,73,90,0,0,37,31,6.6),(28,74,83,0,0,41,35,6.7),(28,75,90,0,0,27,21,6.5),
(29,76,90,1,0,44,39,7.6),(29,77,85,2,1,48,42,8.0),(29,78,90,2,1,32,26,8.1),(29,79,90,0,0,33,27,5.9),(29,80,78,0,0,37,31,6.1),(29,81,90,0,0,24,18,6.0),
(30,79,90,0,0,36,30,6.7),(30,80,84,0,1,40,34,7.1),(30,81,90,1,0,27,21,7.2),(30,76,90,0,0,38,32,6.8),(30,77,83,0,1,42,36,7.1),(30,78,90,1,0,28,22,7.3),
(31,82,90,0,0,38,32,6.9),(31,83,86,1,1,42,36,7.5),(31,84,90,1,0,29,23,7.4),(31,91,90,0,0,37,31,6.5),(31,92,84,0,1,41,35,7.0),(31,93,90,1,0,28,22,7.2),
(32,91,90,0,0,39,33,6.8),(32,92,85,0,1,43,37,7.1),(32,93,90,1,0,29,23,7.3),(32,82,90,0,0,37,31,6.8),(32,83,84,0,1,40,34,7.1),(32,84,90,1,0,28,22,7.3),
(33,64,90,0,0,40,34,6.9),(33,65,86,1,1,45,39,7.6),(33,66,90,1,0,29,23,7.4),(33,67,90,0,0,36,30,6.5),(33,68,83,0,1,40,34,6.9),(33,69,90,1,0,27,21,7.1),
(34,67,90,0,0,37,31,6.8),(34,68,85,0,1,41,35,7.1),(34,69,90,1,0,28,22,7.3),(34,64,90,0,0,39,33,6.8),(34,65,84,0,1,43,37,7.1),(34,66,90,1,0,28,22,7.3),
(35,103,90,0,0,40,34,7.0),(35,104,86,0,1,44,38,7.2),(35,105,90,1,0,29,23,7.4),(35,97,90,0,0,35,29,6.5),(35,98,82,0,0,39,33,6.6),(35,99,90,0,0,26,20,6.4),
(36,97,90,0,0,34,28,6.3),(36,98,80,0,0,38,32,6.4),(36,99,90,0,0,25,19,6.3),(36,103,90,0,0,39,33,7.1),(36,104,85,1,1,43,37,7.5),(36,105,90,1,0,28,22,7.4),
(37,106,90,0,0,39,33,7.0),(37,107,86,1,1,43,37,7.5),(37,108,90,1,0,28,22,7.4),(37,118,90,0,0,35,29,6.4),(37,119,82,0,0,39,33,6.5),(37,120,90,0,0,26,20,6.4),
(38,118,90,0,0,36,30,6.7),(38,119,84,0,1,40,34,7.1),(38,120,90,1,0,27,21,7.2),(38,106,90,0,0,38,32,6.8),(38,107,85,0,1,42,36,7.1),(38,108,90,1,0,28,22,7.3),
(39,88,90,0,0,39,33,7.0),(39,89,86,1,1,44,38,7.5),(39,90,90,1,0,29,23,7.4),(39,61,90,0,0,35,29,6.4),(39,62,82,0,0,39,33,6.5),(39,63,90,0,0,26,20,6.4),
(40,61,90,0,0,36,30,6.7),(40,62,84,0,1,40,34,7.1),(40,63,90,1,0,27,21,7.2),(40,88,90,0,0,38,32,6.8),(40,89,85,0,1,42,36,7.1),(40,90,90,1,0,28,22,7.3),
(41,121,90,0,0,32,26,6.8),(41,122,85,0,0,36,30,6.7),(41,123,90,0,0,24,18,6.5),(41,55,90,0,0,44,38,6.9),(41,56,82,0,0,47,41,6.8),(41,57,90,0,0,28,22,6.6),
(42,55,90,0,1,45,39,7.4),(42,56,84,1,1,49,43,7.8),(42,57,90,2,0,31,25,8.0),(42,121,90,0,0,31,25,6.2),(42,122,80,0,1,35,29,6.8),(42,123,90,1,0,25,19,7.0),
(43,4,90,0,1,46,40,7.2),(43,5,86,1,1,51,45,7.7),(43,6,90,2,0,33,27,7.9),(43,124,90,0,0,32,26,6.3),(43,125,82,1,1,37,31,7.2),(43,126,90,1,0,26,20,7.1),
(44,124,90,0,0,34,28,6.9),(44,125,85,0,0,38,32,6.8),(44,126,90,0,0,25,19,6.6),(44,4,90,0,0,43,37,6.9),(44,5,82,0,0,47,41,6.8),(44,6,90,0,0,29,23,6.7),
(45,13,90,0,0,42,36,7.2),(45,14,88,0,1,46,40,7.5),(45,15,90,1,0,29,23,7.7),(45,40,90,0,0,44,38,6.7),(45,41,84,0,0,47,41,6.6),(45,42,90,0,0,32,26,6.5),
(46,40,90,0,0,45,39,6.3),(46,41,85,0,0,48,42,6.4),(46,42,90,0,0,34,28,6.4),(46,13,90,1,0,40,34,7.6),(46,14,88,0,1,45,39,7.5),(46,15,90,1,0,28,22,7.7),
(47,1,90,0,0,43,37,6.4),(47,2,84,0,0,46,40,6.5),(47,3,90,0,0,30,24,6.4),(47,16,90,0,1,39,33,7.3),(47,17,88,1,1,45,39,7.8),(47,18,90,1,0,28,22,7.6),
(48,16,90,0,0,41,35,7.2),(48,17,87,0,1,46,40,7.6),(48,18,90,2,0,30,24,8.0),(48,1,90,0,0,40,34,6.3),(48,2,82,0,0,44,38,6.4),(48,3,90,0,0,28,22,6.3),
(49,13,90,0,0,43,37,7.0),(49,14,90,0,0,48,42,7.1),(49,15,90,0,0,27,21,6.8),(49,55,90,0,0,39,33,6.9),(49,56,84,0,0,43,37,6.8),(49,57,90,0,0,26,20,6.7),
(50,55,90,0,1,42,36,7.1),(50,56,85,0,0,45,39,6.8),(50,57,90,1,0,29,23,7.4),(50,13,90,0,0,41,35,7.3),(50,14,90,1,1,47,41,8.0),(50,15,90,1,1,30,24,8.2);

COMMIT;
