CREATE TABLE PESSOA (
    CPF         CHAR(11) PRIMARY KEY CHECK (CPF ~ '^[0-9]{11}$'),
    nome        VARCHAR(150) NOT NULL,
    CEP         CHAR(8) CHECK (CEP ~ '^[0-9]{8}$'),
    logradouro  VARCHAR(150),
    numero      VARCHAR(20),
    bairro      VARCHAR(100),
    cidade      VARCHAR(100)
);

CREATE TABLE PESSOA_TELEFONE (
    CPF         CHAR(11) NOT NULL,
    telefone    VARCHAR(20) NOT NULL,
    PRIMARY KEY (CPF, telefone),
    FOREIGN KEY (CPF) REFERENCES PESSOA(CPF) ON DELETE CASCADE
);

CREATE TABLE CIDADAO (
    CPF         CHAR(11) PRIMARY KEY,
    sexo        VARCHAR(20),
    FOREIGN KEY (CPF) REFERENCES PESSOA(CPF) ON DELETE CASCADE
);

CREATE TABLE DEPARTAMENTO (
    id_departamento SERIAL PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    sigla           VARCHAR(15) NOT NULL UNIQUE,
    ramal           VARCHAR(10)
);

CREATE TABLE FUNCIONARIO (
    CPF             CHAR(11) PRIMARY KEY,
    matricula       VARCHAR(30) NOT NULL UNIQUE,
    carga_horaria   INTEGER CHECK (carga_horaria > 0),
    data_admissao   DATE NOT NULL,
    id_departamento INTEGER NOT NULL,
    FOREIGN KEY (CPF) REFERENCES PESSOA(CPF) ON DELETE CASCADE,
    FOREIGN KEY (id_departamento) REFERENCES DEPARTAMENTO(id_departamento) ON DELETE RESTRICT
);

CREATE TABLE VETERINARIO (
    CPF             CHAR(11) PRIMARY KEY,
    CRMV            VARCHAR(30) NOT NULL UNIQUE,
    especialidade   VARCHAR(100),
    FOREIGN KEY (CPF) REFERENCES FUNCIONARIO(CPF) ON DELETE CASCADE
);

CREATE TABLE ANALISTA_ADOCAO (
    CPF             CHAR(11) PRIMARY KEY,
    CNH             VARCHAR(20) NOT NULL UNIQUE,
    FOREIGN KEY (CPF) REFERENCES FUNCIONARIO(CPF) ON DELETE CASCADE
);

CREATE TABLE AGENTE_CAMPO (
    CPF                 CHAR(11) PRIMARY KEY,
    registro_conselho   VARCHAR(30) UNIQUE,
    credencial          VARCHAR(30) NOT NULL UNIQUE,
    categoria_cnh       VARCHAR(5),
    FOREIGN KEY (CPF) REFERENCES FUNCIONARIO(CPF) ON DELETE CASCADE
);

-- 1.2. Abrigos Públicos e Contratos
CREATE TABLE ABRIGO_PUBLICO (
    id_instituicao      SERIAL PRIMARY KEY,
    nome                VARCHAR(150) NOT NULL,
    email               VARCHAR(150),
    orcamento_mensal    NUMERIC(12, 2) CHECK (orcamento_mensal >= 0),
    nome_diretor        VARCHAR(150),
    CEP                 CHAR(8) CHECK (CEP ~ '^[0-9]{8}$'),
    bairro              VARCHAR(100),
    cidade              VARCHAR(100),
    logradouro          VARCHAR(150)
);

CREATE TABLE ABRIGO_TELEFONE (
    id_instituicao  INTEGER NOT NULL,
    telefone        VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_instituicao, telefone),
    FOREIGN KEY (id_instituicao) REFERENCES ABRIGO_PUBLICO(id_instituicao) ON DELETE CASCADE
);

CREATE TABLE CONTRATO (
    id_contrato     SERIAL PRIMARY KEY,
    valor_total     NUMERIC(12, 2) NOT NULL CHECK (valor_total > 0),
    data_assinatura DATE NOT NULL,
    data_vigencia   DATE NOT NULL CHECK (data_vigencia >= data_assinatura),
    CPF_funcionario CHAR(11) NOT NULL,
    id_instituicao  INTEGER NOT NULL,
    FOREIGN KEY (CPF_funcionario) REFERENCES FUNCIONARIO(CPF) ON DELETE RESTRICT,
    FOREIGN KEY (id_instituicao) REFERENCES ABRIGO_PUBLICO(id_instituicao) ON DELETE RESTRICT
);

