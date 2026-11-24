CREATE OR REPLACE FUNCTION fn_validar_exclusividade_pessoa()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'cidadao' AND EXISTS (SELECT 1 FROM FUNCIONARIO WHERE CPF = NEW.CPF) THEN
        RAISE EXCEPTION 'El CPF % ya está registrado como FUNCIONARIO (especialización exclusiva).', NEW.CPF;
    ELSIF TG_TABLE_NAME = 'funcionario' AND EXISTS (SELECT 1 FROM CIDADAO WHERE CPF = NEW.CPF) THEN
        RAISE EXCEPTION 'El CPF % ya está registrado como CIDADAO (especialización exclusiva).', NEW.CPF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_exclusividade_cidadao
BEFORE INSERT OR UPDATE ON CIDADAO
FOR EACH ROW EXECUTE FUNCTION fn_validar_exclusividade_pessoa();

CREATE OR REPLACE TRIGGER trg_exclusividade_funcionario
BEFORE INSERT OR UPDATE ON FUNCIONARIO
FOR EACH ROW EXECUTE FUNCTION fn_validar_exclusividade_pessoa();

-- 2.B. Exclusividad entre VETERINARIO, ANALISTA_ADOCAO y AGENTE_CAMPO
CREATE OR REPLACE FUNCTION fn_validar_exclusividade_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME <> 'veterinario' AND EXISTS (SELECT 1 FROM VETERINARIO WHERE CPF = NEW.CPF) THEN
        RAISE EXCEPTION 'El CPF % ya pertenece a VETERINARIO.', NEW.CPF;
    END IF;
    IF TG_TABLE_NAME <> 'analista_adocao' AND EXISTS (SELECT 1 FROM ANALISTA_ADOCAO WHERE CPF = NEW.CPF) THEN
        RAISE EXCEPTION 'El CPF % ya pertenece a ANALISTA_ADOCAO.', NEW.CPF;
    END IF;
    IF TG_TABLE_NAME <> 'agente_campo' AND EXISTS (SELECT 1 FROM AGENTE_CAMPO WHERE CPF = NEW.CPF) THEN
        RAISE EXCEPTION 'El CPF % ya pertenece a AGENTE_CAMPO.', NEW.CPF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_exclusividade_veterinario
BEFORE INSERT OR UPDATE ON VETERINARIO
FOR EACH ROW EXECUTE FUNCTION fn_validar_exclusividade_funcionario();

CREATE OR REPLACE TRIGGER trg_exclusividade_analista
BEFORE INSERT OR UPDATE ON ANALISTA_ADOCAO
FOR EACH ROW EXECUTE FUNCTION fn_validar_exclusividade_funcionario();

CREATE OR REPLACE TRIGGER trg_exclusividade_agente
BEFORE INSERT OR UPDATE ON AGENTE_CAMPO
FOR EACH ROW EXECUTE FUNCTION fn_validar_exclusividade_funcionario();

-- 2.1. Trigger: Validar fecha de nacimiento y aplicación de vacuna
CREATE OR REPLACE FUNCTION fn_validar_data_aplicacao_vacina()
RETURNS TRIGGER AS $$
DECLARE
    v_data_nasc DATE;
BEGIN
    SELECT data_nasc INTO v_data_nasc
    FROM ANIMAL
    WHERE id_animal = NEW.id_animal;

    IF v_data_nasc IS NOT NULL AND NEW.data_aplicacao < v_data_nasc THEN
        RAISE EXCEPTION 'La fecha de aplicación de vacuna (%) no puede ser anterior al nacimiento del animal (%).',
            NEW.data_aplicacao, v_data_nasc;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_data_aplicacao_vacina
BEFORE INSERT OR UPDATE ON APLICACAO_VACINA
FOR EACH ROW EXECUTE FUNCTION fn_validar_data_aplicacao_vacina();

-- 2.2. Trigger: Validar peso en atención médica (> 0)
CREATE OR REPLACE FUNCTION fn_validar_peso_atendimento()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.peso IS NULL OR NEW.peso <= 0 THEN
        RAISE EXCEPTION 'El peso del animal en la atención médica debe ser mayor que cero (valor recibido: %).',
            COALESCE(NEW.peso::TEXT, 'NULL');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_peso_atendimento
BEFORE INSERT OR UPDATE ON ATENDIMENTO_MEDICO
FOR EACH ROW EXECUTE FUNCTION fn_validar_peso_atendimento();

-- 2.3. Trigger: Validar fecha del rescate (>= fecha de la denuncia relacionada)
CREATE OR REPLACE FUNCTION fn_validar_data_resgate()
RETURNS TRIGGER AS $$
DECLARE
    v_data_denuncia TIMESTAMP;
BEGIN
    IF NEW.id_denuncia IS NOT NULL THEN
        SELECT data_hora INTO v_data_denuncia
        FROM DENUNCIA
        WHERE id_denuncia = NEW.id_denuncia;

        IF v_data_denuncia IS NOT NULL AND NEW.data_hora < v_data_denuncia THEN
            RAISE EXCEPTION 'La fecha del rescate (%) no puede ser anterior a la fecha de la denuncia (%).',
                NEW.data_hora, v_data_denuncia;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_data_resgate
BEFORE INSERT OR UPDATE ON RESGATE
FOR EACH ROW EXECUTE FUNCTION fn_validar_data_resgate();

-- 2.4. Trigger: Validar fecha de adopción (>= fecha de nacimiento del animal)
CREATE OR REPLACE FUNCTION fn_validar_data_adocao()
RETURNS TRIGGER AS $$
DECLARE
    v_data_nasc DATE;
BEGIN
    SELECT data_nasc INTO v_data_nasc
    FROM ANIMAL
    WHERE id_animal = NEW.id_animal;

    IF v_data_nasc IS NOT NULL AND NEW.data_adocao < v_data_nasc THEN
        RAISE EXCEPTION 'La fecha de adopción (%) no puede ser anterior al nacimiento del animal (%).',
            NEW.data_adocao, v_data_nasc;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_data_adocao
BEFORE INSERT OR UPDATE ON REGISTRO_ADOCAO
FOR EACH ROW EXECUTE FUNCTION fn_validar_data_adocao();

-- 2.5. Trigger: Validar duración de campaña (> 0)
CREATE OR REPLACE FUNCTION fn_validar_duracao_campanha()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.duracao IS NULL OR NEW.duracao <= 0 THEN
        RAISE EXCEPTION 'La duración de la campaña debe ser mayor que cero (valor recibido: %).',
            COALESCE(NEW.duracao::TEXT, 'NULL');
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_duracao_campanha
BEFORE INSERT OR UPDATE ON CAMPANHA
FOR EACH ROW EXECUTE FUNCTION fn_validar_duracao_campanha();