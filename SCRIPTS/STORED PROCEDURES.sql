-- 3.1. Registrar denuncia
CREATE OR REPLACE PROCEDURE sp_registrar_denuncia(
    p_cpf_cidadao   CHAR(11),
    p_local_evento  VARCHAR(255),
    p_telefone      VARCHAR(20),
    p_status        VARCHAR(50),
    p_descricao     TEXT,
    p_data_hora     TIMESTAMP,
    p_gravidade     VARCHAR(30),
    p_canal_origem  VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_cpf_cidadao IS NULL OR NOT EXISTS (SELECT 1 FROM CIDADAO WHERE CPF = p_cpf_cidadao) THEN
        RAISE EXCEPTION 'El ciudadano con CPF % no existe en el sistema.', COALESCE(p_cpf_cidadao, 'NULL');
    END IF;

    IF p_local_evento IS NULL OR TRIM(p_local_evento) = '' THEN
        RAISE EXCEPTION 'El local del evento es obligatorio.';
    END IF;

    IF p_status IS NULL OR TRIM(p_status) = '' THEN
        RAISE EXCEPTION 'El estado de la denuncia es obligatorio.';
    END IF;

    INSERT INTO DENUNCIA (
        local_evento, telefone, status, descricao, data_hora, gravidade, canal_origem, CPF_cidadao
    ) VALUES (
        p_local_evento, p_telefone, p_status, p_descricao, COALESCE(p_data_hora, CURRENT_TIMESTAMP), p_gravidade, p_canal_origem, p_cpf_cidadao
    );
END;
$$;

-- 3.2. Registrar rescate y asociarlo con animal y entidades correspondientes
CREATE OR REPLACE PROCEDURE sp_registrar_resgate(
    p_id_denuncia       INTEGER,
    p_cpf_agente        CHAR(11),
    p_id_animal         INTEGER,
    p_data_hora         TIMESTAMP,
    p_proced_local      TEXT,
    p_condicao_fisica   TEXT,
    p_precaucoes        TEXT,
    p_local_destino     VARCHAR(255),
    p_observacoes       TEXT,
    p_desfecho          VARCHAR(150) DEFAULT NULL,
    p_motivacao         TEXT DEFAULT NULL,
    p_coord_abordagem   VARCHAR(60) DEFAULT NULL,
    p_coord_soltura     VARCHAR(60) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_resgate INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM AGENTE_CAMPO WHERE CPF = p_cpf_agente) THEN
        RAISE EXCEPTION 'El agente de campo con CPF % no existe.', p_cpf_agente;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal) THEN
        RAISE EXCEPTION 'El animal con ID % no existe.', p_id_animal;
    END IF;

    IF p_id_denuncia IS NOT NULL AND NOT EXISTS (SELECT 1 FROM DENUNCIA WHERE id_denuncia = p_id_denuncia) THEN
        RAISE EXCEPTION 'La denuncia con ID % no existe.', p_id_denuncia;
    END IF;

    INSERT INTO RESGATE (
        precaucoes, condicao_fisica, proced_local, data_hora, local_destino, observacoes, id_denuncia, CPF_agente
    ) VALUES (
        p_precaucoes, p_condicao_fisica, p_proced_local, p_data_hora, p_local_destino, p_observacoes, p_id_denuncia, p_cpf_agente
    )
    RETURNING id_resgate INTO v_id_resgate;

    INSERT INTO INTERVENCAO (
        id_animal, id_resgate, CPF_agente, desfecho, motivacao, coord_abordagem, coord_soltura
    ) VALUES (
        p_id_animal, v_id_resgate, p_cpf_agente, p_desfecho, p_motivacao, p_coord_abordagem, p_coord_soltura
    );
END;
$$;

-- 3.3. Registrar atención médica
CREATE OR REPLACE PROCEDURE sp_registrar_atendimento_medico(
    p_id_animal             INTEGER,
    p_cpf_veterinario       CHAR(11),
    p_id_estabelecimento    INTEGER,
    p_data_hora             TIMESTAMP,
    p_motivo                TEXT,
    p_peso                  NUMERIC(6, 2),
    p_prescricao            TEXT,
    p_sinais_vitais         TEXT,
    p_estado                VARCHAR(60)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal) THEN
        RAISE EXCEPTION 'El animal con ID % no existe.', p_id_animal;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM VETERINARIO WHERE CPF = p_cpf_veterinario) THEN
        RAISE EXCEPTION 'El veterinario con CPF % no existe.', p_cpf_veterinario;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ESTABELECIMENTO_VET WHERE id_estabelecimento = p_id_estabelecimento) THEN
        RAISE EXCEPTION 'El establecimiento veterinario con ID % no existe.', p_id_estabelecimento;
    END IF;

    INSERT INTO ATENDIMENTO_MEDICO (
        id_animal, CPF_veterinario, id_estabelecimento, motivo, data_hora, peso, prescricao, sinais_vitais, estado
    ) VALUES (
        p_id_animal, p_cpf_veterinario, p_id_estabelecimento, p_motivo, p_data_hora, p_peso, p_prescricao, p_sinais_vitais, p_estado
    );
END;
$$;

-- 3.4. Registrar aplicación de vacuna
CREATE OR REPLACE PROCEDURE sp_registrar_aplicacao_vacina(
    p_id_animal         INTEGER,
    p_id_vacina         INTEGER,
    p_data_aplicacao    DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal) THEN
        RAISE EXCEPTION 'El animal con ID % no existe.', p_id_animal;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM VACINA WHERE id_vacina = p_id_vacina) THEN
        RAISE EXCEPTION 'La vacuna con ID % no existe.', p_id_vacina;
    END IF;

    INSERT INTO APLICACAO_VACINA (id_animal, id_vacina, data_aplicacao)
    VALUES (p_id_animal, p_id_vacina, COALESCE(p_data_aplicacao, CURRENT_DATE));
END;
$$;

-- 3.5. Registrar adopción
CREATE OR REPLACE PROCEDURE sp_registrar_adocao(
    p_id_animal             INTEGER,
    p_cpf_cidadao           CHAR(11),
    p_cpf_analista          CHAR(11),
    p_data_adocao           DATE,
    p_status_acompanhamento VARCHAR(50),
    p_desfecho              VARCHAR(150) DEFAULT NULL,
    p_motivacao             TEXT DEFAULT NULL,
    p_observacoes_vistoria  TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal) THEN
        RAISE EXCEPTION 'El animal con ID % no existe.', p_id_animal;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM CIDADAO WHERE CPF = p_cpf_cidadao) THEN
        RAISE EXCEPTION 'El ciudadano adoptante con CPF % no existe.', p_cpf_cidadao;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM ANALISTA_ADOCAO WHERE CPF = p_cpf_analista) THEN
        RAISE EXCEPTION 'El analista de adopción con CPF % no existe.', p_cpf_analista;
    END IF;

    INSERT INTO REGISTRO_ADOCAO (
        id_animal, CPF_cidadao, CPF_analista, data_adocao,
        status_acompanhamento, desfecho, motivacao, observacoes_vistoria
    ) VALUES (
        p_id_animal, p_cpf_cidadao, p_cpf_analista, p_data_adocao,
        p_status_acompanhamento, p_desfecho, p_motivacao, p_observacoes_vistoria
    );

    UPDATE ANIMAL
    SET CPF_cidadao = p_cpf_cidadao,
        id_instituicao = NULL
    WHERE id_animal = p_id_animal;
END;
$$;