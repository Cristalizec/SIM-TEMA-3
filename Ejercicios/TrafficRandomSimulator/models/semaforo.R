
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Modelo de semaforos
# ==========================================

# Validar tiempos numericos
validar_tiempo <- function(valor, nombre,
                           permitir_cero = TRUE) {
  
  if (!is.numeric(valor) ||
      length(valor) != 1 ||
      is.na(valor) ||
      !is.finite(valor)) {
    
    stop(paste(nombre, "no es valido."))
  }
  
  if (permitir_cero) {
    
    if (valor < 0) {
      stop(paste(
        nombre, "no puede ser negativo."
      ))
    }
    
  } else {
    
    if (valor <= 0) {
      stop(paste(
        nombre, "debe ser mayor que cero."
      ))
    }
  }
}


# Crear un semaforo
crear_semaforo <- function(
    nombre = "Semaforo principal",
    verde_segundos = 40,
    amarillo_segundos = 5,
    rojo_segundos = 35) {
  
  if (!is.character(nombre) ||
      length(nombre) != 1 ||
      is.na(nombre) ||
      !nzchar(trimws(nombre))) {
    
    stop("El nombre del semaforo no es valido.")
  }
  
  validar_tiempo(
    verde_segundos,
    "Tiempo verde",
    FALSE
  )
  
  validar_tiempo(
    amarillo_segundos,
    "Tiempo amarillo"
  )
  
  validar_tiempo(
    rojo_segundos,
    "Tiempo rojo",
    FALSE
  )
  
  tiempos <- c(
    verde_segundos,
    amarillo_segundos,
    rojo_segundos
  )
  
  if (any(tiempos != floor(tiempos))) {
    stop("Los tiempos deben ser segundos enteros.")
  }
  
  ciclo <- sum(tiempos)
  
  semaforo <- list(
    nombre = nombre,
    verde_segundos = verde_segundos,
    amarillo_segundos = amarillo_segundos,
    rojo_segundos = rojo_segundos,
    ciclo_segundos = ciclo
  )
  
  return(semaforo)
}


# Obtener el estado del semaforo
estado_semaforo <- function(
    tiempo_actual,
    semaforo) {
  
  validar_tiempo(
    tiempo_actual,
    "Tiempo actual"
  )
  
  posicion <- tiempo_actual %%
    semaforo$ciclo_segundos
  
  if (posicion < semaforo$verde_segundos) {
    
    return("Verde")
    
  } else if (
    posicion <
    semaforo$verde_segundos +
    semaforo$amarillo_segundos
  ) {
    
    return("Amarillo")
    
  } else {
    
    return("Rojo")
  }
}


# Calcular el siguiente inicio de cruce
calcular_inicio_cruce <- function(
    tiempo_disponible,
    tiempo_cruce,
    semaforo) {
  
  validar_tiempo(
    tiempo_disponible,
    "Tiempo disponible"
  )
  
  validar_tiempo(
    tiempo_cruce,
    "Tiempo de cruce",
    FALSE
  )
  
  # El vehiculo debe terminar de cruzar
  # antes de que termine la luz verde.
  if (tiempo_cruce > semaforo$verde_segundos) {
    
    stop(
      "El tiempo de cruce supera la fase verde."
    )
  }
  
  ciclo <- semaforo$ciclo_segundos
  
  posicion <- tiempo_disponible %% ciclo
  
  # Si puede cruzar durante esta luz verde
  if (
    posicion + tiempo_cruce <=
    semaforo$verde_segundos
  ) {
    
    return(tiempo_disponible)
  }
  
  # Esperar el siguiente ciclo verde
  siguiente_ciclo <- (
    floor(tiempo_disponible / ciclo) + 1
  ) * ciclo
  
  return(siguiente_ciclo)
}


# Calcular el tiempo de espera
calcular_espera_semaforo <- function(
    tiempo_llegada,
    tiempo_cruce,
    semaforo) {
  
  inicio <- calcular_inicio_cruce(
    tiempo_llegada,
    tiempo_cruce,
    semaforo
  )
  
  espera <- inicio - tiempo_llegada
  
  return(espera)
}


# Mostrar informacion del semaforo
mostrar_semaforo <- function(semaforo) {
  
  cat("\n================================\n")
  cat("CONFIGURACION DEL SEMAFORO\n")
  cat("================================\n")
  
  cat("Nombre:", semaforo$nombre, "\n")
  
  cat(
    "Luz verde:",
    semaforo$verde_segundos,
    "segundos\n"
  )
  
  cat(
    "Luz amarilla:",
    semaforo$amarillo_segundos,
    "segundos\n"
  )
  
  cat(
    "Luz roja:",
    semaforo$rojo_segundos,
    "segundos\n"
  )
  
  cat(
    "Duracion del ciclo:",
    semaforo$ciclo_segundos,
    "segundos\n"
  )
}