-- 1.3. Denúncias, Resgates e Animais
CREATE TABLE FORM_AVALIACAO (
    id_formulario       SERIAL PRIMARY KEY,
    data_hora           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tamanho_residencia  VARCHAR(50),
    tipo_residencia     VARCHAR(50),
    qtd_pessoas         INTEGER CHECK (qtd_pessoas >= 0),
    qtd_animais         INTEGER CHECK (qtd_animais >= 0),
    solvencia_econ      VARCHAR(100),
    CPF_cidadao         CHAR(11) NOT NULL,
    FOREIGN KEY (CPF_cidadao) REFERENCES CIDADAO(CPF) ON DELETE CASCADE
);

CREATE TABLE DENUNCIA (
    id_denuncia     SERIAL PRIMARY KEY,
    local_evento    VARCHAR(255) NOT NULL,
    telefone        VARCHAR(20),
    status          VARCHAR(50) NOT NULL,
    descricao       TEXT,
    data_hora       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    gravidade       VARCHAR(30),
    canal_origem    VARCHAR(50),
    CPF_cidadao     CHAR(11),
    FOREIGN KEY (CPF_cidadao) REFERENCES CIDADAO(CPF) ON DELETE SET NULL
);

CREATE TABLE RESGATE (
    id_resgate      SERIAL PRIMARY KEY,
    precaucoes      TEXT,
    condicao_fisica TEXT,
    proced_local    TEXT,
    data_hora       TIMESTAMP NOT NULL,
    local_destino   VARCHAR(255),
    observacoes     TEXT,
    id_denuncia     INTEGER UNIQUE,
    CPF_agente      CHAR(11) NOT NULL,
    FOREIGN KEY (id_denuncia) REFERENCES DENUNCIA(id_denuncia) ON DELETE RESTRICT,
    FOREIGN KEY (CPF_agente) REFERENCES AGENTE_CAMPO(CPF) ON DELETE RESTRICT
);

CREATE TABLE ANIMAL (
    id_animal       SERIAL PRIMARY KEY,
    nome            VARCHAR(100),
    cor_pelagem     VARCHAR(60),
    raca            VARCHAR(80),
    porte           VARCHAR(30),
    data_nasc       DATE,
    sexo            VARCHAR(20),
    temperamento    VARCHAR(100),
    CPF_cidadao     CHAR(11),
    id_instituicao  INTEGER,
    FOREIGN KEY (CPF_cidadao) REFERENCES CIDADAO(CPF) ON DELETE SET NULL,
    FOREIGN KEY (id_instituicao) REFERENCES ABRIGO_PUBLICO(id_instituicao) ON DELETE SET NULL,
    CONSTRAINT chk_animal_guarda_exclusiva CHECK (
        NOT (CPF_cidadao IS NOT NULL AND id_instituicao IS NOT NULL)
    )
);

CREATE TABLE INTERVENCAO (
    id_animal       INTEGER NOT NULL,
    id_resgate      INTEGER NOT NULL,
    CPF_agente      CHAR(11) NOT NULL,
    desfecho        VARCHAR(150),
    motivacao       TEXT,
    coord_abordagem VARCHAR(60),
    coord_soltura   VARCHAR(60),
    PRIMARY KEY (id_animal, id_resgate, CPF_agente),
    FOREIGN KEY (id_animal) REFERENCES ANIMAL(id_animal) ON DELETE CASCADE,
    FOREIGN KEY (id_resgate) REFERENCES RESGATE(id_resgate) ON DELETE CASCADE,
    FOREIGN KEY (CPF_agente) REFERENCES AGENTE_CAMPO(CPF) ON DELETE RESTRICT
);

CREATE TABLE REGISTRO_ADOCAO (
    id_registro             SERIAL PRIMARY KEY,
    id_animal               INTEGER NOT NULL,
    CPF_cidadao             CHAR(11) NOT NULL,
    CPF_analista            CHAR(11) NOT NULL,
    data_adocao             DATE NOT NULL,
    status_acompanhamento   VARCHAR(50),
    desfecho                VARCHAR(150),
    motivacao               TEXT,
    observacoes_vistoria    TEXT,
    FOREIGN KEY (id_animal) REFERENCES ANIMAL(id_animal) ON DELETE RESTRICT,
    FOREIGN KEY (CPF_cidadao) REFERENCES CIDADAO(CPF) ON DELETE RESTRICT,
    FOREIGN KEY (CPF_analista) REFERENCES ANALISTA_ADOCAO(CPF) ON DELETE RESTRICT
);

-- 1.4. Saúde Veterinária, Vacinação e Procedimentos Clínicos
CREATE TABLE VACINA (
    id_vacina   SERIAL PRIMARY KEY,
    nome        VARCHAR(100) NOT NULL,
    fabricante  VARCHAR(100)
);

