import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls
import os

def build_complete_word_report():
    doc = docx.Document()
    
    # Configurar márgenes de página (2.0 cm aprox = 0.79 in)
    sections = doc.sections
    for s in sections:
        s.top_margin = Inches(0.8)
        s.bottom_margin = Inches(0.8)
        s.left_margin = Inches(0.8)
        s.right_margin = Inches(0.8)
        
        # Header y Footer
        header = s.header
        hp = header.paragraphs[0]
        hp.text = "INFORME TÉCNICO DE PREPROCESAMIENTO | MINERÍA DE DATOS (INE BOLIVIA)"
        hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        hp.style.font.size = Pt(8.5)
        hp.style.font.color.rgb = RGBColor(113, 128, 150)
        
        footer = s.footer
        fp = footer.paragraphs[0]
        fp.text = "Proyecto de Preprocesamiento en R: Relación Empleado - Empleador | Octubre 2026"
        fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
        fp.style.font.size = Pt(8.5)
        fp.style.font.color.rgb = RGBColor(113, 128, 150)

    # Colores institucionales
    COLOR_NAVY = RGBColor(26, 54, 93)      # #1A365D
    COLOR_STEEL = RGBColor(43, 108, 176)   # #2B6CB0
    COLOR_DARK = RGBColor(45, 55, 72)      # #2D3748
    COLOR_MUTED = RGBColor(113, 128, 150)  # #718096
    
    def add_title(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(24)
        run.font.bold = True
        run.font.color.rgb = COLOR_NAVY
        p.paragraph_format.space_before = Pt(10)
        p.paragraph_format.space_after = Pt(4)
        return p

    def add_subtitle(text):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(13)
        run.font.italic = True
        run.font.color.rgb = COLOR_STEEL
        p.paragraph_format.space_after = Pt(18)
        return p

    def add_h1(text):
        p = doc.add_paragraph()
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(16)
        run.font.bold = True
        run.font.color.rgb = COLOR_NAVY
        p.paragraph_format.space_before = Pt(18)
        p.paragraph_format.space_after = Pt(6)
        p.paragraph_format.keep_with_next = True
        return p

    def add_h2(text):
        p = doc.add_paragraph()
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(13)
        run.font.bold = True
        run.font.color.rgb = COLOR_STEEL
        p.paragraph_format.space_before = Pt(12)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.keep_with_next = True
        return p

    def add_h3(text):
        p = doc.add_paragraph()
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(11)
        run.font.bold = True
        run.font.color.rgb = COLOR_DARK
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.keep_with_next = True
        return p

    def add_p(text, bold_prefix=None, space_after=6):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            r_pre = p.add_run(bold_prefix)
            r_pre.font.name = 'Calibri'
            r_pre.font.size = Pt(10.5)
            r_pre.font.bold = True
            r_pre.font.color.rgb = COLOR_DARK
        run = p.add_run(text)
        run.font.name = 'Calibri'
        run.font.size = Pt(10.5)
        run.font.color.rgb = COLOR_DARK
        return p

    def add_callout(text, title="NOTA METODOLÓGICA"):
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.cell(0, 0)
        cell.width = Inches(6.8)
        shading = parse_xml(r'<w:shd {} w:fill="EBF8FF"/>'.format(nsdecls('w')))
        cell._tc.get_or_add_tcPr().append(shading)
        borders = parse_xml(r'<w:tcBorders {}><w:left w:val="single" w:sz="24" w:space="0" w:color="2B6CB0"/><w:top w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tcBorders>'.format(nsdecls('w')))
        cell._tc.get_or_add_tcPr().append(borders)
        
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(4)
        p.paragraph_format.space_after = Pt(4)
        r_tit = p.add_run(f"[{title}] ")
        r_tit.bold = True
        r_tit.font.name = 'Calibri'
        r_tit.font.size = Pt(10)
        r_tit.font.color.rgb = COLOR_STEEL
        r_txt = p.add_run(text)
        r_txt.font.name = 'Calibri'
        r_txt.font.size = Pt(10)
        r_txt.font.color.rgb = COLOR_DARK
        doc.add_paragraph().paragraph_format.space_after = Pt(4)

    def add_image_box(img_path, caption, width=Inches(6.0)):
        if os.path.exists(img_path):
            p_img = doc.add_paragraph()
            p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_img.paragraph_format.space_before = Pt(6)
            p_img.paragraph_format.space_after = Pt(2)
            p_img.add_run().add_picture(img_path, width=width)
            
            p_cap = doc.add_paragraph()
            p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p_cap.paragraph_format.space_before = Pt(0)
            p_cap.paragraph_format.space_after = Pt(10)
            r = p_cap.add_run(caption)
            r.font.name = 'Calibri'
            r.font.size = Pt(9)
            r.font.italic = True
            r.font.color.rgb = COLOR_MUTED

    def style_table(tbl, col_widths, headers, data):
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        if len(tbl.rows) == 0:
            hdr_cells = tbl.add_row().cells
        else:
            hdr_cells = tbl.rows[0].cells
        for i, h in enumerate(headers):
            hdr_cells[i].text = h
            hdr_cells[i].width = Inches(col_widths[i])
            shd = parse_xml(r'<w:shd {} w:fill="1A365D"/>'.format(nsdecls('w')))
            hdr_cells[i]._tc.get_or_add_tcPr().append(shd)
            p = hdr_cells[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.font.name = 'Calibri'
                r.font.bold = True
                r.font.size = Pt(9.5)
                r.font.color.rgb = RGBColor(255, 255, 255)
        for row_idx, row_data in enumerate(data):
            row_cells = tbl.add_row().cells
            bg_color = "F7FAFC" if row_idx % 2 == 1 else "FFFFFF"
            for col_idx, val in enumerate(row_data):
                row_cells[col_idx].text = str(val)
                row_cells[col_idx].width = Inches(col_widths[col_idx])
                shd = parse_xml(r'<w:shd {} w:fill="{}"/>'.format(nsdecls('w'), bg_color))
                row_cells[col_idx]._tc.get_or_add_tcPr().append(shd)
                p = row_cells[col_idx].paragraphs[0]
                p.paragraph_format.space_before = Pt(2)
                p.paragraph_format.space_after = Pt(2)
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT if col_idx > 0 else WD_ALIGN_PARAGRAPH.CENTER
                for r in p.runs:
                    r.font.name = 'Calibri'
                    r.font.size = Pt(9)
                    r.font.color.rgb = COLOR_DARK
        doc.add_paragraph().paragraph_format.space_after = Pt(6)

    # =========================================================================
    # PORTADA Y METADATOS
    # =========================================================================
    add_title("INFORME TÉCNICO DE PREPROCESAMIENTO DE DATOS")
    add_subtitle("Minería de Datos del Mercado Laboral: Modelado de Relaciones Contractuales, Calidad del Empleo y Equidad Salarial Empleado - Empleador")

    tbl_meta = doc.add_table(rows=0, cols=2)
    style_table(tbl_meta, [2.2, 4.6], ["Parámetro Institucional", "Detalle Técnico de Ejecución"], [
        ["Código de Documento", "INF-MIN-2026-EH01"],
        ["Fuente de Datos Primaria", "Encuesta de Hogares (EH) – Instituto Nacional de Estadística (INE) Bolivia"],
        ["Entorno y Herramientas", "R versión 4.6.1 (Tidyverse, data.table, ggplot2)"],
        ["Script de Ejecución", "preprocesamiento_empleo.R (12 fases automatizadas con seed 2026)"],
        ["Datasets Curados Resultantes", "dataset_empleo_limpio.csv (3.5 MB) / dataset_modelado_empleado_empleador.rds (378 KB)"],
        ["Bitácora y Auditoría", "BITACORA_LIMPIEZA_DATOS.md y bitacora_limpieza_datos.csv"],
        ["Plataforma Web Interactiva", "INFORME_PREPROCESAMIENTO_EMPLEO.html (Dark Navy Executive Edition)"],
        ["Fecha de Finalización", "Octubre 2026"]
    ])

    # =========================================================================
    # ÍNDICE GENERAL / TABLA DE CONTENIDO FORMAL
    # =========================================================================
    add_h1("Índice General de Contenidos")
    
    tbl_toc = doc.add_table(rows=0, cols=3)
    style_table(tbl_toc, [1.0, 5.0, 0.8], ["Sección", "Título del Apartado Temático", "Pág."], [
        ["1.0", "Introducción al Proyecto de Preprocesamiento Laboral", "2"],
        ["2.0", "Desarrollo Metodológico y Auditoría de Datos", "3"],
        ["2.1", "  • Objetivo Principal", "3"],
        ["2.2", "  • Objetivos Secundarios", "3"],
        ["2.3", "  • Métodos y Técnicas de Calidad Aplicados", "4"],
        ["     -", "      - Duplicados (Unicidad estricta)", "4"],
        ["     -", "      - Datos Incompletos (Completitud e imputación por donante)", "4"],
        ["     -", "      - Etiquetación (Tipado semántico de factores en R)", "5"],
        ["     -", "      - Reglas de Dominio y Valores Atípicos (Filtro legal, consistencia, capping, Winsor)", "5"],
        ["     -", "      - Preprocesamiento para el Análisis (Mincer, Z-scores, partición)", "6"],
        ["     -", "      - Técnicas Descartadas y Justificación (Listwise, media simple, OHE masivo)", "6"],
        ["2.4", "  • Aplicación de las Técnicas (Pipeline en R y Script Automatizado)", "7"],
        ["2.5", "  • Resultados del Preprocesamiento (Matriz Consolidada de 12 Pasos)", "8"],
        ["3.0", "Análisis del Dataset Limpio y Diagnósticos Empíricos", "9"],
        ["3.1", "  • Resultados Empíricos del Dataset Curado (Con Capturas de Gráficos R)", "9"],
        ["     -", "      - A. Auditoría de Completitud [Figura 1]", "9"],
        ["     -", "      - B. Tratamiento de Outliers y Estabilización Salarial [Figura 2]", "10"],
        ["     -", "      - C. Brecha Institucional de Formalidad según Empleador [Figura 3]", "11"],
        ["     -", "      - D. Retornos al Capital Humano y Brecha Salarial de Género [Figura 4]", "12"],
        ["     -", "      - E. Sobrecarga Horaria (>48h) por Macro-Rama CAEB [Figura 5]", "13"],
        ["     -", "      - F. Matriz de Correlaciones Lineales en la Relación Laboral [Figura 6]", "14"],
        ["3.2", "  • Conclusiones de la Dinámica Empleado - Empleador", "15"],
        ["4.0", "Plataforma Web e Informe Interactivo (Dark Mode Edition)", "16"],
        ["4.1", "  • Arquitectura Tecnológica y Características de Usabilidad", "16"],
        ["4.2", "  • Componentes Interactivos y Bitácora Desplegable (Accordion)", "17"],
        ["4.3", "  • Capturas de Pantalla de la Plataforma Web", "18"],
        ["     -", "      - A. Cabecera Hero y Dashboard de KPIs [Figura 7]", "18"],
        ["     -", "      - B. Formulación del Problema y Tensión Empleado-Empleador [Figura 8]", "19"],
        ["     -", "      - C. Catálogo de Variables (Entrada vs. Salida) [Figura 9]", "20"],
        ["     -", "      - D. Bitácora Técnica Desplegable con Código en R [Figura 10]", "21"]
    ])

    doc.add_page_break()

    # =========================================================================
    # 1. INTRODUCCIÓN
    # =========================================================================
    add_h1("1. Introducción")
    add_p(
        "El presente informe técnico expone de manera exhaustiva el diseño, desarrollo, ejecución y validación "
        "de un pipeline de preprocesamiento de datos e ingeniería de características implementado en el lenguaje "
        "estadístico R (v4.6.1). El estudio toma como materia prima la base de microdatos de personas de la Encuesta "
        "de Hogares (EH) levantada por el Instituto Nacional de Estadística (INE) de Bolivia (archivo persona.csv, "
        "compuesto originalmente por 39,497 registros y 275 variables analíticas)."
    )
    add_p(
        "En la ciencia de datos aplicada a la economía laboral y la gestión estratégica del talento humano, "
        "la calidad de las decisiones y la confiabilidad de los modelos predictivos de Machine Learning dependen "
        "críticamente de la fase de preparación de datos (Data Preparation en CRISP-DM). Este trabajo resuelve "
        "la problemática de la relación asimétrica entre Empleado y Empleador en el mercado boliviano, caracterizado "
        "por una marcada dualidad estructural entre un segmento formal hiperprotegido y un extendido sector informal "
        "carente de beneficios de ley."
    )
    add_p(
        "A través de 12 etapas sistemáticas de depuración, el pipeline transforma los datos censales-muestrales brutos "
        "en una matriz curada de 6,925 trabajadores asalariados dependientes y 43 atributos estructurados, con un 100.0% "
        "de completitud, varianzas estabilizadas, outliers acotados y variables normalizadas listas para algoritmos "
        "de clasificación, regresión de salarios y segmentación no supervisada (clustering)."
    )

    # =========================================================================
    # 2. DESARROLLO
    # =========================================================================
    add_h1("2. Desarrollo")

    add_h2("2.1 Objetivo Principal")
    add_p(
        "Diseñar, implementar y validar un flujo automatizado y reproducible de preprocesamiento de datos en R "
        "que depure anomalías, inconsistencias lógicas y valores extremos en la Encuesta de Hogares, aislando "
        "la subpoblación en relación de dependencia asalariada y construyendo variables analíticas que capturen "
        "la formalidad contractual, la compensación horaria justa y la calidad del vínculo laboral entre el empleado "
        "y su unidad económica empleadora."
    )

    add_h2("2.2 Objetivos Secundarios")
    add_p("1. Delimitar estrictamente el universo muestral de análisis a la población ocupada dependiente en edad legal de trabajar (>= 15 años), segregando población inactiva, independiente y casos de trabajo infantil no contractual.", bold_prefix="• ")
    add_p("2. Realizar una auditoría profunda de calidad sobre las 275 variables originales, detectando y corrigiendo discordancias en el diccionario oficial, valores atípicos en jornadas de hasta 168 horas semanales e inconsistencias cronológicas en escolaridad.", bold_prefix="• ")
    add_p("3. Aplicar técnicas robustas de imputación condicional de valores faltantes por donante homogéneo y estabilización de varianza salarial mediante Winsorización y transformaciones logarítmicas.", bold_prefix="• ")
    add_p("4. Desarrollar atributos teóricos de capital humano (ecuación de Mincer, experiencia cuadrática), estratos empresariales por tamaño de planta, macro-sectores económicos CAEB y la variable objetivo estándar de formalidad laboral OIT/INE.", bold_prefix="• ")
    add_p("5. Estandarizar variables continuas a escala Z-score paramétrica y establecer una partición insesgada 80% Entrenamiento y 20% Prueba bajo semilla fija para garantizar reproducibilidad en modelos predictivos.", bold_prefix="• ")
    add_p("6. Documentar el ciclo de vida de los datos mediante una bitácora técnica de 12 pasos y diseñar una plataforma interactiva web en modo oscuro para la visualización ejecutiva de los hallazgos.", bold_prefix="• ")

    add_h2("2.3 Métodos y Técnicas de Calidad")
    add_p(
        "Para garantizar un estándar riguroso de minería de datos, se adoptaron métodos analíticos sustentados en la literatura "
        "estadística y económica, desglosados en las siguientes dimensiones de calidad:"
    )

    add_h3("Duplicados (Unicidad Estricta)")
    add_p(
        "Se evaluó la clave compuesta formada por el identificador de vivienda (folio) y el número de orden del individuo (nro). "
        "Se verificó que no existen registros duplicados a nivel de individuo dentro del mismo hogar, garantizando la unicidad "
        "estricta de cada fila de observación."
    )

    add_h3("Datos Incompletos (Completitud e Imputación por Donante)")
    add_p(
        "En encuestas complejas con saltos de boleta, la presencia de valores nulos (NA) suele obedecer al mecanismo Missing Not At Random (MNAR). "
        "Al delimitar el universo asalariado, la completitud en variables de empleo superó el 99.9%. Para la variable salarial principal "
        "(yprilab), que presentó 2 casos nulos (0.029%), se evitó la eliminación de filas y se aplicó imputación por donante de grupo homogéneo "
        "utilizando la mediana condicional según Sexo, Nivel Educativo y Sector del Empleador, alcanzando 100.0% de completitud final."
    )

    add_h3("Etiquetación (Tipado Semántico de Factores en R)")
    add_p(
        "Se transformaron variables almacenadas como códigos numéricos enteros opacos (1, 2, 3...) en factores estructurados de R "
        "con niveles explícitos y etiquetas normalizadas en español sin caracteres conflictivos. Se estandarizaron: Sexo (Hombre/Mujer), "
        "Área (Urbana/Rural), Departamento (9 departamentos), Nivel Educativo (4 categorías) y Sector Institucional del Empleador (6 niveles)."
    )

    add_h3("Reglas de Dominio y Valores Atípicos (Outliers)")
    add_p("Se implementaron tres controles basados en leyes laborales y biología:", bold_prefix="Reglas de Consistencia: ")
    add_p("a) Filtro de Edad Legal (Ley 548 / OIT C138): Se excluyeron 26 registros de menores de 15 años que distorsionaban contratos formales.", bold_prefix="  - ")
    add_p("b) Consistencia Cronológica de Escolaridad: Se impuso el techo lógico aestudio <= edad - 6 para corregir 5 inconsistencias donde la escolaridad superaba la edad posible.", bold_prefix="  - ")
    add_p("c) Calibración de Jornada Laboral: Se neutralizaron valores físicamente imposibles de hasta 168 horas semanales mediante el producto de días a la semana y horas al día, fijando un techo de 84 h/semana (régimen de 12h x 7 días) y un piso de 4 h/semana.", bold_prefix="  - ")
    add_p(
        "Para el salario mensual, que presentaba 111 outliers extremos según el criterio de Tukey (Q3 + 3*IQR = 12,196 Bs), "
        "se aplicó Winsorización robusta en los percentiles 0.5% (432.6 Bs) y 99.5% (16,553.3 Bs), complementada con la transformación "
        "logarítmica log(x) para estabilizar la varianza residual."
    )

    add_h3("Preprocesamiento para el Análisis (Capital Humano, Normalización Z y Partición)")
    add_p(
        "Se construyeron 14 atributos teóricos esenciales: la variable objetivo formalidad_laboral (1 si recibe seguro médico patronal, 0 si no), "
        "el score_calidad_empleo (0 a 3 beneficios de ley), estrato_empresa (Micro, Pequeña, Mediana, Gran Empresa), macro-sectores CAEB, "
        "experiencia potencial de Mincer, salario horario normalizado (salario / (horas * 4.3333)), sobrejornada (>48h) y salario submínimo (<2500 Bs). "
        "Posteriormente, las 7 variables continuas fueron escaladas mediante Z-Score paramétrico (media 0, desviación estándar 1)."
    )

    add_h3("Técnicas Descartadas y Justificación")
    add_p("1. Eliminación Listwise Agresiva (Complete Case Analysis) sobre la base completa: Hubiera eliminado más del 80% de los datos debido a los saltos legítimos de la encuesta en módulos no laborales.", bold_prefix="• ")
    add_p("2. Imputación con Media Global: Descartada en salarios porque reduce artificialmente la varianza y oculta la brecha salarial de género y el retorno de la educación superior.", bold_prefix="• ")
    add_p("3. One-Hot Encoding no restringido en clasificaciones CAEB/COB: Generar más de 600 columnas binarias para ocupaciones y ramas desagregadas hubiera provocado la maldición de la dimensionalidad y sobreajuste severo.", bold_prefix="• ")
    add_p("4. Eliminación de Outliers Salariales (Trimming): Descartada porque eliminar los salarios altos borraría a los puestos gerenciales y profesionales de mayor productividad; la Winsorización preservó su rango sin distorsionar la media.", bold_prefix="• ")

    add_h2("2.4 Aplicación de las Técnicas (Pipeline en R)")
    add_p(
        "El pipeline fue codificado en el script preprocesamiento_empleo.R, utilizando data.table::fread para lectura ultra-rápida, "
        "dplyr para transformaciones funcionales, scales para formateo numérico y ggplot2 para diagnósticos visuales. "
        "A continuación se presenta un extracto ilustrativo de la lógica nuclear aplicada:"
    )

    add_callout(
        "df_limpio <- df_raw %>%\n"
        "  filter(condact == 1, s04b_12 == 1) %>% # Universo asalariado dependiente\n"
        "  filter(s01a_03 >= 15) %>%               # Edad legal laboral (OIT / Ley 548)\n"
        "  mutate(\n"
        "    aestudio = pmin(aestudio, s01a_03 - 6), # Coherencia cronológica\n"
        "    horas_calc = pmin(84, s04b_15 * s04b_16aa),\n"
        "    phrs_tratada = pmin(84, pmax(4, ifelse(phrs > 84, horas_calc, phrs))),\n"
        "    formalidad_laboral = factor(ifelse(s04c_20a_2 == 1, 'Formal', 'Informal')),\n"
        "    experiencia_potencial = pmax(0, s01a_03 - aestudio - 6),\n"
        "    salario_hora = salario_mensual_winsor / (phrs_tratada * 4.3333)\n"
        "  )",
        title="EXTRACTO DE CÓDIGO R EN preprocesamiento_empleo.R"
    )

    add_h2("2.5 Resultados del Preprocesamiento (Bitácora Consolidada)")
    add_p(
        "La siguiente matriz resume cuantitativamente el impacto de las 12 acciones técnicas registradas en la bitácora de auditoría:"
    )

    tbl_res = doc.add_table(rows=0, cols=5)
    style_table(tbl_res, [0.8, 1.3, 1.4, 1.7, 1.6], ["ID", "Fase", "Variables", "Métrica Antes", "Métrica Después"], [
        ["LIM-01", "Universo", "condact, s04b_12", "39,497 filas (100%)", "6,951 asalariados (17.6%)"],
        ["LIM-02", "Edad Legal", "s01a_03 (Edad)", "Min 10, Max 84 años", "Min 15, Max 84 (6,925 filas)"],
        ["LIM-03", "Consistencia", "aestudio, s01a_03", "5 casos > edad - 5", "0 anomalías (techo lógico)"],
        ["LIM-04", "Jornada", "phrs, s04b_15/16", "Máx: 168.0 h/sem (71 >84h)", "Máx: 84.0 h/sem (Media: 43.88)"],
        ["LIM-05", "Imputación", "yprilab (Salario)", "2 NAs (0.029%)", "0 NAs (Mediana de grupo)"],
        ["LIM-06", "Outliers Sal.", "salario_mensual/hora", "SD: 2,641.7 Bs (111 outliers)", "Winsor [432.6 - 16,553 Bs]"],
        ["LIM-07", "Tipado", "Demografía / Empresa", "6 columnas numéricas opacas", "6 factores estructurados de R"],
        ["LIM-08", "Empleador", "estrato, rama CAEB", "Tamaño 1-3000 y 20 ramas", "4 estratos y 10 macro-ramas"],
        ["LIM-09", "Empleado", "Mincer, sobrejornada", "Variables brutas dispersas", "Mincer, cuadrática, ratios SMN"],
        ["LIM-10", "Targets", "formalidad, score", "Beneficios dispersos", "Target OIT (39.99% formal)"],
        ["LIM-11", "Normalización", "Variables _z", "Escalas físicas dispares", "7 variables con mu=0, sigma=1"],
        ["LIM-12", "Partición", "split_particion", "Sin partición de validación", "Train: 5,540 / Test: 1,385 (80/20)"]
    ])

    # =========================================================================
    # 3. ANÁLISIS DEL DATASET LIMPIO
    # =========================================================================
    add_h1("3. Análisis del Dataset Limpio")

    add_h2("3.1 Resultados Empíricos del Dataset Curado")
    add_p(
        "A partir de la base curada dataset_empleo_limpio.csv se evaluaron las dimensiones esenciales de la relación "
        "empleado-empleador mediante los 6 diagnósticos gráficos generados en R, analizados en detalle a continuación:"
    )

    # GRÁFICO 1
    add_h3("A. Auditoría de Completitud Post-Imputación")
    add_p(
        "La Figura 1 ratifica que el 100.0% de las variables operativas clave en el universo asalariado alcanzaron cero valores nulos. "
        "Esto garantiza que ningún algoritmo de Minería de Datos descartará registros por falta de datos durante el entrenamiento."
    )
    add_image_box("plots/01_missing_values_audit.png", "Figura 1: Tasa de completitud del 100.0% alcanzada en las variables laborales clave tras imputación.")

    # GRÁFICO 2
    add_h3("B. Tratamiento de Outliers y Estabilización de Varianza Salarial")
    add_p(
        "La Figura 2 compara la distribución salarial mensual bruta frente a la tratada mediante Winsorización y logaritmo. "
        "Se observa cómo la cola pesada superior que alcanzaba 30,310 Bs fue acotada al percentil 99.5 (16,553 Bs) y los ingresos inverosímiles "
        "menores a 200 Bs fueron elevados al percentil 0.5 (432 Bs). La transformación logarítmica genera una curva unimodal simétrica "
        "ideal para modelos de regresión lineal y redes neuronales."
    )
    add_image_box("plots/02_outliers_ingreso_horas.png", "Figura 2: Comparativa de la distribución salarial mensual antes vs. después del tratamiento por Winsorización robusta.")

    # GRÁFICO 3
    add_h3("C. La Brecha Institucional de Formalidad por Tipo y Tamaño de Empresa")
    add_p(
        "La Figura 3 revela uno de los hallazgos sociolaborales más contundentes: la formalidad laboral (seguro de salud patronal) "
        "es una condición fuertemente ligada a la escala y naturaleza jurídica de la empresa empleadora. Mientras que en las Empresas Públicas "
        "(90.2%) y el Sector Público (82.6%) la protección es casi universal, y en la Gran Empresa Privada alcanza el 63.1%, "
        "en la Microempresa Privada Informal se derrumba al 7.9%. Esto demuestra que el 92.1% de los asalariados en microempresas "
        "operan en total desprotección patronal."
    )
    add_image_box("plots/03_formalidad_por_sector_tamano.png", "Figura 3: Tasa de formalidad laboral (% con seguro patronal) según sector institucional y estrato de tamaño de la empresa.")

    # GRÁFICO 4
    add_h3("D. Retornos al Capital Humano y Brecha Salarial de Género")
    add_p(
        "La Figura 4 muestra la distribución del salario horario efectivo (Bs/hora) según el nivel educativo y género. "
        "Los retornos a la educación superior son marcadamente convexos: pasar de nivel secundaria a educación superior eleva la mediana "
        "de 12.5 Bs/h a 24.8 Bs/h (una prima cercana al 100%). No obstante, se evidencia una brecha salarial persistente en contra de las mujeres "
        "del 12% al 18% a igualdad de credenciales educativas, reflejando inequidades retributivas y techos de cristal."
    )
    add_image_box("plots/04_brecha_salarial_educacion_genero.png", "Figura 4: Distribución del salario horario (Bs/h) por nivel educativo y género del trabajador asalariado.")

    # GRÁFICO 5
    add_h3("E. Sobrecarga Horaria (> 48h Semanales) por Rama de Actividad Económica")
    add_p(
        "La Figura 5 ilustra la prevalencia de sobrejornada laboral (> 48h semanales) en los diferentes macro-sectores CAEB. "
        "La sobrecarga horaria afecta al 25.59% del total de asalariados, concentrándose fuertemente en Transporte y Almacenamiento (45.2%) "
        "y Comercio (41.8%), en contraste con sectores regulados como Educación y Salud (14.2%) y Administración Pública (11.8%)."
    )
    add_image_box("plots/05_sobrecarga_horaria_por_rama.png", "Figura 5: Porcentaje de empleados asalariados con jornadas superiores a 48 horas semanales por macro-sector CAEB.")

    # GRÁFICO 6
    add_h3("F. Matriz de Correlaciones Lineales en la Relación Laboral")
    add_p(
        "La Figura 6 presenta los coeficientes de correlación de Pearson entre las métricas continuas y ordinales curadas. "
        "Se constata una correlación positiva notable entre Escolaridad y Salario por Hora (r = 0.46) y Score de Beneficios (r = 0.44). "
        "Por el contrario, las Horas Semanales muestran correlación inversa con el Salario por Hora (r = -0.36), lo que evidencia "
        "que las jornadas excesivas caracterizan al empleo informal precario de baja remuneración unitaria."
    )
    add_image_box("plots/06_matriz_correlaciones.png", "Figura 6: Matriz de correlaciones lineales de Pearson entre variables cuantitativas del empleado y del empleador.")

    add_h2("3.2 Conclusiones")
    add_p("1. Determinismo Estructural de la Formalidad: La variable más predictiva de la formalidad laboral no es la cualificación del empleado, sino el estrato de tamaño y el sector institucional de la empresa empleadora. Las intervenciones de política pública deben priorizar la desregulación y subsidio de costos patronales para la microempresa.", bold_prefix="• ")
    add_p("2. Paradoja de la Sobreexplotación Horaria: Laborar más de 48 horas semanales castiga el salario unitario por hora en lugar de incrementarlo, configurando una trampa de subsistencia en sectores terciarios desregulados (transporte y comercio minorista).", bold_prefix="• ")
    add_p("3. Brecha de Género Inexplicada: A igualdad de escolaridad y experiencia de Mincer, las mujeres experimentan una penalización salarial horaria del 12% al 18%, justificando auditorías internas de equidad salarial en las empresas.", bold_prefix="• ")
    add_p("4. Calidad y Preparación de Datos: El conjunto curado dataset_modelado_empleado_empleador.rds elimina el riesgo de fuga de información y sesgo algorítmico, constituyendo una base sólida para modelos de clasificación supervisada (XGBoost) y regresión salarial.", bold_prefix="• ")

    # =========================================================================
    # 4. PLATAFORMA WEB E INFORME INTERACTIVO
    # =========================================================================
    add_h1("4. Plataforma Web e Informe Interactivo (Dark Mode Edition)")
    add_p(
        "Como valor agregado diferencial para la toma de decisiones ejecutivas y la presentación visual de resultados, "
        "se diseñó e implementó la plataforma web interactiva INFORME_PREPROCESAMIENTO_EMPLEO.html, concebida con una "
        "estética profesional en modo oscuro tecnológico (Deep Navy Theme) y arquitectura responsive."
    )

    add_h2("4.1 Arquitectura Tecnológica y Características de Usabilidad")
    add_p("• Paleta Tecnológica Cyber Navy: Fondo en azul marino profundo (#070d19 y #0d1829), tarjetas estructuradas en #132238 con bordes sutiles en #1e3656 y acentos luminosos en cian (#38bdf8), esmeralda (#2dd4bf) y ámbar (#fbbf24).")
    add_p("• Tipografía Jerárquica: Space Grotesk para títulos de impacto analítico, Inter para lectura ejecutiva fluida y JetBrains Mono para fórmulas y código.")
    add_p("• Dashboard de KPIs en Cabecera: Tarjetas métricas interactivas que sintetizan el universo muestral, tasas de formalidad, sobrejornada y salario mediano.")
    add_p("• Autonomía 100% Portátil (Zero External Dependencies): Todas las imágenes de diagnóstico y gráficos ggplot2 se encuentran incrustadas en formato Base64 dentro del mismo archivo HTML, permitiendo abrirlo en cualquier dispositivo sin depender de conexión a internet ni rutas relativas.")
    add_p("• Navegación Lateral Sticky: Menú de acceso rápido que acompaña el desplazamiento del usuario y botones de descarga directa para el script R, el dataset CSV y la bitácora.")

    add_h2("4.2 Componentes Interactivos y Bitácora Desplegable (Accordion)")
    add_p(
        "A petición de los requerimientos de usabilidad ejecutiva, la sección de la bitácora fue totalmente rediseñada "
        "con una estructura de acordeón colapsable. Por defecto, todas las 12 intervenciones técnicas (LIM-01 a LIM-12) "
        "se presentan comprimidas mostrando únicamente la cabecera ejecutiva con el identificador del paso, el título "
        "y el distintivo de estado ('Completado con Éxito'). Al hacer clic sobre cualquier fila, la tarjeta se expande "
        "suavemente mostrando el desglose de variables intervenidas, diagnóstico del problema, métricas cuantitativas antes vs. después, "
        "justificación económica y el bloque de código R ejecutado. Se incluyeron además botones de acción rápida para 'Expandir Todo' "
        "y 'Comprimir Todo' con un solo clic."
    )

    add_h2("4.3 Capturas de Pantalla de la Plataforma Web")
    add_p(
        "A continuación se adjuntan las capturas reales de la interfaz web implementada:"
    )

    add_h3("A. Cabecera Hero y Dashboard de KPIs")
    add_image_box("plots/captura_web_hero.png", "Figura 7: Vista superior de la plataforma web interactiva con panel de KPIs y metadatos técnicos.")

    add_h3("B. Formulación del Problema y Tabla Comparativa Empleado-Empleador")
    add_image_box("plots/captura_web_problema.png", "Figura 8: Sección de contextualización del problema laboral con tabla analítica de tensiones estructurales.")

    add_h3("C. Catálogo de Variables (Entrada vs. Salida) y Atributos Ingeniados")
    add_image_box("plots/captura_web_inventario.png", "Figura 9: Panel de inventario de atributos que detalla las columnas agregadas, mantenidas y descartadas.")

    add_h3("D. Bitácora Técnica Desplegable con Código en R")
    add_image_box("plots/captura_web_bitacora.png", "Figura 10: Fichas técnicas interactivas de la bitácora en acordeón colapsable con diagnósticos de calidad y código R embebido.")

    # Guardar documento Word
    doc.save("INFORME_PREPROCESAMIENTO_EMPLEO.docx")
    print("INFORME_PREPROCESAMIENTO_EMPLEO.docx generated successfully with formal Index and Web Platform section!")

if __name__ == "__main__":
    build_complete_word_report()
