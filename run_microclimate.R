# Given a latitude and longitude, calculate the daily temperature profile

# Note for this to work need to run: NicheMaprR::get.global.climate(folder="data/")

# Read from command line
args <- commandArgs(trailingOnly = TRUE)
lat <- as.numeric(args[1])
long <- as.numeric(args[2])
loc_longlat <- c(long, lat);
month <- args[3]
cat("Location:", loc_longlat, "\n")
cat("Month:", month, "\n")  

# Load the libraries and climate data
library(NicheMapR)
library(tidyverse)

# Now run the microclimate models --------------------------------------------
# build micro climate projections for partially shaded habitats
micro <- micro_global(loc = loc_longlat,
                      #timeinterval = 365, # optionally adjust frequency of day-of-year to calculate from
                      minshade = 50, # input parameter for the light level of shading 
                      maxshade = 90 # input parameter for the dense level of shading 
                      )
# build micro climate projections for sun-heated rock surface
micro_rocks <- micro_global(loc = loc_longlat,
                      #timeinterval = 365,
                      runshade = 0, # switching off shading model
                      minshade = 0, # switching off shading model
                      soiltype = 0, # sets soil type to rock
                      REFL = 1e-6 # solar radiation reflection, this value makes a dark rock that abosrbs a lot of heat from the sun
)
micro_water <- micro_global(loc = loc_longlat,
                            runshade = 0, # switching off shading model
                            minshade = 0, # switching off shading model
                            soiltype = 1, # sets soil type to rock
                            PCTWET = 100
)

# Mapping:
# 1: Rock
# 2: Light veg
# 3: Deep veg
# 4: Pond

# wrangling of prediction results for plotting
light_veg <- as.data.frame(micro$soil) %>% 
  select("DOY","TIME","D0cm") %>% 
  mutate(habitat_desc = "light shading", habitat_code = 2)
dense_veg <- as.data.frame(micro$shadsoil) %>% 
  select("DOY","TIME","D0cm")%>% 
  mutate(habitat_desc = "dense shading", habitat_code = 3)
heated <- as.data.frame(micro_rocks$soil) %>% 
  select("DOY","TIME","D0cm")%>% 
  mutate(habitat_desc = "rock in sun", habitat_code = 1)
pond <- as.data.frame(micro_water$soil) %>% 
  select("DOY","TIME","D0cm")%>% 
  mutate(habitat_desc = "pond surface in sun", habitat_code = 4)
habitats <- bind_rows(light_veg,dense_veg,heated,pond) %>% 
  mutate(month = month(as_date(DOY, origin = "2023-01-01"), 
                       label = TRUE, 
                       abbr = TRUE))

# Filter for the month
habitats <- habitats[habitats$month == month,]

# Now process to correct output matrix
output_matrix <- select(habitats, habitat_code, TIME, D0cm) |>
    mutate(D0cm = round(D0cm, digits = 1)) |>
    pivot_wider(id_cols = habitat_code, 
                names_from = TIME, values_from = D0cm) |>
    arrange(habitat_code)

# Now output
# Open a file connection
file_path <- paste0("data/microclimate_data-",month,".txt")
con <- file(file_path, open = "wt")

# Add comments (starting with # is standard)
writeLines("# First column is vegetation type ID (1: Rock, 2: Light veg., 3: Dense veg., 4: Pond)", con)
writeLines("# Remaining columns are the hourly temperatures (start time midnight)", con)
#writeLines(paste0("# Location (lat,long): ",lat, ", ", long, con) 
writeLines(paste("# Month:", month), con)

# Write the matrix data
write.table(output_matrix, con, sep=",",
            row.names = FALSE, col.names = FALSE)

# Close the connection
close(con)
