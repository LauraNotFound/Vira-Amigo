-- ============================================================================
-- SCRIPT DE POBLACIÓN MASIVA DE DATOS DE TESTE - PROJETO VIRA-AMIGO
-- Genera ~15,000+ registros coherentes cubriendo las 28 tablas y relaciones
-- ============================================================================

SET search_path TO public;

-- Asegura compatibilidad de columnas extendidas en caso de haber usado el DDL inicial
ALTER TABLE RESGATE ADD COLUMN IF NOT EXISTS observacoes TEXT;
ALTER TABLE REGISTRO_ADOCAO
    ADD COLUMN IF NOT EXISTS desfecho VARCHAR(150),
    ADD COLUMN IF NOT EXISTS motivacao TEXT;
ALTER TABLE APLICACAO_VACINA ADD COLUMN IF NOT EXISTS data_aplicacao DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE ATENDIMENTO_EXAME
    ADD COLUMN IF NOT EXISTS situacao VARCHAR(50),
    ADD COLUMN IF NOT EXISTS resultados TEXT;
ALTER TABLE ATENDIMENTO_CIRURGIA
    ADD COLUMN IF NOT EXISTS situacao VARCHAR(50),
    ADD COLUMN IF NOT EXISTS resultados TEXT;

-- (Opcional) Descomenta la siguiente línea si deseas limpiar datos previos antes de poblar:
-- TRUNCATE TABLE PESSOA, DEPARTAMENTO, ABRIGO_PUBLICO, ANIMAL, VACINA, ESTABELECIMENTO_VET, EXAME, CIRURGIA RESTART IDENTITY CASCADE;

DO $$
DECLARE
    -- Catálogos de datos realistas
    v_nomes TEXT[] := ARRAY[
        'Ana', 'Bruno', 'Camila', 'Daniel', 'Eduarda', 'Felipe', 'Gabriela', 'Henrique',
        'Isabela', 'João', 'Larissa', 'Lucas', 'Mariana', 'Mateus', 'Natália', 'Pedro',
        'Rafael', 'Sofia', 'Thiago', 'Vitória', 'Beatriz', 'Caio', 'Fernanda', 'Gustavo'
    ];
    v_sobrenomes TEXT[] := ARRAY[
        'Silva', 'Santos', 'Oliveira', 'Souza', 'Rodrigues', 'Ferreira', 'Alves', 'Pereira',
        'Lima', 'Gomes', 'Costa', 'Ribeiro', 'Martins', 'Carvalho', 'Almeida', 'Lopes',
        'Soares', 'Fernandes', 'Vieira', 'Barbosa', 'Mendes', 'Nunes', 'Cardoso', 'Teixeira'
    ];
    v_bairros TEXT[] := ARRAY[
        'Butantã', 'Pinheiros', 'Itaim Bibi', 'Vila Mariana', 'Mooca', 'Tatuapé',
        'Santana', 'Lapa', 'Ipiranga', 'Campo Limpo', 'Santo Amaro', 'Jabaquara'
    ];
    v_ruas TEXT[] := ARRAY[
        'Av. Prof. Luciano Gualberto', 'Rua dos Pinheiros', 'Av. Brigadeiro Faria Lima',
        'Rua Vergueiro', 'Av. Paes de Barros', 'Rua Tuiuti', 'Av. Braz Leme',
        'Rua Clélia', 'Av. Nazaré', 'Estrada do Campo Limpo', 'Av. Adolfo Pinheiro', 'Av. Jabaquara'
    ];
    v_ceps CHAR(8)[] := ARRAY[
        '05508090', '05424020', '04538132', '04101000', '03114000', '03081003',
        '02011000', '05042000', '04262000', '05777000', '04734002', '04045000'
    ];
    v_nomes_animais TEXT[] := ARRAY[
        'Thor', 'Luna', 'Mel', 'Bob', 'Nina', 'Max', 'Lola', 'Billy', 'Amora', 'Zeus',
        'Bella', 'Rex', 'Maya', 'Toby', 'Cacau', 'Fred', 'Pandora', 'Simba', 'Nala', 'Pipoca',
        'Bidu', 'Belinha', ' Duque', 'Frida', 'Apolo', 'Kiara', 'Chico', 'Zeca', 'Flora', 'Scooby'
    ];
    v_racas TEXT[] := ARRAY[
        'SRD (Vira-lata)', 'SRD (Vira-lata)', 'SRD (Vira-lata)', 'Labrador Retriever',
        'Poodle', 'Pinscher', 'Pastor Alemão', 'Golden Retriever', 'Siamês', 'Persa',
        'Maine Coon', 'Beagle', 'Shih Tzu', 'Pitbull', 'Dachshund'
    ];
    v_pelagens TEXT[] := ARRAY[
        'Caramelo', 'Preto', 'Branco', 'Rajado', 'Tricolor', 'Chocolate', 'Cinza', 'Dourado', 'Malhado'
    ];
    v_portes TEXT[] := ARRAY['Pequeno', 'Médio', 'Grande'];
    v_temperamentos TEXT[] := ARRAY[
        'Dócil e brincalhão', 'Tímido, mas carinhoso', 'Protetor e alerta',
        'Calmo e sociável', 'Energético e ativo', 'Independente e curioso'
    ];
    v_gravidades TEXT[] := ARRAY['Baixa', 'Média', 'Alta', 'Crítica'];
    v_status_denuncia TEXT[] := ARRAY['Aberta', 'Em Análise', 'Em Atendimento', 'Atendida', 'Arquivada'];
    v_canais TEXT[] := ARRAY['Portal Web', 'Telefone 156', 'Aplicativo Móvel', 'Presencial', 'Ouvidoria'];

    -- Variables auxiliares y arreglos de IDs reales
    i INTEGER;
    j INTEGER;
    v_cpf CHAR(11);
    v_nome_completo VARCHAR(150);
    v_idx INTEGER;
    v_data_nasc DATE;
    v_data_ts TIMESTAMP;
    v_data_denuncia TIMESTAMP;
    v_id_denuncia INTEGER;
    v_id_resgate INTEGER;
    v_id_animal INTEGER;
    v_id_atendimento INTEGER;
    v_id_vacina INTEGER;
    v_id_exame INTEGER;
    v_id_cirurgia INTEGER;
    v_cpf_cidadao CHAR(11);
    v_cpf_agente CHAR(11);
    v_cpf_vet CHAR(11);
    v_cpf_analista CHAR(11);
    v_cpf_func CHAR(11);
    v_id_abrigo INTEGER;
    v_id_estab INTEGER;
    v_id_campanha INTEGER;

    arr_deptos INTEGER[];
    arr_cidadaos CHAR(11)[];
    arr_funcionarios CHAR(11)[];
    arr_vets CHAR(11)[];
    arr_analistas CHAR(11)[];
    arr_agentes CHAR(11)[];
    arr_abrigos INTEGER[];
    arr_denuncias INTEGER[];
    arr_resgates INTEGER[];
    arr_animais INTEGER[];
    arr_vacinas INTEGER[];
    arr_estabs INTEGER[];
    arr_atendimentos INTEGER[];
    arr_exames INTEGER[];
    arr_cirurgias INTEGER[];
    arr_campanhas INTEGER[];
