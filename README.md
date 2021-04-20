:warning: As some files in the CSV and the Processed_files folder were too big to be uploaded to GitHub, pleaase click [here](https://drive.google.com/drive/folders/115230W1hG-rpZpULASTO3yqfwehfJOzg?usp=sharing) to download the following files: Gastos_diarios_urbanos_imputados.csv, Gastos diarios Urbanos.txt, Gastos_menos_frecuentes_articulos_Imputados.csv, Caracteristicas generales personas.csv and Gastos menos frecuentes - Artículos.txt for the CSV folder and Caracteristicas_generales_personas.csv for the Processed_files folder. :warning:

# An analysis of Urban Household expenses: Using the National Household Budget Survey Colombia (ENPH) 2016

This is a collection of codes and files to analyze Colombian Urban Household expenses using the Household Budget survey (Encuesta Nacional de Presupuestos de los Hogares - [ENPH](http://microdatos.dane.gov.co/index.php/catalog/566/get_microdata)) with the R programming language. The goal is to aggregate the expenses by month, and type of good per household using the documentation available in the National Statistics Agency of Colombia (Departamento Administrativo Nacional de Estadísticas DANE). It consists of 4 different scripts and 3 folders arranged as follows:

* 01.Data_Imputation: in this script using the [missForest](https://cran.r-project.org/web/packages/missForest/missForest.pdf) package an imputation of the frequency of purchase of goods is done given that it's necessary in order to calculate the monthly expenses and drop those records could lead to an underestimation of expenses. The use of control variables in the model as social stratum, total income, among others is made. Finally, the imputed data is saved as csv files in the 'CSV' folder.
* 02.Monthly_aggregation: in this script, using the montlhy factors available in the survey manual for each file, the expenses are transformed to monthly expenses per household and type of good. The final data is saved as csv file in the 'Processed files' folder.
* 03.Data_compilation: in this script the union of the montlhy expenses calculated by type of good and household for each initial file is made. As a result, we have the ENPH_FINAL csv file. Here we have household characteristics as social stratum, number of bedrooms, among others and also the montlhy expenses in each type of good and the total expenses per household. 
* 04.Data_graphs_analysis: in this script the data analysis and data graphics is made to use our estimations to understand the household's consumption patterns.
* CSV
* Processed_files
* SURVEY DOCUMENTATION

## Survey documentation

This folder contains the documentation of the survey in Spanish available in the ENPH microdata website. The documents are:

* COICOP_CODE
* Ficha_metodologica_ENPH
* MANUAL_ENPH
* Metodología_ENPH
* dd-documentation-spanish-566
* CUADERNILLOS FOLDER

## CSV

This folder has the original and imputed data files as follows:

* Caracteristicas generales personas.csv
* Gastos diarios del hogar urbano - comidas preparadas fuera del hogar.csv
* Gastos diarios personales Urbano.csv
* Gastos diarios Urbano - Capitulo C.csv
* Gastos diarios Urbanos - Mercados.csv
* Gastos diarios Urbanos.txt
* Gastos menos frecuentes - Artículos.txt
* Gastos menos frecuentes - Medio de pago.csv
* Gastos personales Rural - Comidas preparadas fuera del Hogar.csv
* Gastos personales Rural.csv
* Gastos personales Urbano - Comidas preparadas fuera del hogar.csv
* Gastos semanales Rural - Capituulo C.csv
* Gastos semanales Rurarl - Comidas preparadas fuera del hogar.csv
* Gastos semanales Rurales - Mercados.csv
* Gastos semanales Rurales.cvs
* Gastos_diarios_urbanos_imputados.csv
* Gastos_menos_frecuentes_articulos_Imputados.csv
* GDPU_Imputados.csv
* GDU_comprepfuera_Imputados.csv
* Viviendas y hogares.cvs
* Viviendas_y_hogares_Urbano.csv

To see the meaning of original variables go to the [data dictionary](http://microdatos.dane.gov.co/index.php/catalog/566/data_dictionary). (It is only available in spanish)

## Processed_files

This folder contains the files with the montlhy expenses and the final file ENPH_FINAL.

* Caracteristicas_generales_personas.csv
* GMF_art.csv
* GDU.csv
* Viviendas y hogares.csv
* ENPH_FINAL.csv
* GDU_comprepfuera.csv
* GDP.csv
* GPU_comprepfuera.csv
* GMF_medpag.csv
* GDU_medpag.csv
* GDU_capc.csv
* GDU_mercado.csv

## ENPH_FINAL.csv variables description

The ENPH_FINAL has the following variables:

*	DIRECTORIO:  household identification variable.
*	REGION:  Region where the house is located. Has the following factors:
		
		Atlántica, Bogotá, Central, Nuevos departamentos, Oriental, Pacífica, San Andrés
      
*	DOMINIO: city where the household is located. Has the following factors:

		Arauca, Armenia, Barrancabermeja, Barranquilla, Bogotá, Bucaramanga y A.M, Buenaventura, Cali, Cartagena, Centro    poblado, Cúcuta y A.M, Florencia, Ibagué, Inírida, Leticia, Manizales y A.M, Medellín y A.M, Mitú, Mocoa, Montería, Neiva, Otras cabeceras, Pasto, Pereira y A.M, Popayán, Puerto Carreño, Quibdó, Riohacha, Rionegro, Rural disperso, San Andrés, San José del Guaviare, Santa Marta, Sincelejo, Soledad, Tumaco, Tunja, Valledupar, Villavicencio, Yopal, Yumbo 
      
* TIPO_VIV: Type of household

    	1 » Dwelling house
    	2 » Flat
     	3 » Room (s) in tenancy
     	4 » Room (s) in other kind of structure
     	5 » Indigenous housing
     	6 » Another housing (tent, wagon, boat, cave, natual refuge, etc.)
     
* ESTRATO: socioeconomic stratum related to the energy utility if the household.
* NUM_CUARTOS: Number of bedrooms in the household. Including dining room, how many rooms in total does this house have?
* DORMITORIOS: Number of rooms designated as bedrooms in the home.
* PROPIEDAD_VIV: The dwelling occupied by this household is:

      1 » Own, fully paid
      2 » Own, they are paying it
      3 » For lease or sublease
      4 » In usufruct
      5 » Untitled possession (de facto occupant) or collective property
      6 » Other
      
* INGRESOS_SUFICIENTES: you consider that your household income:

      1 » Is more than enough to cover the household basic expenses
      2 » Is enough to cover the household basic expenses
      3 » Is not enough to cover basic expenses
      
* POBRE: Do you consider yourself poor?

      1 » Yes
      2 » No
      
* PERS_HOGAR: Total number of people in the household.
* Hombres_HOGAR: Total number of men in the household.
* Mujeres_HOGAR: Total number of women in the household.
* GENERO_JH: Gender of the head of household. 

      1 » Man
      2 » Woman

* ETNIA_JH: According to your culture, people, or physical characteristics, you are or you are recignized as:

      1 » Indigenous
      2 » Gitano-Rrom
      3 » Raizal of the San Andrés y Providencia archipelago
      4 » Palenquero of San Basilio or descendant
      5 » Black, mulatto, Afro-Colombian or Afro-descendant
      6 » None of the above (mestizo, white, etc.)
      
* EDAD_JH: How old is the head of the household?
* EDUCACION_JH: What is the highest educational level achieved by the head of the household?

      1 » None
      2 » Preschool
      3 » Basic Elementary
      4 » Basic Secondary
      5 » Medium
      6 » Higher or University
      9 » "Does not know, does not report"
      
* Gto_AlimyBeb_NA: Household spending on food and non-alcoholic beverages.
* Gto_Beb_ATE: Household spending on alcoholic beverages, tobacco and narcotics.
* Gto_ropa: Household expenditure on clothing for family members.
* Gto_transp: Household transportation spending. (Includes Acquisition of vehicles, operation of personal transportation equipment and transportation services)
* Gto_IyC: Household information and communications spending. (Includes Postal Services, Telephone Equipment, Telephone Services and Media).
* Gto_RyC: Expenditure on recreation and culture by households.
* Gto_Diversos: Spending on various goods and services such as personal care, prostitution, personal effects, insurance, financial services and other services.
* Gto_Aloj_Serv: Expenditure on accommodation and services for households.
* Gto_RestyHot: Expenditure on restaurants and hotels, which includes contract meals and lodging services.
* Gto_ArtHogar: Expenditure on furniture, household items and ordinary household maintenance.
* Gto_Salud: Health expenditure (devices and health products, hospitals, etc.)
* Gto_Educ: Expenditure on education, which includes basic primary, secondary, higher and not attributable to any level.
* Gto_ServiciosP: Expenditure on public services not declared in Gto_Aloj_Serv.
* Gto_Arriendo: Actual and imputed rental expense not declared in Gto_Aloj_Serv.
* Gto_EMPLEO_HOGAR: Expenditure related to discounts associated with labor income (withholding tax, ICA, health, pension, ARL, compensation fund, etc.)
* GASTO_TOTAL: Sum of calculated expenses
* IT: total income reported by DANE.
* FEX_C: household expansion factor.



## [COICOP](https://www.dane.gov.co/index.php/sistema-estadistico-nacional-sen/normas-y-estandares/nomenclaturas-y-clasificaciones/clasificaciones/clasificacion-del-consumo-individual-por-finalidades-coicop) (Classification of individual consumption by purpose), CODES BY DIVISION

      01 » FOOD AND NON-ALCOHOLIC BEVERAGES
      02 » ALCOHOLIC BEVERAGES, TOBACCO AND NARCOTICS
      03 » CLOTHING AND FOOTWEAR
      04 » HOUSING, WATER, ELECTRICITY, GAS AND OTHER FUELS
      05 » FURNITURE, ARTICLES FOR THE HOUSEHOLD AND FOR THE ORDINARY CONSERVATION OF THE HOUSEHOLD
      06 » HEALTH
      07 » TRANSPORT
      08 » INFORMATION AND COMMUNICATION
      09 » RECREATION AND CULTURE
      10 » EDUCATION
      11 » RESTAURANTS AND HOTELS
      12 » MISCELLANEOUS GOODS AND SERVICES
      
