function result = epi_opt_param_TB(fieldmaps, rois, template, main_orientation, ...
                     fov, base_res, pe_ov, delta_z, echo_spacing, TC, vx_epi, AF, ...
                     PF, tilt, shimz, TEvar, rfs, R2sOpt, FieldGradOpt, suffix)

% =========================================================================
% Copyright (C)            2015-2018          Steffen Volz
% Wellcome Trust Centre for Neuroimaging, London
% and Max Planck Institute for Human Cognitive and Brain Sciences, Leipzig
%
% Updated and refactored   2024 - 2025        Shokoufeh Golshani
% Functional Imaging Laboratory, Imaging Neuroscience, UCL
% =========================================================================

% ========================================================================= 
% This function iterates through the simulation parameter space to identify 
% the optimal BOLD (Blood Oxygen Level Dependent) sensitivity. 
% ========================================================================= 
% fieldmaps                       : Cell Array containing Field gradients 
%                                   in (read, phase, slice) directions in T/m          
% rois                            : Cell Array containing the ROIs
% template                        : Cell Array containing the Brain Mask       
% main_orientation                : Default Slice Orientation in EPI Acquistion                            
% fov                             : Field of View in the Phase Direction  (in mm)
% base_res                        : Base Resolution in number of pixels (Matrix size)
% pe_ov                           : Oversampling in Phase Encoding Direction in %
% delta_z                         : Slice Thickness or more precisely the
%                                   FWHM of the slice excitation profile
%                                   for a Guassian RF Pulse (in mm)
% echo_spacing                    : Echo spacing (in ms)
% TC                              : Central Echo Time (in ms)
% vx_epi                          : Voxel size (in mm)
% AF                              : In-plane Acceleration Factor
% PF                              : In-plane Partial Fourier
% tilt                            : Slice angulation (in degrees)        
%                                  (1x4) array [min ref max step-size]
% PP                              : Shim gradient moment in z-direction (in mT/m*ms)          
%                                  (1x4) array [min ref max step-size]  
% rfs                             : Reduced Field Size                     
%                                   0 = no (original size), 1 = yes (1/3) 
% R2sOpt                          : R2star Choice (in 1/ms)
% suffix                          : suffix for saved result
% =========================================================================

% -------------------------------------------------------------------------
% Define the output folder
% -------------------------------------------------------------------------
out_dir = fullfile(pwd, sprintf('results_BS%s', suffix));
if ~exist(out_dir,'file')
    mkdir(out_dir);
end

% -------------------------------------------------------------------------
% Reading Field Map files
% -------------------------------------------------------------------------
spm_progress_bar('Init', 10, 'preparing ...', 'steps');
spm_progress_bar('Set', 0);

for n = 1:length(fieldmaps)
    sprintf('Using fieldmap(s) = %s;',fieldmaps{n});
end

if (length(fieldmaps) == 3)
   fprintf('loading gradientmaps ...\n');

   rescale_gradient = 1.0;
   vol_fm_dX = spm_vol(fieldmaps{1});
   vol_fm_dY = spm_vol(fieldmaps{2});
   vol_fm_dZ = spm_vol(fieldmaps{3});

   fm_dX = resize(rescale_gradient.*spm_read_vols(vol_fm_dX), rfs);
   fm_dY = resize(rescale_gradient.*spm_read_vols(vol_fm_dY), rfs);
   fm_dZ = resize(rescale_gradient.*spm_read_vols(vol_fm_dZ), rfs);

elseif (length(fieldmaps) == 1)
   fprintf('loading fieldmaps and calculating gradientmaps ...\n');

   spm_progress_bar('Set', 1);
   vol_fm_dX = spm_vol(fieldmaps{1});

   [fm_dX, fm_dY, fm_dZ] = CalculateGradientmaps_TB(fieldmaps{1}, FieldGradOpt);
   fprintf('resizing gradientmaps ...\n');
   
   fm_dX = resize(fm_dX, rfs);
   fm_dY = resize(fm_dY, rfs);
   fm_dZ = resize(fm_dZ, rfs);

else
    fprintf('Error: invalid number of fieldmap files;\n');
end

% -------------------------------------------------------------------------
% Setting Protocol Parameters
% -------------------------------------------------------------------------
fprintf('setting user defined parameters ...\n');
spm_progress_bar('Set' ,7);

epi_param_fix.main_orientation = main_orientation;
epi_param_fix.echo_spacing     = echo_spacing * 10^(-3);

