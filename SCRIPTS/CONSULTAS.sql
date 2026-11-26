-- 1. Listar as denúncias registradas mostrando data, descrição, gravidade, status, local do evento e canal de origem.
SELECT
    data_hora,
    descricao,
    gravidade,
    status,
    local_evento,
    canal_origem
FROM DENUNCIA
ORDER BY data_hora DESC;

-- 2. Mostrar todas as denúncias feitas por um cidadão, incluindo os dados de identificação e o telefone.
SELECT
    p.CPF,
    p.nome,
    c.sexo,
    STRING_AGG(DISTINCT pt.telefone, ', ' ORDER BY pt.telefone) AS telefones,
    d.data_hora,
    d.descricao,
    d.gravidade,
    d.status,
    d.local_evento,
    d.canal_origem
FROM CIDADAO c
JOIN PESSOA p ON p.CPF = c.CPF
LEFT JOIN PESSOA_TELEFONE pt ON pt.CPF = p.CPF
JOIN DENUNCIA d ON d.CPF_cidadao = c.CPF
WHERE c.CPF = (
    SELECT CPF_cidadao
    FROM DENUNCIA
    WHERE CPF_cidadao IS NOT NULL
    ORDER BY id_denuncia
    LIMIT 1
)
GROUP BY
    p.CPF, p.nome, c.sexo,
    d.id_denuncia, d.data_hora, d.descricao, d.gravidade, d.status, d.local_evento, d.canal_origem
ORDER BY d.data_hora DESC;

-- 3. Listar os resgates realizados, mostrando data, procedimento local, condições físicas, precauções, destino e observações.
SELECT
    data_hora,
    proced_local,
    condicao_fisica,
    precaucoes,
    local_destino,
    observacoes
FROM RESGATE
ORDER BY data_hora DESC;

-- 4. Listar os animais registrados mostrando nome, raça, porte, sexo, idade, cor da pelagem e temperamento.

SELECT
    nome,
    raca,
    porte,
    sexo,
    AGE(CURRENT_DATE, data_nasc) AS idade,
    cor_pelagem,
    temperamento
FROM ANIMAL
ORDER BY nome;

-- 5. Mostrar os atendimentos recebidos por um animal, incluindo data, motivo, prescrição, sinais vitais e peso.

SELECT
    a.nome AS nome_animal,
    am.data_hora,
    am.motivo,
    am.prescricao,
    am.sinais_vitais,
    am.peso
FROM ATENDIMENTO_MEDICO am
JOIN ANIMAL a ON a.id_animal = am.id_animal
WHERE am.id_animal = (
    SELECT id_animal
    FROM ATENDIMENTO_MEDICO
    ORDER BY id_animal
    LIMIT 1
)
ORDER BY am.data_hora DESC;

-- 6. Mostrar as vacinas aplicadas a cada animal, incluindo nome da vacina, fabricante e doenças-alvo.
SELECT
    a.nome AS nome_animal,
    v.nome AS nome_vacina,
    v.fabricante,
    STRING_AGG(vda.doenca_alvo, ', ' ORDER BY vda.doenca_alvo) AS doencas_alvo
FROM ANIMAL a
JOIN APLICACAO_VACINA av ON av.id_animal = a.id_animal
JOIN VACINA v ON v.id_vacina = av.id_vacina
LEFT JOIN VACINA_DOENCAS_ALVO vda ON vda.id_vacina = v.id_vacina
GROUP BY a.id_animal, a.nome, v.id_vacina, v.nome, v.fabricante
ORDER BY a.nome, v.nome;

-- 7. Listar as adoções registradas mostrando data, status de acompanhamento, desfecho e motivação.
SELECT
    a.nome AS nome_animal,
    ra.data_adocao,
    ra.status_acompanhamento,
    ra.desfecho,
    ra.motivacao
FROM REGISTRO_ADOCAO ra
JOIN ANIMAL a ON a.id_animal = ra.id_animal
ORDER BY ra.data_adocao DESC;

-- 8. Listar as campanhas e as respectivas ações de conscientização, mostrando nome, descrição, local, duração, público-alvo e quantidade de participantes.

SELECT
    c.nome,
    c.descricao,
    c.local,
    c.duracao,
    ac.publico_alvo,
    ac.qtd_participantes
FROM CAMPANHA c
LEFT JOIN ACAO_CONSCIENTIZACAO ac ON ac.id_campanha = c.id_campanha
ORDER BY c.data DESC, c.id_campanha;

-- 9. Listar os exames e as cirurgias realizados, mostrando tipo, situação, resultados, riscos e preparo prévio.
SELECT
    'Exame' AS categoria,
    e.tipo,
    ae.situacao,
    ae.resultados,
    NULL::VARCHAR(50) AS risco,
    e.preparo_previo
FROM ATENDIMENTO_EXAME ae
JOIN EXAME e ON e.id_exame = ae.id_exame

UNION ALL

SELECT
    'Cirurgia',
    c.nome,
    ac.situacao,
    ac.resultados,
    c.risco_padrao,
    NULL
