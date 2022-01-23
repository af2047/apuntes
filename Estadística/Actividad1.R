# Actividad individual 1 LPE
# Andrés Fernández

# Cargar paquetes
pacman::p_load(tidyverse, httr, xml2, jsonlite, leaflet, leaflet.extras, janitor)

# Apartado 1 --------------------------------------------------------------


# Obtener datos de precios actualizados
url = "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres/"
json <- fromJSON(url)
ds <- json$ListaEESSPrecio %>% as_tibble
write_csv(ds, "carburantes.csv")
# Limpiar los datos
glimpse(ds)
ds_clean <- ds %>% clean_names %>% 
  type_convert(locale = locale(decimal_mark = ","))
glimpse(ds_clean)

# R ha considerado que todos los precios son strings, porque en España
# usamos la coma y no el punto como separador decimal. Una vez corregido,
# todas las columnas están correctas, excepto la correspondiente al precio
# del hidrógeno (que ha considerado logical porque ninguna de las 1000)
# primeras gasolineras ofrecía hidrógeno). Cambio el tipo manualmente.
ds_clean$precio_hidrogeno <-as.double(ds_clean$precio_hidrogeno)

# Para calcular el precio medio por comunidad uso la funcionalidad de grupos
# de dplyr (https://dplyr.tidyverse.org/articles/grouping.html#mutate-and-transmute)

ds_lowcost <- ds_clean %>%
  group_by(idccaa) %>% 
  # Como está agrupado por CC.AA, mean() calcula la media de cada comunidad 
  # autónoma, no de todo el dataset. Uso na.rm para quitar las gasolineras 
  # que no venden gasóleo del cálculo de la media
  mutate(low_cost = (precio_gasoleo_a < mean(precio_gasoleo_a, na.rm=TRUE))) %>% 
  # Elimino la información de grupos porque ya no la necesito
  ungroup()

write_csv(ds_lowcost, "lowcost_22062204.csv")


# Apartado 2 --------------------------------------------------------------

# Códigos de CC.AA. obtenidos de https://www.ine.es/daco/daco42/codmun/cod_ccaa.htm
# (Andalucía -> 1, Madrid -> 13)
totalAnd <- ds_lowcost %>% filter(idccaa=="01") %>% count()
lowcostAnd <- ds_lowcost %>% filter(idccaa=="01" & low_cost) %>% count()
# Hay 2176 gasolineras en Andalucía, de las cuales 899 son low cost.
totalMad <- ds_lowcost %>% filter(idccaa=="13") %>% count()
lowcostMad <- ds_lowcost %>% filter(idccaa=="13"& low_cost) %>% count()
# Hay 779 gasolineras en Madrid, de las que 237 son low cost.

# Como en el resto del apartado 2 y el apartado 3 se nos pide obtener la
# media, máximo y mínimo de varios combustibles en varias provincias,
# voy a escribir una función para automatizar el cálculo.

fPrecios <- function(combustible, provincia) {
  
  # Según parece, hay que utilizar !! para que R evalúe el string
  # Fuente: https://stackoverflow.com/questions/48219732/pass-a-string-as-variable-name-in-dplyrfilter
  preciosEnProvincia <- ds_lowcost %>% filter(idccaa==!!provincia)
  #print(paste("El precio medio del", combustible, "en", provincia, "es", 
  #           mean(preciosEnProvincia[[combustible]], na.rm=TRUE)), sep=" ") 
  #print(paste("El precio máximo del", combustible, "en", provincia, "es", 
  #           max(preciosEnProvincia[[combustible]], na.rm=TRUE)), sep=" ") 
  #print(paste("El precio mínimo del", combustible, "en", provincia, "es", 
  #           min(preciosEnProvincia[[combustible]], na.rm=TRUE)), sep=" ") 
  return(c(mean(preciosEnProvincia[[combustible]], na.rm=TRUE),
         max(preciosEnProvincia[[combustible]], na.rm=TRUE),
          min(preciosEnProvincia[[combustible]], na.rm=TRUE)))
}