epi_param_fix.fov              = fov * 10^(-3);
epi_param_fix.AccF             = AF;
epi_param_fix.PF               = PF;
epi_param_fix.base_res         = base_res;
epi_param_fix.slicethickness   = delta_z * 10^(-3);
epi_param_fix.echotime         = TC * 10^(-3);
epi_param_fix.vx_epi           = vx_epi * 10^(-3);

% Effective phase-encoding steps
epi_param_fix.pe_eff = floor(epi_param_fix.base_res * (1 + pe_ov/100));

% Fully-sampled case
epi_param_fix.TA_FS  = epi_param_fix.echo_spacing * epi_param_fix.pe_eff;

% PF-Acc case
epi_param_fix.pe_eff = epi_param_fix.pe_eff * epi_param_fix.PF/epi_param_fix.AccF;

% Total acquisition time
epi_param_fix.TA     = epi_param_fix.echo_spacing * epi_param_fix.pe_eff; 

% -------------------------------------------------------------------------
% Setting Scanner-dependant Parameter
% -------------------------------------------------------------------------
fieldNames = fieldnames(R2sOpt);
R2sfield = fieldNames{1};

R2s = R2sOpt.(R2sfield);

fprintf('loading R2s value/map\n');
if isnumeric(R2s)
    scanner_param.R2s = R2s*10^3;    
else
    vol_R2s = spm_vol(char(R2s));
    R2sMap = spm_read_vols(vol_R2s);
    scanner_param.R2s = R2sMap.*10^3;
end

% -------------------------------------------------------------------------
% Reading ROIs
% -------------------------------------------------------------------------
fprintf('reading ROIs ...\n');
spm_progress_bar('Set', 8);

for n = 1:length(rois)

    vol_MyRoi = spm_vol(rois{n});
    ROI_slct(:,:,:,n) = logical(resize(spm_read_vols(vol_MyRoi), rfs));

    % ROI_averaged Susceptiblity Gradient
    GSroi = fm_dZ(squeeze(ROI_slct(:,:,:,n))>0);
    GSroi_sd = std(GSroi)*1e6;
    GSroi = mean(GSroi)*1e6;
    
    GSroi_TE = GSroi*epi_param_fix.echotime;

    GProi = fm_dY(squeeze(ROI_slct(:,:,:,n))>0);
    GProi_sd = std(GProi)*1e6;
    GProi = mean(GProi)*1e6;
    
    fprintf(['Mean slice gradient moment in the roi: %0.3f (mT/m*ms). ' ...
             'Adjust shimz moment accordingly. \n'], GSroi_TE);

    plus_minus_char = char(177);
    fprintf('Mean Phase/Slice gradient in the roi: %0.3f %c %0.3f - %0.3f %c %0.3f (uT/m).\n',...
            GProi, plus_minus_char, GProi_sd, GSroi, plus_minus_char, GSroi_sd);

    if strcmp(R2sfield, 'ROI_Averaged') || strcmp(R2sfield, 'Voxel_wise')
        R2sMapROI = R2sMap.*squeeze(ROI_slct(:,:,:,n));
        R2sroi(n) = mean(nonzeros(R2sMapROI))*10^3;   
        fprintf('Averaged R2s value in ROI Nr. %d:  %0.2f (s^-1) \n', n, R2sroi(n));
    end
end

if strcmp(R2sfield, 'ROI_Averaged')         
    scanner_param.R2s = R2sroi;
    scanner_param.R2sOpt = R2sfield;
    scanner_param.nR2s   = length(rois);
else
    scanner_param.nR2s   = 1;
end

% -------------------------------------------------------------------------
% Reading the template brain mask
% -------------------------------------------------------------------------
fprintf('reading the template brain mask ...\n');
spm_progress_bar('Set', 9);

for n = 1:length(template)
    vol_tmpl_msk = spm_vol(template{n});
    Brainmask_tmpl(:,:,:,n) = resize(spm_read_vols(vol_tmpl_msk), rfs);
end

% -------------------------------------------------------------------------
% Setting Simulation Parameters
% -------------------------------------------------------------------------
PP_range = shimz(1):shimz(4):shimz(3);
PP_ref = shimz(2);

tilt_range = tilt(1):tilt(4):tilt(3);
tilt_ref = tilt(2); 

fieldN = fieldnames(TEvar);
TEvarfield = fieldN{1};

if strcmp(TEvarfield, 'Variable_TE')
    TE_range = TEvar.Variable_TE(1):TEvar.Variable_TE(3):TEvar.Variable_TE(2);
