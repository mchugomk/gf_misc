function roidata = extract_roidata_slant(fmri_nii,rroi_nii,rroi_csv,out_dir,tag)
% modified from baxpr conncalc extrac_roidata.m

% Load and count ROIs from the image
Vroi = spm_vol(rroi_nii);
Yroi = spm_read_vols(Vroi);
Yroi(isnan(Yroi(:))) = 0;
roi_vals = unique(Yroi(:));
roi_vals = roi_vals(roi_vals~=0);

% Load the normalized ROI label file
roi_info = readtable(rroi_csv,'Delimiter','comma');
roi_info.LabelName_BrainCOLOR_=cellstr(roi_info.LabelName_BrainCOLOR_)
roi_info.LabelName_BrainCOLOR_=categorical(roi_info.LabelName_BrainCOLOR_)

% Rename rows for 3rd and 4th ventricle
roidata=roi_info;
return


% Check for a problem situation
if ~all(sort(roi_vals) == sort(roi_info.LabelNumber_BrainCOLOR_))
	error('ROI labels in label file do not match image file')
end

% Load fmri and reshape to time x voxel
Vfmri = spm_vol(fmri_nii);
Yfmri = spm_read_vols(Vfmri);
Yfmri = reshape(Yfmri,[],size(Yfmri,4))';

% Extract mean time series
roidata = table();
for r = 1:height(roi_info)
	voxelinds = Yroi(:)==roi_info.LabelNumber_BrainCOLOR_(r);
	voxeldata = Yfmri(:,voxelinds);
	roidata.(roi_info.LabelName_BrainCOLOR_{r})(:,1) = mean(voxeldata,2);
end
% roidata.Properties.VariableNames = roi_info.LabelName_BrainCOLOR_(:)';

% Save ROI data to file
roidata_csv = [out_dir '/roidata_' tag '.csv'];
writetable(roidata,roidata_csv);

return