FROM ATENDIMENTO_CIRURGIA ac
JOIN CIRURGIA c ON c.id_cirurgia = ac.id_cirurgia
ORDER BY categoria, tipo;


-- 10. Inserir uma nova denúncia com data, descrição, gravidade, status, local do evento e canal de origem, associando-a ao cidadão correspondente.

INSERT INTO DENUNCIA (
    data_hora, descricao, gravidade, status, local_evento, canal_origem, CPF_cidadao
)
SELECT
    TIMESTAMP '2026-11-23 14:30:00',
    'Cão mantido em corrente, sem água e sem abrigo no quintal.',
    'Alta',
    'Aberta',
    'Rua das Palmeiras, 450 - Butantã, São Paulo',
    'Portal Web',
    c.CPF
FROM CIDADAO c
ORDER BY c.CPF
LIMIT 1;

-- 11. Inserir um novo resgate com data, procedimento, condições físicas, precauções, destino e observações, relacionando-o às entidades correspondentes do diagrama.
WITH novo_resgate AS (
    INSERT INTO RESGATE (
        data_hora, proced_local, condicao_fisica, precaucoes,
        local_destino, observacoes, id_denuncia, CPF_agente
    )
    SELECT
        d.data_hora + INTERVAL '2 hours',
        'Contenção com guia, hidratação inicial e traslado em caixa ventilada.',
        'Desidratação leve, sem fraturas aparentes.',
        'Uso de luvas de raspa e focinheira preventiva.',
        'Abrigo Público Municipal Butantã',
        'Animal colaborativo após os primeiros minutos.',
        d.id_denuncia,
        (SELECT CPF FROM AGENTE_CAMPO ORDER BY CPF LIMIT 1)
    FROM DENUNCIA d
    WHERE NOT EXISTS (
        SELECT 1 FROM RESGATE r WHERE r.id_denuncia = d.id_denuncia
    )
      AND EXISTS (SELECT 1 FROM AGENTE_CAMPO)
      AND EXISTS (SELECT 1 FROM ANIMAL)
    ORDER BY d.data_hora
    LIMIT 1
    RETURNING id_resgate, CPF_agente
)
INSERT INTO INTERVENCAO (id_animal, id_resgate, CPF_agente, desfecho)
SELECT
    a.id_animal,
    n.id_resgate,
    n.CPF_agente,
    'Encaminhado ao abrigo público'
FROM novo_resgate n
JOIN LATERAL (
    SELECT id_animal
    FROM ANIMAL
    ORDER BY (id_instituicao IS NULL), id_animal
    LIMIT 1
) a ON TRUE;

-- 12. Inserir um novo atendimento veterinário indicando data, motivo, prescrição, sinais vitais e peso do animal atendido.
INSERT INTO ATENDIMENTO_MEDICO (
    id_animal, CPF_veterinario, id_estabelecimento,
    data_hora, motivo, prescricao, sinais_vitais, peso
)
SELECT
    a.id_animal,
    v.CPF,
    e.id_estabelecimento,
    CURRENT_TIMESTAMP,
    'Avaliação clínica de retorno e controle parasitário.',
    'Soro oral 50 ml a cada 6 h por 48 h e antiparasitário em dose única.',
    'FC: 110 lpm, FR: 24 rpm, Temp: 38.5°C',
    14.80
FROM ANIMAL a
JOIN LATERAL (SELECT CPF FROM VETERINARIO ORDER BY CPF LIMIT 1) v ON TRUE
JOIN LATERAL (
    SELECT id_estabelecimento FROM ESTABELECIMENTO_VET ORDER BY id_estabelecimento LIMIT 1
) e ON TRUE
ORDER BY a.id_animal
LIMIT 1;


-- 13. Modificar o status e a descrição de uma denúncia existente quando a situação for atualizada.

UPDATE DENUNCIA
SET status = 'Atendida',
    descricao = descricao || ' Resgate realizado.'
WHERE id_denuncia = (
    SELECT id_denuncia
    FROM DENUNCIA
    WHERE status = 'Aberta'
    ORDER BY data_hora
    LIMIT 1
);

-- 14. Modificar o status de acompanhamento, o desfecho ou a motivação de um registro de adoção.

UPDATE REGISTRO_ADOCAO
SET status_acompanhamento = 'Vistoria Concluída - Aprovada',
    desfecho = 'Adoção definitiva consolidada',
    motivacao = 'Ambiente familiar seguro, quintal cercado e compromisso veterinário comprovado.'
WHERE id_registro = (
    SELECT id_registro
    FROM REGISTRO_ADOCAO
    WHERE status_acompanhamento IS DISTINCT FROM 'Vistoria Concluída - Aprovada'
    ORDER BY data_adocao, id_registro
    LIMIT 1
);


-- 15. Excluir uma aplicação de vacina registrada incorretamente, respeitando as relações e as restrições de integridade do banco de dados.

DELETE FROM APLICACAO_VACINA
WHERE (id_animal, id_vacina) IN (
    SELECT id_animal, id_vacina
    FROM APLICACAO_VACINA
    ORDER BY data_aplicacao DESC, id_animal, id_vacina
    LIMIT 1
);