else
    TE_range = TEvar.Fixed_TE(1);
end


% =========================================================================
% Phase Encoding direction (based on the prewinder gradient moment)
% (-1 = Positive Prewinder, +1 = Negative Prewinder)
% =========================================================================
PE_range = [-1 1];

% -------------------------------------------------------------------------
% Setting Field derivatives
% -------------------------------------------------------------------------
FG.DX        = fm_dX;
FG.DY        = fm_dY;
FG.DZ        = fm_dZ;
FG.direction = vol_fm_dX.mat(1:3,1:3);

% -------------------------------------------------------------------------
% BS for Standard EPI Protocol (no tilt, no compensation, Positive Prewinder (AP))
% This just for producing a valid BSgain mask
% -------------------------------------------------------------------------
epi_param_opt.GP = [0 0 0]*10^-6;              
epi_param_opt.tilt = 0;                   
epi_param_opt.PE_dir = -1;             

[~,~,BS_baseline] = CalculateBS_TB(FG, epi_param_opt, epi_param_fix, scanner_param);

% -------------------------------------------------------------------------
% Exploring the Parameter Space
% -------------------------------------------------------------------------
fprintf('exploring parameter space ... \n');

result = cell(1,size(TE_range, 2));
size_parameterspace = 2*size(tilt_range, 2)*size(PP_range, 2)*size(TE_range, 2);

spm_progress_bar('Clear');
spm_progress_bar('Init', size_parameterspace, 'exploring parameter space', 'settings completed');

ct = 0;
ct0 = 0;

