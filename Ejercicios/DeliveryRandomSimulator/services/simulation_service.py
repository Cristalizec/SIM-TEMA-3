
from dataclasses import dataclass

import numpy as np

from models.pedido import Pedido
from models.entrega import Entrega
from services.dataset_service import cargar_dataset


# Métodos de generación
METODOS = [
    "Transformada inversa",
    "Convolución",
    "Composición"
]

# Velocidad estimada de los repartidores
VELOCIDAD_KMH = 35.0


# Resultado de una simulación
@dataclass
class ResultadoSimulacion:

    metodo: str
    pedidos: list[Pedido]
    entregas: list[Entrega]
    numeros_uniformes: list[float]

    @property
    def tiempo_promedio(self):

        return sum(
            entrega.tiempo_total
            for entrega in self.entregas
        ) / len(self.entregas)


# Generar número uniforme
def _uniforme(rng, registro):

    u = float(rng.random())

    registro.append(u)

    return u


# Método de transformada inversa
# Distribución exponencial
def _exponencial(media, rng, registro):

    u = _uniforme(rng, registro)

    return -media * np.log1p(-u)


# Seleccionar método de generación
def _generar_tiempo(metodo, media, rng, registro):

    # Transformada inversa
    if metodo == "Transformada inversa":

        return _exponencial(
            media,
            rng,
            registro
        )

    # Convolución:
    # Suma de dos exponenciales independientes
    if metodo == "Convolución":

        tiempo1 = _exponencial(
            media / 2,
            rng,
            registro
        )

        tiempo2 = _exponencial(
            media / 2,
            rng,
            registro
        )

        return tiempo1 + tiempo2

    # Composición:
    # Mezcla de dos distribuciones exponenciales
    if metodo == "Composición":

        seleccion = _uniforme(
            rng,
            registro
        )

        if seleccion < 0.80:

            return _exponencial(
                media * 0.75,
                rng,
                registro
            )

        else:

            return _exponencial(
                media * 2,
                rng,
                registro
            )

    raise ValueError(
        "Método de generación no reconocido."
    )


# Ejecutar simulación de entregas
def simular_entregas(
    metodo,
    cantidad_pedidos,
    semilla=None
):

    # Validar método
    if metodo not in METODOS:

        raise ValueError(
            "Selecciona un método válido."
        )

    # Validar número de pedidos
    if not 1 <= cantidad_pedidos <= 1000:

        raise ValueError(
            "La cantidad de pedidos debe estar "
            "entre 1 y 1000."
        )

    # Cargar dataset
    datos = cargar_dataset()

    # Generador aleatorio
    rng = np.random.default_rng(semilla)

    # Seleccionar registros del dataset
    indices = rng.integers(
        0,
        len(datos),
        size=cantidad_pedidos
    )

    muestras = datos.iloc[indices]

    # Calcular tiempos promedio por tipo
    medias_preparacion = (
        datos.groupby("tipo_entrega")[
            "tiempo_preparacion_min"
        ].mean().to_dict()
    )

    # Calcular demoras del transporte
    retrasos = (
        datos["tiempo_transporte_min"]
        - datos["distancia_km"]
        / VELOCIDAD_KMH * 60
    ).clip(lower=0.1)

    medias_retraso = retrasos.groupby(
        datos["tipo_entrega"]
    ).mean().to_dict()

    # Listas de resultados
    pedidos = []
    entregas = []
    uniformes = []

    # Generar pedidos
    for numero, fila in enumerate(
        muestras.itertuples(index=False),
        start=1
    ):

        tipo = fila.tipo_entrega

        # Crear pedido
        pedido = Pedido(
            numero_pedido=numero,
            tipo_entrega=tipo,
            distancia_km=float(
                fila.distancia_km
            ),
            peso_kg=float(
                fila.peso_kg
            ),
            origen_dato="simulado_desde_dataset"
        )

        # Generar tiempo de preparación
        preparacion = round(
            float(
                _generar_tiempo(
                    metodo,
                    medias_preparacion[tipo],
                    rng,
                    uniformes
                )
            ),
            2
        )

        # Generar demora aleatoria
        retraso = float(
            _generar_tiempo(
                metodo,
                medias_retraso[tipo],
                rng,
                uniformes
            )
        )

        # Calcular transporte
        transporte = round(
            pedido.distancia_km
            / VELOCIDAD_KMH * 60
            + retraso,
            2
        )

        # Calcular tiempo total
        total = round(
            preparacion + transporte,
            2
        )

        # Crear entrega
        entrega = Entrega(
            tiempo_preparacion=preparacion,
            tiempo_transporte=transporte,
            tiempo_total=total,
            estado="Entregado"
        )

        pedidos.append(pedido)
        entregas.append(entrega)

    # Devolver resultados
    return ResultadoSimulacion(
        metodo=metodo,
        pedidos=pedidos,
        entregas=entregas,
        numeros_uniformes=uniformes
    )


# Prueba del simulador
if __name__ == "__main__":

    resultado = simular_entregas(
        metodo="Transformada inversa",
        cantidad_pedidos=5,
        semilla=123
    )

    print("\nSIMULACIÓN DE ENTREGAS")
    print("------------------------")

    for pedido, entrega in zip(
        resultado.pedidos,
        resultado.entregas
    ):

        print(
            f"Pedido {pedido.numero_pedido}: "
            f"{pedido.tipo_entrega} | "
            f"{pedido.distancia_km} km | "
            f"{entrega.tiempo_total:.2f} min"
        )

    print(
        f"\nTiempo promedio: "
        f"{resultado.tiempo_promedio:.2f} min"
    )
