# Guión de Presentación: Regresión de Biomasa usando Embeddings AlphaEarth

## INTRODUCCIÓN (2-3 minutos)

### Contexto del Problema

Buenos días/tardes. Hoy presento un análisis de regresión lineal para predecir biomasa forestal utilizando embeddings satelitales de Google AlphaEarth.

**¿Qué estamos haciendo?**
- Predecir la biomasa aérea total por conglomerado forestal
- Usar características del paisaje extraídas de imágenes satelitales (embeddings)
- Evaluar si las señales espectrales pueden capturar la estructura forestal

**¿Por qué es importante?**
- Los inventarios forestales en campo son costosos y laboriosos
- Las imágenes satelitales cubren grandes áreas de forma continua
- Si los embeddings predicen bien la biomasa, podríamos mapear biomasa a escala regional

---

## METODOLOGÍA (5-7 minutos)

### 1. Datos de Entrada

**Embeddings AlphaEarth (Google Earth Engine)**
- Extraídos con un buffer de 56.42 metros de radio (aproximadamente 1 hectárea)
- Cada conglomerado tiene 1 fila con 128 embeddings
- 64 medias (z00-z63): representan el valor promedio de cada banda espectral
- 64 varianzas (v00-v63): capturan la heterogeneidad espacial del paisaje

Estos embeddings son representaciones comprimidas de imágenes satelitales que capturan:
- Estructura de la vegetación
- Cobertura forestal
- Textura del paisaje
- Condiciones del sitio

**Inventario Forestal Nacional (INFyS)**
- Datos de árboles individuales medidos en campo
- 4 sitios circulares de 0.04 ha cada uno por conglomerado
- Total: 0.16 ha muestreadas por conglomerado
- Variables: diámetro, altura, especie de cada árbol
- Biomasa individual calculada con ecuaciones alométricas específicas por especie

### 2. Preparación de Datos

**Paso 1: Estandarización de nombres**
- Google Earth Engine trunca nombres largos
- IdConglomerado aparece como IdConglome en los embeddings
- El código detecta y renombra automáticamente

**Paso 2: Agregación de biomasa**
Este es un paso crítico debido a diferencias en granularidad:
- INF: múltiples árboles por conglomerado (datos individuales)
- Embeddings: 1 fila por conglomerado (paisaje agregado)

Solución: Agregar biomasa por conglomerado
```
Para cada conglomerado:
  1. Sumar biomasa_kg_C3 de todos los árboles
  2. Convertir kg a Mg (dividir entre 1000)
  3. Extrapolar a Mg/ha (dividir entre 0.16 ha)
```

**¿Por qué Mg/ha?**
- Área muestreada: 0.16 ha (4 × 0.04 ha)
- Área de embeddings: ~1 ha (buffer de 56.42m)
- Necesitamos igualar escalas espaciales para comparación justa

**Paso 3: JOIN de datos (1:1)**
- Unir biomasa agregada con embeddings por IdConglomerado
- Resultado: 1 fila por conglomerado con biomasa_Mg_ha + 128 embeddings

### 3. Verificación de Calidad de Datos

**Varianza en predictores**
- Verificamos que los embeddings tienen varianza
- Sin varianza = información constante = inútil para predicción
- Eliminamos columnas con varianza < 1e-10

**Valores faltantes e infinitos**
- Buscamos y eliminamos NA e infinitos
- Garantizamos datos numéricos válidos

**Dimensionalidad (p vs n)**
Si tenemos más predictores que observaciones (p > n):
- Advertencia de posible sobreajuste
- En nuestro caso: 128 embeddings vs número de conglomerados
- La regresión puede ajustar perfectamente el training pero fallar en generalización

### 4. Modelado

**División Train-Test (80-20)**
- 80% de datos para entrenar el modelo
- 20% de datos para evaluar desempeño
- Semilla fija (123) para reproducibilidad

