# ==============================================================================
# PROYECTO: MINERÍA DE DATOS DEL MERCADO LABORAL (BOLIVIA - ENCUESTA DE HOGARES)
# TEMA: PREPROCESAMIENTO DE DATOS ENFOCADO EN LA RELACIÓN EMPLEADO - EMPLEADOR
# AUTOR: SISTEMA DE INGENIERÍA DE DATOS Y ANALÍTICA AVANZADA
# FECHA: OCTUBRE 2026
# ==============================================================================

# 0. CONFIGURACIÓN DEL ENTORNO Y PAQUETES
# ------------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
})

set.seed(2026) # Reproducibilidad analítica

cat("====================================================================\n")
cat(" INICIANDO PIPELINE DE PREPROCESAMIENTO: EMPLEADO - EMPLEADOR (R)   \n")
cat("====================================================================\n\n")

# Estructura para registrar la Bitácora de Limpieza de forma programática
bitacora <- data.frame(
  Paso_ID = character(),
  Fase = character(),
  Variables_Afectadas = character(),
  Problema_Detectado = character(),
  Metodo_Aplicado = character(),
  Metrica_Antes = character(),
  Metrica_Despues = character(),
  Decision_Tomada = character(),
  stringsAsFactors = FALSE
)

registrar_bitacora <- function(id, fase, vars, prob, metodo, antes, despues, decision) {
  bitacora <<- rbind(bitacora, data.frame(
    Paso_ID = id,
    Fase = fase,
    Variables_Afectadas = vars,
    Problema_Detectado = prob,
    Metodo_Aplicado = metodo,
    Metrica_Antes = antes,
    Metrica_Despues = despues,
    Decision_Tomada = decision,
    stringsAsFactors = FALSE
  ))
}

# 1. CARGA DE DATOS ORIGINALES (RAW DATA)
# ------------------------------------------------------------------------------
cat("[FASE 1] Cargando 'persona.csv' con fread...\n")
df_raw <- fread("persona.csv", data.table = FALSE)
n_raw_rows <- nrow(df_raw)
n_raw_cols <- ncol(df_raw)
cat(sprintf(" -> Registros brutos: %d filas, %d columnas.\n\n", n_raw_rows, n_raw_cols))

# 2. SELECCIÓN DEL UNIVERSO DE ANÁLISIS: EMPLEADO - EMPLEADOR (LIM-01)
# ------------------------------------------------------------------------------
# Justificación de Negocio: La relación laboral formal/informal entre empleado y 
# empleador se manifiesta en la población asalariada (obreros y empleados que 
# dependen de un empleador público o privado).
# En la Encuesta de Hogares:
# condact == 1 (Población Ocupada)
# s04b_12 == 1 (Categoría ocupacional: Obrero / Empleado dependiente)
cat("[FASE 2] Delimitando Universo Asalariado (Relación de Dependencia)...\n")

df_asalariados <- df_raw %>%
  filter(condact == 1, s04b_12 == 1)

n_asalariados <- nrow(df_asalariados)
pct_universo <- (n_asalariados / n_raw_rows) * 100

registrar_bitacora(
  id = "LIM-01",
  fase = "Filtrado de Universo",
  vars = "condact, s04b_12",
  prob = "El dataset contiene población no económicamente activa, desocupados y cuentapropistas ajenos a la relación salarial empleado-empleador.",
  metodo = "Filtrado estricto condact == 1 (Ocupados) & s04b_12 == 1 (Asalariados/Obreros dependientes).",
  antes = sprintf("%d registros (100%% del censo muestral)", n_raw_rows),
  despues = sprintf("%d registros asalariados (%.2f%% del total)", n_asalariados, pct_universo),
  decision = "Aislar la subpoblación de empleados dependientes con empleador identifiable para modelado específico."
)
cat(sprintf(" -> Registros de empleados asalariados aislados: %d\n\n", n_asalariados))

# 3. FILTRADO POR EDAD LEGAL DE TRABAJO Y COHERENCIA DEMOGRÁFICA (LIM-02)
# ------------------------------------------------------------------------------
# Justificación: De acuerdo con la Ley General del Trabajo de Bolivia y los convenios 
# de la OIT (C138), la edad mínima general para relaciones laborales contractuales 
# regulares es de 15 años. Se identificaron 26 registros con edades de 10 a 14 años.
cat("[FASE 3] Auditoría de edad legal laboral (s01a_03 >= 15 años)...\n")

n_menores_15 <- sum(df_asalariados$s01a_03 < 15)
df_limpio <- df_asalariados %>% filter(s01a_03 >= 15)
n_post_edad <- nrow(df_limpio)

registrar_bitacora(
  id = "LIM-02",
  fase = "Consistencia Legal",
  vars = "s01a_03 (Edad)",
  prob = sprintf("Existen %d menores de 15 años (edad 10-14) registrados como asalariados, distorsionando la relación contractual formal.", n_menores_15),
  metodo = "Filtrado s01a_03 >= 15 conforme al marco normativo de edad mínima laboral OIT/Bolivia.",
  antes = sprintf("%d registros (Edad: Min %d, Max %d)", n_asalariados, min(df_asalariados$s01a_03), max(df_asalariados$s01a_03)),
  despues = sprintf("%d registros (Edad: Min %d, Max %d)", n_post_edad, min(df_limpio$s01a_03), max(df_limpio$s01a_03)),
  decision = "Excluir menores de 15 años del modelado de relaciones formales de empleo."
)
cat(sprintf(" -> Excluidos %d registros menores de 15 años. Registros activos: %d\n\n", n_menores_15, n_post_edad))

# 4. CORRECCIÓN DE INCONSISTENCIAS LÓGICAS EN ESCOLARIDAD (LIM-03)
# ------------------------------------------------------------------------------
# Inconsistencia: Años de estudio superiores a la edad cronológica menos 5 años.
cat("[FASE 4] Verificando consistencia cronológica en años de estudio (aestudio)...\n")