for TE_val = 1:length(TE_range)
    
    for PE_val = 1:length(PE_range)
        
        for tilt_val = 1:length(tilt_range)
            
            for PP_val = 1:length(PP_range)
                
                spm_progress_bar('Set', ct);
                ct = ct + 1;
    
                PE_all(ct) = PE_range(PE_val);
                tilt_all(ct) = tilt_range(tilt_val);
                PP_all(ct) = PP_range(PP_val);
    
                if (PE_range(PE_val) == -1) && (tilt_range(tilt_val) == tilt_ref) && (PP_range(PP_val) == PP_ref)
                    ct0 = ct;     
                end
    
                epi_param_opt.GP = [0 0 PP_range(PP_val)]*10^-6;
                epi_param_opt.tilt = tilt_range(tilt_val);
                epi_param_opt.PE_dir = PE_range(PE_val);

                epi_param_fix.echotime = TE_range(TE_val)*10^-3;
    
                [~, ~, BS_tmp, fGP, fGS, shift_mask, localTE, Q, Isl] = CalculateBS_TB(FG, epi_param_opt, epi_param_fix, scanner_param);
          
                % -------------------------------------------------------------
                % Excluding out of range values
                % -------------------------------------------------------------
                if strcmp(R2sfield, 'ROI_Averaged')
                    nR2s = length(rois);
                else
                    nR2s = 1;
                end
                BS_gain_tmp = ((BS_tmp./(repmat(BS_baseline, 1, 1, 1, nR2s)+eps)) - 1)*100;
                BSGainMask = ones(size(BS_gain_tmp)); 
                % BSGainMask = (BS_gain_tmp > -100) & (BS_gain_tmp < 200);  (BS_gain_tmp > -200) & (BS_gain_tmp < 200);
                % This is for excluding too large values --> the first constraint does nothing (excluding negative BS which never happens!)
                % The second constraint basically zeros the voxels that were zero in the baseline due to the shift mask!
                % --> would it matter? at the end, we are interesting in the ROI --> BS_gain_roi
                
                BrainAndGainMask_tmp = (repmat(Brainmask_tmpl, 1, 1, 1, nR2s) > 0.99).*BSGainMask;
    
                % -------------------------------------------------------------
                % Evaluating ROIS
                % -------------------------------------------------------------
                for n = 1:length(rois)
                    if strcmp(R2sfield, 'ROI_Averaged')
                        BrainAndGainMask = squeeze(BrainAndGainMask_tmp(:,:,:,n));
                        BS               = squeeze(BS_tmp(:,:,:,n));
                        BS_gain          = squeeze(BS_gain_tmp(:,:,:,n));
                    else
                        BrainAndGainMask = BrainAndGainMask_tmp;
                        BS               = BS_tmp;
                        BS_gain          = BS_gain_tmp;
                    end
     
                    Gain = BS_gain .* BrainAndGainMask;
                    
                    % Finding voxel indices corresponding to the ROI
                    Ind_ToOpt = find((BrainAndGainMask.*squeeze(ROI_slct(:,:,:,n))) > 0);   
                    
                    % Number of voxels with complete signal dropout
                    Dropout_Vox = find(shift_mask(Ind_ToOpt) == 0);     
                    Percnt_Dropout_Vox(n, ct) = length(Dropout_Vox)/length(find(squeeze(ROI_slct(:,:,:,n)) > 0));
                    
                    Roi_Sel_val = BS(Ind_ToOpt);
                    Roi_Sel_gain = Gain(Ind_ToOpt);
                    BS_gain_roi = (BS(Ind_ToOpt) - BS_baseline(Ind_ToOpt))./BS_baseline(Ind_ToOpt);
        
                    % ------------------------------------------------------------
                    % Theoretical BOLD Sensitivity in the ROI
                    Roi_mean(n, ct) = mean(Roi_Sel_val(:));
                    Roi_std(n, ct)  = std(Roi_Sel_val(:));

                    % Introducing a new metric: removing the outliers in the ROI
                    [Roi_Sel_val_rmoutlr, TFrm, TFoutlier, L, U, C] = rmoutliers(Roi_Sel_val, "gesd");
                    Roi_mean_rmoulr(n, ct) = mean(Roi_Sel_val_rmoutlr(:));
                
                    % Introducing a new metric: penalising the mean with standard deviation
                    lambda = 0.01;
                    Roi_mean_std(n, ct) = Roi_mean(n, ct) - lambda*Roi_std(n, ct);   
                    % ------------------------------------------------------------
                    % Gain in the ROI
                    Roi_gain_mean(n, ct) = mean(Roi_Sel_gain(:));
                    Roi_BSgain_mean(n, ct) = mean(BS_gain_roi(:));
        
                    % Susceptibility gradient in the phase direction in the ROI
                    GSP = fGP(Ind_ToOpt);
                    Roi_GSP_mean(n, ct) = mean(GSP(:));
                    Roi_GSP_sd(n, ct) = std(GSP(:));
    
                    % Susceptibility gradient in the slice direction in the ROI
                    GSS = fGS(Ind_ToOpt);
                    Roi_GSS_mean(n, ct) = mean(GSS(:));
                    Roi_GSS_sd(n, ct) = std(GSS(:));

                    % Q factor in the ROI
                    Q_f = Q(Ind_ToOpt);
                    Roi_Q_mean(n, ct) = mean(Q_f(:));
                    Roi_Q_sd(n, ct) = std(Q_f(:));

                    % signal loss due to susceptibility in the slice direction
                    Isl_f = Isl(Ind_ToOpt);
                    Roi_Isl_mean(n, ct) = mean(Isl_f(:));
                    Roi_Isl_sd(n, ct) = std(Isl_f(:));

                    % local TE in the ROI
                    local_TE = localTE(Ind_ToOpt);
                    Roi_localTE_mean(n, ct) = mean(local_TE(:));
                    Roi_localTE_sd(n, ct) = std(local_TE(:));

                    %%-----------------------------------------------------
                    result{TE_val}.Q_matrix(PE_val, tilt_val, PP_val, n)         = Roi_Q_mean(n, ct);
                    result{TE_val}.Isl_matrix(PE_val, tilt_val, PP_val, n)       = Roi_Isl_mean(n, ct);
                    result{TE_val}.localTE_matrix(PE_val, tilt_val, PP_val, n)   = Roi_localTE_mean(n, ct);
                    result{TE_val}.Q_SDmatrix(PE_val, tilt_val, PP_val, n)       = Roi_Q_sd(n, ct);
                    result{TE_val}.Isl_SDmatrix(PE_val, tilt_val, PP_val, n)     = Roi_Isl_sd(n, ct);
                    result{TE_val}.localTE_SDmatrix(PE_val, tilt_val, PP_val, n) = Roi_localTE_sd(n, ct);
                    result{TE_val}.GSP_SDmatrix(PE_val, tilt_val, PP_val, n)     = Roi_GSP_sd(n, ct);
                    result{TE_val}.GSS_SDmatrix(PE_val, tilt_val, PP_val, n)     = Roi_GSS_sd(n, ct);
                    %%-----------------------------------------------------
                    result{TE_val}.BS_matrix(PE_val, tilt_val, PP_val, n)        = Roi_mean(n, ct);
                    result{TE_val}.BS_SDmatrix(PE_val, tilt_val, PP_val, n)      = Roi_std(n, ct);
                    result{TE_val}.GSP_matrix(PE_val, tilt_val, PP_val, n)       = Roi_GSP_mean(n, ct);
                    result{TE_val}.GSS_matrix(PE_val, tilt_val, PP_val, n)       = Roi_GSS_mean(n, ct);
                    result{TE_val}.Gain_matrix(PE_val, tilt_val, PP_val, n)      = Roi_gain_mean(n, ct);
                    result{TE_val}.BSgain_matrix(PE_val, tilt_val, PP_val, n)    = Roi_BSgain_mean(n, ct);
                    %%-----------------------------------------------------
         
                end
            end
        end
    end
