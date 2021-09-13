clear all; 

datadir='/data/gf'

% csv file containing list of files to be coregistered
% format:
% project_label,subject_label,session_label,gf_fmri,slant,cat12,gf_fmriqa
% GenFac_HWZ,141375,141375,GenFac_HWZ-x-141375-x-141375-x-gf-fmri-SPT_v1-x-1c472f2f-a207-4d25-8b28-e30933f147b7,GenFac_HWZ-x-141375-x-141375-x-slant_gpu_v1-x-23cc921b-7d45-454a-9782-b99dcb1d6043,GenFac_HWZ-x-141375-x-141375-x-cat12_ss2p0_v2-x-9ef506a2-9c1f-4933-9479-aa47692455f8,GenFac_HWZ-x-141375-x-141375-x-fmriqa_v4-x-090cadfd-4361-4381-992d-fc462c2ecdb9
gf_coreg_info_file='/data/gf/gf_spt_fmriqa_coreg_list.csv' 

gf_coreg_info = readtable(gf_coreg_info_file,'Delimiter',{','}); % read csv into table


for rw=1:height(gf_coreg_info)
    % project/subject/session info
    project=char(gf_coreg_info.x___project_label(rw));
    subject=num2str(gf_coreg_info.subject_label(rw));
    session=num2str(gf_coreg_info.session_label(rw));
    
    % filepaths
    out_dir=fullfile(datadir,project,subject,session,char(gf_coreg_info.gf_fmriqa(rw)),'MEANFMRI')
    gf_fmriqa_file=fullfile(datadir,project,subject,session,char(gf_coreg_info.gf_fmriqa(rw)),'MEANFMRI','meanfmri.nii') 
    slant_file=fullfile(datadir,project,subject,session,char(gf_coreg_info.slant(rw)),'SEG','T1_seg.nii')
    cat12_file=fullfile(datadir,project,subject,session,char(gf_coreg_info.cat12(rw)),'BIAS_CORR','mt1.nii')
    
        
    % gunzip files if needed
    ferror=false;
    if(~isfile(gf_fmriqa_file))
        if(isfile([gf_fmriqa_file '.gz']))
            gunzip([gf_fmriqa_file '.gz'])
        else
            disp(['Unable to find file ' gf_fmriqa_file '.gz'])
            ferror=true;
        end
    end
    if(~isfile(slant_file))
        if(isfile([slant_file '.gz']))
            gunzip([slant_file '.gz'])
        else
            disp(['Unable to find file ' slant_file '.gz'])
            ferror=true;
        end
    end
    if(~isfile(cat12_file))
        if(isfile([cat12_file '.gz']))
            gunzip([cat12_file '.gz'])
        else
            disp(['Unable to find file ' cat12_file '.gz'])
            ferror=true;
        end
    end
        
    % use Baxter's fmriqa coregistration to coreg T1 and segmentation to
    %   mean fmri
    if(~ferror) % no missing files
        coregister(out_dir, cat12_file, slant_file, gf_fmriqa_path)
    end
    
end

