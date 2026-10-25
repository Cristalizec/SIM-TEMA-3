
from dataclasses import dataclass
from typing import Optional


@dataclass
class Pedido:

    numero_pedido: int
    tipo_entrega: str
    distancia_km: float
    peso_kg: float

    origen_dato: str = "simulado"
    simulacion_id: Optional[int] = None
    id: Optional[int] = None

    # Validar los datos del pedido
    def __post_init__(self):

        if self.numero_pedido <= 0:
            raise ValueError(
                "El número de pedido debe ser positivo"
            )

        if self.distancia_km < 0:
            raise ValueError(
                "La distancia no puede ser negativa"
            )

        if self.peso_kg <= 0:
            raise ValueError(
                "El peso debe ser mayor que cero"
            )

    # Convertir el pedido en un diccionario
    def to_dict(self):

        return {
            "id": self.id,
            "simulacion_id": self.simulacion_id,
            "numero_pedido": self.numero_pedido,
            "tipo_entrega": self.tipo_entrega,
            "distancia_km": self.distancia_km,
            "peso_kg": self.peso_kg,
            "origen_dato": self.origen_dato
        }

    # Mostrar información del pedido
    def mostrar_info(self):

        return (
            f"Pedido: {self.numero_pedido}\n"
            f"Tipo de entrega: {self.tipo_entrega}\n"
            f"Distancia: {self.distancia_km:.2f} km\n"
            f"Peso: {self.peso_kg:.2f} kg\n"
            f"Origen del dato: {self.origen_dato}"
        )