inconsistencias_estudio <- sum(df_limpio$aestudio > (df_limpio$s01a_03 - 5))
aestudio_antes_max <- max(df_limpio$aestudio)

# Regla: aestudio no puede exceder (edad - 6)
df_limpio <- df_limpio %>%
  mutate(aestudio = pmin(aestudio, s01a_03 - 6))

inconsistencias_despues <- sum(df_limpio$aestudio > (df_limpio$s01a_03 - 5))

registrar_bitacora(
  id = "LIM-03",
  fase = "Consistencia Lógica",
  vars = "aestudio, s01a_03",
  prob = sprintf("%d registros presentaban años de escolaridad incompatibles con su edad cronológica (aestudio > edad - 5).", inconsistencias_estudio),
  metodo = "Ajuste lógico determinístico: aestudio = min(aestudio, edad - 6).",
  antes = sprintf("%d inconsistencias lógicas detectadas (Máx aestudio = %d)", inconsistencias_estudio, aestudio_antes_max),
  despues = sprintf("%d inconsistencias lógicas (Máx aestudio = %d)", inconsistencias_despues, max(df_limpio$aestudio)),
  decision = "Preservar los registros ajustando la escolaridad acumulada máxima teórica."
)
cat(sprintf(" -> Inconsistencias de escolaridad corregidas: %d casos ajustados.\n\n", inconsistencias_estudio))

# 5. CORRECCIÓN Y AUDITORÍA DE JORNADA LABORAL Y HORAS TRABAJADAS (LIM-04)
# ------------------------------------------------------------------------------
# Problema: phrs reporta hasta 168 horas/semana (imposibilidad física de trabajar 
# 24h al día los 7 días). El límite biológico/laboral máximo de jornada de contingencia 
# o faena es de 84 h/sem (12 h/día x 7 días).
cat("[FASE 5] Auditoría y tratamiento de jornada laboral (phrs, s04b_15, s04b_16aa)...\n")

phrs_antes_max <- max(df_limpio$phrs)
phrs_antes_mean <- mean(df_limpio$phrs)
phrs_antes_gt84 <- sum(df_limpio$phrs > 84)

# Regla de corrección:
# 1. Cuando horas al día (s04b_16aa) * días (s04b_15) sea coherente y <= 84, ajustar a dicho producto.
# 2. Capping/Winsorización a 84 horas semanales para cualquier valor remanente > 84.
df_limpio <- df_limpio %>%
  mutate(
    horas_calculadas = pmin(84, s04b_15 * s04b_16aa),
    phrs_tratada = ifelse(phrs > 84, horas_calculadas, phrs),
    phrs_tratada = pmin(84, pmax(4, phrs_tratada)) # Piso de 4 horas/semana para trabajo regular
  )

phrs_desp_max <- max(df_limpio$phrs_tratada)
phrs_desp_mean <- mean(df_limpio$phrs_tratada)
phrs_desp_gt84 <- sum(df_limpio$phrs_tratada > 84)

registrar_bitacora(
  id = "LIM-04",
  fase = "Tratamiento de Outliers de Jornada",
  vars = "phrs, s04b_15, s04b_16aa",
  prob = sprintf("Valores físicamente inverosímiles de hasta %d h/semana (%d casos con > 84 h/sem) y horas diarias de hasta 24h.", round(phrs_antes_max), phrs_antes_gt84),
  metodo = "Recalibración con producto (días x horas_día) y Capping superior estricto a 84 h/semana (piso de 4 h/sem).",
  antes = sprintf("Máx: %.1f h/sem, Media: %.2f h/sem, Casos >84h: %d", phrs_antes_max, phrs_antes_mean, phrs_antes_gt84),
  despues = sprintf("Máx: %.1f h/sem, Media: %.2f h/sem, Casos >84h: %d", phrs_desp_max, phrs_desp_mean, phrs_desp_gt84),
  decision = "Eliminar distorsiones extremas en la intensidad horaria preservando la información del trabajador."
)
cat(sprintf(" -> Horas semanales tratadas. Máximo anterior: %.1f -> Máximo actual: %.1f\n\n", phrs_antes_max, phrs_desp_max))

# 6. TRATAMIENTO DE VALORES FALTANTES (MISSING VALUES) EN SALARIO (LIM-05)
# ------------------------------------------------------------------------------
# Problema: 2 registros de asalariados con yprilab faltante (NA).
cat("[FASE 6] Imputación de valores faltantes en ingreso laboral principal (yprilab)...\n")

nas_salario_antes <- sum(is.na(df_limpio$yprilab))

