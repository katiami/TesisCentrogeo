# ══════════════════════════════════════════════════════════════════════════════
# SCRIPT PARA GENERAR TABLA DE MÉTRICAS DE MODELOS BAYESIANOS
# ══════════════════════════════════════════════════════════════════════════════

library(dplyr)
library(INLA)
library(sf)
library(terra)
library(exactextractr)

cat("\n")
cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║              CÁLCULO DE MÉTRICAS PARA MODELOS BAYESIANOS GMB                ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n\n")

# ══════════════════════════════════════════════════════════════════════════════
# 1. CARGAR DATOS DE VALIDACIÓN
# ══════════════════════════════════════════════════════════════════════════════

cat("Cargando datos...\n")

# Cargar datos NFI completos
plot_WGS84 <- st_read("C:/Users/katy/Documents/Tesis_katy_github/codigo/CONAFOR/INF_WGS84.gpkg", quiet = TRUE)

# Dividir en entrenamiento (90%) y prueba (10%) usando la misma semilla
set.seed(123)  # Para reproducibilidad
dt <- sort(sample(nrow(plot_WGS84), nrow(plot_WGS84) * 0.9))
plot_WGS84_train <- plot_WGS84[dt,]
plot_WGS84_test <- plot_WGS84[-dt,]

# Obtener datos de prueba
plot_test <- plot_WGS84_test %>% st_transform("epsg:32616")
agbd.plot.test <- plot_test$biomasa_kg_C3
loc.plot.test <- st_coordinates(plot_test)

# Cargar rasters de covariables
hei.rast <- rast("C:/Users/katy/Documents/Tesis_Maestria/Forest_height_QROO_metricas.tif")
cci.rast <- rast("C:/Users/katy/Documents/Tesis_Maestria/ESA AGBD/CCI_CORTE_QINTANAROO.tif")

# Extraer covariables para los puntos de prueba
hei.plot.test <- exactextractr::exact_extract(hei.rast, st_buffer(plot_test, 56.42), 'mean')
cci.plot.test <- exactextractr::exact_extract(cci.rast, st_buffer(plot_test, 56.42), 'mean')

cat("  ✓ Datos cargados:", length(agbd.plot.test), "puntos de prueba\n\n")

# ══════════════════════════════════════════════════════════════════════════════
# 2. FUNCIÓN PARA CALCULAR MÉTRICAS
# ══════════════════════════════════════════════════════════════════════════════

calcular_metricas <- function(obs, pred) {
  rmse <- sqrt(mean((obs - pred)^2, na.rm = TRUE))
  mae <- mean(abs(obs - pred), na.rm = TRUE)
  r2 <- cor(obs, pred, use = "complete.obs")^2
  bias <- mean(pred - obs, na.rm = TRUE)
  return(c(RMSE = rmse, MAE = mae, R2 = r2, Bias = bias))
}

# ══════════════════════════════════════════════════════════════════════════════
# 3. CARGAR MODELOS Y CALCULAR PREDICCIONES
# ══════════════════════════════════════════════════════════════════════════════

resultados_modelos <- list()

# ──────────────────────────────────────────────────────────────────────────────
# MODELO SQRT
# ──────────────────────────────────────────────────────────────────────────────
cat("Procesando MODELO SQRT...\n")