% end

% spm_progress_bar('Clear');

fprintf('------------------------------------------------------------------\n');
fprintf('BS Optimization done for\n');

for n = 1:length(rois)
    display(sprintf('ROI Nr. %2d: %s;', n, rois{n}));
end

fprintf(' \n');
fprintf('Optimal parameters:\n');


for n = 1:length(rois)
    % Get valid candidates where dropout condition is satisfied
    validIdx = find(Percnt_Dropout_Vox(n,:) * 100 < 0.01);
    if isempty(validIdx)
        fprintf('No valid candidates for ROI Nr. = %d\n', n);
        continue;
    end
    % Which metric you want to maximise
    % maxVal = max(Roi_mean(n,:));
    % maxVal = max(Roi_mean_rmoulr(n,:));
    % maxVal = max(Roi_mean_std(n,:));
    % Ind = find(Roi_mean(n,:) == maxVal);
    % Idx = Ind(1);
    
    [maxVal, relInd] = max(Roi_mean(n, validIdx));
    Idx = validIdx(relInd);     % Actual index in original array
        
    sd = Roi_std(n, Idx);

    fprintf('ROI Nr.: %2d; BS-opt: %0.3e; BS-SD: %0.3e; BS-baseline: %0.3e; BS-gain: %6.3f; PE: %1d; PP: %4.1f; tilt: %4d;\n', ...
                      n, maxVal, sd, Roi_mean(n, ct0), ((maxVal/Roi_mean(n, ct0))-1)*100, PE_all(Idx), PP_all(Idx), tilt_all(Idx));
    result{TE_val}.results(n, 1) = Idx;                  result{TE_val}.results(n, 2) = maxVal; 
    result{TE_val}.results(n, 3) = Roi_std(n, Idx);      result{TE_val}.results(n, 4) = Roi_mean(n, ct0); 
    result{TE_val}.results(n, 5) = PP_all(Idx);          result{TE_val}.results(n, 6) = tilt_all(Idx);
    result{TE_val}.results(n, 7) = PE_all(Idx);          result{TE_val}.results(n, 8) = ((maxVal/Roi_mean(n, ct0))-1)*100;

   % % Optimum BS
   % epi_param_opt.GP = [0 0 PP_all(I)]*10^-6;
   % epi_param_opt.tilt = tilt_all(I);
   % epi_param_opt.PE_dir = PE_all(I);
   % 
   % if strcmp(R2sfield, 'ROI_Averaged')
   %     scanner_param = [];
   %     scanner_param.R2s = R2sroi(n);
   % end
   % 
   % [~, ~, BS] = CalculateBS_TB(FG, epi_param_opt, epi_param_fix, scanner_param);
   % BS_Optimum{n} = BS;

end
end

fprintf(' \n');
fprintf('------------------------------------------------------------------\n');
fprintf('BS = Optimized Mean BS in ROI \n');
fprintf('BS-SD = Standard deviation of BS in ROI \n');
fprintf('BS-REF = Baseline BS in ROI \n');
fprintf('BS-gain = BS in optimal protocol compared to default protocol\n');
fprintf('PE = phase encoding direction (-1 = AP, +1 = PA)\n');
fprintf('PP = Shim gradient moment in z-direction (mT/m*ms)\n');
fprintf('tilt = tilt of slice (Positive = towards foot, Negative = towards head)\n');
fprintf('------------------------------------------------------------------\n');

% -------------------------------------------------------------------------
% Saving the result
% -------------------------------------------------------------------------
matname = fullfile(out_dir, 'BSOpt.mat');
% save(matname, 'result', 'BS_Optimum', 'BS_baseline', 'sII');
save(matname, 'result', 'BS_baseline', 'Percnt_Dropout_Vox');

% % -------------------------------------------------------------------------
% % Display the result
% % -------------------------------------------------------------------------
% DisplayBS_TB(result, tilt_range, PP_range, rois)

result = 1;

end
