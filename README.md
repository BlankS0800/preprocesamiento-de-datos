# 📊 Preprocesamiento de Datos: Relación Empleado - Empleador (INE Bolivia)

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Online-success?style=for-the-badge&logo=github)](https://blanks0800.github.io/preprocesamiento-de-datos/)
[![R Version](https://img.shields.io/badge/R-v4.6.1-blue?style=for-the-badge&logo=r)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

> **Pipeline analítico y metodológico en R** para la auditoría, depuración e ingeniería de características de los microdatos de la **Encuesta de Hogares (EH)** del **Instituto Nacional de Estadística (INE) de Bolivia**, orientado a resolver la problemática de calidad del empleo, formalidad contractual y equidad salarial entre **Empleado y Empleador**.

🌐 **Acceso al Informe Web Interactivo (GitHub Pages):**  
👉 **[https://blanks0800.github.io/preprocesamiento-de-datos/](https://blanks0800.github.io/preprocesamiento-de-datos/)**

---

## 📑 Estructura del Repositorio

| Archivo / Carpeta | Descripción |
|:---|:---|
| [`index.html`](index.html) | Página principal para **GitHub Pages** con dashboard interactivo en modo oscuro (*Deep Navy Theme*) y bitácora colapsable. |
| [`INFORME_PREPROCESAMIENTO_EMPLEO.docx`](INFORME_PREPROCESAMIENTO_EMPLEO.docx) | Informe técnico formal en **Microsoft Word** con portada, índice general, desarrollo metodológico y 10 figuras integradas. |
| [`INFORME_PREPROCESAMIENTO_EMPLEO.md`](INFORME_PREPROCESAMIENTO_EMPLEO.md) | Versión completa del informe técnico en formato Markdown. |
| [`BITACORA_LIMPIEZA_DATOS.md`](BITACORA_LIMPIEZA_DATOS.md) | Bitácora técnica detallada (*Audit Trail*) con las 12 intervenciones de preprocesamiento, justificaciones y códigos en R. |
| [`bitacora_limpieza_datos.csv`](bitacora_limpieza_datos.csv) | Matriz tabular de control de calidad con métricas antes vs. después. |
| [`preprocesamiento_empleo.R`](preprocesamiento_empleo.R) | Script principal en R que ejecuta el flujo de 12 etapas de forma 100% reproducible. |
| [`dataset_empleo_limpio.csv`](dataset_empleo_limpio.csv) | Dataset final curado con **6,925 trabajadores asalariados dependientes y 43 variables analíticas** (0.00% valores nulos). |
| [`dataset_modelado_empleado_empleador.rds`](dataset_modelado_empleado_empleador.rds) | Objeto nativo de R que preserva factores, variables continuas estandarizadas Z-Score y partición Train (80%) / Test (20%). |
| [`plots/`](plots/) | Directorio de gráficos diagnósticos generados con `ggplot2` y capturas de la plataforma web. |

---

## 🎯 Resumen del Pipeline (12 Etapas en R)

1. **LIM-01 (Universo Asalariado):** Aislamiento de 6,951 empleados dependientes (`condact == 1` & `s04b_12 == 1`).
2. **LIM-02 (Edad Legal):** Exclusión de 26 menores de 15 años conforme a OIT/Ley 548 (muestra ajustada a 6,925).
3. **LIM-03 (Consistencia Lógica):** Corrección cronológica de escolaridad (`aestudio <= edad - 6`).
4. **LIM-04 (Jornada Laboral):** Capping a 84 h/sem y reconciliación de horas diarias/semanales.
5. **LIM-05 (Imputación Salarial):** Imputación condicional de 2 NAs por donante de grupo homogéneo (Sexo, Nivel, Sector).
6. **LIM-06 (Winsorización Salarial):** Capping a percentiles robustos p0.5-p99.5 y transformación logarítmica.
7. **LIM-07 (Tipado de Factores):** Conversión a factores ordenados en R de atributos sociodemográficos y patronales.
8. **LIM-08 (Atributos Empleador):** Generación de 4 estratos empresariales y 10 macro-sectores CAEB.
9. **LIM-09 (Atributos Empleado):** Capital humano de Mincer, experiencia cuadrática, sobrejornada (>48h) y salario submínimo.
10. **LIM-10 (Construcción Targets):** Target OIT de formalidad laboral (`formalidad_laboral`: 39.99% formal vs 60.01% informal) y score de beneficios (0-3).
11. **LIM-11 (Normalización Z-Score):** Escalado paramétrico ($\mu=0, \sigma=1$) en variables continuas.
12. **LIM-12 (Partición Estratificada):** Segmentación reproducible 80% Train ($n=5,540$) y 20% Test ($n=1,385$) con semilla 2026.

---

## 🚀 Replicación en R

Para ejecutar el flujo de preprocesamiento completo en R:
```r
# Clonar el repositorio
# git clone https://github.com/BlankS0800/preprocesamiento-de-datos.git

# Ejecutar el script en R
source("preprocesamiento_empleo.R")
```

---
*Desarrollado para el ciclo de Minería de Datos 2026 &bull; Encuesta de Hogares INE Bolivia.*
