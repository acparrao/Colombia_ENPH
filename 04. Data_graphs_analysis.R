## Set as working directory the folder where this file is
actual_wd <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(actual_wd)

## Install packages of they are not already installed
x <- c("tidyverse", "readxl", "ggplot2", "stringi", "ggpubr", "corrplot", 
       "gam", "mgcv")
new.packages <- x[!(x %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

## Load the packages
lapply(x, library, character.only = TRUE)

rm(actual_wd, x, new.packages)


## Use the ENPH_FINAL file created in the last step. This has the monthly
## expenses in each type of good and multiple house's and people's characteristics
datos <- read.csv("Processed_files/ENPH_FINAL.csv", sep=";")

## In Colombia only exists social stratum from 1 to 6, so drop all the 
## houses with no stratum, zero stratum or 99 stratum. In addition,
## a expansion factor < 1 has no sense by the construction, so those 
## observations were also droped
datos <- datos %>% filter(!is.na(datos$ESTRATO) & datos$ESTRATO!=9  
                          & datos$ESTRATO!=0 & datos$DORMITORIOS!=99 & datos$FEX_C>=1)

## Transform to factor different variables
V <- c(4, 5, 8, 9, 10, 14, 15, 17)
for (i in V) {
  datos[,i] <- as.factor(datos[,i]) 
}

## Drop special characteres from the REGION and DOMINIO variables
datos <- datos %>% 
  mutate(REGION = stri_trans_general(REGION, 'Latin-ASCII')) %>% 
  mutate(DOMINIO = stri_trans_general(DOMINIO, 'Latin-ASCII'))

## Change 'NUEVO DEPARTAMENTOS' for 'NUEVOS \n DEPTOS' to made easy to read
## graphs
datos <- datos %>% mutate(REGION = ifelse(REGION == 'NUEVO DEPARTAMENTOS', 
                                       'NUEVOS \n DEPTOS', REGION))
datos$REGION <- as.factor(datos$REGION)

## Create variables of share of total expenditure in each group of good
dat <- function(df, n) {
  varname <- paste("Prop", names(df)[n] , sep="_")
  df[[varname]] <- with(df, df[[n]] / GASTO_TOTAL)
  df
}


for(i in 19:31) {
  datos <- dat(df=datos, n=i)
}


## Find correlations and correlation plot between expenses in every type of 
## good, total expenditure and total income reported by DANE
correlacion<-round(cor(datos[,18:34]), 1)
corrplot(correlacion, method="number", type="upper", tl.cex = 0.5, 
        number.cex=0.5)


## Find mean for Social stratum and REGION, so we can compare between
## regions, stratums and type of goods.
prom <- datos %>% 
  aggregate(by= list(datos$ESTRATO, datos$REGION), FUN=mean) %>% 
  dplyr::select(Group.1, Group.2, PERS_HOGAR, Hombres_HOGAR, Mujeres_HOGAR,
         EDAD_JH, Gto_AlimyBeb_NA:IT)
names(prom)[1:2] <- c('ESTRATO', 'REGION')


## To create easily graphs, transform from wide to long format
datos_2 <- datos %>% 
  dplyr::select(DIRECTORIO, REGION, ESTRATO, PERS_HOGAR, Hombres_HOGAR, Mujeres_HOGAR,
         EDAD_JH, Gto_AlimyBeb_NA:IT) %>% 
  gather(type_good, Expenditure, Gto_AlimyBeb_NA:IT, factor_key=TRUE)
## Transform to thousand pesos
datos_2 <- datos_2 %>% mutate(Expenditure = Expenditure / 1000)


datos_3 <- datos %>% 
  dplyr::select(DIRECTORIO, REGION, ESTRATO, PERS_HOGAR, Hombres_HOGAR, Mujeres_HOGAR,
         EDAD_JH, Prop_Gto_AlimyBeb_NA:Prop_Gto_Arriendo, GASTO_TOTAL) %>% 
  gather(type_good, Proportion, Prop_Gto_AlimyBeb_NA:Prop_Gto_Arriendo,
         factor_key=TRUE)


#A <- unique(datos_2$REGION)
#B <- unique(datos_2$ESTRATO)

## Histogram to compare expenditure in each good
ggplot(datos_2, aes(Expenditure)) +
  facet_wrap(~type_good, scales = 'free_x') +
  geom_histogram(bins = 40)
ggplot(datos_2, aes(Expenditure)) +
  facet_wrap(~type_good, scales = 'free') +
  geom_histogram(bins = 40)

## Histogram to compare total expenditure by social stratum
ggplot(datos, aes(GASTO_TOTAL)) +
  facet_wrap( ~ ESTRATO, scales = 'free_x') +
  geom_histogram(bins = 40)

## Histogram to compare total expenditure by regions
ggplot(datos, aes(GASTO_TOTAL)) +
  facet_wrap( ~ REGION, scales = 'free_x') +
  geom_histogram(bins = 40)

## Histogram to compare share on each good
ggplot(datos_3, aes(Proportion)) +
  facet_wrap(~type_good, scales = 'free_x') +
  geom_histogram(bins = 40)
ggplot(datos_3, aes(Proportion)) +
  facet_wrap(~type_good, scales = 'free') +
  geom_histogram(bins = 40)


####### Graphs of the shares in different goods vs total expenditure
## By stratum
ggplot(datos_3, aes(x=GASTO_TOTAL, y=Proportion, colour=ESTRATO)) +
  facet_wrap(~type_good, scales = 'free') +
  geom_point()

## By region
ggplot(datos_3, aes(x=GASTO_TOTAL, y=Proportion, colour=REGION)) +
  facet_wrap(~type_good, scales = 'free') +
  geom_point()


## Estimate Engel's curves using lm

A <- names(datos[,36:49])
resultList_lm <- list()
fit_models <- list()

for (n in A) {
  fit <- lm(log(datos$GASTO_TOTAL) ~ datos[[n]], data=datos, weights = FEX_C)
  fit_models[[n]] <- fit 
  resultList_lm[[n]] <- summary(fit)
}

## Using Social Stratum and REGION variables
resultList_lm2 <- list()
fit_models2 <- list()
for (n in A) {
  fit <- lm(log(datos$GASTO_TOTAL) ~ datos[[n]]+REGION+ESTRATO, 
            data=datos, weights = FEX_C)
  fit_models2[[n]] <- fit 
  resultList_lm2[[n]] <- summary(fit)
}

### Graphing lm results
ggplot(datos_3, aes(x = log(GASTO_TOTAL), y = Proportion)) + 
  facet_wrap(~type_good, scales = 'free') +
  geom_point() +
  stat_smooth(method = "lm", col = "red")

## Graphing the Engel's curve with a cubic spline smoothing 
ggplot(datos_3, aes(x = log(GASTO_TOTAL), y = Proportion)) + 
  facet_wrap(~type_good, scales = 'free') +
  geom_point() +
  stat_smooth(formula= y ~ ns(x,3), 
              method = "lm", col = "red")


