import os
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL
from dotenv import load_dotenv

# Cargar explícitamente el .env ubicado en la misma carpeta que analize.py
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path, override=True)

def conectar_postgres():
    """Crea la conexión segura hacia PostgreSQL usando SQLAlchemy + psycopg2."""
    db_password = os.getenv("DB_PASSWORD")
    if not db_password:
        raise RuntimeError(
            f"No se encontró DB_PASSWORD. Verifica que exista el archivo '{env_path}' "
            "guardado en UTF-8 y con la variable DB_PASSWORD definida."
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

def ejecutar_analisis():
    engine = conectar_postgres()
    sns.set_theme(style="whitegrid", palette="Set2")

    with engine.connect() as conn:
        # Verificar conexión y versión del SGBD
        version_pg = conn.execute(text("SELECT version();")).scalar()
        print("=" * 80)
        print("CONEXIÓN EXITOSA AL SGBD:")
        print(version_pg)
        print("=" * 80)

        # --------------------------------------------------------------------
        # CONSULTA 1 (Desde VIEW vw_denuncias_cidadaos): Denuncias por Gravedad y Estado
        # --------------------------------------------------------------------
        df_denuncias = pd.read_sql(text("""
            SELECT gravidade, status, COUNT(*) AS total
            FROM vw_denuncias_cidadaos
            GROUP BY gravidade, status
            ORDER BY total DESC;
        """), conn)

        print("\n[TABLA 1] Resumen de Denuncias por Gravedad y Estado (via VIEW):")
        print(df_denuncias.to_markdown(index=False))

        # --------------------------------------------------------------------
        # CONSULTA 2 (Desde Tabla ANIMAL): Distribución por Porte y Situación de Guarda
        # --------------------------------------------------------------------
        df_animais = pd.read_sql(text("""
            SELECT
                porte,
                CASE
                    WHEN CPF_cidadao IS NOT NULL THEN 'Adoptado / Guarda Ciudadana'
                    WHEN id_instituicao IS NOT NULL THEN 'En Abrigo Público'
                    ELSE 'En Tránsito'
                END AS situacao_guarda,
                COUNT(*) AS total
            FROM ANIMAL
            GROUP BY porte, situacao_guarda
            ORDER BY porte, total DESC;
        """), conn)

        print("\n[TABLA 2] Población Animal por Porte y Situación de Guarda:")
        print(df_animais.to_markdown(index=False))

        # --------------------------------------------------------------------
        # CONSULTA 3 (Desde VIEW vw_vacinacao_animais): Top Vacunas Aplicadas
        # --------------------------------------------------------------------
        df_vacinas = pd.read_sql(text("""
            SELECT nome_vacina, fabricante, COUNT(*) AS total_aplicacoes
            FROM vw_vacinacao_animais
            GROUP BY nome_vacina, fabricante
            ORDER BY total_aplicacoes DESC
            LIMIT 8;
        """), conn)

        print("\n[TABLA 3] Top 8 Vacunas más Aplicadas (via VIEW):")
        print(df_vacinas.to_markdown(index=False))

        # --------------------------------------------------------------------
        # CONSULTA 4 (Desde VIEW vw_campanhas_acoes): Participación por Tipo de Campaña
        # --------------------------------------------------------------------
        df_campanhas = pd.read_sql(text("""
            SELECT
                tipo_campanha,
                COUNT(DISTINCT id_campanha) AS total_campanhas,
                SUM(qtd_participantes) AS total_participantes,
                ROUND(AVG(qtd_participantes), 1) AS media_participantes
            FROM vw_campanhas_acoes
            GROUP BY tipo_campanha
            ORDER BY total_participantes DESC;
        """), conn)

        print("\n[TABLA 4] Impacto de Campañas y Acciones de Concientización (via VIEW):")
        print(df_campanhas.to_markdown(index=False))

        # --------------------------------------------------------------------
        # CONSULTA 5 (Desde VIEW vw_historico_veterinario): Atenciones por Establecimiento
        # --------------------------------------------------------------------
        df_vet = pd.read_sql(text("""
            SELECT
                tipo_estabelecimento,
                COUNT(*) AS total_atendimentos,
                ROUND(AVG(peso), 2) AS peso_medio_kg
            FROM vw_historico_veterinario
            GROUP BY tipo_estabelecimento
            ORDER BY total_atendimentos DESC;
        """), conn)

        print("\n[TABLA 5] Atenciones Clínicas por Tipo de Establecimiento (via VIEW):")
        print(df_vet.to_markdown(index=False))

    # ========================================================================
    # GENERACIÓN DE DASHBOARD DE GRÁFICOS (2x2)
    # ========================================================================
    fig, axes = plt.subplots(2, 2, figsize=(15, 10))
    fig.suptitle("Projeto Vira-Amigo — Análisis Operacional desde PostgreSQL", fontsize=15, fontweight="bold")

    # Gráfico 1: Denuncias por Gravedad y Estado
    sns.barplot(
        data=df_denuncias, x="gravidade", y="total", hue="status",
        ax=axes[0, 0], order=["Baixa", "Média", "Alta", "Crítica"]
    )
    axes[0, 0].set_title("Denuncias por Gravedad y Estado")
    axes[0, 0].set_xlabel("Gravedad")
    axes[0, 0].set_ylabel("Cantidad de Denuncias")
    axes[0, 0].legend(title="Estado", fontsize=8)

    # Gráfico 2: Animales por Porte y Situación de Guarda
    sns.barplot(
        data=df_animais, x="porte", y="total", hue="situacao_guarda",
        ax=axes[0, 1], order=["Pequeno", "Médio", "Grande"]
    )
    axes[0, 1].set_title("Distribución de Animales por Porte y Guarda")
    axes[0, 1].set_xlabel("Porte")
    axes[0, 1].set_ylabel("Cantidad de Animales")
    axes[0, 1].legend(title="Situación", fontsize=8)

    # Gráfico 3: Top Vacunas Aplicadas
    sns.barplot(
        data=df_vacinas, y="nome_vacina", x="total_aplicacoes",
        ax=axes[1, 0], palette="viridis", hue="nome_vacina", legend=False
    )
    axes[1, 0].set_title("Vacunas más Aplicadas en el Sistema")
    axes[1, 0].set_xlabel("Total de Aplicaciones")
    axes[1, 0].set_ylabel("")

    # Gráfico 4: Participantes por Tipo de Campaña
    sns.barplot(
        data=df_campanhas, x="tipo_campanha", y="total_participantes",
        ax=axes[1, 1], palette="magma", hue="tipo_campanha", legend=False
    )
    axes[1, 1].set_title("Participantes en Acciones por Tipo de Campaña")
    axes[1, 1].set_xlabel("Tipo de Campaña")
    axes[1, 1].set_ylabel("Total de Participantes")

    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig("relatorio_vira_amigo.png", dpi=300)
    print("\nGráfico exportado como 'relatorio_vira_amigo.png'.")
    plt.show()

if __name__ == "__main__":
    ejecutar_analisis()