# Instrucciones para Convertir el Speech a PDF

## Archivo creado:
- `speech_presentacion_modelo.md` - Guión completo de presentación del modelo

## Opciones para convertir a PDF:

### Opción 1: Usando Pandoc (Recomendado)

Si tienes Pandoc instalado:

```bash
pandoc speech_presentacion_modelo.md -o speech_presentacion_modelo.pdf --pdf-engine=xelatex -V geometry:margin=1in
```

Si no tienes Pandoc, instálalo desde: https://pandoc.org/installing.html

### Opción 2: Usando RStudio

1. Abre `speech_presentacion_modelo.md` en RStudio
2. Agrega al inicio del archivo:
```yaml
---
output: pdf_document
---
```
3. Haz clic en "Knit to PDF"

### Opción 3: Usando VS Code

Si tienes VS Code con extensión Markdown PDF:
1. Abre `speech_presentacion_modelo.md`
2. Presiona Ctrl+Shift+P
3. Busca "Markdown PDF: Export (pdf)"

### Opción 4: Conversión Online

1. Ve a https://www.markdowntopdf.com/
2. Sube el archivo `speech_presentacion_modelo.md`
3. Descarga el PDF generado

### Opción 5: Usando Google Chrome

1. Abre `speech_presentacion_modelo.md` en un visor markdown (GitHub, VS Code preview, etc.)
2. Presiona Ctrl+P (imprimir)
3. Selecciona "Guardar como PDF"
4. Ajusta márgenes y guarda

## Personalización

Para mejor formato en PDF, puedes agregar al inicio del archivo markdown:

```yaml
---
title: "Guión de Presentación: Regresión de Biomasa usando Embeddings"
author: "Tu Nombre"
date: "`r Sys.Date()`"
output:
  pdf_document:
    toc: true
    toc_depth: 3
    number_sections: true
fontsize: 11pt
geometry: margin=1in
---
```

## Contenido del Speech

El documento incluye:
- Introducción (2-3 min)
- Metodología (5-7 min)
- Resultados (5-7 min)
- Discusión (3-5 min)
- Conclusiones (2 min)
- Preguntas anticipadas y respuestas
- Material de apoyo (ecuaciones, glosario)
- Cronograma de presentación

Total: 22-34 minutos de presentación
