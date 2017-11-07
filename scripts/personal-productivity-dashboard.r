# 
# author: Patrick Ball
# last modified: 6 Nov 2017

# get the data from the log spreadsheet
library(readxl)
library(ggTimeSeries)
library(lubridate)
library(dplyr)
library(tidyr)
library(magrittr)

end_date <- today()
start_date <- max(as.Date("2017-04-01 UTC"), end_date - 365)

# colnames(log) <- make.names(colnames(log))

log <- read_excel("~/Documents/notes/log.xlsx", sheet='log') %>%
    set_colnames(make.names(colnames(.))) %>% 
    filter(start_date <= date & date <= end_date) %>% 
    replace_na(list(work.hours=0))

p1 <- ggplot_calendar_heatmap(log, 'date', 'work.hours') + scale_fill_gradient(low="white", high="red")
p2 <- ggplot_calendar_heatmap(log, 'date', 'word.count') + scale_fill_gradient(low="white", high="green")