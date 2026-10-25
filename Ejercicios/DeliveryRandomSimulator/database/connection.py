
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Cargar variables del archivo .env
BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


# Crear conexión con PostgreSQL
def get_engine():

    database_url = URL.create(
        drivername="postgresql+psycopg",
        username=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        database=os.getenv(
            "DB_NAME", "delivery_simulator_db"
        )
    )

    engine = create_engine(
        database_url,
        pool_pre_ping=True
    )

    return engine


# Probar conexión
def test_connection():

    try:
        engine = get_engine()

        with engine.connect() as connection:

            result = connection.execute(
                text("SELECT current_database()")
            )

            database_name = result.scalar()

            print("Conexión exitosa con PostgreSQL")
            print("Base de datos:", database_name)

        engine.dispose()
        return True

    except Exception as error:

        print("Error al conectar con PostgreSQL:")
        print(error)

        return False


# Ejecutar prueba
if __name__ == "__main__":
    test_connection()