# Prueba:
# fPrecios("precio_gasoleo_a", "01")

gasolinerasAndalucia <- c(totalAnd, lowcostAnd)
gasolinerasMadrid <- c(totalMad, lowcostMad)
preciosAndalucia <- c(fPrecios("precio_gasoleo_a", "01"),
                      fPrecios("precio_gasolina_95_e5", "01"),
                      fPrecios("precio_gasoleo_premium", "01"))
preciosMadrid <- c(fPrecios("precio_gasoleo_a", "13"),
                      fPrecios("precio_gasolina_95_e5", "13"),
                      fPrecios("precio_gasoleo_premium", "13"))

listaNombres <- c("Total de gasolineras", "Gasolineras low cost",
                  "Precio medio gasóleo A", "Precio máximo gasóleo A",
                  "Precio mínimo gasóleo A",
                  "Precio medio gasolina 95 E5", "Precio máximo gasolina 95 E5",
                  "Precio mínimo gasolina 95 E5",
                  "Precio medio gasóleo premium", "Precio máximo gasóleo premium",
                  "Precio mínimo gasóleo premium")
datosAndalucia <- c(gasolinerasAndalucia, preciosAndalucia)
datosMadrid <- c(gasolinerasMadrid, preciosMadrid)

informeApartado2 <- tibble(`Dato`=listaNombres, `Andalucía`=unlist(datosAndalucia),
                           `Madrid`=unlist(datosMadrid))
write_csv(informeApartado2, "informe_CAM_22062204.csv")

# Apartado 3 --------------------------------------------------------------

provinciasExcluidas <- c('MADRID', 'BARCELONA', 'SEVILLA', 'VALENCIA')

gasolinerasProvincias <- ds_lowcost %>% filter( 
  (provincia %in% provinciasExcluidas) == FALSE)

totalProv <- gasolinerasProvincias %>% count()
lowcostProv <- gasolinerasProvincias %>% filter(low_cost) %>% count()
noLowcostProv <- totalProv - lowcostProv

mediaGasoleoA <- mean(gasolinerasProvincias$precio_gasoleo_a, na.rm=TRUE)
minGasoleoA <- min(gasolinerasProvincias$precio_gasoleo_a, na.rm=TRUE)
maxGasoleoA <- max(gasolinerasProvincias$precio_gasoleo_a, na.rm=TRUE)

mediaGasolina95 <- mean(gasolinerasProvincias$precio_gasolina_95_e5_premium, na.rm=TRUE)
minGasolina95 <- min(gasolinerasProvincias$precio_gasolina_95_e5_premium, na.rm=TRUE)
maxGasolina95 <- max(gasolinerasProvincias$precio_gasolina_95_e5_premium, na.rm=TRUE)

listaNombresProv <- c('Gasolineras low cost','Gasolineras no low cost',
                      'Precio medio gasóleo A', 'Precio mínimo gasóleo A',
                      'Precio máximo gasóleo A', 'Precio medio gasolina 95 E5 Premium',
                      'Precio mínimo gasolina 95 E5 Premium',
                      'Precio máximo gasolina 95 E5 Premium')

datosProv <- c(lowcostProv, noLowcostProv, mediaGasoleoA, minGasoleoA,
               maxGasoleoA, mediaGasolina95, minGasolina95, maxGasolina95)


informeApartado3 <- tibble(`Dato`=listaNombresProv, `Valor`=unlist(datosProv))
write_csv(informeApartado3, "informe_no_grandes_ciudades_22062204.csv")


# Apartado 4 --------------------------------------------------------------

no24horas <- ds_lowcost %>% filter(horario != 'L-D: 24H')
no_24_horas <- no24horas %>% select(-horario)

write_excel_csv(no_24_horas, "no_24_horas.xls")
