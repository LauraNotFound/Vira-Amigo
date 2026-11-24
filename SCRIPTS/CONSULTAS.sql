-- 1. Consultar denuncias
SELECT
    id_denuncia,
    data_hora,
    descricao,
    gravidade,
    status,
    local_evento,
    canal_origem
FROM DENUNCIA
ORDER BY data_hora DESC;

-- 2. Consultar denuncias por ciudadano
SELECT
    c.CPF,
    p.nome AS nome_cidadao,
    c.sexo,
    p.CEP,
    p.logradouro,
    p.numero,
    p.bairro,
    p.cidade,
    STRING_AGG(DISTINCT pt.telefone, ', ') AS telefones,
    d.id_denuncia,
    d.data_hora,
    d.descricao,
    d.gravidade,
    d.status,
    d.local_evento,
    d.canal_origem
FROM CIDADAO c
INNER JOIN PESSOA p ON c.CPF = p.CPF
LEFT JOIN PESSOA_TELEFONE pt ON p.CPF = pt.CPF
INNER JOIN DENUNCIA d ON c.CPF = d.CPF_cidadao
WHERE c.CPF = '12345678901'
GROUP BY
    c.CPF, p.nome, c.sexo, p.CEP, p.logradouro, p.numero, p.bairro, p.cidade,
    d.id_denuncia, d.data_hora, d.descricao, d.gravidade, d.status, d.local_evento, d.canal_origem
ORDER BY d.data_hora DESC;

-- 3. Consultar rescates
SELECT
    r.id_resgate,
    r.data_hora,
    r.proced_local,
    r.condicao_fisica,
    r.precaucoes,
    r.local_destino,
    COALESCE(r.observacoes, ra.observacoes_vistoria) AS observacoes_vistoria
FROM RESGATE r
LEFT JOIN INTERVENCAO i ON r.id_resgate = i.id_resgate
LEFT JOIN ANIMAL a ON i.id_animal = a.id_animal
LEFT JOIN REGISTRO_ADOCAO ra ON a.id_animal = ra.id_animal
ORDER BY r.data_hora DESC;

-- 4. Consultar animales
SELECT
    id_animal,
    nome,
    raca,
    porte,
    sexo,
    AGE(CURRENT_DATE, data_nasc) AS idade,
    cor_pelagem,
    temperamento
FROM ANIMAL
ORDER BY nome;

-- 5. Consultar historial de atención médica
SELECT
    am.id_atendimento,
    a.id_animal,
    a.nome AS nome_animal,
    am.data_hora,
    am.motivo,
    am.prescricao,
    am.sinais_vitais,
    am.peso
FROM ATENDIMENTO_MEDICO am
INNER JOIN ANIMAL a ON am.id_animal = a.id_animal
WHERE a.id_animal = 1
ORDER BY am.data_hora DESC;

-- 6. Consultar aplicaciones de vacunas
SELECT
    a.id_animal,
    a.nome AS nome_animal,
    v.nome AS nome_vacina,
    v.fabricante,
    av.data_aplicacao,
    STRING_AGG(vda.doenca_alvo, ', ') AS enfermidades_objetivo
FROM ANIMAL a
INNER JOIN APLICACAO_VACINA av ON a.id_animal = av.id_animal
INNER JOIN VACINA v ON av.id_vacina = v.id_vacina
LEFT JOIN VACINA_DOENCAS_ALVO vda ON v.id_vacina = vda.id_vacina
GROUP BY a.id_animal, a.nome, v.nome, v.fabricante, av.data_aplicacao
ORDER BY a.nome, av.data_aplicacao DESC;

-- 7. Consultar registros de adopción
SELECT
    ra.id_registro,
    a.nome AS nome_animal,
    p.nome AS nome_adotante,
    ra.data_adocao,
    ra.status_acompanhamento,
    COALESCE(ra.desfecho, i.desfecho) AS desfecho,
    COALESCE(ra.motivacao, i.motivacao) AS motivacao
FROM REGISTRO_ADOCAO ra
INNER JOIN ANIMAL a ON ra.id_animal = a.id_animal
INNER JOIN PESSOA p ON ra.CPF_cidadao = p.CPF
LEFT JOIN INTERVENCAO i ON a.id_animal = i.id_animal
ORDER BY ra.data_adocao DESC;