BEGIN
    -- ========================================================================
    -- 1. DEPARTAMENTOS (6 registros)
    -- ========================================================================
    INSERT INTO DEPARTAMENTO (nome, sigla, ramal) VALUES
        ('Operações e Resgate em Campo', 'ORC', '201'),
        ('Saúde e Vigilância Veterinária', 'SVV', '202'),
        ('Adoção e Bem-Estar Animal', 'ABEA', '203'),
        ('Fiscalização e Atendimento de Denúncias', 'FAD', '204'),
        ('Gestão de Abrigos e Contratos', 'GAC', '205'),
        ('Educação Ambiental e Campanhas', 'EAC', '206')
    ON CONFLICT (sigla) DO NOTHING;

    SELECT ARRAY_AGG(id_departamento) INTO arr_deptos FROM DEPARTAMENTO;

    -- ========================================================================
    -- 2. PESSOAS (1,500), TELEFONES (~2,250), CIDADAOS (1,350) Y FUNCIONARIOS (150)
    -- ========================================================================
    FOR i IN 1..1500 LOOP
        v_cpf := LPAD((20000000000 + i)::TEXT, 11, '0');
        v_idx := (i % 12) + 1;
        v_nome_completo := v_nomes[(i % 24) + 1] || ' ' ||
                           v_sobrenomes[((i * 3) % 24) + 1] || ' ' ||
                           v_sobrenomes[((i * 7) % 24) + 1];

        INSERT INTO PESSOA (CPF, nome, CEP, logradouro, numero, bairro, cidade)
        VALUES (
            v_cpf,
            v_nome_completo,
            v_ceps[v_idx],
            v_ruas[v_idx],
            ((i % 1900) + 10)::TEXT,
            v_bairros[v_idx],
            'São Paulo'
        )
        ON CONFLICT (CPF) DO NOTHING;

        -- Teléfono principal
        INSERT INTO PESSOA_TELEFONE (CPF, telefone)
        VALUES (v_cpf, '119' || LPAD((80000000 + i)::TEXT, 8, '0'))
        ON CONFLICT DO NOTHING;

        -- Segundo teléfono para el 50% de las personas
        IF i % 2 = 0 THEN
            INSERT INTO PESSOA_TELEFONE (CPF, telefone)
            VALUES (v_cpf, '113' || LPAD((2000000 + i)::TEXT, 7, '0'))
            ON CONFLICT DO NOTHING;
        END IF;

        -- Especialización exclusiva: 1..1350 -> CIDADAO | 1351..1500 -> FUNCIONARIO
        IF i <= 1350 THEN
            INSERT INTO CIDADAO (CPF, sexo)
            VALUES (v_cpf, CASE WHEN i % 2 = 0 THEN 'Feminino' ELSE 'Masculino' END)
            ON CONFLICT (CPF) DO NOTHING;
        ELSE
            INSERT INTO FUNCIONARIO (CPF, matricula, carga_horaria, data_admissao, id_departamento)
            VALUES (
                v_cpf,
                'MAT-VA-' || LPAD(i::TEXT, 5, '0'),
                CASE WHEN i % 3 = 0 THEN 36 ELSE 40 END,
                DATE '2021-01-10' + ((i - 1350) * 9) * INTERVAL '1 day',
                arr_deptos[((i - 1351) % ARRAY_LENGTH(arr_deptos, 1)) + 1]
            )
            ON CONFLICT (CPF) DO NOTHING;

            -- Subespecialización exclusiva de FUNCIONARIO:
            -- 1351..1395 (45): VETERINARIO
            -- 1396..1440 (45): ANALISTA_ADOCAO
            -- 1441..1485 (45): AGENTE_CAMPO
            -- 1486..1500 (15): Administrativos generales (especialización parcial)
            IF i BETWEEN 1351 AND 1395 THEN
                INSERT INTO VETERINARIO (CPF, CRMV, especialidade)
                VALUES (
                    v_cpf,
                    'CRMV-SP-' || (30000 + i)::TEXT,
                    CASE (i % 4)
                        WHEN 0 THEN 'Clínica Médica de Pequenos Animais'
                        WHEN 1 THEN 'Cirurgia Geral e Ortopedia'
                        WHEN 2 THEN 'Medicina Veterinária Preventiva'
                        ELSE 'Emergência e Terapia Intensiva'
                    END
                )
                ON CONFLICT (CPF) DO NOTHING;
            ELSIF i BETWEEN 1396 AND 1440 THEN
                INSERT INTO ANALISTA_ADOCAO (CPF, CNH)
                VALUES (v_cpf, LPAD((40000000000 + i)::TEXT, 11, '0'))
                ON CONFLICT (CPF) DO NOTHING;
            ELSIF i BETWEEN 1441 AND 1485 THEN
                INSERT INTO AGENTE_CAMPO (CPF, registro_conselho, credencial, categoria_cnh)
                VALUES (
                    v_cpf,
                    'CRBio-' || (70000 + i)::TEXT,
                    'CRED-OP-' || LPAD(i::TEXT, 4, '0'),
                    CASE WHEN i % 2 = 0 THEN 'AB' ELSE 'B' END
                )
                ON CONFLICT (CPF) DO NOTHING;
            END IF;
        END IF;
    END LOOP;

    SELECT ARRAY_AGG(CPF) INTO arr_cidadaos FROM CIDADAO;
    SELECT ARRAY_AGG(CPF) INTO arr_funcionarios FROM FUNCIONARIO;
    SELECT ARRAY_AGG(CPF) INTO arr_vets FROM VETERINARIO;
    SELECT ARRAY_AGG(CPF) INTO arr_analistas FROM ANALISTA_ADOCAO;
    SELECT ARRAY_AGG(CPF) INTO arr_agentes FROM AGENTE_CAMPO;

    -- ========================================================================
    -- 3. ABRIGOS PÚBLICOS (12), TELÉFONOS (24) Y CONTRATOS (60)
    -- ========================================================================
    FOR i IN 1..12 LOOP
        INSERT INTO ABRIGO_PUBLICO (nome, email, orcamento_mensal, nome_diretor, CEP, bairro, cidade, logradouro)
        VALUES (
            'Abrigo Público Regional ' || v_bairros[i],
            'abrigo.' || LOWER(REPLACE(v_bairros[i], ' ', '')) || '@viraamigo.sp.gov.br',
            35000.00 + (i * 4250.50),
            v_nomes[(i % 24) + 1] || ' ' || v_sobrenomes[((i * 2) % 24) + 1],
            v_ceps[i],
            v_bairros[i],
            'São Paulo',
            v_ruas[i] || ', ' || (500 + i * 35)::TEXT
        );
    END LOOP;

    SELECT ARRAY_AGG(id_instituicao) INTO arr_abrigos FROM ABRIGO_PUBLICO;

    FOR i IN 1..ARRAY_LENGTH(arr_abrigos, 1) LOOP
        v_id_abrigo := arr_abrigos[i];
        INSERT INTO ABRIGO_TELEFONE (id_instituicao, telefone) VALUES
            (v_id_abrigo, '113500' || LPAD(i::TEXT, 4, '0')),
            (v_id_abrigo, '1197500' || LPAD(i::TEXT, 4, '0'))
        ON CONFLICT DO NOTHING;
    END LOOP;

    FOR i IN 1..60 LOOP
        v_cpf_func := arr_funcionarios[(i % ARRAY_LENGTH(arr_funcionarios, 1)) + 1];
        v_id_abrigo := arr_abrigos[(i % ARRAY_LENGTH(arr_abrigos, 1)) + 1];
        v_data_nasc := DATE '2024-01-10' + (i * 12) * INTERVAL '1 day';

        INSERT INTO CONTRATO (valor_total, data_assinatura, data_vigencia, CPF_funcionario, id_instituicao)
        VALUES (
            12000.00 + (i * 1850.00),
            v_data_nasc,
            v_data_nasc + INTERVAL '365 days',
            v_cpf_func,
            v_id_abrigo
        );
    END LOOP;

    -- ========================================================================
    -- 4. FORMULARIOS DE EVALUACIÓN SOCIOECONÓMICA (800 registros)
    -- ========================================================================
    FOR i IN 1..800 LOOP
        v_cpf_cidadao := arr_cidadaos[(i % ARRAY_LENGTH(arr_cidadaos, 1)) + 1];
        INSERT INTO FORM_AVALIACAO (
            data_hora, tamanho_residencia, tipo_residencia, qtd_pessoas, qtd_animais, solvencia_econ, CPF_cidadao
        ) VALUES (
            TIMESTAMP '2025-01-05 09:00:00' + (i * 14) * INTERVAL '1 hour',
            CASE (i % 3) WHEN 0 THEN 'Pequena (< 60m²)' WHEN 1 THEN 'Média (60-120m²)' ELSE 'Grande (> 120m²)' END,
            CASE (i % 3) WHEN 0 THEN 'Apartamento telado' WHEN 1 THEN 'Casa com quintal murado' ELSE 'Chácara cercada' END,
            (i % 5) + 1,
            (i % 3),
            CASE (i % 3) WHEN 0 THEN 'Comprovada - Renda Estável' WHEN 1 THEN 'Adequada' ELSE 'Alta' END,
            v_cpf_cidadao
        );
    END LOOP;

    -- ========================================================================
    -- 5. DENUNCIAS (1,200 registros) Y RESCATES (700 registros vinculados 1:1)
    -- ========================================================================
    FOR i IN 1..1200 LOOP
        v_idx := (i % 12) + 1;
        -- 15% de denuncias anónimas (CPF_cidadao NULL)
        IF i % 7 = 0 THEN
            v_cpf_cidadao := NULL;
        ELSE
            v_cpf_cidadao := arr_cidadaos[(i % ARRAY_LENGTH(arr_cidadaos, 1)) + 1];
        END IF;

        v_data_denuncia := TIMESTAMP '2025-01-10 08:00:00' + (i * 12) * INTERVAL '1 hour';

        INSERT INTO DENUNCIA (
            local_evento, telefone, status, descricao, data_hora, gravidade, canal_origem, CPF_cidadao
        ) VALUES (
            v_ruas[v_idx] || ', ' || ((i % 2500) + 1)::TEXT || ' - ' || v_bairros[v_idx],
            '119' || LPAD((70000000 + i)::TEXT, 8, '0'),
            CASE WHEN i <= 700 THEN 'Atendida' ELSE v_status_denuncia[(i % 5) + 1] END,
            CASE (i % 5)
                WHEN 0 THEN 'Animal mantido em corrente curta sem abrigo contra sol e chuva.'
                WHEN 1 THEN 'Cão abandonado em via pública apresentando sinais de desnutrição.'
                WHEN 2 THEN 'Ninhada de filhotes deixada em caixa próxima a terreno baldio.'
                WHEN 3 THEN 'Animal atropelado necessitando atendimento veterinário urgente.'
                ELSE 'Suspeita de maus-tratos e privação de água e alimento em residência.'
            END,
            v_data_denuncia,
            v_gravidades[(i % 4) + 1],
            v_canais[(i % 5) + 1],
            v_cpf_cidadao
        )
        RETURNING id_denuncia INTO v_id_denuncia;

        -- Los primeros 700 casos generan un RESGATE (cumpliendo data_hora >= denuncia.data_hora)
        IF i <= 700 THEN
            v_cpf_agente := arr_agentes[(i % ARRAY_LENGTH(arr_agentes, 1)) + 1];
            v_id_abrigo := arr_abrigos[(i % ARRAY_LENGTH(arr_abrigos, 1)) + 1];

            INSERT INTO RESGATE (
                precaucoes, condicao_fisica, proced_local, data_hora, local_destino, observacoes, id_denuncia, CPF_agente
            ) VALUES (
                CASE (i % 3)
                    WHEN 0 THEN 'Uso de luvas de raspa e guia de contenção.'
                    WHEN 1 THEN 'Caixa de transporte ventilada e manta térmica.'
                    ELSE 'Aproximação gradual com focinheira preventiva.'
                END,
                CASE (i % 4)
                    WHEN 0 THEN 'Desidratação leve e baixo escore corporal.'
                    WHEN 1 THEN 'Escoriações superficiais, sem fraturas.'
                    WHEN 2 THEN 'Alerta e responsivo, infestação por ectoparasitas.'
                    ELSE 'Claudicação em membro posterior direito.'
                END,
                'Contenção segura, avaliação primária de sinais vitais e embarque.',
                v_data_denuncia + ((i % 48) + 1) * INTERVAL '1 hour',
                'Abrigo Público Regional ' || v_bairros[(v_id_abrigo % 12) + 1],
                'Resgate documentado com apoio da equipe operacional. Ocorrência #' || i,
                v_id_denuncia,
                v_cpf_agente
            );
        END IF;
    END LOOP;

    SELECT ARRAY_AGG(id_resgate) INTO arr_resgates FROM RESGATE;

    -- ========================================================================
    -- 6. ANIMALES (1,000 registros respetando exclusión mutua de guarda)
    -- ========================================================================
    FOR i IN 1..1000 LOOP
        v_data_nasc := DATE '2019-02-01' + ((i * 2) % 2500) * INTERVAL '1 day';

        -- 450 animales adoptados/bajo custodia ciudadana; 500 en abrigos; 50 en tránsito (ambos NULL)
        IF i <= 450 THEN
            v_cpf_cidadao := arr_cidadaos[(i % ARRAY_LENGTH(arr_cidadaos, 1)) + 1];
            v_id_abrigo := NULL;
        ELSIF i <= 950 THEN
            v_cpf_cidadao := NULL;
            v_id_abrigo := arr_abrigos[(i % ARRAY_LENGTH(arr_abrigos, 1)) + 1];
        ELSE
            v_cpf_cidadao := NULL;
            v_id_abrigo := NULL;
        END IF;

        INSERT INTO ANIMAL (
            nome, cor_pelagem, raca, porte, data_nasc, sexo, temperamento, CPF_cidadao, id_instituicao
        ) VALUES (
            v_nomes_animais[(i % 30) + 1] || ' #' || i,
            v_pelagens[(i % 9) + 1],
            v_racas[(i % 15) + 1],
            v_portes[(i % 3) + 1],
            v_data_nasc,
            CASE WHEN i % 2 = 0 THEN 'Fêmea' ELSE 'Macho' END,
            v_temperamentos[(i % 6) + 1],
            v_cpf_cidadao,
            v_id_abrigo
        );
    END LOOP;

    SELECT ARRAY_AGG(id_animal) INTO arr_animais FROM ANIMAL;

    -- ========================================================================
    -- 7. INTERVENCIONES DE RESCATE (900 registros ternarios)
    -- ========================================================================
    FOR i IN 1..900 LOOP
        v_id_animal := arr_animais[(i % ARRAY_LENGTH(arr_animais, 1)) + 1];
        v_id_resgate := arr_resgates[(i % ARRAY_LENGTH(arr_resgates, 1)) + 1];
        v_cpf_agente := arr_agentes[(i % ARRAY_LENGTH(arr_agentes, 1)) + 1];

        INSERT INTO INTERVENCAO (
            id_animal, id_resgate, CPF_agente, desfecho, motivacao, coord_abordagem, coord_soltura
        ) VALUES (
            v_id_animal,
            v_id_resgate,
            v_cpf_agente,
            CASE (i % 3)
                WHEN 0 THEN 'Encaminhado ao abrigo público para reabilitação'
                WHEN 1 THEN 'Encaminhado ao hospital veterinário conveniado'
                ELSE 'Resgatado e integrado ao programa de adoção'
            END,
            'Atendimento à ocorrência de abandono/risco em via pública.',
            '-23.' || LPAD((5200 + (i % 450))::TEXT, 4, '0') || ', -46.' || LPAD((6100 + (i % 450))::TEXT, 4, '0'),
            NULL
        )
        ON CONFLICT DO NOTHING;
    END LOOP;

    -- ========================================================================
    -- 8. REGISTROS DE ADOPCIÓN (450 registros validando data_adocao >= data_nasc)
    -- ========================================================================
    FOR i IN 1..450 LOOP
        v_id_animal := arr_animais[i];
        SELECT data_nasc, CPF_cidadao INTO v_data_nasc, v_cpf_cidadao
        FROM ANIMAL WHERE id_animal = v_id_animal;

        v_cpf_analista := arr_analistas[(i % ARRAY_LENGTH(arr_analistas, 1)) + 1];

        INSERT INTO REGISTRO_ADOCAO (
            id_animal, CPF_cidadao, CPF_analista, data_adocao,
            status_acompanhamento, desfecho, motivacao, observacoes_vistoria
        ) VALUES (
            v_id_animal,
            v_cpf_cidadao,
            v_cpf_analista,
            LEAST(CURRENT_DATE, v_data_nasc + (60 + (i % 300)) * INTERVAL '1 day'),
            CASE (i % 3)
                WHEN 0 THEN 'Vistoria Concluída - Aprovada'
                WHEN 1 THEN 'Em Acompanhamento (30 dias)'
                ELSE 'Acompanhamento Semestral Regular'
            END,
            'Adoção definitiva consolidada',
            'Adotante aprovado em avaliação socioeconômica e comprometido com guarda responsável.',
            'Animal bem adaptado ao novo lar, vacinação e alimentação em dia.'
        );
    END LOOP;

    -- ========================================================================
    -- 9. VACUNAS (12), ENFERMEDADES OBJETIVO (26) Y APLICACIONES (2,000)
    -- ========================================================================
    INSERT INTO VACINA (nome, fabricante) VALUES
        ('V10 Polivalente Canina', 'Zoetis'),
        ('V8 Óctupla Canina', 'MSD Saúde Animal'),
        ('Antirrábica Inativada', 'Boehringer Ingelheim'),
        ('Tríplice Felina (V3)', 'Zoetis'),
        ('Quádrupla Felina (V4)', 'Virbac'),
        ('Quíntupla Felina (V5)', 'Elanco'),
        ('Bronchi-Shield (Gripe Canina)', 'Boehringer Ingelheim'),
        ('GiardiaVax', 'Zoetis'),
        ('Leish-Tec', 'Ceva Saúde Animal'),
        ('Nobivac Puppy DP', 'MSD Saúde Animal'),
        ('Felocell CVR', 'Zoetis'),
        ('Rabisin-I', 'Boehringer Ingelheim');

    SELECT ARRAY_AGG(id_vacina) INTO arr_vacinas FROM VACINA;

    INSERT INTO VACINA_DOENCAS_ALVO (id_vacina, doenca_alvo) VALUES
        (arr_vacinas[1], 'Cinomose'), (arr_vacinas[1], 'Parvovirose'), (arr_vacinas[1], 'Leptospirose'), (arr_vacinas[1], 'Hepatite Infecciosa'),
        (arr_vacinas[2], 'Cinomose'), (arr_vacinas[2], 'Parvovirose'), (arr_vacinas[2], 'Coronavirose'),
        (arr_vacinas[3], 'Raiva'),
        (arr_vacinas[4], 'Rinotraqueíte'), (arr_vacinas[4], 'Calicivirose'), (arr_vacinas[4], 'Panleucopenia'),
        (arr_vacinas[5], 'Rinotraqueíte'), (arr_vacinas[5], 'Calicivirose'), (arr_vacinas[5], 'Clamidiose'),
        (arr_vacinas[6], 'Leucemia Felina (FeLV)'), (arr_vacinas[6], 'Panleucopenia'),
        (arr_vacinas[7], 'Traqueobronquite Infecciosa (Tosse dos Canis)'),
        (arr_vacinas[8], 'Giardíase'),
        (arr_vacinas[9], 'Leishmaniose Visceral Canina'),
        (arr_vacinas[10], 'Cinomose'), (arr_vacinas[10], 'Parvovirose'),
        (arr_vacinas[11], 'Rinotraqueíte Viral Felina'),
        (arr_vacinas[12], 'Raiva')
    ON CONFLICT DO NOTHING;

    -- 2 vacunas por cada uno de los 1,000 animales = 2,000 aplicaciones válidas
    FOR i IN 1..1000 LOOP
        v_id_animal := arr_animais[i];
        SELECT data_nasc INTO v_data_nasc FROM ANIMAL WHERE id_animal = v_id_animal;

        FOR j IN 1..2 LOOP
            v_id_vacina := arr_vacinas[((i + j * 3) % ARRAY_LENGTH(arr_vacinas, 1)) + 1];
            INSERT INTO APLICACAO_VACINA (id_animal, id_vacina, data_aplicacao)
            VALUES (
                v_id_animal,
                v_id_vacina,
                LEAST(CURRENT_DATE, v_data_nasc + (45 + j * 30 + (i % 180)) * INTERVAL '1 day')
            )
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;

    -- ========================================================================
    -- 10. ESTABLECIMIENTOS VET (15), ATENCIONES MÉDICAS (1,800), EXÁMENES Y CIRUGÍAS
    -- ========================================================================
    FOR i IN 1..15 LOOP
        v_idx := (i % 12) + 1;
        INSERT INTO ESTABELECIMENTO_VET (
            razao_social, tipo, telefone_emergencia, horario_funcionamento, endereco_comp
        ) VALUES (
            CASE WHEN i % 3 = 0 THEN 'Hospital Veterinário Público ' ELSE 'Clínica Veterinária Conveniada ' END || v_bairros[v_idx] || ' #' || i,
            CASE (i % 3) WHEN 0 THEN 'Hospital Veterinário' WHEN 1 THEN 'Clínica Geral' ELSE 'Centro Cirúrgico' END,
            '113800' || LPAD(i::TEXT, 4, '0'),
            CASE WHEN i % 3 = 0 THEN '24 horas' ELSE 'Seg a Sáb - 08:00 às 20:00' END,
            v_ruas[v_idx] || ', ' || (100 + i * 45)::TEXT || ' - ' || v_bairros[v_idx] || ', São Paulo'
        );
    END LOOP;

    SELECT ARRAY_AGG(id_estabelecimento) INTO arr_estabs FROM ESTABELECIMENTO_VET;

    INSERT INTO EXAME (tipo, preparo_previo) VALUES
        ('Hemograma Completo', 'Jejum alimentar de 8 horas'),
        ('Bioquímico Renal e Hepático', 'Jejum alimentar de 8 a 12 horas'),
        ('Ultrassonografia Abdominal', 'Jejum de 8h e retenção urinária de 2h'),
        ('Radiografia Torácica e Ortopédica', 'Sem preparo prévio obrigatório'),
        ('Teste Rápido FIV/FeLV', 'Sem preparo prévio'),
        ('Teste Rápido Cinomose / Parvovirose', 'Sem preparo prévio'),
        ('Exame Coproparasitológico', 'Coleta de amostra fecal fresca'),
        ('Ecocardiograma Doppler', 'Manter o animal calmo antes do exame'),
        ('Urinálise Tipo I', 'Não urinar 2 horas antes da coleta'),
        ('Sorologia para Leishmaniose', 'Jejum alimentar de 6 horas');

    SELECT ARRAY_AGG(id_exame) INTO arr_exames FROM EXAME;

    INSERT INTO CIRURGIA (nome, risco_padrao) VALUES
        ('Orquiectomia (Castração Macho)', 'Baixo'),
        ('Ovariohisterectomia (Castração Fêmea)', 'Baixo'),
        ('Sutura e Debridamento de Laceração', 'Baixo'),
        ('Osteossíntese de Fêmur', 'Moderado'),
        ('Extração Dentária e Profilaxia Periodontal', 'Baixo'),
        ('Exérese de Nódulo Cutâneo', 'Moderado'),
        ('Enucleação Ocular', 'Moderado'),
        ('Laparotomia Exploratória', 'Alto');

    SELECT ARRAY_AGG(id_cirurgia) INTO arr_cirurgias FROM CIRURGIA;

    FOR i IN 1..1800 LOOP
        v_id_animal := arr_animais[(i % ARRAY_LENGTH(arr_animais, 1)) + 1];
        SELECT data_nasc INTO v_data_nasc FROM ANIMAL WHERE id_animal = v_id_animal;

        v_cpf_vet := arr_vets[(i % ARRAY_LENGTH(arr_vets, 1)) + 1];
        v_id_estab := arr_estabs[(i % ARRAY_LENGTH(arr_estabs, 1)) + 1];
        v_data_ts := LEAST(
            CURRENT_TIMESTAMP - INTERVAL '1 hour',
            v_data_nasc::TIMESTAMP + (20 + (i % 450)) * INTERVAL '1 day'
        );

        INSERT INTO ATENDIMENTO_MEDICO (
            id_animal, CPF_veterinario, id_estabelecimento, motivo, data_hora, peso, prescricao, sinais_vitais, estado
        ) VALUES (
            v_id_animal,
            v_cpf_vet,
            v_id_estab,
            CASE (i % 5)
                WHEN 0 THEN 'Triagem clínica inicial pós-resgate'
                WHEN 1 THEN 'Avaliação pré-operatória para castração'
                WHEN 2 THEN 'Consulta de retorno e controle parasitário'
                WHEN 3 THEN 'Tratamento dermatológico e otite leve'
                ELSE 'Check-up geral pré-adoção'
            END,
            v_data_ts,
            ROUND((2.50 + ((i * 7) % 320) / 10.0)::NUMERIC, 2),
            'Vermífugo de amplo espectro + suplementação vitamínica por 10 dias.',
            'FC: ' || (90 + (i % 40))::TEXT || ' lpm | FR: ' || (20 + (i % 15))::TEXT || ' rpm | Temp: 38.' || (i % 9)::TEXT || '°C',
            CASE (i % 3) WHEN 0 THEN 'Estável' WHEN 1 THEN 'Em Recuperação' ELSE 'Saudável / Liberado' END
        )
        RETURNING id_atendimento INTO v_id_atendimento;

        -- Asociar examen clínico a ~1,100 atenciones
        IF i <= 1100 THEN
            v_id_exame := arr_exames[(i % ARRAY_LENGTH(arr_exames, 1)) + 1];
            INSERT INTO ATENDIMENTO_EXAME (id_atendimento, id_exame, situacao, resultados)
            VALUES (
                v_id_atendimento,
                v_id_exame,
                CASE WHEN i % 10 = 0 THEN 'Em Análise' ELSE 'Concluído' END,
                'Parâmetros hematológicos e bioquímicos compatíveis com recuperação clínica.'
            )
            ON CONFLICT DO NOTHING;
        END IF;

        -- Asociar cirugía a ~400 atenciones
        IF i <= 400 THEN
            v_id_cirurgia := arr_cirurgias[(i % ARRAY_LENGTH(arr_cirurgias, 1)) + 1];
            INSERT INTO ATENDIMENTO_CIRURGIA (id_atendimento, id_cirurgia, situacao, resultados)
            VALUES (
                v_id_atendimento,
                v_id_cirurgia,
                'Concluída',
                'Procedimento realizado sem intercorrências anestésicas; paciente estável.'
            )
            ON CONFLICT DO NOTHING;
        END IF;
    END LOOP;

    -- ========================================================================
    -- 11. CAMPAÑAS (40) Y ACCIONES DE CONCIENTIZACIÓN (120)
    -- ========================================================================
    FOR i IN 1..40 LOOP
        v_idx := (i % 12) + 1;
        v_cpf_agente := arr_agentes[(i % ARRAY_LENGTH(arr_agentes, 1)) + 1];

        INSERT INTO CAMPANHA (nome, tipo, data, local, duracao, descricao, CPF_agente)
        VALUES (
            CASE (i % 4)
                WHEN 0 THEN 'Feira de Adoção Responsável - Edição ' || i
                WHEN 1 THEN 'Mutirão Gratuito de Castração - Etapa ' || i
                WHEN 2 THEN 'Campanha de Vacinação Antirrábica - Região ' || v_bairros[v_idx]
                ELSE 'Caravana Vira-Amigo nas Escolas #' || i
            END,
            CASE (i % 4) WHEN 0 THEN 'Adoção' WHEN 1 THEN 'Castração' WHEN 2 THEN 'Vacinação' ELSE 'Educativa' END,
            DATE '2025-02-01' + (i * 15) * INTERVAL '1 day',
            'Parque / Praça Comunitária - ' || v_bairros[v_idx],
            4 + (i % 6), -- Duración en horas (> 0)
            'Ação comunitária integrada para promoção do bem-estar animal e prevenção ao abandono.',
            v_cpf_agente
        )
        RETURNING id_campanha INTO v_id_campanha;

        -- 3 acciones de concientización por campaña = 120 acciones
        FOR j IN 1..3 LOOP
            INSERT INTO ACAO_CONSCIENTIZACAO (
                objetivo, publico_alvo, resultados, situacao, qtd_participantes, id_campanha
            ) VALUES (
                CASE j
                    WHEN 1 THEN 'Orientar sobre posse responsável, vacinação e castração'
                    WHEN 2 THEN 'Sensibilizar contra abandono e maus-tratos (Lei Sansão)'
                    ELSE 'Capacitar voluntários locais e tutores de primeira viagem'
                END,
                CASE j
                    WHEN 1 THEN 'Famílias e moradores locais'
                    WHEN 2 THEN 'Estudantes do ensino fundamental e médio'
                    ELSE 'Protetores independentes e comunidade'
                END,
                'Distribuição de material educativo e cadastro de interessados em adoção.',
                CASE WHEN i <= 35 THEN 'Realizada' ELSE 'Planejada' END,
                35 + ((i * j * 7) % 180),
                v_id_campanha
            );
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Población completada con éxito para las 28 tablas de Vira-Amigo.';
END $$;

-- ============================================================================
-- VERIFICACIÓN DE VOLUMEN DE DATOS POR TABLA (28 TABLAS)
-- ============================================================================
SELECT table_name AS tabela,
       (xpath('/row/cnt/text()', xml_count))[1]::TEXT::INT AS total_registros
FROM (
    SELECT table_name,
           query_to_xml(FORMAT('SELECT COUNT(*) AS cnt FROM %I.%I', table_schema, table_name), FALSE, TRUE, '') AS xml_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_type = 'BASE TABLE'
) t
ORDER BY total_registros DESC, tabela;