
import numpy as np

from scipy import stats

from services.simulation_service import simular_entregas


# Nivel de significancia
ALFA = 0.05


# Calcular estadísticas descriptivas
def calcular_estadisticas(resultado):

    tiempos = np.array([
        entrega.tiempo_total
        for entrega in resultado.entregas
    ], dtype=float)

    if len(tiempos) == 0:
        raise ValueError(
            "No existen entregas para analizar."
        )

    estadisticas = {
        "cantidad_pedidos": len(tiempos),
        "tiempo_promedio": float(np.mean(tiempos)),
        "mediana": float(np.median(tiempos)),
        "desviacion_estandar": float(
            np.std(tiempos, ddof=1)
        ) if len(tiempos) > 1 else 0.0,
        "tiempo_minimo": float(np.min(tiempos)),
        "tiempo_maximo": float(np.max(tiempos)),
        "varianza": float(
            np.var(tiempos, ddof=1)
        ) if len(tiempos) > 1 else 0.0
    }

    return estadisticas


# Prueba de uniformidad
# Kolmogorov-Smirnov
def prueba_uniformidad(numeros):

    datos = np.asarray(numeros, dtype=float)

    if len(datos) < 5:
        return {
            "nombre_prueba": "Kolmogorov-Smirnov",
            "estadistico": None,
            "valor_p": None,
            "resultado": "Datos insuficientes"
        }

    # Comparar con Uniforme(0,1)
    estadistico, valor_p = stats.kstest(
        datos,
        "uniform"
    )

    if valor_p >= ALFA:
        decision = "No se rechaza H0"
    else:
        decision = "Se rechaza H0"

    return {
        "nombre_prueba": "Kolmogorov-Smirnov",
        "estadistico": float(estadistico),
        "valor_p": float(valor_p),
        "resultado": decision
    }


# Prueba de independencia
# Prueba de corridas respecto a 0.5
def prueba_independencia(numeros):

    datos = np.asarray(numeros, dtype=float)

    if len(datos) < 10:
        return {
            "nombre_prueba": "Prueba de corridas",
            "estadistico": None,
            "valor_p": None,
            "resultado": "Datos insuficientes"
        }

    # Clasificar números respecto a 0.5
    signos = datos >= 0.5

    n1 = int(np.sum(signos))
    n2 = int(len(signos) - n1)

    if n1 == 0 or n2 == 0:
        return {
            "nombre_prueba": "Prueba de corridas",
            "estadistico": None,
            "valor_p": None,
            "resultado": "Datos insuficientes"
        }

    # Contar corridas
    corridas = 1 + np.sum(
        signos[1:] != signos[:-1]
    )

    n = len(signos)

    # Media esperada
    media = 1 + (2 * n1 * n2) / n

    # Varianza esperada
    varianza = (
        2 * n1 * n2 * (2 * n1 * n2 - n)
    ) / (
        n ** 2 * (n - 1)
    )

    if varianza <= 0:
        return {
            "nombre_prueba": "Prueba de corridas",
            "estadistico": None,
            "valor_p": None,
            "resultado": "Datos insuficientes"
        }

    # Estadístico Z
    z = (corridas - media) / np.sqrt(varianza)

    # Valor p bilateral
    valor_p = 2 * stats.norm.sf(abs(z))

    if valor_p >= ALFA:
        decision = "No se rechaza H0"
    else:
        decision = "Se rechaza H0"

    return {
        "nombre_prueba": "Prueba de corridas",
        "estadistico": float(z),
        "valor_p": float(valor_p),
        "resultado": decision
    }


# Ejecutar todas las pruebas estadísticas
def analizar_simulacion(resultado):

    # Estadísticas descriptivas
    resumen = calcular_estadisticas(resultado)

    # Números uniformes utilizados
    uniformes = resultado.numeros_uniformes

    # Pruebas estadísticas
    uniformidad = prueba_uniformidad(
        uniformes
    )

    independencia = prueba_independencia(
        uniformes
    )

    return {
        "resumen": resumen,
        "pruebas": [
            uniformidad,
            independencia
        ]
    }


# Probar el módulo
if __name__ == "__main__":

    print("ANÁLISIS ESTADÍSTICO")
    print("------------------------------")

    # Generar simulación
    simulacion = simular_entregas(
        metodo="Transformada inversa",
        cantidad_pedidos=100,
        semilla=123
    )

    # Analizar resultados
    analisis = analizar_simulacion(simulacion)

    resumen = analisis["resumen"]

    print("\nESTADÍSTICAS DESCRIPTIVAS")

    print(
        "Cantidad de pedidos:",
        resumen["cantidad_pedidos"]
    )

    print(
        f"Tiempo promedio: "
        f"{resumen['tiempo_promedio']:.2f} min"
    )

    print(
        f"Mediana: "
        f"{resumen['mediana']:.2f} min"
    )

    print(
        f"Desviación estándar: "
        f"{resumen['desviacion_estandar']:.2f}"
    )

    print(
        f"Varianza: "
        f"{resumen['varianza']:.2f}"
    )

    print(
        f"Tiempo mínimo: "
        f"{resumen['tiempo_minimo']:.2f} min"
    )

    print(
        f"Tiempo máximo: "
        f"{resumen['tiempo_maximo']:.2f} min"
    )

    print("\nPRUEBAS ESTADÍSTICAS")

    for prueba in analisis["pruebas"]:

        print(
            "\nPrueba:",
            prueba["nombre_prueba"]
        )

        if prueba["valor_p"] is not None:

            print(
                f"Estadístico: "
                f"{prueba['estadistico']:.4f}"
            )

            print(
                f"Valor p: "
                f"{prueba['valor_p']:.4f}"
            )

        print(
            "Resultado:",
            prueba["resultado"]
        )