**Validación Cruzada K-Fold (K=10)**
- Método adicional para evaluar estabilidad del modelo
- Divide datos en 10 particiones (folds)
- Entrena 10 modelos, cada uno usando 9 folds para entrenar y 1 para validar
- Calcula promedio y desviación estándar de métricas
- Objetivo: detectar sobreajuste y evaluar robustez

**Modelo: Regresión Lineal Múltiple**
```
biomasa_Mg_ha = β₀ + β₁×z00 + β₂×z01 + ... + β₁₂₈×v63 + ε
```

Donde:
- biomasa_Mg_ha: variable respuesta
- z00-z63, v00-v63: 128 predictores (embeddings)
- β₀, β₁, ..., β₁₂₈: coeficientes a estimar
- ε: error residual

---

## RESULTADOS (5-7 minutos)

### 1. Estadísticas Descriptivas de Biomasa

**Distribución de la variable respuesta**
- Mostrar histograma de biomasa por conglomerado
- Rango de valores (mínimo, máximo)
- Media y mediana
- Coeficiente de variación

**Interpretación:**
- Si CV > 50%: alta variabilidad entre conglomerados
- Distribución sesgada vs simétrica
- Presencia de outliers en el boxplot

### 2. Desempeño del Modelo

**Métricas principales:**

**R² (Coeficiente de Determinación)**
- Indica qué porcentaje de la varianza en biomasa explica el modelo
- Rango: 0 a 1 (0% a 100%)

Interpretación:
- R² > 0.7: EXCELENTE - embeddings capturan fuertemente la estructura forestal
- R² > 0.5: BUENO - relación clara entre paisaje y biomasa
- R² > 0.3: MODERADO - hay señal pero con variabilidad no explicada
- R² < 0.3: LIMITADO - baja capacidad predictiva

**RMSE (Error Cuadrático Medio)**
- Error promedio en Mg/ha
- Penaliza más los errores grandes
- Contexto: comparar con la media de biomasa

**MAE (Error Absoluto Medio)**
- Error promedio absoluto en Mg/ha
- No penaliza errores grandes
- Más robusto a outliers que RMSE

**Ejemplo de interpretación:**
Si tenemos:
- Media de biomasa: 150 Mg/ha
- RMSE: 30 Mg/ha
- Error relativo: 30/150 = 20%

Esto significa que las predicciones se desvían en promedio 20% del valor real.

**Validación Cruzada K-Fold**
- Promedio de R² en 10 folds: [completar con resultado]
- Desviación estándar: [completar]
- Coeficiente de variación: [completar]

Interpretación de estabilidad:
- CV < 10%: modelo MUY ESTABLE
- CV 10-20%: variabilidad MODERADA (esperada)
- CV > 20%: modelo INESTABLE (posible sobreajuste)

**Detección de Sobreajuste:**

Comparar R² de train vs validación cruzada:
- Gap < 0.05: NO sobreajuste
- Gap 0.05-0.15: sobreajuste LIGERO (aceptable)
- Gap > 0.15: sobreajuste SIGNIFICATIVO (problema)

Si hay sobreajuste:
- Considerar regularización (Ridge, Lasso)
- Reducir número de predictores
- Aumentar tamaño de muestra

### 3. Visualizaciones Clave

**Gráfico de Predicciones vs Valores Reales**
- Línea diagonal roja = predicción perfecta
- Puntos cerca de la línea = buen ajuste
- Dispersión amplia = bajo ajuste

Qué buscar:
- Patrones sistemáticos (predicción consistentemente alta o baja en ciertos rangos)
- Heterocedasticidad (variabilidad cambia con el nivel de biomasa)

**Análisis de Residuos**
- Residuo = valor real - valor predicho
- Idealmente: distribuidos aleatoriamente alrededor de cero
- Sin patrones = supuestos de regresión se cumplen

### 4. Variables Más Importantes

**Top embeddings con mayor coeficiente**
- Identifica qué características del paisaje son más predictivas
- Coeficientes positivos: aumentan biomasa
- Coeficientes negativos: disminuyen biomasa

**Interpretación:**
Por ejemplo, si v15 (varianza de la banda 15) tiene un coeficiente alto:
- Mayor heterogeneidad espacial se asocia con mayor/menor biomasa
- Puede reflejar estructura forestal compleja