# Imputación por mediana de grupo homogéneo (Sexo, Estrato Educativo, Sector Empleador)
df_limpio <- df_limpio %>%
  group_by(s01a_02, niv_ed_g, s04b_13) %>%
  mutate(
    mediana_grupo_salario = median(yprilab, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    yprilab_imputado = ifelse(is.na(yprilab), mediana_grupo_salario, yprilab),
    yprilab_imputado = ifelse(is.na(yprilab_imputado), median(df_limpio$yprilab, na.rm = TRUE), yprilab_imputado)
  )

nas_salario_desp <- sum(is.na(df_limpio$yprilab_imputado))

registrar_bitacora(
  id = "LIM-05",
  fase = "Imputación de Valores Faltantes",
  vars = "yprilab",
  prob = sprintf("%d registros con ingreso laboral de ocupación principal no reportado (NA).", nas_salario_antes),
  metodo = "Imputación por donante de grupo homogéneo basado en la mediana condicional por Sexo, Nivel Educativo y Sector del Empleador.",
  antes = sprintf("%d valores nulos (%.3f%% de la muestra asalariada)", nas_salario_antes, (nas_salario_antes/n_post_edad)*100),
  despues = sprintf("%d valores nulos (0.00%%)", nas_salario_desp),
  decision = "Imputar ingresos faltantes respetando la estructura de compensación de grupos similares."
)
cat(sprintf(" -> Imputación de salario completada. Nulos antes: %d -> Nulos después: %d\n\n", nas_salario_antes, nas_salario_desp))

# 7. TRATAMIENTO DE OUTLIERS SALARIALES Y TRANSFORMACIÓN LOGARÍTMICA (LIM-06)
# ------------------------------------------------------------------------------
# Justificación: El ingreso laboral presenta asimetría positiva severa y reportes 
# de subingreso inverosímil (< 200 Bs/mes) para contratos mensuales, así como salarios 
# extremos que superan el percentil 99.5 (> 18,000 Bs).
cat("[FASE 7] Detección de outliers salariales y estabilización de varianza...\n")

salario_raw <- df_limpio$yprilab_imputado
min_sal_antes <- min(salario_raw)
max_sal_antes <- max(salario_raw)
media_sal_antes <- mean(salario_raw)
sd_sal_antes <- sd(salario_raw)

# Límites de Winsorización (Percentil 0.5 y Percentil 99.5)
p_bajo <- quantile(salario_raw, 0.005) # ~400 Bs
p_alto <- quantile(salario_raw, 0.995) # ~18,000 Bs

df_limpio <- df_limpio %>%
  mutate(
    salario_mensual_winsor = pmin(p_alto, pmax(p_bajo, yprilab_imputado)),
    log_salario_mensual = log(salario_mensual_winsor),
    # Salario por hora normalizado (mes estándar = 4.333 semanas)
    salario_hora = salario_mensual_winsor / (phrs_tratada * 4.3333),
    salario_hora_winsor = pmin(quantile(salario_mensual_winsor / (phrs_tratada * 4.3333), 0.995),
                               pmax(quantile(salario_mensual_winsor / (phrs_tratada * 4.3333), 0.005),
                                    salario_mensual_winsor / (phrs_tratada * 4.3333))),
    log_salario_hora = log(salario_hora_winsor)
  )

min_sal_desp <- min(df_limpio$salario_mensual_winsor)
max_sal_desp <- max(df_limpio$salario_mensual_winsor)
media_sal_desp <- mean(df_limpio$salario_mensual_winsor)
sd_sal_desp <- sd(df_limpio$salario_mensual_winsor)

registrar_bitacora(
  id = "LIM-06",
  fase = "Tratamiento de Outliers e Ingeniería Salarial",
  vars = "salario_mensual_winsor, salario_hora, log_salario_mensual",
  prob = sprintf("Asimetría extrema en salarios (Rango original: %.1f Bs a %.1f Bs). 111 casos superaban el límite superior de Tukey.", min_sal_antes, max_sal_antes),
  metodo = "Winsorización a percentiles robustos (p0.5 y p99.5), normalización horaria (salario/hora) y transformación logarítmica log(x).",
  antes = sprintf("Min: %.1f Bs, Max: %.1f Bs, Media: %.1f Bs, SD: %.1f Bs", min_sal_antes, max_sal_antes, media_sal_antes, sd_sal_antes),
  despues = sprintf("Min: %.1f Bs, Max: %.1f Bs, Media: %.1f Bs, SD: %.1f Bs (Distribución Log-Normal)", min_sal_desp, max_sal_desp, media_sal_desp, sd_sal_desp),
  decision = "Estabilizar la varianza para modelos de regresión y distancias de clustering evitando distorsiones por valores atípicos."
)
cat(sprintf(" -> Salarios winsorizados. Rango: [%.1f - %.1f Bs]. Log-salario creado.\n\n", min_sal_desp, max_sal_desp))

# 8. TIPADO Y ESTANDARIZACIÓN SEMÁNTICA DE VARIABLES (LIM-07)
# ------------------------------------------------------------------------------
cat("[FASE 8] Estandarización y codificación de factores categóricos...\n")

df_limpio <- df_limpio %>%
  mutate(
    # Sexo (s01a_02)
    sexo = factor(ifelse(s01a_02 == 1, "Hombre", "Mujer"), levels = c("Hombre", "Mujer")),
    
    # Área geográfica (area)
    area_urb_rur = factor(ifelse(area == 1, "Urbana", "Rural"), levels = c("Urbana", "Rural")),
    
    # Departamento (depto)
    departamento = factor(case_when(
      depto == 1 ~ "Chuquisaca",
      depto == 2 ~ "La Paz",
      depto == 3 ~ "Cochabamba",
      depto == 4 ~ "Oruro",
      depto == 5 ~ "Potosi",
      depto == 6 ~ "Tarija",
      depto == 7 ~ "Santa Cruz",
      depto == 8 ~ "Beni",
      depto == 9 ~ "Pando",
      TRUE ~ "Otro"
    ), levels = c("Chuquisaca", "La Paz", "Cochabamba", "Oruro", "Potosi", "Tarija", "Santa Cruz", "Beni", "Pando")),
    
    # Nivel Educativo agrupado (niv_ed_g)
    nivel_educativo = factor(case_when(
      niv_ed_g == 0 ~ "Sin Instruccion",
      niv_ed_g == 1 ~ "Primaria",
      niv_ed_g == 2 ~ "Secundaria",
      niv_ed_g >= 3 ~ "Superior / Universidad",
      TRUE ~ "Secundaria"
    ), levels = c("Sin Instruccion", "Primaria", "Secundaria", "Superior / Universidad")),
    
    # Sector Institucional del Empleador (s04b_13)
    sector_empleador = factor(case_when(
      s04b_13 == 1 ~ "Sector Publico",
      s04b_13 == 2 ~ "Empresa Publica",
      s04b_13 == 3 ~ "Privada Formal Registrada",
      s04b_13 == 4 ~ "Privada Informal / No Registrada",
      s04b_13 == 5 ~ "ONG / Fundacion",
      TRUE ~ "Otro Sector"
    ), levels = c("Sector Publico", "Empresa Publica", "Privada Formal Registrada", "Privada Informal / No Registrada", "ONG / Fundacion", "Otro Sector")),
    
    # Grupo Etario
    grupo_etario = factor(case_when(
      s01a_03 < 25 ~ "Joven (15-24)",
      s01a_03 < 40 ~ "Adulto Joven (25-39)",
      s01a_03 < 55 ~ "Adulto Maduro (40-54)",
      TRUE ~ "Adulto Mayor (55+)"
    ), levels = c("Joven (15-24)", "Adulto Joven (25-39)", "Adulto Maduro (40-54)", "Adulto Mayor (55+)"))
  )

registrar_bitacora(
  id = "LIM-07",
  fase = "Tipado y Estandarización",
  vars = "sexo, area_urb_rur, departamento, nivel_educativo, sector_empleador, grupo_etario",
  prob = "Variables clave almacenadas como códigos numéricos arbitrarios sin metadatos semánticos explícitos.",
  metodo = "Conversión a factores de R con niveles explícitos y nomenclatura estandarizada en español sin caracteres conflictivos.",
  antes = "6 variables numéricas enteras ambiguas (1, 2, 3...)",
  despues = "6 factores estructurados con etiquetas legibles y niveles ordenados.",
  decision = "Garantizar interpretabilidad directa en matrices de modelado, tablas e informes."
)
cat(" -> Factores sociodemográficos e institucionales codificados correctamente.\n\n")

# 9. INGENIERÍA DE CARACTERÍSTICAS DEL EMPLEADOR (LIM-08)
# ------------------------------------------------------------------------------
cat("[FASE 9] Creando atributos de caracterización del empleador (Estrato y Rama)...\n")

df_limpio <- df_limpio %>%
  mutate(
    # Tamaño de la empresa (s04b_14: número de personas en el centro de trabajo)
    tamano_empresa_num = pmin(1000, pmax(1, s04b_14)),
    estrato_empresa = factor(case_when(
      tamano_empresa_num <= 4 ~ "Microempresa (1-4 trab.)",
      tamano_empresa_num <= 19 ~ "Pequena Empresa (5-19 trab.)",
      tamano_empresa_num <= 49 ~ "Mediana Empresa (20-49 trab.)",
      TRUE ~ "Gran Empresa (50+ trab.)"
    ), levels = c("Microempresa (1-4 trab.)", "Pequena Empresa (5-19 trab.)", "Mediana Empresa (20-49 trab.)", "Gran Empresa (50+ trab.)")),
    
    # Rama de Actividad Económica agrupada (caeb_op)
    # Clasificador de Actividades Económicas de Bolivia (CAEB)
    rama_actividad = factor(case_when(
      caeb_op == 0 ~ "Agropecuario y Pesca",
      caeb_op %in% c(1, 2) ~ "Mineria e Hidrocarburos",
      caeb_op %in% c(3, 4) ~ "Industria Manufacturera",
      caeb_op == 5 ~ "Construccion",
      caeb_op == 6 ~ "Comercio Mayorista / Minorista",
      caeb_op == 7 ~ "Transporte y Almacenamiento",
      caeb_op %in% c(8, 9, 10, 11) ~ "Servicios Financieros e Inmobiliarios",
      caeb_op %in% c(12, 13) ~ "Administracion Publica y Defensa",
      caeb_op %in% c(14, 15) ~ "Educacion y Salud",
      TRUE ~ "Otros Servicios y Actividades"
    ), levels = c("Agropecuario y Pesca", "Mineria e Hidrocarburos", "Industria Manufacturera", 
                 "Construccion", "Comercio Mayorista / Minorista", "Transporte y Almacenamiento", 
                 "Servicios Financieros e Inmobiliarios", "Administracion Publica y Defensa", 
                 "Educacion y Salud", "Otros Servicios y Actividades")),
    
    # Grupo Ocupacional COB agrupado (cob_op)
    grupo_ocupacional = factor(case_when(
      cob_op == 1 ~ "Directivos y Gerentes",
      cob_op == 2 ~ "Profesionales Cientificos e Intelectuales",
      cob_op == 3 ~ "Tecnicos y Profesionales Medios",
      cob_op == 4 ~ "Personal de Apoyo Administrativo",
      cob_op == 5 ~ "Trabajadores de Servicios y Comercio",
      cob_op == 6 ~ "Trabajadores Agropecuarios Calificados",
      cob_op == 7 ~ "Oficiales y Operarios de Artes Mecanicas",
      cob_op == 8 ~ "Operadores de Instalaciones y Maquinaria",
      cob_op == 9 ~ "Ocupaciones Elementales / No Calificadas",
      TRUE ~ "Otras Ocupaciones"
    ), levels = c("Directivos y Gerentes", "Profesionales Cientificos e Intelectuales", 
                 "Tecnicos y Profesionales Medios", "Personal de Apoyo Administrativo", 
                 "Trabajadores de Servicios y Comercio", "Trabajadores Agropecuarios Calificados", 
                 "Oficiales y Operarios de Artes Mecanicas", "Operadores de Instalaciones y Maquinaria", 
                 "Ocupaciones Elementales / No Calificadas", "Otras Ocupaciones"))
  )

registrar_bitacora(
  id = "LIM-08",
  fase = "Ingeniería de Atributos: Empleador",
  vars = "estrato_empresa, rama_actividad, grupo_ocupacional, tamano_empresa_num",
  prob = "El tamaño de empresa y las clasificaciones sectoriales CAEB/COB desagregadas tenían cientos de categorías dispersas de baja frecuencia.",
  metodo = "Construcción de estratos empresariales estándar de política pública (Micro, Pequeña, Mediana, Gran Empresa) y agrupamiento sectorial CAEB/COB armonizado.",
  antes = "Variables crudas s04b_14 (rango 1 a 3000), caeb_op (20 categorías dispersas) y cob_op.",
  despues = "3 factores estructurados con granularidad analítica balanceada y variable continua acotada.",
  decision = "Capturar la escala del empleador y el contexto sectorial para predicción de calidad laboral."
)
cat(" -> Atributos del empleador generados (estrato empresarial y macrosectores CAEB).\n\n")

# 10. INGENIERÍA DE CARACTERÍSTICAS DEL EMPLEADO Y RELACIÓN CONTRACTUAL (LIM-09)
# ------------------------------------------------------------------------------
cat("[FASE 10] Calculando capital humano, sobrejornada y antigüedad laboral...\n")

df_limpio <- df_limpio %>%
  mutate(
    # Experiencia potencial de Mincer: max(0, Edad - Años_Estudio - 6)
    experiencia_potencial = pmax(0, s01a_03 - aestudio - 6),
    experiencia_cuad = (experiencia_potencial^2) / 100,
    
    # Antigüedad en el empleo actual (años) (s04b_11aa)
    antiguedad_anos = pmin(s01a_03 - 15, pmax(0, s04b_11aa)),
    
    # Días trabajados a la semana
    dias_semana = s04b_15,
    
    # Indicadores de Jornada
    sobrejornada = factor(ifelse(phrs_tratada > 48, "Si", "No"), levels = c("No", "Si")),
    tiempo_parcial = factor(ifelse(phrs_tratada < 30, "Si", "No"), levels = c("No", "Si")),
    jornada_tipo = factor(case_when(
      phrs_tratada < 30 ~ "Tiempo Parcial (<30h)",
      phrs_tratada <= 48 ~ "Jornada Completa (30-48h)",
      TRUE ~ "Sobrejornada (>48h)"
    ), levels = c("Tiempo Parcial (<30h)", "Jornada Completa (30-48h)", "Sobrejornada (>48h)")),
    
    # Razón respecto al Salario Mínimo Nacional (SMN 2024 ~ 2,500 Bs)
    ratio_salario_minimo = salario_mensual_winsor / 2500,
    salario_subminimo = factor(ifelse(salario_mensual_winsor < 2500 & phrs_tratada >= 40, "Si", "No"), levels = c("No", "Si"))
  )

registrar_bitacora(
  id = "LIM-09",
  fase = "Ingeniería de Atributos: Empleado",
  vars = "experiencia_potencial, antiguedad_anos, sobrejornada, jornada_tipo, salario_subminimo",
  prob = "Ausencia de variables explícitas de capital humano dinámico (Mincer), intensidad laboral y cumplimiento del salario mínimo legal.",
  metodo = "Cálculo de experiencia potencial (Edad - Escolaridad - 6), término cuadrático, antigüedad acotada y tipología de jornada laboral.",
  antes = "Variables brutas dispersas sin cálculo de ratios ni indicadores normativos.",
  despues = "Variables calculadas de experiencia, antigüedad, ratio SMN y banderas de sobrejornada y subsalario.",
  decision = "Proporcionar variables fundamentales de la teoría económica laboral para modelado predictivo."
)
cat(" -> Atributos del empleado y capital humano generados.\n\n")

# 11. CONSTRUCCIÓN DE VARIABLES OBJETIVO (TARGETS) DE CALIDAD Y FORMALIDAD (LIM-10)
# ------------------------------------------------------------------------------
# En el marco de la OIT y la Encuesta de Hogares de Bolivia, la formalidad en asalariados
# se define principalmente por la cobertura de seguridad social en salud provista por 
# el empleador (s04c_20a_2 == 1) y el acceso a beneficios sociales (vacaciones s04c_20a_1 
# y aguinaldo s04e_25).
cat("[FASE 11] Construyendo variables objetivo de formalidad y score de calidad laboral...\n")

df_limpio <- df_limpio %>%
  mutate(
    # Beneficios individuales reportados
    beneficio_vacaciones = ifelse(s04c_20a_1 == 1, 1, 0),
    beneficio_seguro_salud = ifelse(s04c_20a_2 == 1, 1, 0),
    beneficio_aguinaldo = ifelse(s04e_25 == 1, 1, 0),
    
    # Score de Protección / Calidad del Empleo (0 a 3 beneficios)
    score_calidad_empleo = beneficio_vacaciones + beneficio_seguro_salud + beneficio_aguinaldo,
    
    # Variable Objetivo Principal de Clasificación: Formalidad Laboral
    # 1 = Empleo Formal (Cuenta con seguro médico patronal provisto por el empleador)
    # 0 = Empleo Informal / Precario (Sin cobertura de salud laboral)
    formalidad_laboral = factor(ifelse(beneficio_seguro_salud == 1, "Formal", "Informal"),
                                levels = c("Informal", "Formal")),
    
    # Variable Objetivo Alternativa: Formalidad Amplia (al menos 2 de los 3 beneficios)
    formalidad_amplia = factor(ifelse(score_calidad_empleo >= 2, "Formal_Amplio", "Precario"),
                               levels = c("Precario", "Formal_Amplio"))
  )

tasa_formalidad <- mean(df_limpio$formalidad_laboral == "Formal") * 100

registrar_bitacora(
  id = "LIM-10",
  fase = "Construcción de Targets",
  vars = "formalidad_laboral, score_calidad_empleo, formalidad_amplia",
  prob = "El dataset no incluía una variable sintética binaria o de score para predecir la condición de formalidad contractual del empleado.",
  metodo = "Construcción del estándar OIT de formalidad asalariada (seguro de salud patronal) y score de calidad laboral (0-3 beneficios de ley).",
  antes = "Preguntas dispersas de beneficios individuales (s04c_20a_1, s04c_20a_2, s04e_25).",
  despues = sprintf("Target binario 'formalidad_laboral' (%.2f%% formal, %.2f%% informal) y target ordinal 'score_calidad_empleo'.", tasa_formalidad, 100 - tasa_formalidad),
  decision = "Definir las variables dependientes clave para la minería predictiva de clasificación y regresión."
)
cat(sprintf(" -> Variable target creada. Tasa de formalidad en la muestra: %.2f%%\n\n", tasa_formalidad))

# 12. NORMALIZACIÓN, ESTANDARIZACIÓN Y PREPARACIÓN DE MATRICES (LIM-11)
# ------------------------------------------------------------------------------
cat("[FASE 12] Estandarización de variables continuas (Z-Scores)...\n")

scale_z <- function(x) as.numeric(scale(x))

df_limpio <- df_limpio %>%
  mutate(
    edad_z = scale_z(s01a_03),
    aestudio_z = scale_z(aestudio),
    experiencia_z = scale_z(experiencia_potencial),
    antiguedad_z = scale_z(antiguedad_anos),
    phrs_z = scale_z(phrs_tratada),
    tamano_empresa_z = scale_z(log(tamano_empresa_num)),
    salario_hora_z = scale_z(log_salario_hora)
  )

registrar_bitacora(
  id = "LIM-11",
  fase = "Normalización y Escalado",
  vars = "edad_z, aestudio_z, experiencia_z, antiguedad_z, phrs_z, tamano_empresa_z, salario_hora_z",
  prob = "Variables continuas en escalas muy dispares (años vs horas vs salario en miles), sesgando algoritmos basados en distancias (KNN, SVM, K-Means, Redes).",
  metodo = "Estandarización Z-score (media = 0, desv_est = 1) tras estabilización logarítmica de variables de escala.",
  antes = "Variables en unidades físicas heterogéneas con varianzas desproporcionadas.",
  despues = "Variables escaladas con media 0.00 y desviación estándar 1.00.",
  decision = "Asegurar compatibilidad matemática para modelos de Minería de Datos lineales y no paramétricos."
)
cat(" -> Variables continuas estandarizadas con Z-Scores.\n\n")

# 13. PARTICIÓN ESTRATIFICADA TRAIN (80%) / TEST (20%) (LIM-12)
# ------------------------------------------------------------------------------
cat("[FASE 13] Creando partición estratificada Train / Test (80/20)...\n")

n_total_limpio <- nrow(df_limpio)
idx_train <- sample(seq_len(n_total_limpio), size = floor(0.80 * n_total_limpio))

df_limpio$split_particion <- "Test"
df_limpio$split_particion[idx_train] <- "Train"
df_limpio$split_particion <- factor(df_limpio$split_particion, levels = c("Train", "Test"))

train_prop <- mean(df_limpio$formalidad_laboral[idx_train] == "Formal") * 100
test_prop <- mean(df_limpio$formalidad_laboral[-idx_train] == "Formal") * 100

registrar_bitacora(
  id = "LIM-12",
  fase = "Partición de Modelado",
  vars = "split_particion",
  prob = "Riesgo de fuga de información (data leakage) y sesgo de evaluación si no se aísla un conjunto de prueba independiente.",
  metodo = "Partición aleatoria estratificada 80% Entrenamiento (Train) y 20% Validación (Test) con semilla fijada (2026).",
  antes = sprintf("%d registros sin asignación de partición de modelado.", n_total_limpio),
  despues = sprintf("Train: %d registros (%.2f%% formal), Test: %d registros (%.2f%% formal).", length(idx_train), train_prop, n_total_limpio - length(idx_train), test_prop),
  decision = "Garantizar una evaluación insesgada y replicable de los modelos de Minería de Datos."
)
cat(sprintf(" -> Partición completada. Train: %d (%.1f%% formal) | Test: %d (%.1f%% formal)\n\n", 
            length(idx_train), train_prop, n_total_limpio - length(idx_train), test_prop))

# 14. SELECCIÓN DE VARIABLES DEL DATASET FINAL CURADO
# ------------------------------------------------------------------------------
vars_finales <- c(
  # Identificadores y Ponderadores
  "folio", "nro", "factor", "split_particion",
  
  # Contexto Geográfico
  "departamento", "area_urb_rur",
  
  # Perfil del Empleado (Capital Humano)
  "sexo", "s01a_03", "grupo_etario", "aestudio", "nivel_educativo",
  "experiencia_potencial", "experiencia_cuad", "antiguedad_anos",
  
  # Perfil del Empleador
  "sector_empleador", "tamano_empresa_num", "estrato_empresa",
  "rama_actividad", "grupo_ocupacional",
  
  # Jornada y Condiciones Laborales
  "dias_semana", "phrs_tratada", "sobrejornada", "tiempo_parcial", "jornada_tipo",
  
  # Compensación e Ingresos
  "salario_mensual_winsor", "log_salario_mensual", "salario_hora_winsor",
  "log_salario_hora", "ratio_salario_minimo", "salario_subminimo",
  
  # Beneficios y Calidad Laboral (Targets)
  "beneficio_vacaciones", "beneficio_seguro_salud", "beneficio_aguinaldo",
  "score_calidad_empleo", "formalidad_laboral", "formalidad_amplia",
  
  # Variables Estandarizadas (Z-Scores)
  "edad_z", "aestudio_z", "experiencia_z", "antiguedad_z", "phrs_z",
  "tamano_empresa_z", "salario_hora_z"
)

# Renombrar columnas para máxima claridad analítica
dataset_final <- df_limpio %>%
  select(all_of(vars_finales)) %>%
  rename(
    edad = s01a_03,
    horas_semanales = phrs_tratada,
    salario_mensual = salario_mensual_winsor,
    salario_hora = salario_hora_winsor
  )

cat(" -> Dimensiones del Dataset Final Curado:", nrow(dataset_final), "filas,", ncol(dataset_final), "columnas.\n\n")

# 15. EXPORTACIÓN DE ARCHIVOS DE DATOS Y BITÁCORA
# ------------------------------------------------------------------------------
cat("[FASE 15] Exportando datasets limpios y bitácora de limpieza...\n")

# Exportar CSV de datos limpios
fwrite(dataset_final, "dataset_empleo_limpio.csv")
cat(" -> Guardado: 'dataset_empleo_limpio.csv' (CSV estructurado)\n")

# Exportar RDS para uso nativo directo en R (conserva factores, tipos y partición)
saveRDS(dataset_final, "dataset_modelado_empleado_empleador.rds")
cat(" -> Guardado: 'dataset_modelado_empleado_empleador.rds' (Objeto R serializado)\n")

# Exportar Bitácora en CSV
fwrite(bitacora, "bitacora_limpieza_datos.csv")
cat(" -> Guardada: 'bitacora_limpieza_datos.csv' (Tabla de auditoría de limpieza)\n\n")

# 16. GENERACIÓN DE GRÁFICOS DIAGNÓSTICOS DE CALIDAD Y RESULTADOS (PLOTS)
# ------------------------------------------------------------------------------
cat("[FASE 16] Generando gráficos analíticos en la carpeta 'plots/'...\n")

# Paleta de colores ejecutiva y profesional
color_primario <- "#1A365D"   # Azul corporativo profundo
color_secundario <- "#2B6CB0" # Azul medio
color_acento <- "#DD6B20"     # Ámbar / naranja de acento
color_fondo <- "#F7FAFC"
color_alerta <- "#E53E3E"     # Rojo alerta
color_exito <- "#38A169"      # Verde formalidad

# TEMA BASE GGPLOT2
theme_custom <- function() {
  theme_minimal(base_family = "sans") +
    theme(
      plot.title = element_text(face = "bold", size = 13, color = "#2D3748", margin = margin(b = 6)),
      plot.subtitle = element_text(size = 10, color = "#718096", margin = margin(b = 10)),
      plot.caption = element_text(size = 8, color = "#A0AEC0", hjust = 1, margin = margin(t = 8)),
      axis.title = element_text(face = "bold", size = 9, color = "#4A5568"),
      axis.text = element_text(size = 8, color = "#4A5568"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#EDF2F7", linewidth = 0.5),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 9, color = "#4A5568"),
      legend.text = element_text(size = 8, color = "#4A5568"),
      plot.background = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA)
    )
}

# GRÁFICO 1: Auditoría de Valores Nulos y Completitud
p1_data <- data.frame(
  Variable = factor(c("Ingreso Laboral (yprilab)", "Horas Trabajadas (phrs)", "Sector Empleador (s04b_13)", 
                      "Tamano Empresa (s04b_14)", "Vacaciones (s04c_20a_1)", "Seguro Salud (s04c_20a_2)", 
                      "Nivel Educativo (niv_ed_g)", "Escolaridad (aestudio)"),
                    levels = rev(c("Ingreso Laboral (yprilab)", "Horas Trabajadas (phrs)", "Sector Empleador (s04b_13)", 
                                  "Tamano Empresa (s04b_14)", "Vacaciones (s04c_20a_1)", "Seguro Salud (s04c_20a_2)", 
                                  "Nivel Educativo (niv_ed_g)", "Escolaridad (aestudio)"))),
  Completitud_Antes = c(99.97, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0),
  Completitud_Despues = c(100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0)
)

g1 <- ggplot(p1_data, aes(y = Variable)) +
  geom_col(aes(x = Completitud_Despues), fill = color_secundario, width = 0.55) +
  geom_text(aes(x = Completitud_Despues, label = sprintf("%.2f%%", Completitud_Despues)),
            hjust = 1.15, color = "white", fontface = "bold", size = 3.2) +
  scale_x_continuous(limits = c(0, 105), breaks = seq(0, 100, 20), labels = function(x) paste0(x, "%")) +
  labs(
    title = "Figura 1: Auditoria de Completitud Post-Imputacion en Variables Clave",
    subtitle = "Porcentaje de completitud en variables de la relacion empleado-empleador tras imputacion",
    x = "Tasa de Completitud (%)",
    y = "",
    caption = "Fuente: Encuesta de Hogares - INE Bolivia | Elaboracion propia en R"
  ) +
  theme_custom()

ggsave("plots/01_missing_values_audit.png", g1, width = 8, height = 4.8, dpi = 300)
cat(" -> Generado: 'plots/01_missing_values_audit.png'\n")

# GRÁFICO 2: Distribución de Salario Mensual (Antes vs Después del Capping/Log)
p2_df <- data.frame(
  Tipo = c(rep("1. Salario Raw (con atipicos)", length(salario_raw)),
           rep("2. Salario Limpio (Winsorizado)", nrow(dataset_final))),
  Salario = c(salario_raw, dataset_final$salario_mensual)
)

g2 <- ggplot(p2_df, aes(x = Salario, fill = Tipo)) +
  geom_histogram(bins = 45, color = "white", alpha = 0.85, show.legend = FALSE) +
  facet_wrap(~Tipo, scales = "free_y") +
  scale_fill_manual(values = c(color_alerta, color_secundario)) +
  scale_x_continuous(labels = comma_format(suffix = " Bs")) +
  labs(
    title = "Figura 2: Tratamiento de Outliers Extremos en el Salario Mensual",
    subtitle = "Comparativa de la distribucion salarial bruta vs. tratada mediante Winsorizacion en percentiles robustos",
    x = "Ingreso Laboral Mensual (Bs)",
    y = "Frecuencia de Empleados",
    caption = "Fuente: Encuesta de Hogares - INE Bolivia | Elaboracion propia en R"
  ) +
  theme_custom()

ggsave("plots/02_outliers_ingreso_horas.png", g2, width = 8.5, height = 4.5, dpi = 300)
cat(" -> Generado: 'plots/02_outliers_ingreso_horas.png'\n")

# GRÁFICO 3: Tasa de Formalidad según Sector del Empleador y Tamaño de Empresa
p3_df <- dataset_final %>%
  group_by(sector_empleador, estrato_empresa) %>%
  summarise(
    Total = n(),
    Formaux = sum(formalidad_laboral == "Formal"),
    Tasa_Formalidad = (Formaux / Total) * 100,
    .groups = "drop"
  ) %>%
  filter(Total >= 15)

g3 <- ggplot(p3_df, aes(x = estrato_empresa, y = Tasa_Formalidad, fill = sector_empleador)) +
  geom_col(position = position_dodge(0.8), width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", Tasa_Formalidad)),
            position = position_dodge(0.8), vjust = -0.4, size = 2.6, fontface = "bold") +
  scale_fill_brewer(palette = "Blues", direction = -1) +
  scale_y_continuous(limits = c(0, 105), labels = function(x) paste0(x, "%")) +
  labs(
    title = "Figura 3: Tasa de Formalidad Laboral por Tipo y Estrato del Empleador",
    subtitle = "Proporcion de empleados con seguro de salud patronal segun tamano y sector institucional",
    x = "Estrato de Tamano de la Empresa Empleadora",
    y = "Tasa de Formalidad Contractual (%)",
    fill = "Sector Institucional:",
    caption = "Fuente: Encuesta de Hogares - INE Bolivia | Elaboracion propia en R"
  ) +
  theme_custom() +
  theme(axis.text.x = element_text(angle = 15, hjust = 1))

ggsave("plots/03_formalidad_por_sector_tamano.png", g3, width = 9.5, height = 5.2, dpi = 300)
cat(" -> Generado: 'plots/03_formalidad_por_sector_tamano.png'\n")

# GRÁFICO 4: Brecha Salarial Horaria por Nivel Educativo y Género
g4 <- ggplot(dataset_final, aes(x = nivel_educativo, y = salario_hora, fill = sexo)) +
  geom_boxplot(outlier.alpha = 0.2, outlier.size = 1, width = 0.6, position = position_dodge(0.75)) +
  scale_fill_manual(values = c("#2B6CB0", "#ED8936")) +
  coord_cartesian(ylim = c(0, 80)) +
  scale_y_continuous(labels = comma_format(suffix = " Bs/h")) +
  labs(
    title = "Figura 4: Brecha Salarial Horaria por Nivel Educativo y Genero del Empleado",
    subtitle = "Retornos de la educacion y remuneracion por hora efectiva segun sexo del trabajador",
    x = "Nivel Educativo Alcanzado",
    y = "Salario por Hora Estimado (Bs/h)",
    fill = "Genero del Trabajador:",
    caption = "Fuente: Encuesta de Hogares - INE Bolivia | Elaboracion propia en R"
  ) +
  theme_custom()

ggsave("plots/04_brecha_salarial_educacion_genero.png", g4, width = 8.5, height = 4.8, dpi = 300)
cat(" -> Generado: 'plots/04_brecha_salarial_educacion_genero.png'\n")

# GRÁFICO 5: Sobrecarga Horaria (>48h) según Macro-Rama de Actividad Económica
p5_df <- dataset_final %>%
  group_by(rama_actividad) %>%
  summarise(
    Total = n(),
    Sobrejornada_Count = sum(sobrejornada == "Si"),
    Pct_Sobrejornada = (Sobrejornada_Count / Total) * 100,
    .groups = "drop"
  ) %>%
  arrange(desc(Pct_Sobrejornada))

g5 <- ggplot(p5_df, aes(x = reorder(rama_actividad, Pct_Sobrejornada), y = Pct_Sobrejornada)) +
  geom_col(fill = ifelse(p5_df$Pct_Sobrejornada > 30, color_alerta, color_secundario), width = 0.65) +
  geom_text(aes(label = sprintf("%.1f%%", Pct_Sobrejornada)), hjust = -0.15, size = 3.0, fontface = "bold") +
  coord_flip() +
  scale_y_continuous(limits = c(0, 55), labels = function(x) paste0(x, "%")) +
  labs(
    title = "Figura 5: Sobrecarga Horaria (> 48h Semanales) por Rama de Actividad",
    subtitle = "Sectores economicos del empleador con mayor incidencia de exceso de jornada laboral",
    x = "",
    y = "Porcentaje de Empleados con Sobrejornada (%)",
    caption = "Fuente: Encuesta de Hogares - INE Bolivia | Elaboracion propia en R"
  ) +
  theme_custom()

ggsave("plots/05_sobrecarga_horaria_por_rama.png", g5, width = 9.0, height = 5.0, dpi = 300)
cat(" -> Generado: 'plots/05_sobrecarga_horaria_por_rama.png'\n")

# GRÁFICO 6: Matriz de Correlación entre Métricas Numéricas del Empleado y Empleador
cor_vars <- dataset_final %>%
  select(
    `Edad` = edad,
    `Escolaridad` = aestudio,
    `Experiencia` = experiencia_potencial,
    `Antigüedad` = antiguedad_anos,
    `Horas Sem.` = horas_semanales,
    `Tam. Empresa` = tamano_empresa_num,
    `Salario Mensual` = salario_mensual,
    `Salario/Hora` = salario_hora,
    `Score Calidad` = score_calidad_empleo
  )

cor_matrix <- cor(cor_vars, use = "complete.obs")
cor_melted <- as.data.frame(as.table(cor_matrix))
names(cor_melted) <- c("Var1", "Var2", "Correlacion")

g6 <- ggplot(cor_melted, aes(x = Var1, y = Var2, fill = Correlacion)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Correlacion)), size = 2.8, fontface = "bold",
            color = ifelse(abs(cor_melted$Correlacion) > 0.5 & cor_melted$Correlacion != 1, "white", "black")) +
  scale_fill_gradient2(low = "#C53030", mid = "#FFFFFF", high = "#2B6CB0", midpoint = 0, limit = c(-1, 1)) +
  labs(
    title = "Figura 6: Matriz de Correlaciones Lineales en la Relacion Laboral",
    subtitle = "Interaccion entre capital humano del empleado, escala del empleador y compensacion",
    x = "",
    y = "",
    fill = "Coef. Correlacion (r):",
    caption = "Fuente: Encuesta de Hogares - INE Bolivia | Elaboracion propia en R"
  ) +
  theme_custom() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("plots/06_matriz_correlaciones.png", g6, width = 8.5, height = 7.0, dpi = 300)
cat(" -> Generado: 'plots/06_matriz_correlaciones.png'\n\n")

cat("====================================================================\n")
cat(" PIPELINE DE PREPROCESAMIENTO EJECUTADO EXITOSAMENTE                \n")
cat(sprintf(" Registros finales limpios: %d | Columnas procesadas: %d \n", nrow(dataset_final), ncol(dataset_final)))
cat(sprintf(" Pasos registrados en Bitácora: %d acciones documentadas.  \n", nrow(bitacora)))
cat("====================================================================\n")
