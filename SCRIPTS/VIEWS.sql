-- 1. Apresentar os animais registrados junto com a idade, calculada a partir da data de nascimento.
CREATE OR REPLACE VIEW vw_animal AS
SELECT
    id_animal,
    nome,
    cor_pelagem,
    raca,
    porte,
    data_nasc,
    sexo,
    temperamento,
    CPF_cidadao,
    id_instituicao,
    AGE(CURRENT_DATE, data_nasc) AS idade
FROM ANIMAL;

-- 2. Apresentar as denúncias registradas junto com o tempo decorrido desde o registro.
CREATE OR REPLACE VIEW vw_denuncia AS
SELECT
    id_denuncia,
    local_evento,
    telefone,
    status,
    descricao,
    data_hora,
    gravidade,
    canal_origem,
    CPF_cidadao,
    CURRENT_TIMESTAMP - data_hora AS tempo_decorrido
FROM DENUNCIA;

-- 3. Apresentar as denúncias registradas junto com os cidadãos que as fizeram.
CREATE OR REPLACE VIEW vw_denuncias_cidadaos AS
SELECT
    d.id_denuncia,
    d.data_hora,
    d.descricao,
    d.gravidade,
    d.status,
    d.local_evento,
    d.canal_origem,
    d.telefone AS telefone_denuncia,
    c.CPF AS cpf_cidadao,
    p.nome AS nome_cidadao,
    c.sexo AS sexo_cidadao,
    p.CEP,
    p.logradouro,
    p.numero,
    p.bairro,
    p.cidade,
    STRING_AGG(DISTINCT pt.telefone, ', ' ORDER BY pt.telefone) AS telefones_cidadao
FROM DENUNCIA d
LEFT JOIN CIDADAO c ON d.CPF_cidadao = c.CPF
LEFT JOIN PESSOA p ON c.CPF = p.CPF
LEFT JOIN PESSOA_TELEFONE pt ON p.CPF = pt.CPF
GROUP BY
    d.id_denuncia, d.data_hora, d.descricao, d.gravidade, d.status,
    d.local_evento, d.canal_origem, d.telefone,
    c.CPF, p.nome, c.sexo, p.CEP, p.logradouro, p.numero, p.bairro, p.cidade;

-- 4. Apresentar os resgates registrados junto com os animais que foram resgatados e os agentes de campo que os realizaram.
DROP VIEW IF EXISTS vw_rescates_animais;
CREATE OR REPLACE VIEW vw_resgates_animais AS
SELECT
    r.id_resgate,
    r.data_hora AS data_resgate,
    r.proced_local,
    r.condicao_fisica,
    r.precaucoes,
    r.local_destino,
    r.observacoes,
    r.id_denuncia,
    r.CPF_agente,
    ag.nome AS nome_agente,
    a.id_animal,
    a.nome AS nome_animal,
    a.raca,
    a.porte,
    a.sexo,
    AGE(CURRENT_DATE, a.data_nasc) AS idade,
    a.cor_pelagem,
    a.temperamento,
    STRING_AGG(DISTINCT i.desfecho, ' | ') AS desfecho,
    STRING_AGG(DISTINCT i.motivacao, ' | ') AS motivacao
FROM RESGATE r
LEFT JOIN PESSOA ag ON r.CPF_agente = ag.CPF
LEFT JOIN INTERVENCAO i ON r.id_resgate = i.id_resgate
LEFT JOIN ANIMAL a ON i.id_animal = a.id_animal
GROUP BY
    r.id_resgate, r.data_hora, r.proced_local, r.condicao_fisica, r.precaucoes,
    r.local_destino, r.observacoes, r.id_denuncia, r.CPF_agente, ag.nome,
    a.id_animal, a.nome, a.raca, a.porte, a.sexo, a.data_nasc, a.cor_pelagem, a.temperamento;

-- 5. Apresentar os atendimentos médicos registrados junto com os animais que foram atendidos, os estabelecimentos onde foram realizados e os veterinários que os realizaram.
CREATE OR REPLACE VIEW vw_historico_veterinario AS
SELECT
    am.id_atendimento,
    am.data_hora,
    am.motivo,
    am.prescricao,
    am.sinais_vitais,
    am.peso,
    am.estado AS estado_clinico,
    a.id_animal,
    a.nome AS nome_animal,
    a.raca,
    a.porte,
    ev.id_estabelecimento,
    ev.razao_social AS estabelecimento,
    ev.tipo AS tipo_estabelecimento,
    ev.telefone_emergencia,
    v.CPF AS cpf_veterinario,
    p.nome AS nome_veterinario,
    v.CRMV
FROM ATENDIMENTO_MEDICO am
JOIN ANIMAL a ON am.id_animal = a.id_animal
JOIN ESTABELECIMENTO_VET ev ON am.id_estabelecimento = ev.id_estabelecimento
JOIN VETERINARIO v ON am.CPF_veterinario = v.CPF
JOIN PESSOA p ON v.CPF = p.CPF;

-- 6. Apresentar as vacinas aplicadas junto com os animais que foram vacinados.
CREATE OR REPLACE VIEW vw_vacinacao_animais AS
SELECT
    a.id_animal,
    a.nome AS nome_animal,
    a.raca,
    a.porte,
    v.id_vacina,
    v.nome AS nome_vacina,
    v.fabricante,
    av.data_aplicacao,
    STRING_AGG(DISTINCT vda.doenca_alvo, ', ' ORDER BY vda.doenca_alvo) AS doencas_alvo
FROM ANIMAL a
JOIN APLICACAO_VACINA av ON a.id_animal = av.id_animal
JOIN VACINA v ON av.id_vacina = v.id_vacina
LEFT JOIN VACINA_DOENCAS_ALVO vda ON v.id_vacina = vda.id_vacina
GROUP BY
    a.id_animal, a.nome, a.raca, a.porte,
    v.id_vacina, v.nome, v.fabricante, av.data_aplicacao;

-- 7. Apresentar as campanhas registradas junto com as ações de conscientização que as acompanham.
CREATE OR REPLACE VIEW vw_campanhas_acoes AS
SELECT
    c.id_campanha,
    c.nome AS nome_campanha,
    c.tipo AS tipo_campanha,
    c.data AS data_campanha,
    c.local,
    c.duracao,
    c.descricao,
    ac.id_acao,
    ac.objetivo,
    ac.publico_alvo,
    ac.qtd_participantes,
    ac.situacao,
    ac.resultados
FROM CAMPANHA c
LEFT JOIN ACAO_CONSCIENTIZACAO ac ON c.id_campanha = ac.id_campanha;
