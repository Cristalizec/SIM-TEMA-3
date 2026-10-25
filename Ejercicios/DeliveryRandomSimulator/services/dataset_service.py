
from pathlib import Path

import numpy as np
import pandas as pd


# Ubicación del dataset
DATASET_PATH = (
    Path(__file__).resolve().parent.parent
    / "dataset"
    / "entregas.csv"
)

# Tipos de entrega
TIPOS_ENTREGA = [
    "Estándar",
    "Exprés",
    "Prioritaria"
]

# Columnas del dataset
COLUMNAS = [
    "tipo_entrega",
    "distancia_km",
    "peso_kg",
    "tiempo_preparacion_min",
    "tiempo_transporte_min",
    "tiempo_total_min"
]


# Generar dataset de entregas
def generar_dataset(cantidad=500, semilla=2026):

    if cantidad < 1:
        raise ValueError(
            "La cantidad debe ser mayor a cero."
        )

    rng = np.random.default_rng(semilla)

    # Generar tipos de entrega
    tipos = rng.choice(
        TIPOS_ENTREGA,
        size=cantidad,
        p=[0.60, 0.30, 0.10]
    )

    # Generar distancias y pesos aleatorios
    distancias = np.round(
        rng.uniform(1, 30, cantidad),
        2
    )

    pesos = np.round(
        rng.uniform(0.2, 15, cantidad),
        2
    )

    # Tiempos promedio según el tipo
    medias_preparacion = {
        "Estándar": 18,
        "Exprés": 12,
        "Prioritaria": 8
    }

    medias_demora = {
        "Estándar": 12,
        "Exprés": 7,
        "Prioritaria": 5
    }

    # Generar tiempos de preparación
    preparacion = np.round(
        rng.gamma(
            2,
            [
                medias_preparacion[tipo] / 2
                for tipo in tipos
            ]
        ),
        2
    )

    # Generar demoras aleatorias
    demora = rng.exponential(
        [
            medias_demora[tipo]
            for tipo in tipos
        ]
    )

    # Tiempo de transporte
    # Suponemos velocidad de 35 km/h
    transporte = np.round(
        distancias / 35 * 60 + demora,
        2
    )

    # Calcular tiempo total
    tiempo_total = np.round(
        preparacion + transporte,
        2
    )

    # Crear DataFrame
    dataframe = pd.DataFrame({
        "tipo_entrega": tipos,
        "distancia_km": distancias,
        "peso_kg": pesos,
        "tiempo_preparacion_min": preparacion,
        "tiempo_transporte_min": transporte,
        "tiempo_total_min": tiempo_total
    })

    # Crear carpeta si no existe
    DATASET_PATH.parent.mkdir(
        parents=True,
        exist_ok=True
    )

    # Guardar dataset en CSV
    dataframe.to_csv(
        DATASET_PATH,
        index=False,
        encoding="utf-8-sig"
    )

    return dataframe


# Cargar y validar dataset
def cargar_dataset():

    # Generar automáticamente si no existe
    if not DATASET_PATH.exists():
        generar_dataset()

    dataframe = pd.read_csv(DATASET_PATH)

    # Revisar columnas obligatorias
    if dataframe.empty or any(
        columna not in dataframe.columns
        for columna in COLUMNAS
    ):
        raise ValueError(
            "El dataset está vacío o faltan columnas."
        )

    # Revisar tipos de entrega
    if not dataframe["tipo_entrega"].isin(
        TIPOS_ENTREGA
    ).all():
        raise ValueError(
            "Hay tipos de entrega desconocidos."
        )

    # Validar datos numéricos
    for columna in COLUMNAS[1:]:

        dataframe[columna] = pd.to_numeric(
            dataframe[columna],
            errors="raise"
        )

        if (
            not np.isfinite(dataframe[columna]).all()
            or (dataframe[columna] <= 0).any()
        ):
            raise ValueError(
                f"Datos inválidos en {columna}"
            )

    return dataframe


# Probar dataset
if __name__ == "__main__":

    datos = cargar_dataset()

    print("Dataset:", DATASET_PATH)
    print("Registros:", len(datos))

    print("\nPrimeras 5 entregas:")
    print(datos.head().to_string(index=False))
