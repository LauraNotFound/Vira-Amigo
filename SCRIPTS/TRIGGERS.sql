-- 1. Impedir que um mesmo CPF fique registrado ao mesmo tempo como cidadão e como funcionário.
CREATE OR REPLACE FUNCTION fn_validar_exclusividade_pessoa()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'cidadao' AND EXISTS (
        SELECT 1 FROM FUNCIONARIO WHERE CPF = NEW.CPF
    ) THEN
        RAISE EXCEPTION 'Esse CPF já está registrado como funcionário.';
    END IF;

    IF TG_TABLE_NAME = 'funcionario' AND EXISTS (
        SELECT 1 FROM CIDADAO WHERE CPF = NEW.CPF
    ) THEN
        RAISE EXCEPTION 'Esse CPF já está registrado como cidadão.';
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

-- 2. Impedir que um funcionário pertença a mais de uma especialização entre veterinário, analista de adoção e agente de campo.
CREATE OR REPLACE FUNCTION fn_validar_exclusividade_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME <> 'veterinario' AND EXISTS (
        SELECT 1 FROM VETERINARIO WHERE CPF = NEW.CPF
    ) THEN
        RAISE EXCEPTION 'Esse CPF já está registrado como veterinário.';
    END IF;

    IF TG_TABLE_NAME <> 'analista_adocao' AND EXISTS (
        SELECT 1 FROM ANALISTA_ADOCAO WHERE CPF = NEW.CPF
    ) THEN
        RAISE EXCEPTION 'Esse CPF já está registrado como analista de adoção.';
    END IF;

    IF TG_TABLE_NAME <> 'agente_campo' AND EXISTS (
        SELECT 1 FROM AGENTE_CAMPO WHERE CPF = NEW.CPF
    ) THEN
        RAISE EXCEPTION 'Esse CPF já está registrado como agente de campo.';
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

-- 3. Impedir que uma vacina seja aplicada antes do nascimento do animal.
CREATE OR REPLACE FUNCTION fn_validar_data_aplicacao_vacina()
RETURNS TRIGGER AS $$
DECLARE
    v_data_nasc DATE;
BEGIN
    SELECT data_nasc INTO v_data_nasc
    FROM ANIMAL
    WHERE id_animal = NEW.id_animal;

    IF v_data_nasc IS NOT NULL AND NEW.data_aplicacao < v_data_nasc THEN
        RAISE EXCEPTION 'A vacina não pode ser aplicada antes do nascimento do animal.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_data_aplicacao_vacina
BEFORE INSERT OR UPDATE ON APLICACAO_VACINA
FOR EACH ROW EXECUTE FUNCTION fn_validar_data_aplicacao_vacina();

-- 4. Impedir que o peso de um atendimento médico seja zero ou negativo.
CREATE OR REPLACE FUNCTION fn_validar_peso_atendimento()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.peso IS NOT NULL AND NEW.peso <= 0 THEN
        RAISE EXCEPTION 'O peso do atendimento tem que ser maior que zero.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_peso_atendimento
BEFORE INSERT OR UPDATE ON ATENDIMENTO_MEDICO
FOR EACH ROW EXECUTE FUNCTION fn_validar_peso_atendimento();

-- 5. Impedir que um resgate seja registrado antes da denúncia que o originou.
CREATE OR REPLACE FUNCTION fn_validar_data_resgate()
RETURNS TRIGGER AS $$
DECLARE
    v_data_denuncia TIMESTAMP;
BEGIN
    IF NEW.id_denuncia IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT data_hora INTO v_data_denuncia
    FROM DENUNCIA
    WHERE id_denuncia = NEW.id_denuncia;

    IF v_data_denuncia IS NOT NULL AND NEW.data_hora < v_data_denuncia THEN
        RAISE EXCEPTION 'O resgate não pode ser anterior à denúncia.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_data_resgate
BEFORE INSERT OR UPDATE ON RESGATE
FOR EACH ROW EXECUTE FUNCTION fn_validar_data_resgate();

-- 6. Impedir que uma adoção seja registrada antes do nascimento do animal.

CREATE OR REPLACE FUNCTION fn_validar_data_adocao()
RETURNS TRIGGER AS $$
DECLARE
    v_data_nasc DATE;
BEGIN
    SELECT data_nasc INTO v_data_nasc
    FROM ANIMAL
    WHERE id_animal = NEW.id_animal;

    IF v_data_nasc IS NOT NULL AND NEW.data_adocao < v_data_nasc THEN
        RAISE EXCEPTION 'A adoção não pode ser anterior ao nascimento do animal.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_data_adocao
BEFORE INSERT OR UPDATE ON REGISTRO_ADOCAO
FOR EACH ROW EXECUTE FUNCTION fn_validar_data_adocao();

-- 7. Impedir que a duração de uma campanha seja zero ou negativa.

CREATE OR REPLACE FUNCTION fn_validar_duracao_campanha()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.duracao IS NOT NULL AND NEW.duracao <= 0 THEN
        RAISE EXCEPTION 'A duração da campanha tem que ser maior que zero.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_validar_duracao_campanha
BEFORE INSERT OR UPDATE ON CAMPANHA
FOR EACH ROW EXECUTE FUNCTION fn_validar_duracao_campanha();
