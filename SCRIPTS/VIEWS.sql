-- 4.A. Vistas para atributos derivados del diagrama EER
CREATE OR REPLACE VIEW vw_animal AS
SELECT
    *,
    AGE(CURRENT_DATE, data_nasc) AS idade
FROM ANIMAL;

CREATE OR REPLACE VIEW vw_denuncia AS
SELECT
    *,
    (CURRENT_TIMESTAMP - data_hora) AS tempo_decorrido
FROM DENUNCIA;

-- 4.1. Vista de denuncias y ciudadanos
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
    p.cidade,
    p.bairro,
    STRING_AGG(pt.telefone, ', ') AS telefones_cidadao
FROM DENUNCIA d
LEFT JOIN CIDADAO c ON d.CPF_cidadao = c.CPF
LEFT JOIN PESSOA p ON c.CPF = p.CPF
LEFT JOIN PESSOA_TELEFONE pt ON p.CPF = pt.CPF
GROUP BY
    d.id_denuncia, d.data_hora, d.descricao, d.gravidade, d.status,
    d.local_evento, d.canal_origem, d.telefone, c.CPF, p.nome,
    c.sexo, p.cidade, p.bairro;

-- 4.2. Vista de rescates y animales
CREATE OR REPLACE VIEW vw_rescates_animais AS
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
    i.desfecho,
    i.motivacao,
    i.coord_abordagem,
    i.coord_soltura,
    a.id_animal,
    a.nome AS nome_animal,
    a.raca,
    a.porte,
    a.sexo,
    AGE(CURRENT_DATE, a.data_nasc) AS idade,
    a.cor_pelagem,
    a.temperamento
FROM RESGATE r
LEFT JOIN INTERVENCAO i ON r.id_resgate = i.id_resgate
LEFT JOIN ANIMAL a ON i.id_animal = a.id_animal;

-- 4.3. Vista del historial veterinario
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
INNER JOIN ANIMAL a ON am.id_animal = a.id_animal
INNER JOIN ESTABELECIMENTO_VET ev ON am.id_estabelecimento = ev.id_estabelecimento
INNER JOIN VETERINARIO v ON am.CPF_veterinario = v.CPF
INNER JOIN PESSOA p ON v.CPF = p.CPF;

-- 4.4. Vista de vacunación de animales
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
    STRING_AGG(vda.doenca_alvo, ', ') AS doencas_alvo
FROM ANIMAL a
INNER JOIN APLICACAO_VACINA av ON a.id_animal = av.id_animal
INNER JOIN VACINA v ON av.id_vacina = v.id_vacina
LEFT JOIN VACINA_DOENCAS_ALVO vda ON v.id_vacina = vda.id_vacina
GROUP BY
    a.id_animal, a.nome, a.raca, a.porte,
    v.id_vacina, v.nome, v.fabricante, av.data_aplicacao;

-- 4.5. Vista de campañas y acciones de concientización
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