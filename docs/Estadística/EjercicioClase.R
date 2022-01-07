# Pregunta 1 --------------------------------------------------------------

install.packages("pacman")
pacman::p_load(tidyverse, leaflet, janitor, httr, readr, jsonlite, xml2)

# Pregunta 2 --------------------------------------------------------------

url_0 <- "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/" 
url_1 <- "https://datos.madrid.es/egob/catalogo/300107-0-agenda-actividades-eventos.json"
url_12 <- "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/FiltroCCAA/"

httr::GET(url_0)
# Charset UTF-8, XML, response 200

httr::GET(url_1)
# Charset UTF-8, JSON, response 200

httr::GET(url_2)
# Charset UTF-8, XML, response 200


# Pregunta 3 -------------------------------------------------------------

httr::GET(url_0, write_disk('f0.xml'))
httr::GET(url_1, write_disk('f1.json'))
httr::GET(url_2, write_disk('f2.xml'))


# Pregunta 4 --------------------------------------------------------------

r_0 <- read_xml("f0.xml")
# Al fromJSON hay que pasarle la URL directamente
r_1 <- fromJSON(url_1)
r_2 <- read_xml("f2.xml")
r_12 <- fromJSON(url_12)

# Pregunta 5 --------------------------------------------------------------

as_tibble(r_1$`@graph`)
df_d <- r_1$ListaEESSPrecio


# Pregunta 6 --------------------------------------------------------------

df_d <- janitor::clean_names(df_d)
glimpse(df_d)
type_convert(df_d, locale=locale(decimal_mark=","))
df_d %>% filter(provincia %in% c("Huelva", "Sevilla", "Cadiz", "Cordoba", "Jaen", "Granada", "Almeria", "Malaga")) %>% select(provincia, precio_gasolina_95_e5_premium) %>% view()

count(df_d,idccaa)


# Pregunta 8 --------------------------------------------------------------

# Crear columna con nombre oficial de la CC.AA. normalizado por el INE.

mutate(ccaa=case_when(idccaa=="01"~"Andaluc?a", idccaa=="02"~"Arag?n"))

