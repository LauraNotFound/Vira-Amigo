-- 1. Registrar uma denúncia, associada a um cidadão existente quando o CPF for informado, verificando se o local e o status estão disponíveis.
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
    IF p_cpf_cidadao IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM CIDADAO WHERE CPF = p_cpf_cidadao
    ) THEN
        RAISE EXCEPTION 'Não há um cidadão com o CPF informado.';
    END IF;

    IF p_local_evento IS NULL OR TRIM(p_local_evento) = '' THEN
        RAISE EXCEPTION 'Informe o local da denúncia.';
    END IF;

    IF p_status IS NULL OR TRIM(p_status) = '' THEN
        RAISE EXCEPTION 'Informe o status da denúncia.';
    END IF;

    INSERT INTO DENUNCIA (
        local_evento, telefone, status, descricao, data_hora, gravidade, canal_origem, CPF_cidadao
    ) VALUES (
        p_local_evento,
        p_telefone,
        p_status,
        p_descricao,
        COALESCE(p_data_hora, CURRENT_TIMESTAMP),
        p_gravidade,
        p_canal_origem,
        p_cpf_cidadao
    );
END;
$$;

-- 2. Registrar um resgate, associado a um agente de campo existente quando o CPF for informado, verificando se o animal e a denúncia estão disponíveis.
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
    IF p_data_hora IS NULL THEN
        RAISE EXCEPTION 'Informe a data do resgate.';
    END IF;

    IF p_cpf_agente IS NULL OR NOT EXISTS (
        SELECT 1 FROM AGENTE_CAMPO WHERE CPF = p_cpf_agente
    ) THEN
        RAISE EXCEPTION 'Não há um agente de campo com o CPF informado.';
    END IF;

    IF p_id_animal IS NULL OR NOT EXISTS (
        SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal
    ) THEN
        RAISE EXCEPTION 'Não há um animal com esse identificador.';
    END IF;

    IF p_id_denuncia IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM DENUNCIA WHERE id_denuncia = p_id_denuncia
    ) THEN
        RAISE EXCEPTION 'Não há uma denúncia com esse identificador.';
    END IF;

    IF p_id_denuncia IS NOT NULL AND EXISTS (
        SELECT 1 FROM RESGATE WHERE id_denuncia = p_id_denuncia
    ) THEN
        RAISE EXCEPTION 'Essa denúncia já tem um resgate.';
    END IF;

    INSERT INTO RESGATE (
        precaucoes, condicao_fisica, proced_local, data_hora,
        local_destino, observacoes, id_denuncia, CPF_agente
    ) VALUES (
        p_precaucoes, p_condicao_fisica, p_proced_local, p_data_hora,
        p_local_destino, p_observacoes, p_id_denuncia, p_cpf_agente
    )
    RETURNING id_resgate INTO v_id_resgate;

    INSERT INTO INTERVENCAO (
        id_animal, id_resgate, CPF_agente, desfecho, motivacao, coord_abordagem, coord_soltura
    ) VALUES (
        p_id_animal, v_id_resgate, p_cpf_agente,
        p_desfecho, p_motivacao, p_coord_abordagem, p_coord_soltura
    );
END;
$$;

-- 3. Registrar um atendimento médico, associado a um veterinário existente quando o CPF for informado, verificando se o animal e o estabelecimento estão disponíveis.

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
    IF p_data_hora IS NULL THEN
        RAISE EXCEPTION 'Informe a data do atendimento.';
    END IF;

    IF p_id_animal IS NULL OR NOT EXISTS (
        SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal
    ) THEN
        RAISE EXCEPTION 'Não há um animal com esse identificador.';
    END IF;

    IF p_cpf_veterinario IS NULL OR NOT EXISTS (
        SELECT 1 FROM VETERINARIO WHERE CPF = p_cpf_veterinario
    ) THEN
        RAISE EXCEPTION 'Não há um veterinário com o CPF informado.';
    END IF;

    IF p_id_estabelecimento IS NULL OR NOT EXISTS (
        SELECT 1 FROM ESTABELECIMENTO_VET WHERE id_estabelecimento = p_id_estabelecimento
    ) THEN
        RAISE EXCEPTION 'Não há um estabelecimento com esse identificador.';
    END IF;

    INSERT INTO ATENDIMENTO_MEDICO (
        id_animal, CPF_veterinario, id_estabelecimento, motivo,
        data_hora, peso, prescricao, sinais_vitais, estado
    ) VALUES (
        p_id_animal, p_cpf_veterinario, p_id_estabelecimento, p_motivo,
        p_data_hora, p_peso, p_prescricao, p_sinais_vitais, p_estado
    );
END;
$$;

-- 4. Registrar uma aplicação de vacina, associada a um animal existente quando o identificador for informado, verificando se a vacina está disponível.
CREATE OR REPLACE PROCEDURE sp_registrar_aplicacao_vacina(
    p_id_animal         INTEGER,
    p_id_vacina         INTEGER,
    p_data_aplicacao    DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_id_animal IS NULL OR NOT EXISTS (
        SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal
    ) THEN
        RAISE EXCEPTION 'Não há um animal com esse identificador.';
    END IF;

    IF p_id_vacina IS NULL OR NOT EXISTS (
        SELECT 1 FROM VACINA WHERE id_vacina = p_id_vacina
    ) THEN
        RAISE EXCEPTION 'Não há uma vacina com esse identificador.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM APLICACAO_VACINA
        WHERE id_animal = p_id_animal
          AND id_vacina = p_id_vacina
    ) THEN
        RAISE EXCEPTION 'Essa vacina já está registrada para este animal.';
    END IF;

    INSERT INTO APLICACAO_VACINA (id_animal, id_vacina, data_aplicacao)
    VALUES (p_id_animal, p_id_vacina, COALESCE(p_data_aplicacao, CURRENT_DATE));
END;
$$;

-- 5. Registrar uma adoção, associada a um cidadão existente quando o CPF for informado, verificando se o animal e o analista de adoção estão disponíveis.

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
    IF p_data_adocao IS NULL THEN
        RAISE EXCEPTION 'Informe a data de adoção.';
    END IF;

    IF p_id_animal IS NULL OR NOT EXISTS (
        SELECT 1 FROM ANIMAL WHERE id_animal = p_id_animal
    ) THEN
        RAISE EXCEPTION 'Não há um animal com esse identificador.';
    END IF;

    IF p_cpf_cidadao IS NULL OR NOT EXISTS (
        SELECT 1 FROM CIDADAO WHERE CPF = p_cpf_cidadao
    ) THEN
        RAISE EXCEPTION 'Não há um cidadão com o CPF informado.';
    END IF;

    IF p_cpf_analista IS NULL OR NOT EXISTS (
        SELECT 1 FROM ANALISTA_ADOCAO WHERE CPF = p_cpf_analista
    ) THEN
        RAISE EXCEPTION 'Não há um analista de adoção com o CPF informado.';
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