---

## DISCUSIÓN (3-5 minutos)

### Fortalezas del Enfoque

1. **Escalamiento espacial apropiado**
   - Biomasa extrapolada a Mg/ha para igualar escala de embeddings
   - Comparación justa entre datos de campo y satelitales

2. **Simplicidad e interpretabilidad**
   - Regresión lineal es transparente
   - Coeficientes tienen interpretación directa

3. **Uso de embeddings pre-entrenados**
   - AlphaEarth captura patrones complejos de imágenes satelitales
   - No requiere entrenamiento de redes neuronales profundas

### Limitaciones y Consideraciones

1. **Problema de alta dimensionalidad (si p > n)**
   - 128 predictores pueden ser muchos si tenemos pocos conglomerados
   - Riesgo de sobreajuste
   - Posibles soluciones futuras: regularización (Ridge, Lasso), selección de variables

2. **Supuestos de regresión lineal**
   - Linealidad: relación entre embeddings y biomasa es lineal
   - Independencia: conglomerados son independientes
   - Homocedasticidad: varianza constante de residuos
   - Normalidad: residuos distribuidos normalmente

   Verificar con gráficos de diagnóstico

3. **Variabilidad no capturada**
   - Factores locales no visibles desde satélite
   - Especies específicas con densidades de madera diferentes
   - Perturbaciones recientes (huracanes, incendios)

4. **Escala temporal**
   - Embeddings: promedio 2017-2024
   - INFyS: mediciones de 2019
   - Posible desajuste temporal si hubo cambios importantes

### Posibles Mejoras Futuras

1. **Regularización**
   - Ridge regression: penaliza coeficientes grandes
   - Lasso: selecciona variables importantes automáticamente
   - Elastic Net: combinación de ambas

2. **Variables adicionales**
   - Variables climáticas (precipitación, temperatura)
   - Variables topográficas (elevación, pendiente)
   - Índices de vegetación (NDVI, EVI)

3. **Modelos más complejos**
   - Random Forest: captura no-linealidades
   - Gradient Boosting: predicciones más precisas
   - Modelos espaciales: consideran autocorrelación espacial

---

## CONCLUSIONES (2 minutos)

### Hallazgos Principales

1. **Capacidad predictiva de los embeddings**
   - [Completar según resultados: R² = X%]
   - Los embeddings de AlphaEarth [capturan / capturan parcialmente / no capturan bien] la variabilidad en biomasa forestal

2. **Implicaciones prácticas**
   - Si R² > 0.5: viable para mapeo de biomasa a escala regional
   - Si R² < 0.5: necesario complementar con otras variables o modelos más complejos

3. **Contribución metodológica**
   - Demostración de uso de embeddings satelitales para estimación de biomasa
   - Protocolo para escalar correctamente datos de campo vs remotos

### Mensaje Final

Los embeddings satelitales de AlphaEarth representan una herramienta prometedora para estimar biomasa forestal a partir de características del paisaje. El nivel de precisión alcanzado [completar según resultados] sugiere que [esta aproximación es viable / requiere refinamiento] para aplicaciones de monitoreo forestal.

El escalamiento espacial apropiado (0.16 ha → Mg/ha) fue crítico para obtener resultados interpretables. Trabajos futuros deberían explorar [mencionar según resultados: regularización si hay sobreajuste, variables adicionales si R² es bajo, validación espacial, etc.].

---

## PREGUNTAS ANTICIPADAS Y RESPUESTAS

### P1: ¿Por qué no usar PCA para reducir dimensionalidad?

**R:** Decidimos trabajar con los embeddings originales porque:
- Queremos identificar qué embeddings específicos son más importantes
- PCA crearía componentes que son combinaciones lineales difíciles de interpretar
- Si el modelo presenta problemas de sobreajuste, consideraremos regularización (Ridge/Lasso) que mantiene interpretabilidad

### P2: ¿Cómo justifican la extrapolación de 0.16 ha a Mg/ha?

