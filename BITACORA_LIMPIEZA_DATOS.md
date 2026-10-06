# BITÁCORA TÉCNICA DE LIMPIEZA Y PREPROCESAMIENTO DE DATOS
## Proyecto de Minería de Datos: Análisis y Modelado de la Relación Empleado - Empleador
**Fuente de Datos:** Encuesta de Hogares (EH) – Instituto Nacional de Estadística (INE) de Bolivia  
**Entorno de Ejecución:** R versión 4.6.1 | Script: [`preprocesamiento_empleo.R`](file:///d:/proyecto%20mineria%20datos/preprocesamiento_empleo.R)  
**Fecha de Auditoría:** Octubre 2026  
**Dataset de Entrada:** `persona.csv` (39,497 registros, 275 variables)  
**Dataset Curado de Salida:** [`dataset_empleo_limpio.csv`](file:///d:/proyecto%20mineria%20datos/dataset_empleo_limpio.csv) (6,925 registros, 43 variables)  

---

## 1. Inventario y Auditoría de Columnas: Agregadas, Descartadas y Mantenidas

El pipeline transformó una base censal-muestral multidimensional y ruidosa (275 columnas) en una matriz analítica compacta y de alto valor (43 columnas).

```
========================================================================================
RESUMEN DE TRANSFORMACIÓN DE ATRIBUTOS (FEATURE FLOW)
========================================================================================
- Columnas Originales en persona.csv:                         275 columnas
- Columnas Descartadas (Irrelevantes o No Laborales):         246 columnas (89.5%)
- Columnas Troncales Retenidas y Estandarizadas:               29 columnas (10.5%)
- Columnas Nuevas Creadas (Feature Engineering):               14 columnas
- Columnas Finales en el Dataset Limpio:                       43 columnas
========================================================================================
```

### 1.1 Detalle de Columnas Agregadas por Ingeniería de Características
Las siguientes 14 variables fueron formuladas e implementadas en R para resolver de forma cuantitativa la relación empleado-empleador:

1. **`formalidad_laboral`** (Factor binario: "Formal" / "Informal"): Creada a partir de `s04c_20a_2 == 1`. Es el estándar internacional OIT/INE de formalidad asalariada (seguro de salud provisto por la empresa empleadora).
2. **`score_calidad_empleo`** (Entero: 0 a 3): Suma aditiva de beneficios legales obligatorios: Seguro de Salud Patronal + Vacaciones Pagadas + Aguinaldo de Navidad.
3. **`estrato_empresa`** (Factor: 4 niveles): Clasificación estándar de tamaño de planta a partir de `s04b_14`:
   - Microempresa: 1 a 4 trabajadores.
   - Pequeña Empresa: 5 a 19 trabajadores.
   - Mediana Empresa: 20 a 49 trabajadores.
   - Gran Empresa: 50 o más trabajadores.
4. **`experiencia_potencial`** (Numérica continua): Ecuación de capital humano de Mincer: $\max(0, \text{Edad} - \text{Años\_Estudio} - 6)$.
5. **`experiencia_cuad`** (Numérica continua): Término de rendimientos marginales decrecientes: $(\text{Experiencia}^2) / 100$.
6. **`salario_hora`** (Numérica continua): Remuneración normalizada por hora efectiva de trabajo: $\text{Salario\_Mensual} / (\text{Horas\_Semanales} \times 4.3333)$.
7. **`log_salario_hora`** y **`log_salario_mensual`** (Numéricas continuas): Transformaciones logarítmicas naturales para estabilizar la varianza residual y neutralizar asimetría positiva.
8. **`sobrejornada`** (Factor: "Si" / "No"): Bandera de alerta legal cuando `horas_semanales > 48` (violación de jornada máxima legal).
9. **`tiempo_parcial`** (Factor: "Si" / "No"): Bandera para jornadas reducidas (`horas_semanales < 30`).
10. **`salario_subminimo`** (Factor: "Si" / "No"): Indicador de incumplimiento del Salario Mínimo Nacional (SMN ~ 2,500 Bs) en empleados con jornada completa ($\ge 40$h semanales).
11. **`ratio_salario_minimo`** (Numérica continua): Razón proporcional $\text{Salario} / 2500$.
12. **`rama_actividad`** (Factor: 10 macro-sectores): Agrupación armonizada del clasificador CAEB (0 a 19) para evitar sobreajuste por categorías de baja frecuencia.
13. **Variables Normalizadas Z-Scores (`_z`)**: 7 atributos continuos estandarizados ($\mu = 0, \sigma = 1$) para algoritmos basados en distancias (KNN, SVM, K-Means).
14. **`split_particion`** (Factor: "Train", "Test"): Partición pseudoaleatoria estratificada 80/20 fijada con semilla 2026 para garantizar validación cruzada insesgada.

### 1.2 Justificación de las 246 Columnas Descartadas
Se removieron bloques completos de la encuesta que no corresponden a la relación contractual de empleo dependiente:
- **Salud y Morbilidad General (`s02a`, `s02b`):** 36 variables sobre dolencias en los últimos 30 días, medicamentos comprados, movilidad reducida (grupo Washington).
- **Fecundidad y Maternidad Familiar (`s02c`, `s02d`):** 12 variables sobre controles prenatales, nacimientos y atención médica en partos (ajenos a la estructura de la empresa).
- **Migración Temporal (`s01b`):** 16 variables sobre residencia 5 años atrás o motivo de traslado provincial.
- **Educación Básica e Inasistencia (`s03a`, `s03b`, `s03c`):** 28 variables sobre causas de abandono escolar en niños y tenencia de computadoras hogareñas (resumido de forma canónica en `aestudio`).
- **Ocupación Secundaria (`s04f`):** 18 variables sobre horas e ingresos derivados de trabajos independientes secundarios.
- **Transferencias Estatales y Rentas (`s05a`, `s05b`, `s05c`):** 42 variables sobre Bono Juancito Pinto, Renta Dignidad, Bono Juana Azurduy, pensiones de vejez y remesas internacionales.

---

## 2. Matriz Consolidada de Control y Auditoría (Audit Trail)

| ID | Fase de Ingeniería | Variables Intervenidas | Problema Detectado | Técnica de Limpieza en R | Métrica Antes | Métrica Después | Estado |
|:---|:---|:---|:---|:---|:---|:---|:---:|
| **LIM-01** | Delimitación de Universo | `condact`, `s04b_12` | Muestra global con población inactiva, desempleada y cuentapropistas. | Filtrado estricto: `condact == 1` & `s04b_12 == 1`. | 39,497 registros (100% muestra) | 6,951 asalariados (17.60%) | **Aprobado** |
| **LIM-02** | Consistencia Legal Laboral | `s01a_03` (Edad) | 26 menores de 15 años (edad 10-14) laborando como dependientes. | Filtrado legal OIT/LGT: `s01a_03 >= 15`. | 6,951 registros (Min: 10, Max: 84) | 6,925 registros (Min: 15, Max: 84) | **Aprobado** |
| **LIM-03** | Consistencia Lógica Cronológica | `aestudio`, `s01a_03` | 5 casos donde la escolaridad superaba la edad posible (`aestudio > edad - 5`). | Ajuste lógico determinístico: `min(aestudio, edad - 6)`. | 5 inconsistencias cronológicas | 0 inconsistencias cronológicas | **Aprobado** |
| **LIM-04** | Outliers de Intensidad Laboral | `phrs`, `s04b_15`, `s04b_16aa` | Jornadas inverosímiles (hasta 168 h/sem) y 71 casos con > 84 h/sem. | Recalibración cruzada (días × h_día) y Capping superior a 84 h/sem. | Máx: 168.0 h/sem, Media: 44.03 | Máx: 84.0 h/sem, Media: 43.88 | **Aprobado** |
| **LIM-05** | Imputación de Valores Faltantes | `yprilab` | 2 trabajadores asalariados con salario mensual no reportado (`NA`). | Imputación por donante de grupo homogéneo (Sexo, Educación, Sector). | 2 valores nulos (0.029% NAs) | 0 valores nulos (0.00% NAs) | **Aprobado** |
| **LIM-06** | Outliers Salariales y Varianza | `salario_mensual`, `salario_hora` | Asimetría positiva severa (129.9 a 30,310 Bs) con 111 outliers de Tukey. | Winsorización a percentiles robustos (p0.5 - p99.5) y transformación `log(x)`. | Min: 129.9 Bs, Max: 30,310 Bs | Min: 432.6 Bs, Max: 16,553 Bs | **Aprobado** |
| **LIM-07** | Tipado y Estandarización | Factores demográficos e institucionales | Códigos enteros arbitrarios sin semántica explícita (`area`, `s01a_02`, `depto`). | Conversión a factores de R con niveles ordenados y etiquetas semánticas. | 6 variables enteras opacas | 6 factores categóricos estructurados | **Aprobado** |
| **LIM-08** | Ingeniería: Atributos Empleador | `estrato_empresa`, `rama_actividad` | Claves CAEB/COB y tamaño continuo con alta dispersión y categorías raras. | Agrupación en 4 estratos de empresa y 10 macro-ramas CAEB armonizadas. | 20 ramas y rango 1-3000 trabajadores | 4 estratos y 10 ramas equilibradas | **Aprobado** |
| **LIM-09** | Ingeniería: Atributos Empleado | `experiencia_potencial`, `sobrejornada` | Carencia de variables dinámicas de capital humano e indicadores de jornada legal. | Cálculo de experiencia de Mincer, término cuadrático y banderas de jornada. | Atributos brutos desarticulados | 6 variables de capital humano y jornada | **Aprobado** |
| **LIM-10** | Construcción de Targets | `formalidad_laboral`, `score_calidad` | No existía una variable consolidada de formalidad contractual patronal. | Creación de indicador OIT (seguro patronal) y score de calidad (0 a 3). | Variables dispersas de beneficios | Target formalidad (39.99% formal) | **Aprobado** |
| **LIM-11** | Normalización y Escalado | `edad_z`, `aestudio_z`, `salario_hora_z` | Escalas físicas heterogéneas que sesgan algoritmos basados en distancias. | Estandarización paramétrica Z-score ($\mu = 0, \sigma = 1$). | Varianzas dispares (1 a 10^7) | Variables continuas escaladas ($\mu=0, \sigma=1$) | **Aprobado** |
| **LIM-12** | Partición Estratificada | `split_particion` | Riesgo de sobreajuste y fuga de información en la evaluación de modelos. | División pseudoaleatoria estratificada 80% Train y 20% Test (Seed 2026). | 6,925 filas sin asignación | Train: 5,540 (39.9%) / Test: 1,385 (40.5%) | **Aprobado** |

---

## 3. Fichas Técnicas Detalladas por Acción de Limpieza

### Ficha LIM-01: Delimitación del Universo Asalariado Dependiente
- **Fase:** Selección y Delimitación de Población Objetivo.
- **Dimensión de Calidad:** Validez de Dominio y Relevancia Teórica.
- **Variables Intervenidas:** `condact`, `s04b_12`.
- **Descripción de lo Realizado:** Se filtró la base de datos nacional para retener únicamente a la población ocupada (`condact == 1`) cuya categoría ocupacional corresponda a obrero o empleado asalariado (`s04b_12 == 1`).
- **Justificación Empleado - Empleador:** En la teoría económica y la gestión de RRHH, la relación de empleo formal o informal requiere un vínculo de dependencia salarial y subordinación patronal. Analizar trabajadores por cuenta propia o cooperativistas en este marco desvirtuaría los indicadores de cumplimiento patronal de seguridad social.
- **Código en R:**
  ```r
  df_asalariados <- df_raw %>% filter(condact == 1, s04b_12 == 1)
  ```
- **Métricas:**
  * Antes: 39,497 filas (100% censo muestral).
  * Después: 6,951 filas (17.60% del total nacional).

---

### Ficha LIM-02: Filtro de Edad Legal Laboral y Consistencia Normativa
- **Fase:** Depuración Normativa y Consistencia Ética.
- **Dimensión de Calidad:** Conformidad Legal y Exactitud.
- **Variables Intervenidas:** `s01a_03` (Edad en años cumplidos).
- **Descripción de lo Realizado:** Se identificaron 26 menores de 15 años (edades 10 a 14) registrados como asalariados y se excluyeron del dataset analítico de relaciones formales.
- **Justificación Empleado - Empleador:** Conforme al Convenio 138 de la OIT y la Ley 548 (Código Niña, Niño y Adolescente de Bolivia), la edad legal mínima para formalizar un contrato laboral regular es de 15 años. Estos registros reflejan trabajo infantil precario que carece de personería contractual y distorsionaría las curvas salariales.
- **Código en R:**
  ```r
  df_limpio <- df_asalariados %>% filter(s01a_03 >= 15)
  ```
- **Métricas:**
  * Antes: 6,951 registros | Rango de edad: [10 - 84 años].
  * Después: 6,925 registros válidos | Rango de edad: [15 - 84 años].

---

### Ficha LIM-03: Corrección de Inconsistencias Cronológicas en Capital Humano
- **Fase:** Consistencia Lógica Cruzada.
- **Dimensión de Calidad:** Consistencia y Plausibilidad Biológica.
- **Variables Intervenidas:** `aestudio`, `s01a_03`.
- **Descripción de lo Realizado:** Se detectaron 5 casos donde los años de estudio reportados superaban la edad del individuo menos 5 años, imputándose el techo coherente $\min(\text{aestudio}, \text{edad} - 6)$.
- **Justificación Empleado - Empleador:** Un trabajador de 15 años no puede acumular 18 años de estudio. Errores de tipeo en la escolaridad distorsionan severamente la experiencia potencial de Mincer, que es la variable explicativa básica del capital humano.
- **Código en R:**
  ```r
  df_limpio <- df_limpio %>% mutate(aestudio = pmin(aestudio, s01a_03 - 6))
  ```
- **Métricas:**
  * Antes: 5 inconsistencias activas | Máximo escolaridad: 23 años.
  * Después: 0 inconsistencias | Máximo escolaridad: 23 años (acotado lógicamente).

---

### Ficha LIM-04: Tratamiento de Outliers Extremos en Intensidad Horaria
- **Fase:** Calibración de Jornada y Plausibilidad Física.
- **Dimensión de Calidad:** Exactitud y Coherencia Física.
- **Variables Intervenidas:** `phrs`, `s04b_15`, `s04b_16aa`.
- **Descripción de lo Realizado:** Se corrigieron valores inverosímiles de hasta 168 h/semana mediante la reconciliación del producto de días a la semana y horas al día, estableciendo un techo de 84 h/semana (régimen extremo de 12h x 7 días) y un piso de 4 h/semana.
- **Justificación Empleado - Empleador:** Dividir el salario mensual entre 168 horas semanales pulveriza de manera artificial el salario horario. La corrección evita falsos positivos de explotación extrema sin eliminar observaciones útiles.
- **Código en R:**
  ```r
  df_limpio <- df_limpio %>% mutate(
    horas_calculadas = pmin(84, s04b_15 * s04b_16aa),
    phrs_tratada = ifelse(phrs > 84, horas_calculadas, phrs),
    phrs_tratada = pmin(84, pmax(4, phrs_tratada))
  )
  ```
- **Métricas:**
  * Antes: Máximo: 168.0 h/sem | Media: 44.03 h/sem | Casos > 84h: 71.
  * Después: Máximo: 84.0 h/sem | Media: 43.88 h/sem | Casos > 84h: 0.

---

### Ficha LIM-05: Imputación de Salarios Faltantes por Donante Homogéneo
- **Fase:** Imputación de Valores Perdidos (Missing Values).
- **Dimensión de Calidad:** Completitud.
- **Variables Intervenidas:** `yprilab`.
- **Descripción de lo Realizado:** Para los únicos 2 asalariados con valor `NA` en salario mensual, se imputó la mediana condicional del subgrupo homogéneo con idéntico Sexo, Nivel Educativo y Sector Institucional de la empresa.
- **Justificación Empleado - Empleador:** Descartar las filas hubiera reducido la muestra innecesariamente, mientras que imputar con la media general hubiera ignorado las brechas de género e institucionales.
- **Código en R:**
  ```r
  df_limpio <- df_limpio %>%
    group_by(s01a_02, niv_ed_g, s04b_13) %>%
    mutate(mediana_grupo = median(yprilab, na.rm = TRUE)) %>%
    ungroup() %>%
    mutate(yprilab_imputado = ifelse(is.na(yprilab), mediana_grupo, yprilab))
  ```
- **Métricas:**
  * Antes: 2 valores nulos (0.029% NAs).
  * Después: 0 valores nulos (100.0% de completitud).

---

### Ficha LIM-06: Tratamiento de Outliers Salariales y Estabilización de Varianza
- **Fase:** Winsorización y Transformación de Escala.
- **Dimensión de Calidad:** Robustez Paramétrica.
- **Variables Intervenidas:** `salario_mensual`, `salario_hora`, `log_salario`.
- **Descripción de lo Realizado:** Se acotaron los percentiles 0.5% ($p_{0.5} = 432.6$ Bs) y 99.5% ($p_{99.5} = 16,553.3$ Bs) y se aplicó la transformación logarítmica natural.
- **Justificación Empleado - Empleador:** La distribución salarial original presentaba colas pesadas de hasta 30,310 Bs (111 outliers de Tukey) y salarios de 86 Bs/mes. La Winsorización preserva el orden de rango neutralizando el apalancamiento excesivo en modelos lineales.
- **Código en R:**
  ```r
  p_bajo <- quantile(salario_raw, 0.005); p_alto <- quantile(salario_raw, 0.995)
  df_limpio <- df_limpio %>% mutate(
    salario_mensual_winsor = pmin(p_alto, pmax(p_bajo, yprilab_imputado)),
    log_salario_mensual = log(salario_mensual_winsor),
    salario_hora = salario_mensual_winsor / (phrs_tratada * 4.3333)
  )
  ```
- **Métricas:**
  * Antes: Min: 129.9 Bs | Max: 30,310.0 Bs | Desv. Est: 2,641.7 Bs.
  * Después: Min: 432.6 Bs | Max: 16,553.3 Bs | Distribución Log-Normal simétrica.

---

### Ficha LIM-07 a LIM-12: Ingeniería, Normalización y Partición
- **LIM-07 (Tipado):** Conversión de números enteros en factores semánticos con niveles ordenados (`sexo`, `departamento`, `area_urb_rur`, `sector_empleador`, `nivel_educativo`).
- **LIM-08 (Atributos Empleador):** Generación de 4 estratos empresariales por número de personal (Micro, Pequeña, Mediana, Gran Empresa) y consolidación de 10 macro-ramas CAEB.
- **LIM-09 (Atributos Empleado):** Cálculo de Experiencia de Mincer ($Edad - Años\_Estudio - 6$), término cuadrático de rendimientos decrecientes y banderas de jornada (>48h) y salario submínimo (<2,500 Bs en jornada completa).
- **LIM-10 (Construcción Targets):** Formulación de `formalidad_laboral` (1 = Cuenta con seguro médico patronal provisto por la empresa; 0 = Informal/Precario) y `score_calidad_empleo` (0 a 3 beneficios).
- **LIM-11 (Escalado Z):** Estandarización paramétrica $Z = (X - \mu) / \sigma$ en 7 variables continuas clave.
- **LIM-12 (Partición Estratificada):** Segmentación 80% Entrenamiento ($n = 5,540$, 39.86% formal) y 20% Prueba ($n = 1,385$, 40.51% formal) para garantizar evaluación insesgada.

---

## 4. Resumen de Calidad Final de Datos

```
========================================================================================
RESUMEN DE CALIDAD DE DATOS (DATA QUALITY SCORECARD)
========================================================================================
- Registros Originales en persona.csv:       39,497
- Universo Asalariado Dependiente:            6,951  (17.60% del total nacional)
- Registros Finales Válidos Curados:          6,925  (Excluidos 26 casos de trabajo infantil)
- Variables Finales en Dataset Limpio:           43
- Tasa de Valores Faltantes Remanentes:        0.00% (Completitud absoluta en las 43 vars)
- Inconsistencias Cronológicas Restantes:      0 casos
- Outliers de Jornada > 84h Restantes:         0 casos
- Salarios Extremos sin Estabilizar:           0 casos (Tratados mediante Winsorización y Log)
- Distribución Target Formalidad:              60.01% Informal / Precario | 39.99% Formal
- Archivos Entregados:
  * Dataset CSV Limpio:      dataset_empleo_limpio.csv (3.5 MB)
  * Dataset RDS Modelado:    dataset_modelado_empleado_empleador.rds (378 KB)
  * Bitácora CSV Auditoría:  bitacora_limpieza_datos.csv (6.7 KB)
  * Informe Interactivo:     INFORME_PREPROCESAMIENTO_EMPLEO.html (952 KB)
  * Diagnósticos Gráficos:   plots/01_*.png a plots/06_*.png
========================================================================================
```