CREATE TABLE VACINA_DOENCAS_ALVO (
    id_vacina   INTEGER NOT NULL,
    doenca_alvo VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_vacina, doenca_alvo),
    FOREIGN KEY (id_vacina) REFERENCES VACINA(id_vacina) ON DELETE CASCADE
);

CREATE TABLE APLICACAO_VACINA (
    id_animal       INTEGER NOT NULL,
    id_vacina       INTEGER NOT NULL,
    data_aplicacao  DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_animal, id_vacina),
    FOREIGN KEY (id_animal) REFERENCES ANIMAL(id_animal) ON DELETE CASCADE,
    FOREIGN KEY (id_vacina) REFERENCES VACINA(id_vacina) ON DELETE RESTRICT
);

CREATE TABLE ESTABELECIMENTO_VET (
    id_estabelecimento      SERIAL PRIMARY KEY,
    razao_social            VARCHAR(150) NOT NULL,
    tipo                    VARCHAR(60),
    telefone_emergencia     VARCHAR(20),
    horario_funcionamento   VARCHAR(100),
    endereco_comp           VARCHAR(255)
);

CREATE TABLE ATENDIMENTO_MEDICO (
    id_atendimento      SERIAL PRIMARY KEY,
    id_animal           INTEGER NOT NULL,
    CPF_veterinario     CHAR(11) NOT NULL,
    id_estabelecimento  INTEGER NOT NULL,
    motivo              TEXT,
    data_hora           TIMESTAMP NOT NULL,
    peso                NUMERIC(6, 2) CHECK (peso > 0),
    prescricao          TEXT,
    sinais_vitais       TEXT,
    estado              VARCHAR(60),
    FOREIGN KEY (id_animal) REFERENCES ANIMAL(id_animal) ON DELETE RESTRICT,
    FOREIGN KEY (CPF_veterinario) REFERENCES VETERINARIO(CPF) ON DELETE RESTRICT,
    FOREIGN KEY (id_estabelecimento) REFERENCES ESTABELECIMENTO_VET(id_estabelecimento) ON DELETE RESTRICT
);

CREATE TABLE EXAME (
    id_exame        SERIAL PRIMARY KEY,
    tipo            VARCHAR(100) NOT NULL,
    preparo_previo  TEXT
);

CREATE TABLE ATENDIMENTO_EXAME (
    id_atendimento  INTEGER NOT NULL,
    id_exame        INTEGER NOT NULL,
    situacao        VARCHAR(50),
    resultados      TEXT,
    PRIMARY KEY (id_atendimento, id_exame),
    FOREIGN KEY (id_atendimento) REFERENCES ATENDIMENTO_MEDICO(id_atendimento) ON DELETE CASCADE,
    FOREIGN KEY (id_exame) REFERENCES EXAME(id_exame) ON DELETE RESTRICT
);

CREATE TABLE CIRURGIA (
    id_cirurgia     SERIAL PRIMARY KEY,
    nome            VARCHAR(120) NOT NULL,
    risco_padrao    VARCHAR(50)
);

CREATE TABLE ATENDIMENTO_CIRURGIA (
    id_atendimento  INTEGER NOT NULL,
    id_cirurgia     INTEGER NOT NULL,
    situacao        VARCHAR(50),
    resultados      TEXT,
    PRIMARY KEY (id_atendimento, id_cirurgia),
    FOREIGN KEY (id_atendimento) REFERENCES ATENDIMENTO_MEDICO(id_atendimento) ON DELETE CASCADE,
    FOREIGN KEY (id_cirurgia) REFERENCES CIRURGIA(id_cirurgia) ON DELETE RESTRICT
);

-- 1.5. Campanhas e Conscientização
CREATE TABLE CAMPANHA (
    id_campanha SERIAL PRIMARY KEY,
    nome        VARCHAR(150) NOT NULL,
    tipo        VARCHAR(60),
    data        DATE,
    local       VARCHAR(200),
    duracao     INTEGER CHECK (duracao > 0),
    descricao   TEXT,
    CPF_agente  CHAR(11) NOT NULL,
    FOREIGN KEY (CPF_agente) REFERENCES AGENTE_CAMPO(CPF) ON DELETE RESTRICT
);

CREATE TABLE ACAO_CONSCIENTIZACAO (
    id_acao             SERIAL PRIMARY KEY,
    objetivo            TEXT,
    publico_alvo        VARCHAR(120),
    resultados          TEXT,
    situacao            VARCHAR(50),
    qtd_participantes   INTEGER CHECK (qtd_participantes >= 0),
    id_campanha         INTEGER NOT NULL,
    FOREIGN KEY (id_campanha) REFERENCES CAMPANHA(id_campanha) ON DELETE CASCADE
);