tryCatch({
  load("C:/Users/katy/Documents/KATY_TESIS_CL/productos/INLA_model_fit.RData")

  # Calcular efectos espaciales
  alpha_spat_test <- model_fit$summary.random[[1]]$mean
  beta_spat_test <- model_fit$summary.random[[2]]$mean
  eta_spat_test <- model_fit$summary.random[[3]]$mean

  # Interpolar efectos espaciales a los puntos de prueba
  alpha_spat_test_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit$.args$data$mesh, loc = loc.plot.test),
    alpha_spat_test
  )
  beta_spat_test_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit$.args$data$mesh, loc = loc.plot.test),
    beta_spat_test
  )
  eta_spat_test_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit$.args$data$mesh, loc = loc.plot.test),
    eta_spat_test
  )

  # Obtener coeficientes fijos
  alpha <- model_fit$summary.fixed$mean[1]
  beta <- model_fit$summary.fixed$mean[2]
  eta <- model_fit$summary.fixed$mean[3]

  # Predicción en escala transformada
  pred_sqrt_transform <- (alpha + alpha_spat_test_interp) +
                          (beta + beta_spat_test_interp) * cci.plot.test +
                          (eta + eta_spat_test_interp) * hei.plot.test

  # Back-transform: elevar al cuadrado
  pred_sqrt <- pred_sqrt_transform^2

  # Calcular residuales
  residuales_sqrt <- agbd.plot.test - pred_sqrt

  # Test K-S para normalidad de residuales
  ks_residuales_sqrt <- ks.test(residuales_sqrt, "pnorm",
                                  mean = mean(residuales_sqrt, na.rm = TRUE),
                                  sd = sd(residuales_sqrt, na.rm = TRUE))

  # Test K-S de dos muestras: predicciones vs observaciones
  ks_pred_sqrt <- ks.test(pred_sqrt, agbd.plot.test)

  # Almacenar resultados
  resultados_modelos[["SQRT"]] <- list(
    predicciones = pred_sqrt,
    residuales = residuales_sqrt,
    metricas = calcular_metricas(agbd.plot.test, pred_sqrt),
    ks_residuales_p = ks_residuales_sqrt$p.value,
    ks_pred_vs_obs_p = ks_pred_sqrt$p.value,
    normalidad_ok = ks_residuales_sqrt$p.value > 0.05,
    ajuste_ok = ks_pred_sqrt$p.value > 0.05
  )

  cat("  ✓ Modelo SQRT procesado exitosamente\n")

}, error = function(e) {
  cat("  ✗ Error en modelo SQRT:", e$message, "\n")
})

# ──────────────────────────────────────────────────────────────────────────────
# MODELO LOG
# ──────────────────────────────────────────────────────────────────────────────
cat("Procesando MODELO LOG...\n")

tryCatch({
  load("C:/Users/katy/Documents/KATY_TESIS_CL/productos/INLA_model_log.RData")

  # Calcular efectos espaciales
  alpha_spat_test_log <- model_fit_v2$summary.random[[1]]$mean
  beta_spat_test_log <- model_fit_v2$summary.random[[2]]$mean
  eta_spat_test_log <- model_fit_v2$summary.random[[3]]$mean

  # Interpolar efectos espaciales a los puntos de prueba
  alpha_spat_test_log_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit_v2$.args$data$mesh, loc = loc.plot.test),
    alpha_spat_test_log
  )
  beta_spat_test_log_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit_v2$.args$data$mesh, loc = loc.plot.test),
    beta_spat_test_log
  )
  eta_spat_test_log_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit_v2$.args$data$mesh, loc = loc.plot.test),
    eta_spat_test_log
  )

  # Obtener coeficientes fijos
  alpha_log <- model_fit_v2$summary.fixed$mean[1]
  beta_log <- model_fit_v2$summary.fixed$mean[2]
  eta_log <- model_fit_v2$summary.fixed$mean[3]

  # Predicción en escala transformada
  pred_log_transform <- (alpha_log + alpha_spat_test_log_interp) +
                         (beta_log + beta_spat_test_log_interp) * cci.plot.test +
                         (eta_log + eta_spat_test_log_interp) * hei.plot.test

  # Back-transform: exponencial
  pred_log <- exp(pred_log_transform)

  # Calcular residuales
  residuales_log <- agbd.plot.test - pred_log

  # Test K-S para normalidad de residuales
  ks_residuales_log <- ks.test(residuales_log, "pnorm",
                                 mean = mean(residuales_log, na.rm = TRUE),
                                 sd = sd(residuales_log, na.rm = TRUE))

  # Test K-S de dos muestras: predicciones vs observaciones
  ks_pred_log <- ks.test(pred_log, agbd.plot.test)

  # Almacenar resultados
  resultados_modelos[["LOG"]] <- list(
    predicciones = pred_log,
    residuales = residuales_log,
    metricas = calcular_metricas(agbd.plot.test, pred_log),
    ks_residuales_p = ks_residuales_log$p.value,
    ks_pred_vs_obs_p = ks_pred_log$p.value,
    normalidad_ok = ks_residuales_log$p.value > 0.05,
    ajuste_ok = ks_pred_log$p.value > 0.05
  )

  cat("  ✓ Modelo LOG procesado exitosamente\n")

}, error = function(e) {
  cat("  ✗ Error en modelo LOG:", e$message, "\n")
})

