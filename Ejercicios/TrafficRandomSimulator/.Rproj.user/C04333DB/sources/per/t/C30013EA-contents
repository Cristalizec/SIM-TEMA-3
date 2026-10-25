
# ==========================================
# TRAFFIC RANDOM SIMULATOR
# Conexion con PostgreSQL
# ==========================================

library(DBI)
library(RPostgres)

# Cargar configuracion privada
if (file.exists(".Renviron")) {
  readRenviron(".Renviron")
}

# Funcion para conectar con PostgreSQL

get_connection <- function() {
  
  password <- Sys.getenv(
    "DB_PASSWORD",
    unset = ""
  )
  
  conexion <- DBI::dbConnect(
    RPostgres::Postgres(),
    
    dbname = Sys.getenv(
      "DB_NAME",
      "traffic_simulator_db"
    ),
    
    host = Sys.getenv(
      "DB_HOST",
      "localhost"
    ),
    
    port = as.integer(
      Sys.getenv("DB_PORT", "5432")
    ),
    
    user = Sys.getenv(
      "DB_USER",
      "postgres"
    ),
    
    password = password
  )
  
  return(conexion)
}



# Funcion para probar la conexion
test_connection <- function() {
  
  conexion <- NULL
  
  tryCatch({
    
    conexion <- get_connection()
    
    resultado <- DBI::dbGetQuery(
      conexion,
      "SELECT current_database() AS base_datos,
              current_user AS usuario"
    )
    
    cat("\n================================\n")
    cat("CONEXION EXITOSA CON POSTGRESQL\n")
    cat("================================\n")
    
    cat(
      "Base de datos:",
      resultado$base_datos,
      "\n"
    )
    
    cat(
      "Usuario:",
      resultado$usuario,
      "\n"
    )
    
    cat(
      "Estado: CONECTADO\n"
    )
    
    return(TRUE)
    
  }, error = function(error) {
    
    cat("\nERROR DE CONEXION\n")
    cat(conditionMessage(error), "\n")
    
    return(FALSE)
    
  }, finally = {
    
    if (!is.null(conexion) &&
        DBI::dbIsValid(conexion)) {
      
      DBI::dbDisconnect(conexion)
    }
    
  })
}

