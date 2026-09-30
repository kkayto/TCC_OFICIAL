CREATE DATABASE IF NOT EXISTS bancoREPRE
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bancoREPRE;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS
  vw_status_entregas_aluno,
  vw_entregas_mensais,
  vw_media_aluno_disciplina,
  vw_atividades_por_tipo,
  vw_proximas_entregas,
  vw_frequencia;

DROP TRIGGER IF EXISTS trg_entregas_bi;
DROP TRIGGER IF EXISTS trg_atividades_ai;
DROP TRIGGER IF EXISTS trg_entregas_au;

DROP TABLE IF EXISTS
  log_auditoria,
  tarefas_pessoais,
  notificacoes,
  eventos,
  presencas,
  aulas,
  avisos,
  comentarios,
  anexos,
  entrega_criterios,
  criterios_avaliacao,
  entregas,
  atividades,
  mensagens,
  canais,
  equipe_alunos,
  equipes,
  turma_disciplinas,
  turma_alunos,
  periodos_letivos,
  disciplinas,
  turmas,
  alunos;

SET FOREIGN_KEY_CHECKS = 1;

DROP USER IF EXISTS 'tcc_user'@'localhost';

CREATE USER 'tcc_user'@'localhost'
IDENTIFIED BY 'SENHA123';

GRANT ALL PRIVILEGES ON bancoREPRE.*
TO 'tcc_user'@'localhost';

FLUSH PRIVILEGES;



CREATE TABLE alunos (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome          VARCHAR(120) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  senha_hash    VARCHAR(255) NOT NULL,
  tipo          ENUM(
                  'aluno',
                  'professor',
                  'coordenador',
                  'admin'
                ) NOT NULL DEFAULT 'aluno',
  matricula     VARCHAR(30) NULL UNIQUE,
  foto_url      VARCHAR(255) NULL,
  ativo         TINYINT(1) NOT NULL DEFAULT 1,
  ultimo_login  DATETIME NULL,
  criado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_alunos_tipo (tipo)
) ENGINE=InnoDB;


-- =========================================================
-- TURMAS
-- =========================================================

CREATE TABLE turmas (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome       VARCHAR(80) NOT NULL,
  serie      VARCHAR(40) NULL,
  turno      ENUM('manha','tarde','noite')
             NOT NULL DEFAULT 'manha',
  ano_letivo YEAR NOT NULL,
  ativa      TINYINT(1) NOT NULL DEFAULT 1,

  UNIQUE KEY uq_turma (nome, ano_letivo)
) ENGINE=InnoDB;


-- =========================================================
-- DISCIPLINAS
-- =========================================================

CREATE TABLE disciplinas (
  id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nome     VARCHAR(80) NOT NULL UNIQUE,
  cor_hex  CHAR(7) NOT NULL DEFAULT '#000000'
) ENGINE=InnoDB;


-- =========================================================
-- PERÍODOS LETIVOS
-- =========================================================

CREATE TABLE periodos_letivos (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  ano         YEAR NOT NULL,
  nome        VARCHAR(40) NOT NULL,
  data_inicio DATE NOT NULL,
  data_fim    DATE NOT NULL,

  UNIQUE KEY uq_periodo (ano, nome),

  CHECK (data_fim >= data_inicio)
) ENGINE=InnoDB;


-- =========================================================
-- ALUNOS DAS TURMAS
-- =========================================================

