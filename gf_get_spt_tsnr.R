rm(list=ls())

library(tidyverse)


## File info
data_dir <- "/data/gf/tSNR"
gf_spt_fmriqa_file <- file.path(data_dir,"gf_spt_fmriqa_coreg_list.csv")
gf_tsnr_file <- file.path(data_dir, "gf_spt_fmriqa_tsnr_data.csv")
gf_tsnr_pattern <- "roidata.*.csv" # fmriqa tsnr pulled from slant ROIs, not topup corrected

setwd(data_dir)

## Get list of all csv files matching gf_tsnr_pattern, read them into data frame
gf_tsnr <- list.files(pattern = gf_tsnr_pattern, recursive = T) %>% 
  tibble(filename=.) %>%
  separate(filename,c("project_label","subject_label","session_label", "fmriqa"),"/",remove = F) %>%
  mutate(data = lapply(filename, read_csv)) %>%
  unnest(data) #%>%
  # select(filename)

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

ggplot(gf_tsnr_hipp, aes(x=LabelName, y=LabelMean)) +
  geom_violin(draw_quantiles = c(0.5))
  # geom_boxplot()

ggsave(file.path(figdir,"baseline_falffnorm_ap_boxplot.pdf"),plot=falffnorm_ap.boxplot,dpi=300,width=150,height=86,units="mm")


## Plot data for all regions
# filter out cerebellum, ventricles, brain stem, and white matter
gf_tsnr_all <- filter(gf_tsnr, (! grepl(pattern="Ventricle",x=LabelName)) & 
                        (! grepl(pattern="Cerebell", x=LabelName)) & 
                        (! grepl(pattern="White", x=LabelName)) & 
                        (! grepl(pattern="Lat Vent",x=LabelName)) &
                        (! grepl(pattern="Brain Stem",x=LabelName)))

# ggplot(gf_tsnr_all, aes(x=LabelName, y=LabelMean)) +
#   geom_violin(draw_quantiles = c(0.5))

## summarize data across all subjects
gf_tsnr_all_summary <- summarise(group_by(gf_tsnr_all, LabelName), median=median(LabelMean,na.rm=T), 
                                 mean=mean(LabelMean,na.rm=T), sd=sd(LabelMean,na.rm=T), n=n(), non_na_count=sum(!is.na(LabelMean))) %>%
  as.data.frame()
gf_tsnr_all_summary <- gf_tsnr_all_summary[order(gf_tsnr_all_summary$median), ]  # sort by median
gf_tsnr_all_summary$LabelName <- factor(gf_tsnr_all_summary$LabelName, levels = gf_tsnr_all_summary$LabelName)
gf_tsnr_all_summary$OverallMedian <- median(gf_tsnr$LabelMean, na.rm = T)


## dot plot
ggplot(gf_tsnr_all_summary, aes(x=LabelName, y=median)) + 
  geom_point(size=2) +   # Draw points
  geom_segment(aes(x=LabelName, 
                   xend=LabelName, 
                   y=min(median), 
                   yend=max(median)), 
               linetype="dashed", 
               size=0.1) +   # Draw dashed lines
  labs(title="tSNR median") +  
  coord_flip()

ggplot(gf_tsnr_all_summary, aes(x=1, y=LabelName, fill=median)) +
  geom_raster() +
  theme(axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank())+   
  labs(title="tSNR")


# Lollipop Plot
ggplot(gf_tsnr_all_summary, aes(x=LabelName, y=median)) + 
  geom_point(size=3) + 
  geom_segment(aes(x=LabelName, 
                   xend=LabelName, 
                   y=0, 
                   yend=median)) + 
  labs(title="tSNR median") +  
  coord_flip()


                      