# ──────────────────────────────────────────────────────────────────────────────
# MODELO NONE (sin transformación)
# ──────────────────────────────────────────────────────────────────────────────
cat("Procesando MODELO NONE...\n")

tryCatch({
  load("C:/Users/katy/Documents/KATY_TESIS_CL/productos/INLA_model_none.RData")

  # Calcular efectos espaciales
  alpha_spat_test_none <- model_fit_none$summary.random[[1]]$mean
  beta_spat_test_none <- model_fit_none$summary.random[[2]]$mean
  eta_spat_test_none <- model_fit_none$summary.random[[3]]$mean

  # Interpolar efectos espaciales a los puntos de prueba
  alpha_spat_test_none_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit_none$.args$data$mesh, loc = loc.plot.test),
    alpha_spat_test_none
  )
  beta_spat_test_none_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit_none$.args$data$mesh, loc = loc.plot.test),
    beta_spat_test_none
  )
  eta_spat_test_none_interp <- inla.mesh.project(
    inla.mesh.projector(model_fit_none$.args$data$mesh, loc = loc.plot.test),
    eta_spat_test_none
  )

  # Obtener coeficientes fijos
  alpha_none <- model_fit_none$summary.fixed$mean[1]
  beta_none <- model_fit_none$summary.fixed$mean[2]
  eta_none <- model_fit_none$summary.fixed$mean[3]

  # Predicción (sin transformación)
  pred_none <- (alpha_none + alpha_spat_test_none_interp) +
               (beta_none + beta_spat_test_none_interp) * cci.plot.test +
               (eta_none + eta_spat_test_none_interp) * hei.plot.test

  # Calcular residuales
  residuales_none <- agbd.plot.test - pred_none

  # Test K-S para normalidad de residuales
  ks_residuales_none <- ks.test(residuales_none, "pnorm",
                                  mean = mean(residuales_none, na.rm = TRUE),
                                  sd = sd(residuales_none, na.rm = TRUE))

  # Test K-S de dos muestras: predicciones vs observaciones
  ks_pred_none <- ks.test(pred_none, agbd.plot.test)

  # Almacenar resultados
  resultados_modelos[["NONE"]] <- list(
    predicciones = pred_none,
    residuales = residuales_none,
    metricas = calcular_metricas(agbd.plot.test, pred_none),
    ks_residuales_p = ks_residuales_none$p.value,
    ks_pred_vs_obs_p = ks_pred_none$p.value,
    normalidad_ok = ks_residuales_none$p.value > 0.05,
    ajuste_ok = ks_pred_none$p.value > 0.05
  )

  cat("  ✓ Modelo NONE procesado exitosamente\n")

}, error = function(e) {
  cat("  ✗ Error en modelo NONE:", e$message, "\n")
})

cat("\n")

# ══════════════════════════════════════════════════════════════════════════════
# 4. CREAR TABLA DE MÉTRICAS
# ══════════════════════════════════════════════════════════════════════════════

cat("Generando tabla de métricas...\n\n")

tabla_metricas <- data.frame()