CREATE TABLE turma_alunos (
  turma_id  INT UNSIGNED NOT NULL,
  aluno_id  INT UNSIGNED NOT NULL,
  papel     ENUM('aluno','representante')
            NOT NULL DEFAULT 'aluno',
  entrou_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  PRIMARY KEY (turma_id, aluno_id),

  FOREIGN KEY (turma_id)
    REFERENCES turmas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (aluno_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- TURMA + DISCIPLINA + PROFESSOR
-- =========================================================

CREATE TABLE turma_disciplinas (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  turma_id      INT UNSIGNED NOT NULL,
  disciplina_id INT UNSIGNED NOT NULL,
  professor_id  INT UNSIGNED NOT NULL,

  UNIQUE KEY uq_td (turma_id, disciplina_id),

  FOREIGN KEY (turma_id)
    REFERENCES turmas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (disciplina_id)
    REFERENCES disciplinas(id)
    ON DELETE RESTRICT,

  FOREIGN KEY (professor_id)
    REFERENCES alunos(id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =========================================================
-- EQUIPES
-- =========================================================

CREATE TABLE equipes (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  turma_disciplina_id INT UNSIGNED NOT NULL,
  nome                VARCHAR(80) NOT NULL,
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (turma_disciplina_id)
    REFERENCES turma_disciplinas(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- ALUNOS DAS EQUIPES
-- =========================================================

CREATE TABLE equipe_alunos (
  equipe_id INT UNSIGNED NOT NULL,
  aluno_id  INT UNSIGNED NOT NULL,
  lider     TINYINT(1) NOT NULL DEFAULT 0,

  PRIMARY KEY (equipe_id, aluno_id),

  FOREIGN KEY (equipe_id)
    REFERENCES equipes(id)
    ON DELETE CASCADE,

  FOREIGN KEY (aluno_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- CANAIS
-- =========================================================

CREATE TABLE canais (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  turma_disciplina_id INT UNSIGNED NOT NULL,
  equipe_id           INT UNSIGNED NULL,
  nome                VARCHAR(80) NOT NULL,
  tipo                ENUM(
                        'geral',
                        'avisos',
                        'duvidas',
                        'equipe'
                      ) NOT NULL DEFAULT 'geral',
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (turma_disciplina_id)
    REFERENCES turma_disciplinas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (equipe_id)
    REFERENCES equipes(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- MENSAGENS
-- =========================================================

CREATE TABLE mensagens (
  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  canal_id      INT UNSIGNED NOT NULL,
  autor_id      INT UNSIGNED NOT NULL,
  resposta_a_id BIGINT UNSIGNED NULL,
  conteudo      TEXT NOT NULL,
  editada       TINYINT(1) NOT NULL DEFAULT 0,
  criado_em     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_msg_canal (canal_id, criado_em),

  FOREIGN KEY (canal_id)
    REFERENCES canais(id)
    ON DELETE CASCADE,

  FOREIGN KEY (autor_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE,

  FOREIGN KEY (resposta_a_id)
    REFERENCES mensagens(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;


-- =========================================================
-- ATIVIDADES
-- =========================================================

CREATE TABLE atividades (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  turma_disciplina_id INT UNSIGNED NOT NULL,
  periodo_id          INT UNSIGNED NULL,
  criador_id          INT UNSIGNED NOT NULL,

  titulo              VARCHAR(150) NOT NULL,
  descricao           TEXT NULL,

  tipo                ENUM(
                        'tarefa',
                        'trabalho',
                        'prova',
                        'quiz',
                        'projeto',
                        'leitura'
                      ) NOT NULL DEFAULT 'tarefa',

  status              ENUM(
                        'rascunho',
                        'publicada',
                        'encerrada'
                      ) NOT NULL DEFAULT 'rascunho',

  em_grupo            TINYINT(1) NOT NULL DEFAULT 0,

  pontos              DECIMAL(5,2) NOT NULL DEFAULT 10.00,
  peso                DECIMAL(4,2) NOT NULL DEFAULT 1.00,

  permite_atraso      TINYINT(1) NOT NULL DEFAULT 1,

  publicada_em        DATETIME NULL,
  data_limite         DATETIME NULL,

  criada_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  atualizada_em       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                      ON UPDATE CURRENT_TIMESTAMP,

  INDEX idx_ativ_limite (data_limite),
  INDEX idx_ativ_td (turma_disciplina_id, status),

  FOREIGN KEY (turma_disciplina_id)
    REFERENCES turma_disciplinas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (periodo_id)
    REFERENCES periodos_letivos(id)
    ON DELETE SET NULL,

  FOREIGN KEY (criador_id)
    REFERENCES alunos(id)
    ON DELETE RESTRICT
) ENGINE=InnoDB;


-- =========================================================
-- ENTREGAS
-- =========================================================

CREATE TABLE entregas (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  atividade_id  INT UNSIGNED NOT NULL,
  aluno_id      INT UNSIGNED NOT NULL,
  equipe_id     INT UNSIGNED NULL,

  status        ENUM(
                  'pendente',
                  'entregue',
                  'atrasada',
                  'corrigida',
                  'devolvida'
                ) NOT NULL DEFAULT 'pendente',

  texto         TEXT NULL,
  enviado_em    DATETIME NULL,

  nota          DECIMAL(5,2) NULL,
  feedback      TEXT NULL,

  corrigido_por INT UNSIGNED NULL,
  corrigido_em  DATETIME NULL,

  UNIQUE KEY uq_entrega (atividade_id, aluno_id),

  INDEX idx_entrega_aluno (aluno_id, status),

  FOREIGN KEY (atividade_id)
    REFERENCES atividades(id)
    ON DELETE CASCADE,

  FOREIGN KEY (aluno_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE,

  FOREIGN KEY (equipe_id)
    REFERENCES equipes(id)
    ON DELETE SET NULL,

  FOREIGN KEY (corrigido_por)
    REFERENCES alunos(id)
    ON DELETE SET NULL,

  CHECK (nota IS NULL OR nota >= 0)
) ENGINE=InnoDB;


-- =========================================================
-- CRITÉRIOS DE AVALIAÇÃO
-- =========================================================

CREATE TABLE criterios_avaliacao (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  atividade_id INT UNSIGNED NOT NULL,
  descricao   VARCHAR(200) NOT NULL,
  pontos_max  DECIMAL(5,2) NOT NULL,

  FOREIGN KEY (atividade_id)
    REFERENCES atividades(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- NOTAS POR CRITÉRIO
-- =========================================================

CREATE TABLE entrega_criterios (
  entrega_id  INT UNSIGNED NOT NULL,
  criterio_id INT UNSIGNED NOT NULL,
  pontos      DECIMAL(5,2) NOT NULL,

  PRIMARY KEY (entrega_id, criterio_id),

  FOREIGN KEY (entrega_id)
    REFERENCES entregas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (criterio_id)
    REFERENCES criterios_avaliacao(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- AVISOS
-- =========================================================

CREATE TABLE avisos (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  turma_id            INT UNSIGNED NULL,
  turma_disciplina_id INT UNSIGNED NULL,
  autor_id            INT UNSIGNED NOT NULL,

  titulo              VARCHAR(150) NOT NULL,
  conteudo            TEXT NOT NULL,

  fixado              TINYINT(1) NOT NULL DEFAULT 0,
  criado_em           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (turma_id)
    REFERENCES turmas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (turma_disciplina_id)
    REFERENCES turma_disciplinas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (autor_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- ANEXOS
-- =========================================================

CREATE TABLE anexos (
  id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  atividade_id   INT UNSIGNED NULL,
  entrega_id     INT UNSIGNED NULL,
  mensagem_id    BIGINT UNSIGNED NULL,
  aviso_id       INT UNSIGNED NULL,

  enviado_por    INT UNSIGNED NOT NULL,

  nome_original  VARCHAR(255) NOT NULL,
  caminho        VARCHAR(255) NOT NULL,
  mime_type      VARCHAR(100) NULL,
  tamanho_bytes  BIGINT UNSIGNED NULL,

  criado_em      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (atividade_id)
    REFERENCES atividades(id)
    ON DELETE CASCADE,

  FOREIGN KEY (entrega_id)
    REFERENCES entregas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (mensagem_id)
    REFERENCES mensagens(id)
    ON DELETE CASCADE,

  FOREIGN KEY (aviso_id)
    REFERENCES avisos(id)
    ON DELETE CASCADE,

  FOREIGN KEY (enviado_por)
    REFERENCES alunos(id)
    ON DELETE CASCADE,

  CHECK (
    (atividade_id IS NOT NULL) +
    (entrega_id IS NOT NULL) +
    (mensagem_id IS NOT NULL) +
    (aviso_id IS NOT NULL) = 1
  )
) ENGINE=InnoDB;


-- =========================================================
-- COMENTÁRIOS
-- =========================================================

CREATE TABLE comentarios (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  atividade_id INT UNSIGNED NULL,
  entrega_id   INT UNSIGNED NULL,

  autor_id     INT UNSIGNED NOT NULL,

  texto        TEXT NOT NULL,
  privado      TINYINT(1) NOT NULL DEFAULT 0,

  criado_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (atividade_id)
    REFERENCES atividades(id)
    ON DELETE CASCADE,

  FOREIGN KEY (entrega_id)
    REFERENCES entregas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (autor_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE,

  CHECK (
    (atividade_id IS NOT NULL) +
    (entrega_id IS NOT NULL) = 1
  )
) ENGINE=InnoDB;


-- =========================================================
-- AULAS
-- =========================================================

CREATE TABLE aulas (
  id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  turma_disciplina_id INT UNSIGNED NOT NULL,
  data_aula           DATE NOT NULL,
  conteudo            VARCHAR(255) NULL,

  UNIQUE KEY uq_aula (
    turma_disciplina_id,
    data_aula
  ),

  FOREIGN KEY (turma_disciplina_id)
    REFERENCES turma_disciplinas(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- PRESENÇAS
-- =========================================================

CREATE TABLE presencas (
  aula_id  INT UNSIGNED NOT NULL,
  aluno_id INT UNSIGNED NOT NULL,

  situacao ENUM(
    'presente',
    'falta',
    'justificada'
  ) NOT NULL DEFAULT 'presente',

  PRIMARY KEY (aula_id, aluno_id),

  FOREIGN KEY (aula_id)
    REFERENCES aulas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (aluno_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- EVENTOS
-- =========================================================

CREATE TABLE eventos (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  turma_id     INT UNSIGNED NULL,
  atividade_id INT UNSIGNED NULL,
  criador_id   INT UNSIGNED NOT NULL,

  titulo       VARCHAR(150) NOT NULL,
  descricao    TEXT NULL,

  tipo         ENUM(
                 'aula',
                 'prova',
                 'entrega',
                 'reuniao',
                 'feriado',
                 'outro'
               ) NOT NULL DEFAULT 'outro',

  inicio       DATETIME NOT NULL,
  fim          DATETIME NULL,

  INDEX idx_evento_inicio (inicio),

  FOREIGN KEY (turma_id)
    REFERENCES turmas(id)
    ON DELETE CASCADE,

  FOREIGN KEY (atividade_id)
    REFERENCES atividades(id)
    ON DELETE CASCADE,

  FOREIGN KEY (criador_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- NOTIFICAÇÕES
-- =========================================================

CREATE TABLE notificacoes (
  id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  usuario_id INT UNSIGNED NOT NULL,

  tipo       ENUM(
               'nova_atividade',
               'nota',
               'prazo',
               'mensagem',
               'aviso',
               'sistema'
             ) NOT NULL,

  titulo     VARCHAR(150) NOT NULL,
  mensagem   VARCHAR(255) NULL,
  link       VARCHAR(255) NULL,

  lida       TINYINT(1) NOT NULL DEFAULT 0,

  criada_em  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  INDEX idx_notif_usuario (
    usuario_id,
    lida,
    criada_em
  ),

  FOREIGN KEY (usuario_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE
) ENGINE=InnoDB;


-- =========================================================
-- TAREFAS PESSOAIS
-- =========================================================

CREATE TABLE tarefas_pessoais (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  usuario_id   INT UNSIGNED NOT NULL,
  atividade_id INT UNSIGNED NULL,

  titulo       VARCHAR(150) NOT NULL,
  descricao    TEXT NULL,

  coluna       ENUM(
                 'a_fazer',
                 'fazendo',
                 'concluida'
               ) NOT NULL DEFAULT 'a_fazer',

  prioridade   ENUM(
                 'baixa',
                 'media',
                 'alta'
               ) NOT NULL DEFAULT 'media',

  prazo        DATE NULL,

  criada_em    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (usuario_id)
    REFERENCES alunos(id)
    ON DELETE CASCADE,

  FOREIGN KEY (atividade_id)
    REFERENCES atividades(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;


-- =========================================================
-- LOG DE AUDITORIA
-- =========================================================

CREATE TABLE log_auditoria (
  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

  usuario_id  INT UNSIGNED NULL,

  acao        VARCHAR(60) NOT NULL,
  entidade    VARCHAR(60) NOT NULL,
  entidade_id BIGINT UNSIGNED NULL,

  ip          VARCHAR(45) NULL,

  criado_em   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (usuario_id)
    REFERENCES alunos(id)
    ON DELETE SET NULL
) ENGINE=InnoDB;


-- =========================================================
-- TRIGGERS
-- =========================================================

DELIMITER $$


-- ---------------------------------------------------------
-- Atualiza automaticamente o status da entrega
-- ---------------------------------------------------------

CREATE TRIGGER trg_entregas_bi
BEFORE INSERT ON entregas
FOR EACH ROW
BEGIN
  DECLARE v_limite DATETIME;

  IF NEW.status IN ('entregue', 'atrasada') THEN

    IF NEW.enviado_em IS NULL THEN
      SET NEW.enviado_em = NOW();
    END IF;

    SELECT data_limite
      INTO v_limite
      FROM atividades
     WHERE id = NEW.atividade_id;

    IF v_limite IS NOT NULL
       AND NEW.enviado_em > v_limite THEN

      SET NEW.status = 'atrasada';

    ELSE

      SET NEW.status = 'entregue';

    END IF;

  END IF;
END$$


-- ---------------------------------------------------------
-- Notifica alunos quando uma atividade publicada é criada
-- ---------------------------------------------------------

CREATE TRIGGER trg_atividades_ai
AFTER INSERT ON atividades
FOR EACH ROW
BEGIN

  IF NEW.status = 'publicada' THEN

    INSERT INTO notificacoes (
      usuario_id,
      tipo,
      titulo,
      mensagem
    )

    SELECT
      ta.aluno_id,
      'nova_atividade',
      'Nova atividade',
      NEW.titulo

    FROM turma_disciplinas td

    INNER JOIN turma_alunos ta
      ON ta.turma_id = td.turma_id

    WHERE td.id = NEW.turma_disciplina_id;

  END IF;

END$$


-- ---------------------------------------------------------
-- Notifica aluno quando uma nota é lançada/alterada
-- ---------------------------------------------------------

CREATE TRIGGER trg_entregas_au
AFTER UPDATE ON entregas
FOR EACH ROW
BEGIN

  IF NEW.nota IS NOT NULL
     AND (
       OLD.nota IS NULL
       OR OLD.nota <> NEW.nota
     ) THEN

    INSERT INTO notificacoes (
      usuario_id,
      tipo,
      titulo,
      mensagem
    )

    VALUES (
      NEW.aluno_id,
      'nota',
      'Nota lançada',
      CONCAT('Sua nota: ', NEW.nota)
    );

  END IF;

END$$


DELIMITER ;


-- =========================================================
-- VIEWS
-- =========================================================

-- Entregas por status
CREATE OR REPLACE VIEW vw_status_entregas_aluno AS
SELECT
  aluno_id,
  status,
  COUNT(*) AS total
FROM entregas
GROUP BY
  aluno_id,
  status;


-- Entregas por mês
CREATE OR REPLACE VIEW vw_entregas_mensais AS
SELECT
  a.turma_disciplina_id,
  DATE_FORMAT(e.enviado_em, '%Y-%m') AS mes,
  COUNT(*) AS total

FROM entregas e

INNER JOIN atividades a
  ON a.id = e.atividade_id

WHERE e.enviado_em IS NOT NULL

GROUP BY
  a.turma_disciplina_id,
  mes;


-- Média por aluno e disciplina
CREATE OR REPLACE VIEW vw_media_aluno_disciplina AS
SELECT
  e.aluno_id,
  td.id AS turma_disciplina_id,
  d.nome AS disciplina,
  d.cor_hex,

  ROUND(
    AVG(
      CASE
        WHEN a.pontos > 0
        THEN (e.nota / a.pontos) * 10
        ELSE NULL
      END
    ),
    2
  ) AS media

FROM entregas e

INNER JOIN atividades a
  ON a.id = e.atividade_id

INNER JOIN turma_disciplinas td
  ON td.id = a.turma_disciplina_id

INNER JOIN disciplinas d
  ON d.id = td.disciplina_id

WHERE e.nota IS NOT NULL

GROUP BY
  e.aluno_id,
  td.id,
  d.nome,
  d.cor_hex;


-- Atividades por tipo
CREATE OR REPLACE VIEW vw_atividades_por_tipo AS
SELECT
  turma_disciplina_id,
  tipo,
  COUNT(*) AS total

FROM atividades

WHERE status <> 'rascunho'

GROUP BY
  turma_disciplina_id,
  tipo;


-- Próximas entregas
CREATE OR REPLACE VIEW vw_proximas_entregas AS
SELECT
  e.aluno_id,
  a.id AS atividade_id,
  a.titulo,
  a.tipo,
  a.data_limite,
  d.nome AS disciplina,
  d.cor_hex,
  e.status

FROM entregas e

INNER JOIN atividades a
  ON a.id = e.atividade_id

INNER JOIN turma_disciplinas td
  ON td.id = a.turma_disciplina_id

INNER JOIN disciplinas d
  ON d.id = td.disciplina_id

WHERE
  e.status = 'pendente'
  AND a.status = 'publicada'

ORDER BY
  a.data_limite;


-- Frequência por aluno e disciplina
CREATE OR REPLACE VIEW vw_frequencia AS
SELECT
  p.aluno_id,
  au.turma_disciplina_id,

  ROUND(
    100 * SUM(
      CASE
        WHEN p.situacao <> 'falta'
        THEN 1
        ELSE 0
      END
    ) / COUNT(*),
    1
  ) AS pct_presenca

FROM presencas p

INNER JOIN aulas au
  ON au.id = p.aula_id

GROUP BY
  p.aluno_id,
  au.turma_disciplina_id;


-- =========================================================
-- DADOS INICIAIS
-- =========================================================

-- ---------------------------------------------------------
-- Usuários
-- ---------------------------------------------------------

INSERT INTO alunos (
  nome,
  email,
  senha_hash,
  tipo,
  matricula
)
VALUES
(
  'Administrador',
  'admin@escola.com',
  '$123',
  'admin',
  NULL
),
(
  'Marina Costa',
  'marina@escola.com',
  'teste2',
  'professor',
  NULL
),
(
  'Ricardo Lima',
  'ricardo@escola.com',
  'teste3',
  'professor',
  NULL
),
(
  'Ana Souza',
  'ana@aluno.com',
  'teste4',
  'aluno',
  '2026001'
),
(
  'Bruno Alves',
  'bruno@aluno.com',
  '$teste5',
  'aluno',
  '2026002'
)


-- ---------------------------------------------------------
-- Turma
-- ---------------------------------------------------------

INSERT INTO turmas (
  nome,
  serie,
  turno,
  ano_letivo
)
VALUES (
  '3º A',
  'Ensino Médio',
  'manha',
  2026
);


-- ---------------------------------------------------------
-- Disciplinas
-- ---------------------------------------------------------

INSERT INTO disciplinas (
  nome,
  cor_hex
)
VALUES
(
  'Matemática',
  '#4F46E5'
),
(
  'História',
  '#F59E0B'
),
(
  'Português',
  '#10B981'
);


-- ---------------------------------------------------------
-- Períodos letivos
-- ---------------------------------------------------------

INSERT INTO periodos_letivos (
  ano,
  nome,
  data_inicio,
  data_fim
)
VALUES
(
  2026,
  '1º Bimestre',
  '2026-02-02',
  '2026-04-10'
),
(
  2026,
  '2º Bimestre',
  '2026-04-13',
  '2026-06-30'
),
(
  2026,
  '3º Bimestre',
  '2026-08-03',
  '2026-10-09'
),
(
  2026,
  '4º Bimestre',
  '2026-10-13',
  '2026-12-18'
);


-- ---------------------------------------------------------
-- Alunos da turma
-- ---------------------------------------------------------

INSERT INTO turma_alunos (
  turma_id,
  aluno_id,
  papel
)
VALUES
(
  1,
  4,
  'representante'
),
(
  1,
  5,
  'aluno'
),
(
  1,
  6,
  'aluno'
);


-- ---------------------------------------------------------
-- Disciplinas da turma
-- Professores:
-- 2 = Marina
-- 3 = Ricardo
-- ---------------------------------------------------------

INSERT INTO turma_disciplinas (
  turma_id,
  disciplina_id,
  professor_id
)
VALUES
(
  1,
  1,
  2
),
(
  1,
  2,
  3
),
(
  1,
  3,
  2
);


-- ---------------------------------------------------------
-- Canais
-- ---------------------------------------------------------

INSERT INTO canais (
  turma_disciplina_id,
  nome,
  tipo
)
VALUES
(
  1,
  'Geral',
  'geral'
),
(
  1,
  'Dúvidas',
  'duvidas'
),
(
  2,
  'Geral',
  'geral'
);


-- ---------------------------------------------------------
-- Atividades
-- ---------------------------------------------------------

INSERT INTO atividades (
  turma_disciplina_id,
  periodo_id,
  criador_id,
  titulo,
  descricao,
  tipo,
  status,
  em_grupo,
  pontos,
  publicada_em,
  data_limite
)
VALUES
(
  1,
  3,
  2,
  'Lista de exercícios — Funções',
  'Resolver os exercícios 1 a 15.',
  'tarefa',
  'publicada',
  0,
  10,
  NOW(),
  '2026-10-10 23:59:00'
),
(
  2,
  3,
  3,
  'Trabalho: Revolução Industrial',
  'Pesquisa em grupo com apresentação.',
  'trabalho',
  'publicada',
  1,
  20,
  NOW(),
  '2026-10-20 23:59:00'
),
(
  1,
  3,
  2,
  'Prova bimestral de Matemática',
  'Conteúdo: funções e geometria.',
  'prova',
  'publicada',
  0,
  10,
  NOW(),
  '2026-10-05 08:00:00'
);


-- ---------------------------------------------------------
-- Entregas
-- ---------------------------------------------------------

INSERT INTO entregas (
  atividade_id,
  aluno_id,
  status,
  enviado_em,
  nota,
  corrigido_por,
  corrigido_em
)
VALUES
(
  1,
  4,
  'entregue',
  '2026-09-25 14:00:00',
  NULL,
  NULL,
  NULL
),
(
  1,
  5,
  'entregue',
  NOW(),
  NULL,
  NULL,
  NULL
),
(
  1,
  6,
  'pendente',
  NULL,
  NULL,
  NULL,
  NULL
),
(
  2,
  4,
  'pendente',
  NULL,
  NULL,
  NULL,
  NULL
),
(
  2,
  5,
  'pendente',
  NULL,
  NULL,
  NULL,
  NULL
),
(
  2,
  6,
  'pendente',
  NULL,
  NULL,
  NULL,
  NULL
);


-- ---------------------------------------------------------
-- Corrigir entrega da Ana
-- ---------------------------------------------------------

UPDATE entregas
SET
  status = 'corrigida',
  nota = 9.0,
  feedback = 'Ótimo trabalho!',
  corrigido_por = 2,
  corrigido_em = NOW()
WHERE
  atividade_id = 1
  AND aluno_id = 4;


-- ---------------------------------------------------------
-- Evento
-- ---------------------------------------------------------

INSERT INTO eventos (
  turma_id,
  atividade_id,
  criador_id,
  titulo,
  tipo,
  inicio
)
VALUES (
  1,
  3,
  2,
  'Prova bimestral de Matemática',
  'prova',
  '2026-10-05 08:00:00'
);


-- ---------------------------------------------------------
-- Aviso
-- ---------------------------------------------------------

INSERT INTO avisos (
  turma_id,
  autor_id,
  titulo,
  conteudo,
  fixado
)
VALUES (
  1,
  2,
  'Bem-vindos ao 3º bimestre',
  'Confiram o calendário de provas no mural.',
  1
);


-- ---------------------------------------------------------
-- Tarefa pessoal
-- ---------------------------------------------------------

INSERT INTO tarefas_pessoais (
  usuario_id,
  atividade_id,
  titulo,
  coluna,
  prioridade,
  prazo
)
VALUES (
  4,
  2,
  'Pesquisar sobre a Revolução Industrial',
  'fazendo',
  'alta',
  '2026-10-15'
);


-- =========================================================
-- FINALIZAÇÃO
-- =========================================================

SET FOREIGN_KEY_CHECKS = 1;
