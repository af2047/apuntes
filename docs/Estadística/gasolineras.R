# URLs utilizadas en clase

urls <- c("https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/","https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/Listados/Provincias/","https://datos.madrid.es/egob/catalogo/300107-0-agenda-actividades-eventos.json","https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/Listados/Municipios/")

# Cargar paquetes ---------------------------------------------------------

# install.packages("pacman")
pacman::p_load(tidyverse, httr, readxl, xml2, jsonlite, janitor, leaflet, leaflet.extras)


# Cargar archivo local ----------------------------------------------------

# El archivo "preciosEESS_es.xls" debe estar en el working directory
original <- read_xls("preciosEESS_es.xls") %>% glimpse

# Las tres primeras filas no tienen nada útil
original <- read_xls("preciosEESS_es.xls", skip=3) %>% glimpse


# Obtener datos de un servicio web ------------------------------------------

# Los datos de las gasolineras están en https://datos.gob.es/es/catalogo/e05024301-precio-de-carburantes-en-las-gasolineras-espanolas
# Pulsar en datos en tiempo real, luego bajar a la sección REST
url <- "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/"

r <- httr::GET(url)
# Si quisiéramos escribirlo en disco, GET(url, write_disk("gasolineras.xml"))

status_code(r)  # 200 (OK)

# Consultar el header content-type para ver el tipo de archivo y el encoding
headers(r)  # content-type: application/xml; charset=utf-8

# Consultar el tamaño (en bytes)
as.numeric(headers(r)$`content-length`)
# Para pasarlo a MB, dividir por 1024^2

# Para leer un XML, pasarle el contenido del request como texto:
datos_xml <- xml2::read_xml(content(r, as="text"))

# Para leer un JSON, podemos pasar directamente la URL (sin necesidad de usar httr)
datos_json <- jsonlite::fromJSON(url)

# datos_json contiene algunos elementos adicionales (fecha, estado, etc.) además de los datos que nos interesan
# Seleccionamos sólo los datos:
df <- datos_json$ListaEESSPrecio

# Como es un dataframe, lo pasamos a tibble:
df <- as_tibble(df) %>% glimpse


# Limpieza de datos -------------------------------------------------------

# Quitamos acentos y espacios de los nombres de columnas
clean <- clean_names(df)

# El separador decimal es la coma en vez del punto
clean <- type_convert(clean, locale = locale(decimal_mark = ","))

# Cogemos sólo los datos de Salamanca, y creamos una columna nueva para el precio
datosSalamanca <- clean %>% filter(provincia=="SALAMANCA")
gasolinerasCaras <- c("CAMPSA", "REPSOL", "BP", "Shell", "CEPSA", "GALP")
withprice <- datosSalamanca %>% mutate(precio = if_else(marca %in% gasolinerasCaras, "Cara", "Barata"))

# Crear columna con nombre oficial de la CC.AA. normalizado por el INE
comunidades <- mutate(clean, ccaa=case_when(idccaa=="01"~"Andalucía", idccaa=="02"~"Aragón"))

# Contar el número de gasolineras en cada comunidad
count(comunidades, ccaa)
count(comunidades, ccaa, sort=TRUE)

# Separar el horario en dos columnas
separate(comunidades, col=horario, into=c('dias', 'horas'), sep=' ')

# Histogramas -------------------------------------------------------------

ggplot(comunidades, aes(ccaa)) + geom_histogram()

# Mapas -------------------------------------------------------------------

# Vamos a dibujar en el mapa las gasolineras que no están abiertas 24h
df2 <- mutate(df2, "t24h" = Horario=="L-D: 24H")
df3 <- filter(df2, t24h == FALSE)
df3 <- type_convert(df3, locale=locale(decimal_mark=","))

m <- df3 %>% leaflet() %>%
  addProviderTiles("CartoDB") %>%  
  addHeatmap(lng=~`Longitud (WGS84)`, lat=~Latitud, radius=10)
  #addCircles(lng=~`Longitud (WGS84)`, lat=~Latitud, popup="Gasolinera")

# Provider tiles -> por defecto usa openstreetmap(OSM),
# que incluye carreteras, etc. Para que se# vea mejor, 
# usar una capa más limpia, como CartoDB.

# Acordarse de la virgulilla (~) para seleccionar las columnas


# Subir archivos con POST -------------------------------------------------

url2 <- "URL a la que queremos subir el archivo"
write.csv (df3, "datos.csv", row.names = TRUE)
httr::POST(url2, list(x=upload_file("datos.csv")))
