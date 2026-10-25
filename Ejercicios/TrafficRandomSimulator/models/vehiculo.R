
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Modelo de vehiculos
# ==========================================

# Tipos de vehiculos disponibles
TIPOS_VEHICULOS <- c(
  "Automovil",
  "Motocicleta",
  "Camion",
  "Autobus"
)


# Validar valores numericos
validar_numero <- function(valor, nombre,
                           permitir_cero = TRUE) {
  
  if (!is.numeric(valor) ||
      length(valor) != 1 ||
      is.na(valor) ||
      !is.finite(valor)) {
    
    stop(paste(
      nombre,
      "debe ser un numero valido."
    ))
  }
  
  if (permitir_cero) {
    
    if (valor < 0) {
      stop(paste(
        nombre,
        "no puede ser negativo."
      ))
    }
    
  } else {
    
    if (valor <= 0) {
      stop(paste(
        nombre,
        "debe ser mayor que cero."
      ))
    }
  }
}


# Crear un vehiculo
crear_vehiculo <- function(
    numero_vehiculo,
    tipo_vehiculo,
    velocidad_kmh,
    intervalo_llegada_seg,
    tiempo_llegada_seg,
    tiempo_cruce_seg) {
  
  # Validar numero de vehiculo
  validar_numero(
    numero_vehiculo,
    "Numero de vehiculo",
    FALSE
  )
  
  if (numero_vehiculo !=
      floor(numero_vehiculo)) {
    
    stop(
      "El numero de vehiculo debe ser entero."
    )
  }
  
  # Validar tipo de vehiculo
  if (length(tipo_vehiculo) != 1 ||
      is.na(tipo_vehiculo) ||
      !tipo_vehiculo %in% TIPOS_VEHICULOS) {
    
    stop("Tipo de vehiculo no valido.")
  }
  
  # Validar velocidad
  validar_numero(
    velocidad_kmh,
    "Velocidad",
    FALSE
  )
  
  # Validar intervalo de llegada
  validar_numero(
    intervalo_llegada_seg,
    "Intervalo de llegada"
  )
  
  # Validar tiempo de llegada
  validar_numero(
    tiempo_llegada_seg,
    "Tiempo de llegada"
  )
  
  # Validar tiempo de cruce
  validar_numero(
    tiempo_cruce_seg,
    "Tiempo de cruce",
    FALSE
  )
  
  # Crear el registro del vehiculo
  vehiculo <- data.frame(
    
    numero_vehiculo = as.integer(
      numero_vehiculo
    ),
    
    tipo_vehiculo = tipo_vehiculo,
    
    velocidad_kmh = round(
      velocidad_kmh, 2
    ),
    
    intervalo_llegada_seg = round(
      intervalo_llegada_seg, 2
    ),
    
    tiempo_llegada_seg = round(
      tiempo_llegada_seg, 2
    ),
    
    tiempo_cruce_seg = round(
      tiempo_cruce_seg, 2
    ),
    
    stringsAsFactors = FALSE
  )
  
  return(vehiculo)
}


# Generar un tipo de vehiculo aleatorio
generar_tipo_vehiculo <- function() {
  
  tipo <- sample(
    TIPOS_VEHICULOS,
    size = 1,
    prob = c(
      0.60,
      0.25,
      0.10,
      0.05
    )
  )
  
  return(tipo)
}


# Generar una velocidad aleatoria
generar_velocidad <- function(tipo_vehiculo) {
  
  velocidad <- switch(
    
    tipo_vehiculo,
    
    "Automovil" = runif(1, 25, 60),
    
    "Motocicleta" = runif(1, 30, 65),
    
    "Camion" = runif(1, 15, 40),
    
    "Autobus" = runif(1, 20, 45),
    
    stop("Tipo de vehiculo desconocido.")
  )
  
  return(round(velocidad, 2))
}


# Mostrar informacion del vehiculo
mostrar_vehiculo <- function(vehiculo) {
  
  cat("\n================================\n")
  cat("INFORMACION DEL VEHICULO\n")
  cat("================================\n")
  
  print(vehiculo)
  
  cat("\nRegistro generado correctamente.\n")
}
