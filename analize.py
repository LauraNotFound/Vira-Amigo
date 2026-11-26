"""
Análise estatística do Vira-Amigo.

O volume (contagens, médias, desvio, mediana, correlação e histograma)
é calculado dentro do PostgreSQL. O Python só recebe tabelas já resumidas
e é usado para o que o SGBD não oferece: o teste de independência
(qui-quadrado) e os gráficos.
"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from dotenv import load_dotenv
from scipy.stats import chi2_contingency
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path, override=True)


def conectar_postgres():
    """Cria a conexão com o PostgreSQL usando SQLAlchemy + psycopg2."""
    db_password = os.getenv("DB_PASSWORD")
    if not db_password:
        raise RuntimeError(
            f"DB_PASSWORD não foi encontrada. Verifique se o arquivo '{env_path}' "
            "existe, salvo em UTF-8, com a variável DB_PASSWORD definida."
        )

    url_conexion = URL.create(
        drivername="postgresql+psycopg2",
        username=os.getenv("DB_USER", "postgres"),
        password=db_password,
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", 5432)),
        database=os.getenv("DB_NAME", "vira_amigo"),
    )
    return create_engine(url_conexion)


def consultar(conn, sql):
    """Executa uma consulta já agregada e devolve poucas linhas, não a tabela bruta."""
    return pd.read_sql(text(sql), conn)


def interpretar_correlacao(r):
    if r is None or (isinstance(r, float) and np.isnan(r)):
        return "Não houve dados suficientes para calcular a correlação."
    forca = abs(r)
    if forca < 0.10:
        return (
            f"r = {r:.3f}: não há relação prática entre a idade e o peso "
            "(o valor está quase em zero)."
        )
    if forca < 0.30:
        nivel = "fraca"
    elif forca < 0.70:
        nivel = "moderada"
    else:
        nivel = "forte"
    sentido = "positiva (quando um sobe, o outro tende a subir)" if r > 0 else (
        "negativa (quando um sobe, o outro tende a descer)"
    )
    return f"r = {r:.3f}: associação {nivel} e {sentido}."


def executar_analise():
    engine = conectar_postgres()
    sns.set_theme(style="whitegrid", palette="Set2")

    with engine.connect() as conn:
        version_pg = conn.execute(text("SELECT version();")).scalar()
        print("=" * 80)
        print("CONEXÃO BEM-SUCEDIDA COM O SGBD:")
        print(version_pg)
        print("=" * 80)
        print(
            "As consultas abaixo usam COUNT, AVG, STDDEV, PERCENTILE e CORR "
            "dentro do PostgreSQL. No Python chegam apenas os resumos."
        )

        # Gravidade x status: tabela de contingência (insumo do qui-quadrado).
        df_denuncias = consultar(conn, """
            SELECT gravidade, status, COUNT(*)::int AS total
            FROM vw_denuncias_cidadaos
            WHERE gravidade IS NOT NULL
              AND status IS NOT NULL
            GROUP BY gravidade, status
            ORDER BY gravidade, status;
        """)

        # Um peso por animal (média dos atendimentos) e depois média,
        # desvio e mediana por porte. Todo o cálculo fica no SGBD.
        df_peso = consultar(conn, """
            WITH peso_animal AS (
                SELECT
                    id_animal,
                    porte,
                    AVG(peso) AS peso_medio
                FROM vw_historico_veterinario
                WHERE peso IS NOT NULL
                  AND porte IS NOT NULL
                GROUP BY id_animal, porte
            )
            SELECT
                porte,
                COUNT(*)::int AS n_animais,
                ROUND(AVG(peso_medio)::numeric, 2)::float8 AS media_kg,
                ROUND(STDDEV_SAMP(peso_medio)::numeric, 2)::float8 AS desvio_kg,
                ROUND(
                    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peso_medio))::numeric,
                    2
                )::float8 AS mediana_kg
            FROM peso_animal
            GROUP BY porte
            ORDER BY CASE porte
                WHEN 'Pequeno' THEN 1
                WHEN 'Médio' THEN 2
                WHEN 'Grande' THEN 3
                ELSE 4
            END;
        """)

        # Tempo entre a denúncia e o resgate: resumo e histograma por faixas.
        df_tempo = consultar(conn, """
            WITH horas_resgate AS (
                SELECT EXTRACT(EPOCH FROM (r.data_hora - d.data_hora)) / 3600.0 AS horas
                FROM RESGATE r
                JOIN DENUNCIA d ON d.id_denuncia = r.id_denuncia
                WHERE r.data_hora >= d.data_hora
            )
            SELECT
                COUNT(*)::int AS n_resgates,
                ROUND(AVG(horas)::numeric, 2)::float8 AS media_horas,
                ROUND(STDDEV_SAMP(horas)::numeric, 2)::float8 AS desvio_horas,
                ROUND(
                    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY horas))::numeric,
                    2
                )::float8 AS mediana_horas,
                ROUND(MIN(horas)::numeric, 2)::float8 AS minimo_horas,
                ROUND(MAX(horas)::numeric, 2)::float8 AS maximo_horas
            FROM horas_resgate;
        """)

        df_hist_tempo = consultar(conn, """
            WITH horas_resgate AS (
                SELECT EXTRACT(EPOCH FROM (r.data_hora - d.data_hora)) / 3600.0 AS horas
                FROM RESGATE r
                JOIN DENUNCIA d ON d.id_denuncia = r.id_denuncia
                WHERE r.data_hora >= d.data_hora
            )
            SELECT
                CASE
                    WHEN horas <= 8 THEN '1 a 8 h'
                    WHEN horas <= 16 THEN '9 a 16 h'
                    WHEN horas <= 24 THEN '17 a 24 h'
                    WHEN horas <= 32 THEN '25 a 32 h'
                    WHEN horas <= 40 THEN '33 a 40 h'
                    ELSE '41 a 48 h'
                END AS faixa,
                COUNT(*)::int AS total
            FROM horas_resgate
            GROUP BY faixa
            ORDER BY MIN(horas);
        """)

        # Participantes por campanha (as ações são somadas) e depois média e desvio por tipo.
        df_campanhas = consultar(conn, """
            WITH por_campanha AS (
                SELECT
                    id_campanha,
                    tipo_campanha,
                    SUM(qtd_participantes) AS participantes
                FROM vw_campanhas_acoes
                GROUP BY id_campanha, tipo_campanha
            )
            SELECT
                tipo_campanha,
                COUNT(*)::int AS n_campanhas,
                ROUND(AVG(participantes)::numeric, 1)::float8 AS media_participantes,
                ROUND(STDDEV_SAMP(participantes)::numeric, 1)::float8 AS desvio_participantes,
                ROUND(
                    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY participantes))::numeric,
                    1
                )::float8 AS mediana_participantes
            FROM por_campanha
            WHERE participantes IS NOT NULL
            GROUP BY tipo_campanha
            ORDER BY media_participantes DESC;
        """)

        # CORR é função do PostgreSQL: viaja uma única linha, não o histórico clínico.
        df_corr = consultar(conn, """
            WITH por_animal AS (
                SELECT
                    a.id_animal,
                    EXTRACT(YEAR FROM AGE(CURRENT_DATE, a.data_nasc)) * 12
                        + EXTRACT(MONTH FROM AGE(CURRENT_DATE, a.data_nasc)) AS idade_meses,
                    AVG(am.peso) AS peso_medio
                FROM ANIMAL a
                JOIN ATENDIMENTO_MEDICO am ON am.id_animal = a.id_animal
                WHERE a.data_nasc IS NOT NULL
                  AND am.peso IS NOT NULL
                GROUP BY a.id_animal, a.data_nasc
            )
            SELECT
                COUNT(*)::int AS n_animais,
                ROUND(CORR(idade_meses, peso_medio)::numeric, 3)::float8 AS correlacao_pearson
            FROM por_animal;
        """)

    print("\n[TABELA 1] Denúncias por gravidade e status (COUNT na view):")
    print(df_denuncias.to_string(index=False))
    print(f"Linhas trazidas do SGBD: {len(df_denuncias)} (combinações, não cada denúncia).")

    tabla = (
        df_denuncias.pivot(index="gravidade", columns="status", values="total")
        .fillna(0)
        .astype(int)
    )
    chi2, p_valor, gl, _esperado = chi2_contingency(tabla.to_numpy())
    n = int(tabla.to_numpy().sum())
    k = min(tabla.shape) - 1
    cramer = float(np.sqrt(chi2 / (n * k))) if n and k else float("nan")

    print("\n[TESTE] Qui-quadrado de independência (gravidade × status):")
    print("Este teste não existe como função do PostgreSQL; é calculado em Python")
    print("sobre a tabela de contagens já agregada.")
    print(f"  qui-quadrado = {chi2:.3f}")
    print(f"  graus de liberdade = {gl}")
    print(f"  p-valor = {p_valor:.4f}")
    print(f"  V de Cramér = {cramer:.3f} (0 = nenhuma associação, 1 = associação total)")
    if p_valor < 0.05:
        print(
            "  Leitura: p < 0,05. A gravidade e o status da denúncia "
            "não se distribuem de forma independente."
        )
    else:
        print(
            "  Leitura: p >= 0,05. Não há evidência de que a gravidade "
            "mude o status da denúncia."
        )

    print("\n[TABELA 2] Peso clínico por porte (média, desvio e mediana no SGBD):")
    print(df_peso.to_string(index=False))
    print(f"Linhas trazidas do SGBD: {len(df_peso)}.")

    print("\n[TABELA 3] Horas entre a denúncia e o resgate:")
    print(df_tempo.to_string(index=False))
    print("\nDistribuição por faixas (o histograma foi montado com COUNT no SQL):")
    print(df_hist_tempo.to_string(index=False))

    print("\n[TABELA 4] Participantes por tipo de campanha (média, desvio e mediana):")
    print(df_campanhas.to_string(index=False))
    print(f"Linhas trazidas do SGBD: {len(df_campanhas)}.")

    print("\n[TABELA 5] Correlação de Pearson entre idade (meses) e peso médio:")
    print(df_corr.to_string(index=False))
    r = df_corr["correlacao_pearson"].iloc[0] if not df_corr.empty else None
    print(interpretar_correlacao(None if pd.isna(r) else float(r)))

    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle(
        "Vira-Amigo — Análise estatística calculada no PostgreSQL",
        fontsize=15,
        fontweight="bold",
    )

    ordem_gravidade = [g for g in ["Baixa", "Média", "Alta", "Crítica"] if g in set(df_denuncias["gravidade"])]
    sns.barplot(
        data=df_denuncias,
        x="gravidade",
        y="total",
        hue="status",
        order=ordem_gravidade,
        ax=axes[0, 0],
    )
    axes[0, 0].set_title("Denúncias por gravidade e status")
    axes[0, 0].set_xlabel("Gravidade")
    axes[0, 0].set_ylabel("Quantidade")
    axes[0, 0].legend(
        title="Status",
        fontsize=7,
        loc="upper center",
        bbox_to_anchor=(0.5, -0.28),
        ncol=3,
        frameon=False,
    )

    axes[0, 1].bar(df_hist_tempo["faixa"], df_hist_tempo["total"], color="#4C9F70")
    axes[0, 1].set_title("Tempo de resposta do resgate")
    axes[0, 1].set_xlabel("Horas desde a denúncia")
    axes[0, 1].set_ylabel("Quantidade de resgates")
    axes[0, 1].tick_params(axis="x", rotation=20)

    axes[1, 0].bar(
        df_peso["porte"],
        df_peso["media_kg"],
        yerr=df_peso["desvio_kg"],
        color="#3D7EA6",
        capsize=6,
        ecolor="#1F3A4D",
    )
    axes[1, 0].set_title("Peso médio por porte (barra = desvio padrão)")
    axes[1, 0].set_xlabel("Porte")
    axes[1, 0].set_ylabel("Quilogramas")

    axes[1, 1].bar(
        df_campanhas["tipo_campanha"],
        df_campanhas["media_participantes"],
        yerr=df_campanhas["desvio_participantes"],
        color="#C46B3A",
        capsize=6,
        ecolor="#5C3317",
    )
    axes[1, 1].set_title("Participantes por tipo de campanha (barra = desvio)")
    axes[1, 1].set_xlabel("Tipo de campanha")
    axes[1, 1].set_ylabel("Participantes")

    plt.tight_layout(rect=[0, 0.04, 1, 0.95])
    saida = Path(__file__).resolve().parent / "relatorio_vira_amigo.png"
    fig.savefig(saida, dpi=200, bbox_inches="tight")
    print(f"\nGráfico exportado como '{saida.name}'.")

    # A janela abre ao executar o script. ANALISE_SEM_JANELA=1 só salva o PNG.
    if os.getenv("ANALISE_SEM_JANELA") == "1":
        plt.close(fig)
    else:
        plt.show()


if __name__ == "__main__":
    executar_analise()