**R:** Es una normalización espacial necesaria porque:
- Los embeddings capturan información de ~1 ha (buffer 56.42m)
- El inventario muestrea 0.16 ha distribuidos en 4 sitios
- Al expresar ambos en Mg/ha, los hacemos comparables en la misma escala
- Asumimos que los 4 sitios son representativos del conglomerado completo

### P3: ¿Qué pasa si hay autocorrelación espacial?

**R:** Es una limitación potencial:
- Conglomerados cercanos pueden ser similares
- Viola supuesto de independencia en regresión lineal
- Soluciones:
  - Verificar con test de Moran's I
  - Usar modelos espaciales (SAR, CAR) si es necesario
  - División train-test espacialmente estratificada

### P4: ¿Por qué regresión lineal y no machine learning?

**R:** Comenzamos con regresión lineal por:
- Interpretabilidad: entendemos qué embeddings son importantes
- Baseline: establece rendimiento mínimo esperado
- Transparencia: fácil de auditar y explicar
- Si los resultados son prometedores, podemos explorar Random Forest, XGBoost, etc.

### P5: ¿Qué significa que un embedding tiene coeficiente negativo?

**R:** Significa que:
- Mayor valor de ese embedding se asocia con menor biomasa
- Puede reflejar características del paisaje:
  - Ejemplo: alta varianza podría indicar áreas fragmentadas con baja biomasa
  - O alta reflectancia en ciertas bandas podría indicar suelos expuestos
- Requiere interpretación cuidadosa con conocimiento del dominio

---

## MATERIAL DE APOYO

### Ecuaciones Clave

**Biomasa agregada:**
```
biomasa_Mg_ha = (Σ biomasa_kg_árbol / 1000) / 0.16
```

**Modelo de regresión:**
```
ŷ = β₀ + Σ(βᵢ × xᵢ)
donde i = 1, ..., 128
```

**Métricas:**
```
R² = 1 - (SS_res / SS_tot)
RMSE = √(Σ(y - ŷ)² / n)
MAE = Σ|y - ŷ| / n
```

### Glosario

- **Embedding**: Representación comprimida de imágenes satelitales
- **AlphaEarth**: Modelo de Google para generar embeddings de imágenes de la Tierra
- **Conglomerado**: Unidad de muestreo del inventario forestal
- **Mg/ha**: Megagramos por hectárea = toneladas métricas por hectárea
- **Ecuación alométrica**: Fórmula que relaciona dimensiones del árbol (diámetro, altura) con biomasa
- **Buffer**: Área circular alrededor de un punto central
- **Granularidad**: Nivel de detalle de los datos (individual vs agregado)

---

## CRONOGRAMA DE PRESENTACIÓN

| Sección | Tiempo | Contenido Clave |
|---------|--------|-----------------|
| Introducción | 2-3 min | Problema, importancia, objetivos |
| Metodología | 5-7 min | Datos, preparación, modelado |
| Resultados | 5-7 min | Métricas, visualizaciones, variables importantes |
| Discusión | 3-5 min | Fortalezas, limitaciones, mejoras futuras |
| Conclusiones | 2 min | Hallazgos, implicaciones, mensaje final |
| Preguntas | 5-10 min | Responder audiencia |
| **TOTAL** | **22-34 min** | |

### Recomendaciones de Presentación

1. **Preparar 3 versiones:**
   - Corta (15 min): Intro + Resultados + Conclusiones
   - Media (25 min): Completa sin profundizar
   - Larga (35 min): Completa con detalles técnicos

2. **Visualizaciones esenciales:**
   - Diagrama de flujo del análisis
   - Histograma de biomasa
   - Scatter plot predicciones vs reales (test set)
   - Gráfico de residuos
   - Top 10 embeddings importantes

3. **Práctica:**
   - Ensayar transiciones entre secciones
   - Tener respuestas listas para preguntas anticipadas
   - Conocer bien las cifras exactas de resultados
   - Practicar explicar conceptos técnicos en términos simples

---

**Última actualización:** [Fecha]
**Versión:** 1.0
