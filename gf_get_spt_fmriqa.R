rm(list=ls())

library(tidyverse)

data_dir<-"/data/gf/tSNR"
setwd(data_dir)
gf_scan_info <- read.csv(file.path(data_dir,"gf_xnatreport.csv"), skip = 2) %>%
  filter(as_type=="spt1APA_FMRI_MB3_2_5mm_1300")
gf_scan_info$as_label <- as.character(gf_scan_info$as_label)
gf_fmriqa_info <- read.csv(file.path(data_dir,"Xnatreport_fmriqa_v4_info.csv"))
gf_fmriqa_info$scan_fmri <- as.character(gf_fmriqa_info$scan_fmri)

gf_spt_fmriqa <- left_join(gf_scan_info, gf_fmriqa_info, by=c("project_id"="project_label","subject_label","session_label",
                                                              "as_label"="scan_fmri"))
write.csv(gf_spt_fmriqa, file.path(data_dir,"gf_spt_fmriqa_v4.csv"),row.names = F)

# merge fmriqa with gf fmri processed data
gf_spt_proc_info <- read.csv(file.path(data_dir,"gf_spt_processed.csv"))
gf_spt_fmriqa_limited <- select(gf_spt_fmriqa, c(subject_label,session_label,as_label, assessor_label, scan_t1, assr_ma))
gf_spt_proc_info_fmriqa <- left_join(gf_spt_proc_info, gf_spt_fmriqa_limited, c("subject_label","session_label"))
write.csv(gf_spt_proc_info_fmriqa, file.path(data_dir,"gf_spt_processed_fmriqa.csv"),row.names = F)


