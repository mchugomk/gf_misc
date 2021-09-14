rm(list=ls())

library(tidyverse)
library(ggtext)
library(glue)

# https://stackoverflow.com/questions/61733297/apply-bold-font-on-specific-axis-ticks
highlight = function(x, pat, color="black", family="") {
  ifelse(grepl(pat, x), glue("<b style='font-family:{family}; color:{color}'>{x}</b>"), x)
}


## File info
data_dir <- "/data/gf/tSNR"
tsnr_csv_data_dir <- "/data/gf"
gf_spt_fmriqa_file <- file.path(data_dir,"gf_spt_fmriqa_coreg_list.csv")
gf_tsnr_file <- file.path(data_dir, "gf_spt_fmriqa_tsnr_data.csv")
gf_tsnr_pattern <- "roidata.*.csv" # fmriqa tsnr pulled from slant ROIs, not topup corrected


setwd(tsnr_csv_data_dir)
## Get list of all csv files matching gf_tsnr_pattern, read them into data frame
gf_tsnr <- list.files( pattern = gf_tsnr_pattern, recursive = T) %>% 
  tibble(filename=.) %>%
  separate(filename,c("project_label","subject_label","session_label", "fmriqa"),"/",remove = F) %>%
  mutate(data = lapply(filename, read_csv)) %>%
  unnest(data) #%>%
  # select(filename)

setwd(data_dir)

## Check for duplicates
dups <- data.frame(filename=unique(gf_tsnr$filename)) %>%
  separate(filename,c("project_label","subject_label","session_label", "fmriqa"),"/",remove = F) 
dups$duplicated <- duplicated(dups$subject_label) 
dups <- filter(dups, duplicated==T)

## Read in fmriqa list used to generate tSNR
gf_spt_fmriqa_info <- read_csv(gf_spt_fmriqa_file)
gf_spt_fmriqa_info$subject_label<-as.character(gf_spt_fmriqa_info$subject_label)
gf_spt_fmriqa_info$session_label<-as.character(gf_spt_fmriqa_info$session_label)


## Merge tsnr data with fmriqa list and save - might include a few duplicates?
gf_tsnr_out <- left_join(gf_spt_fmriqa_info, gf_tsnr, by=c("project_label","subject_label","session_label",
                                                           "gf_fmriqa"="fmriqa"))
write_csv(gf_tsnr_out, gf_tsnr_file, na = "")

## Get lists of missing or duplicate subjects
gf_tsnr_missing <- filter(gf_tsnr_out, is.na(LabelMean))
gf_tsnr_missing$problem <- "missing data"
# gf_tsnr_nodups <- filter(gf_tsnr_out, (! gf_fmriqa %in% dups$fmriqa)) # gf_fmriqa ! %in% dups$fmriqa # subject_label %in% dups$subject_label
gf_tsnr_dups <- filter(gf_tsnr_out, (subject_label %in% dups$subject_label)) # gf_fmriqa ! %in% dups$fmriqa # subject_label %in% dups$subject_label
gf_tsnr_dups$problem <- "duplicate"
gf_tsnr_problems <- rbind(gf_tsnr_missing, gf_tsnr_dups)
write_csv(gf_tsnr_problems, file.path(data_dir,"gf_tsnr_problems.csv"))

## Cleanup
rm(list=c("dups","gf_tsnr_missing","gf_tsnr_dups","gf_tsnr_problems"))

## Plot data for hippocampusf
gf_tsnr_hipp <- filter(gf_tsnr, LabelName=="Right Hippocampus" | LabelName=="Left Hippocampus") 

gf_tsnr_hipp.violin <- ggplot(gf_tsnr_hipp, aes(x=LabelName, y=LabelMean)) +
  geom_violin(draw_quantiles = c(0.5))+
  labs(y = "Median tSNR") +
  theme(axis.title.x = element_blank())
gf_tsnr_hipp.violin
ggsave("gf_tsnr_hipp.pdf",plot=gf_tsnr_hipp.violin,dpi=300,width=86,height=86,units="mm")


## Plot data for all regions
# filter out cerebellum, ventricles, brain stem, and white matter
gf_tsnr_all <- filter(gf_tsnr, (! grepl(pattern="Ventricle",x=LabelName)) & 
                        (! grepl(pattern="Cerebell", x=LabelName)) & 
                        (! grepl(pattern="White", x=LabelName)) & 
                        (! grepl(pattern="Lat Vent",x=LabelName)) &
                        (! grepl(pattern="Brain Stem",x=LabelName)))


## summarize data across all subjects
gf_tsnr_all_summary <- summarise(group_by(gf_tsnr_all, LabelName), median=median(LabelMean,na.rm=T), 
                                 mean=mean(LabelMean,na.rm=T), sd=sd(LabelMean,na.rm=T), n=n(), non_na_count=sum(!is.na(LabelMean))) %>%
  as.data.frame()
gf_tsnr_all_summary <- gf_tsnr_all_summary[order(gf_tsnr_all_summary$median), ]  # sort by median
gf_tsnr_all_summary$LabelName <- factor(gf_tsnr_all_summary$LabelName, levels = gf_tsnr_all_summary$LabelName)
gf_tsnr_all_summary$OverallMedian <- median(gf_tsnr_all_summary$median, na.rm = T)
gf_tsnr_all_summary


## heatmap
gf_tsnr_all.heatmap <- ggplot(gf_tsnr_all_summary, aes(x=1, y=LabelName, fill=median)) +
  geom_raster() +
  geom_hline(yintercept = gf_tsnr_all_summary$OverallMedian) + 
  scale_fill_viridis_c(name="Median tSNR")+
  theme_bw() +
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank())+   
  scale_y_discrete(labels= function(x) highlight(x, "Right Hippocampus|Left Hippocampus", "red")) +
  theme(axis.text.y=element_markdown()) +
  annotate("text", 1, gf_tsnr_all_summary$OverallMedian, vjust = -1, label = "global median")
gf_tsnr_all.heatmap
ggsave("gf_tsnr_all_heatmap.pdf",plot=gf_tsnr_all.heatmap,dpi=300,width=150,height=400,units="mm")

## Lollipop Plot
gf_tsnr_all.lol <- ggplot(gf_tsnr_all_summary, aes(x=median, y=LabelName, )) + 
  geom_point(size=3) + 
  geom_segment(aes(y=LabelName, 
                   yend=LabelName, 
                   x=0, 
                   xend=median)) + 
  geom_vline(xintercept = gf_tsnr_all_summary$OverallMedian) + 
  labs(x = "Median tSNR") +
  scale_y_discrete(labels= function(x) highlight(x, "Right Hippocampus|Left Hippocampus", "red")) +
  theme(axis.text.y=element_markdown()) +
  annotate("text", gf_tsnr_all_summary$OverallMedian, y = 1, vjust = -1, label = "global median")
gf_tsnr_all.lol
ggsave("gf_tsnr_all_lol.pdf",plot=gf_tsnr_all.lol,dpi=300,width=150,height=400,units="mm")

                      