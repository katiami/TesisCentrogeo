# KATY_TESIS_CL - Modelo Bayesiano para Estimación de Biomasa

Este repositorio contiene los códigos organizados para el análisis de biomasa aérea en Quintana Roo utilizando un enfoque geoestadístico bayesiano.

## Estructura del Repositorio

```
KATY_TESIS_CL/
├── modelo_bayesiano/          # Códigos de análisis
│   ├── 01_preprocesamiento_altura_GFCH.ipynb
│   ├── 02_preprocesamiento_limpieza_gdi_cci.Rmd
│   └── 03_modelo_bayesiano_GMB.Rmd
├── insumos/                   # Datos de entrada
│   ├── QuintanaRoo_Entidad_wgs84.gpkg
│   ├── INF_WGS84.gpkg
│   ├── Forest_height_QROO_metricas.tif
│   ├── CCI_CORTE_QINTANAROO.tif
│   └── Forest_height_2019_NAM.tif (5.3 GB)
├── productos/                 # Datos generados
│   ├── Forest_height_QROO.tif
│   ├── hei.tif
│   ├── biomasa.tif
│   ├── NFI_CCI_GEDIheights_2.csv
│   └── INLA_model_*.RData
└── README.md
```

## Orden de Ejecución

Los códigos deben ejecutarse en el siguiente orden:

### 1. Preprocesamiento de Altura Forestal (GFCH 2019)
**Archivo:** `01_preprocesamiento_altura_GFCH.ipynb`

**Descripción:** Recorta el raster global de altura forestal de GFCH 2019 al área de Quintana Roo.

**Entrada:**
- `insumos/QuintanaRoo_Entidad_wgs84.gpkg` - Límite administrativo
- `insumos/Forest_height_2019_NAM.tif` - Raster global de altura forestal GFCH 2019 (5.3 GB)

**Salida:**
- `productos/Forest_height_QROO.tif` - Altura forestal recortada para Quintana Roo

---

### 2. Limpieza y Preprocesamiento de Datos GEDI y CCI
**Archivo:** `02_preprocesamiento_limpieza_gdi_cci.Rmd`

**Descripción:** Procesa los datos del Inventario Forestal Nacional (INF), altura GEDI y biomasa CCI. Aplica recorte espacial, limpieza de valores inválidos y extracción de datos en las parcelas del INF.

**Entrada:**
- `insumos/QuintanaRoo_Entidad_wgs84.gpkg` - Límite administrativo
- `insumos/INF_WGS84.gpkg` - Datos del Inventario Forestal
- `productos/Forest_height_QROO.tif` - Altura GFCH (del paso 1)
- `insumos/Forest_height_QROO_metricas.tif` - Métricas de altura GEDI
- `insumos/CCI_CORTE_QINTANAROO.tif` - Biomasa CCI-ESA

**Salida:**
- `productos/hei.tif` - Raster de altura limpio
- `productos/biomasa.tif` - Raster de biomasa limpio

**Procesos:**
- Reproyección a EPSG:32616 (UTM zona 16N)
- Recorte espacial con máscara de Quintana Roo
- Eliminación de píxeles con valores ≤ 0
- Extracción de valores promedio en parcelas del INF (buffer de 56.42 m)

---

### 3. Modelo Geoestadístico Bayesiano
**Archivo:** `03_modelo_bayesiano_GMB.Rmd`

**Descripción:** Implementa el modelo geoestadístico bayesiano (GMB) utilizando INLA para estimar biomasa aérea, integrando datos del INF con covariables de teledetección (altura GEDI y biomasa CCI).

**Entrada:**
- `insumos/QuintanaRoo_Entidad_wgs84.gpkg` - Límite administrativo
- `insumos/INF_WGS84.gpkg` - Datos del Inventario Forestal
- `productos/hei.tif` - Altura limpia (del paso 2)
- `productos/biomasa.tif` - Biomasa limpia (del paso 2)

**Salida:**
- `productos/NFI_CCI_GEDIheights_2.csv` - Dataset integrado
- `productos/INLA_model_fit.RData` - Modelo entrenado
- Predicciones de biomasa con incertidumbre asociada

**Características del Modelo:**
- Enfoque bayesiano jerárquico
- Utiliza INLA (Integrated Nested Laplace Approximations)
- Incorpora efectos espaciales mediante mallas (mesh)
- Validación con 10% de datos separados

---

## Requisitos de Software

### Para Python (archivo .ipynb):
- Python 3.x
- geopandas
- rasterio
- matplotlib
- contextily

### Para R (archivos .Rmd):
- R 4.x
- Paquetes: terra, sf, dplyr, ggplot2, exactextractr, INLA, inlabru, fmesher, tidyterra, viridis

## Metodología

El flujo de trabajo implementa un modelo geoestadístico bayesiano para la estimación de biomasa aérea. El modelo sigue la forma:

```
y(s) = (α + α̃(s)) + (β + β̃(s))·x1(s) + (η + η̃(s))·x2(s) + ε(s)
```

Donde:
- `y(s)` es la biomasa estimada en la ubicación s
- `x1(s)` es la covariable de biomasa CCI
- `x2(s)` es la covariable de altura GEDI
- `α, β, η` son parámetros de regresión constantes
- `α̃, β̃, η̃` son efectos espaciales autocorrelacionados
- `ε(s)` es el error aleatorio

## Notas Importantes

1. **Rutas Relativas:** Todos los códigos usan rutas relativas (`../insumos/`, `../productos/`) para facilitar la portabilidad del repositorio.

2. **Productos Intermedios:** Los archivos en la carpeta `productos/` son generados automáticamente por los scripts anteriores y sirven como entrada para scripts posteriores.

3. **División Train/Test:** El código 03 divide los datos del INF en 90% entrenamiento y 10% validación de forma aleatoria.

4. **Tamaño del Repositorio:** Debido al archivo `Forest_height_2019_NAM.tif` (5.3 GB), el repositorio completo ocupa aproximadamente 5.5 GB.

## Contacto

Para preguntas sobre este repositorio, contactar a la autora de la tesis.
