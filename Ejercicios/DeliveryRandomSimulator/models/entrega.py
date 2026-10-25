
from dataclasses import dataclass
from typing import Optional
import math


@dataclass
class Entrega:

    tiempo_preparacion: float
    tiempo_transporte: float
    tiempo_total: float
    estado: str = "Entregado"

    pedido_id: Optional[int] = None
    id: Optional[int] = None

    # Validar datos de la entrega
    def __post_init__(self):

        tiempos = [
            self.tiempo_preparacion,
            self.tiempo_transporte,
            self.tiempo_total
        ]

        if not all(
            math.isfinite(valor) and valor >= 0
            for valor in tiempos
        ):
            raise ValueError(
                "Los tiempos deben ser números finitos "
                "y no negativos."
            )

        if not math.isclose(
            self.tiempo_total,
            self.tiempo_preparacion + self.tiempo_transporte,
            abs_tol=0.01
        ):
            raise ValueError(
                "El tiempo total debe ser la suma "
                "de preparación y transporte."
            )

    # Convertir entrega a diccionario
    def to_dict(self):

        return {
            "id": self.id,
            "pedido_id": self.pedido_id,
            "tiempo_preparacion": self.tiempo_preparacion,
            "tiempo_transporte": self.tiempo_transporte,
            "tiempo_total": self.tiempo_total,
            "estado": self.estado
        }