for (modelo_nombre in names(resultados_modelos)) {
  res <- resultados_modelos[[modelo_nombre]]

  fila <- data.frame(
    Modelo = modelo_nombre,
    R2 = res$metricas["R2"],
    RMSE = res$metricas["RMSE"],
    MAE = res$metricas["MAE"],
    Bias = res$metricas["Bias"],
    KS_Residuales_p = res$ks_residuales_p,
    KS_Pred_vs_Obs_p = res$ks_pred_vs_obs_p,
    Normalidad_OK = res$normalidad_ok,
    Ajuste_OK = res$ajuste_ok,
    row.names = NULL
  )

  tabla_metricas <- rbind(tabla_metricas, fila)
}

# ══════════════════════════════════════════════════════════════════════════════
# 5. MOSTRAR Y GUARDAR RESULTADOS
# ══════════════════════════════════════════════════════════════════════════════

cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                     TABLA DE MÉTRICAS - MODELOS GMB                          ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n\n")

print(tabla_metricas, row.names = FALSE)

cat("\n")

# Guardar tabla como CSV
archivo_salida <- "C:/Users/katy/Documents/KATY_TESIS_CL/productos/tabla_metricas_modelos.csv"
write.csv(tabla_metricas, archivo_salida, row.names = FALSE)
cat("✓ Tabla guardada en:", archivo_salida, "\n\n")

# Guardar también como RDS para uso posterior en R
archivo_rds <- "C:/Users/katy/Documents/KATY_TESIS_CL/productos/tabla_metricas_modelos.rds"
saveRDS(tabla_metricas, archivo_rds)
cat("✓ Tabla guardada en formato RDS:", archivo_rds, "\n\n")

# ══════════════════════════════════════════════════════════════════════════════
# 6. ANÁLISIS DETALLADO
# ══════════════════════════════════════════════════════════════════════════════

cat("═══════════════════════════════════════════════════════════════════════════════\n")
cat("ANÁLISIS POR CRITERIO\n")
cat("═══════════════════════════════════════════════════════════════════════════════\n\n")

# Mejor R²
mejor_r2_idx <- which.max(tabla_metricas$R2)
cat("🏆 MEJOR R²:", tabla_metricas$Modelo[mejor_r2_idx],
    sprintf("(R² = %.4f)\n", tabla_metricas$R2[mejor_r2_idx]))

# Mejor RMSE
mejor_rmse_idx <- which.min(tabla_metricas$RMSE)
cat("🏆 MEJOR RMSE:", tabla_metricas$Modelo[mejor_rmse_idx],
    sprintf("(RMSE = %.4f Mg/ha)\n", tabla_metricas$RMSE[mejor_rmse_idx]))

# Mejor MAE
mejor_mae_idx <- which.min(tabla_metricas$MAE)
cat("🏆 MEJOR MAE:", tabla_metricas$Modelo[mejor_mae_idx],
    sprintf("(MAE = %.4f Mg/ha)\n", tabla_metricas$MAE[mejor_mae_idx]))

# Mejor Bias (más cercano a 0)
mejor_bias_idx <- which.min(abs(tabla_metricas$Bias))
cat("🏆 MEJOR BIAS:", tabla_metricas$Modelo[mejor_bias_idx],
    sprintf("(Bias = %.4f Mg/ha)\n", tabla_metricas$Bias[mejor_bias_idx]))

cat("\n")

# Modelos que pasan test de normalidad
cat("✓ Modelos con residuales normales (K-S p > 0.05):\n")
modelos_normales <- tabla_metricas$Modelo[tabla_metricas$Normalidad_OK]
if (length(modelos_normales) > 0) {
  for (m in modelos_normales) {
    cat("  -", m, "\n")
  }
} else {
  cat("  Ninguno\n")
}

cat("\n")

# Modelos con buen ajuste
cat("✓ Modelos con buen ajuste (K-S Pred vs Obs p > 0.05):\n")
modelos_ajuste <- tabla_metricas$Modelo[tabla_metricas$Ajuste_OK]
if (length(modelos_ajuste) > 0) {
  for (m in modelos_ajuste) {
    cat("  -", m, "\n")
  }
} else {
  cat("  Ninguno\n")
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════════════════════\n")
cat("Script completado exitosamente.\n")
cat("═══════════════════════════════════════════════════════════════════════════════\n")