-- 8. Consultar campañas y acciones de concientización
SELECT
    c.id_campanha,
    c.nome,
    c.descricao,
    c.local,
    c.duracao,
    ac.publico_alvo,
    ac.qtd_participantes
FROM CAMPANHA c
LEFT JOIN ACAO_CONSCIENTIZACAO ac ON c.id_campanha = ac.id_campanha
ORDER BY c.data DESC;

-- 9. Consultar procedimientos veterinarios (exámenes y cirugías)
SELECT
    'Exame' AS categoria,
    ae.id_atendimento,
    e.tipo,
    ae.situacao,
    ae.resultados,
    NULL::VARCHAR(50) AS riscos,
    e.preparo_previo AS preparacao_previa
FROM ATENDIMENTO_EXAME ae
INNER JOIN EXAME e ON ae.id_exame = e.id_exame

UNION ALL

SELECT
    'Cirurgia' AS categoria,
    ac.id_atendimento,
    c.nome AS tipo,
    ac.situacao,
    ac.resultados,
    c.risco_padrao AS riscos,
    NULL::TEXT AS preparacao_previa
FROM ATENDIMENTO_CIRURGIA ac
INNER JOIN CIRURGIA c ON ac.id_cirurgia = c.id_cirurgia
ORDER BY id_atendimento DESC;


-- ----------------------------------------------------------------------------
-- B. INSERT (3)
-- ----------------------------------------------------------------------------

-- 10. Registrar una denuncia
INSERT INTO DENUNCIA (
    data_hora, descricao, gravidade, status, local_evento, canal_origem, CPF_cidadao
) VALUES (
    '2026-11-23 14:30:00',
    'Perro encadenado sin agua ni refugio en patio descubierto.',
    'Alta',
    'Aberta',
    'Rua das Palmeiras, 450 - Butantã, São Paulo',
    'Portal Web',
    '12345678901'
);

-- 11. Registrar un rescate (asociado a la denuncia 2)
INSERT INTO RESGATE (
    data_hora, proced_local, condicao_fisica, precaucoes, local_destino, observacoes, id_denuncia, CPF_agente
) VALUES (
    '2026-11-23 16:00:00',
    'Contención con correa de manejo, hidratación inicial y traslado en caja ventilada.',
    'Deshidratación leve y bajo peso, sin fracturas aparentes.',
    'Uso de guantes de cuero y bozal preventivo por estrés.',
    'Abrigo Público Municipal Butantã',
    'Animal colaborativo tras primeros minutos; propietario notificado en el lugar.',
    2,
    '98765432100'
);

-- 12. Registrar una atención médica
INSERT INTO ATENDIMENTO_MEDICO (
    id_animal, CPF_veterinario, id_estabelecimento, data_hora, motivo, prescricao, sinais_vitais, peso, estado
) VALUES (
    1,
    '55566677788',
    1,
    '2026-11-23 17:15:00',
    'Evaluación clínica de seguimiento y desparasitación.',
    'Suero oral 50ml cada 6h por 48h + antiparasitario dosis única.',
    'FC: 110 lpm, FR: 24 rpm, Temp: 38.5°C',
    14.80,
    'Estável'
);


-- ----------------------------------------------------------------------------
-- C. UPDATE (2)
-- ----------------------------------------------------------------------------

-- 13. Actualizar estado de denuncia
UPDATE DENUNCIA
SET status = 'Atendida',
    descricao = CONCAT(descricao, ' | Actualización: Rescate ejecutado con éxito el 23/11/2026.')
WHERE id_denuncia = 1;

-- 14. Actualizar seguimiento de adopción
UPDATE REGISTRO_ADOCAO
SET status_acompanhamento = 'Vistoria Concluída - Aprovada',
    desfecho = 'Adoção definitiva consolidada',
    motivacao = 'Ambiente familiar seguro, patio cercado y compromiso veterinario comprobado.'
WHERE id_registro = 1;


-- ----------------------------------------------------------------------------
-- D. DELETE (1)
-- ----------------------------------------------------------------------------

-- 15. Eliminar un registro de vacuna incorrecto
DELETE FROM APLICACAO_VACINA
WHERE id_animal = 1
  AND id_vacina = 2;