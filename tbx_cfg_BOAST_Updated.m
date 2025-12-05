function fmpoptbs = tbx_cfg_BOAST_Updated

% =========================================================================
% MATLAB BATCH configuration file for the 'tbx_cfg_BOAST_Updated' toolbox
%_______________________________________________________________________
% This toolbox was originally developed by Steffen Volz and later updated, 
% and refactored with new features by Shokoufeh Golshani.
%
% Copyright (C)                   2015 – 2018          Steffen Volz
% Wellcome Trust Centre for Neuroimaging, London
% Max Planck Institute for Human Cognitive and Brain Sciences, Leipzig
%
% Refactored and Updated          2024 - 2025          Shokoufeh Golshani
% Functional Imaging Laboratory, Imaging Neuroscience, UCL
% =========================================================================

% Adding the toolbox folder
% if ~isdeployed
%     addpath(fullfile(spm('Dir'),'toolbox','BOAST_Updated')); 
% end
% rmpath('C:\Users\sgolshani\Documents\MATLAB\spm12\spm12\toolbox\FmpOptBS');

%==========================================================================
% Input Values
%==========================================================================

% -------------------------------------------------------------------------
% field maps
% -------------------------------------------------------------------------
fieldmaps         = cfg_files;
fieldmaps.tag     = 'fieldmaps';
fieldmaps.name    = 'Input fieldmaps';
fieldmaps.help    = {['Include one fieldmap or 3 fieldmap gradient (dX dY dZ) files ' ...
                      'for optimizing BOLD sensitivity. Note that the units for the ' ...
                      'field map should be in Hz and for the derivatives should be in T/m.']};
fieldmaps.ufilter = '.*';
fieldmaps.num     = [1 Inf];
% -------------------------------------------------------------------------
% template
% -------------------------------------------------------------------------
template         = cfg_files;
template.tag     = 'template';
template.name    = 'Input template';
template.help    = {'template (Brain Mask) for illustration'};
template.ufilter = '.*';
template.num     = [1 Inf];
% -------------------------------------------------------------------------
% ROIs
% -------------------------------------------------------------------------
rois         = cfg_files;
rois.tag     = 'rois';
rois.name    = 'ROI files';
rois.help    = {'ROIs for which BOLD is optimized.'};
rois.ufilter = '.*';
rois.num     = [1 Inf];
% -------------------------------------------------------------------------
% Input Files
% -------------------------------------------------------------------------
inputfiles         = cfg_branch;
inputfiles.tag     = 'inputfiles';
inputfiles.name    = 'Input files';
inputfiles.val     = {fieldmaps template rois};
inputfiles.help    = {'Needed Input Files'};
% -------------------------------------------------------------------------
% menu main orientation
% -------------------------------------------------------------------------
main_orientation         = cfg_menu;
main_orientation.tag     = 'main_orientation';
main_orientation.name    = 'Choose the main orientation';
main_orientation.help    = {'Option to choose the main orientation'};
main_orientation.labels  = {'TRA' 'COR' 'SAG'};
main_orientation.values  = {'TRA' 'COR' 'SAG'};
main_orientation.val     = {'TRA'};
% -------------------------------------------------------------------------
% Field of View
% -------------------------------------------------------------------------
fov         = cfg_entry;
fov.tag     = 'fov';
fov.name    = 'Field of view';
fov.val     = {192};
fov.help    = {'Field Of View in Phase Encoding Direction in mm'};
fov.strtype = 'r';
fov.num     = [1 1];
% -------------------------------------------------------------------------
% Phase Resolution
% -------------------------------------------------------------------------
base_res         = cfg_entry;
base_res.tag     = 'base_res';
base_res.name    = 'Base resolution';
base_res.val     = {64};
base_res.help    = {'Base Resolution in #px'};
base_res.strtype = 'r';
base_res.num     = [1 1];
% -------------------------------------------------------------------------
% Phase Encoding Oversampling
% -------------------------------------------------------------------------
pe_ov         = cfg_entry;
pe_ov.tag     = 'pe_ov';
pe_ov.name    = 'Phase oversampling';
pe_ov.val     = {12};
pe_ov.help    = {'Oversampling Ratio in Phase Encoding Direction in %'};
pe_ov.strtype = 'r';
pe_ov.num     = [1 1];
% -------------------------------------------------------------------------
% Slice Thickness
% -------------------------------------------------------------------------
slicethickness         = cfg_entry;
slicethickness.tag     = 'slicethickness';
slicethickness.name    = 'Slice thickness';
slicethickness.val     = {2};
slicethickness.help    = {'Slice Thickness or (if known) the Full Width at ' ...
                          'Half Maximum (FWHM) of the slice excitation profile in mm'};
slicethickness.strtype = 'r';
slicethickness.num     = [1 1];
% -------------------------------------------------------------------------
% Echo Spacing
% -------------------------------------------------------------------------
echospacing         = cfg_entry;
echospacing.tag     = 'echospacing';
echospacing.name    = 'Echo spacing';
echospacing.val     = {0.5};
echospacing.help    = {'Echo Spacing in ms'};
echospacing.strtype = 'r';
echospacing.num     = [1 1];
% -------------------------------------------------------------------------
% Echo Time
% -------------------------------------------------------------------------
echotime         = cfg_entry;
echotime.tag     = 'echotime';
echotime.name    = 'Echo time';
echotime.val     = {30};
echotime.help    = {'Echo Time in ms'};
echotime.strtype = 'r';
echotime.num     = [1 1];
% -------------------------------------------------------------------------
% Voxel Size
% -------------------------------------------------------------------------
vox         = cfg_entry;
vox.tag     = 'vox';
vox.name    = 'Voxel size';
vox.val     = {[3 3 3]};
vox.help    = {'Voxel Size [read, phase, slice] in mm'}; % Note the order of input!
vox.strtype = 'r';
vox.num     = [1 3];
% -------------------------------------------------------------------------
% Acceleration Factor
% -------------------------------------------------------------------------
AccF         = cfg_entry;
AccF.tag     = 'AccF';
AccF.name    = 'Acceleration factor';
AccF.val     = {1};
AccF.help    = {'In-plane/GRAPPA Acceleration Factor'};
AccF.strtype = 'r';
AccF.num     = [1 1];
% -------------------------------------------------------------------------
% Partial Fourier Factor
% -------------------------------------------------------------------------
PF         = cfg_entry;
PF.tag     = 'PF';
PF.name    = 'Partial Fourier factor';
PF.val     = {1};
PF.help    = {'In-plane Partial Fourier Factor'};
PF.strtype = 'r';
PF.num     = [1 1];
% -------------------------------------------------------------------------
% Fixed Protocol Parameters
% -------------------------------------------------------------------------
fixedparameters         = cfg_branch;
fixedparameters.tag     = 'fixedparameters';
fixedparameters.name    = 'Fixed Protocol Parameters';
fixedparameters.val     = {main_orientation fov base_res pe_ov slicethickness echospacing echotime vox AccF PF};
fixedparameters.help    = {'Fixed Protocol Parameters'};

% =========================================================================
% Set Simulation Parameters
% =========================================================================

% -------------------------------------------------------------------------
% Parameter shimz
% -------------------------------------------------------------------------
shimz         = cfg_entry;
shimz.tag     = 'shimz';
shimz.name    = 'shimz';
shimz.val     = {[-5 0 5 0.2]};
shimz.help    = {'Shim Gradient moment in z-direction in mT/m*ms [min ref max step-size]'};
shimz.strtype = 'r';
shimz.num     = [1 4];
% -------------------------------------------------------------------------
% Parameter tilt
% -------------------------------------------------------------------------
tilt         = cfg_entry;
tilt.tag     = 'tilt';
tilt.name    = 'tilt';
tilt.val     = {[-44 0 44 4]};
tilt.help    = {'tilt in degree [min ref max step-size]'};
tilt.strtype = 'r';
tilt.num     = [1 4];
% -------------------------------------------------------------------------
% Additional Inputs for TE Variation Option
% -------------------------------------------------------------------------
Fixed_TE         = cfg_entry;
Fixed_TE.tag     = 'Fixed_TE';
Fixed_TE.name    = 'Fixed TE value';
Fixed_TE.val     = {30};                              
Fixed_TE.help    = {'Fixed TE value as in the reference EPI in [ms]'};
Fixed_TE.num     = [1 1];
% -------------------------------------------------------------------------
% Additional Inputs for TE Variation Option
% -------------------------------------------------------------------------
Variable_TE         = cfg_entry;
Variable_TE.tag     = 'Variable_TE';
Variable_TE.name    = 'Variable TE values';
Variable_TE.val     = {30};                              
Variable_TE.help    = {'Input range of TE values to be used in ms [min max step-size]'};
Variable_TE.num     = [1 3];
% -------------------------------------------------------------------------
% Varying Parameter TE
% -------------------------------------------------------------------------
TEOpt         = cfg_choice;
TEOpt.tag     = 'TEOpt';
TEOpt.name    = 'TE Option';
TEOpt.values  = {Fixed_TE Variable_TE};
TEOpt.val     = {Fixed_TE};
TEOpt.help    = {['Inoporate TE variations in the optimization; The options are:' ...
                  '1. Fixed TE (the same as echotime in the Reference Sequence)' ...
                  '2. Variable TE']};
% -------------------------------------------------------------------------
% Simulation Parameters
% -------------------------------------------------------------------------
simu         = cfg_branch;
simu.tag     = 'simu';
simu.name    = 'Simulation Parameters';
simu.val     = {shimz tilt TEOpt};
simu.help    = {['Parameters to be simulated: all these parameters have a minimum, ' ...
                 'maximum and default value and a step size for the optimization procedure']};

% =========================================================================
% Other Settings
% =========================================================================

% -------------------------------------------------------------------------
% Reduce Field size
% -------------------------------------------------------------------------
rfs         = cfg_entry;
rfs.tag     = 'rfs';
rfs.name    = 'Reduce Field size';
rfs.val     = {0};
rfs.help    = {'0 = no (original size), 1 = yes (1/3)'};
rfs.strtype = 'r';
rfs.num     = [1 1];
% -------------------------------------------------------------------------
% Additional Inputs for R2s Option
% -------------------------------------------------------------------------
Global_3T         = cfg_entry;
Global_3T.tag     = 'Global_3T';
Global_3T.name    = '3T Global R2*';
Global_3T.val     = {1/45};                              
Global_3T.help    = {'Global R2* Value in 3T in [ms]^-1'};
Global_3T.num     = [1 1];
% -------------------------------------------------------------------------
% Additional Inputs for R2s Option
% -------------------------------------------------------------------------
Global_7T         = cfg_entry;
Global_7T.tag     = 'Global_7T';
Global_7T.name    = '7T Global R2*';
Global_7T.val     = {1/30};                              
Global_7T.help    = {'Global R2* Value in 7T in [ms]^-1'};
Global_7T.num     = [1 1];
% -------------------------------------------------------------------------
% Additional Inputs for R2s Option
% -------------------------------------------------------------------------
Voxel_wise         = cfg_files;
Voxel_wise.tag     = 'Voxel_wise';
Voxel_wise.name    = 'Voxel_wise R2* map';                             
Voxel_wise.help    = {'Input an R2* map in [ms]^-1'};
Voxel_wise.num     = [1 Inf];
% -------------------------------------------------------------------------
% Additional Inputs for R2s Option
% -------------------------------------------------------------------------
ROI_Averaged         = cfg_files;
ROI_Averaged.tag     = 'ROI_Averaged';
ROI_Averaged.name    = 'ROI_Averaged R2* value';                            
ROI_Averaged.help    = {['Input an R2* map in [ms]^-1, an averaged value within' ...
                         'each ROI will be used for optimization']};
ROI_Averaged.num     = [1 1];
% -------------------------------------------------------------------------
% R2star Designation
% -------------------------------------------------------------------------
R2sOpt         = cfg_choice;
R2sOpt.tag     = 'R2sOpt';
R2sOpt.name    = 'R2star Option';
R2sOpt.values  = {Global_3T Global_7T Voxel_wise ROI_Averaged};
R2sOpt.val     = {Global_3T};
R2sOpt.help    = {['How to inoporate R2* in the optimization; The options are:' ...
                  '1. Global Value in 3T (1/45 ms^-1)' ...
                  '2. Global value in 7T (1/30 ms^-1)' ...
                  '3. Voxel-wise Map (ms^-1)' ...
                  '4. ROI-specific Averaged Value']};
% -------------------------------------------------------------------------
% Additional Inputs for Field Gradient Calculation Method
% -------------------------------------------------------------------------
Simple_Diff         = cfg_entry;
Simple_Diff.tag     = 'Simple_Diff';
Simple_Diff.name    = 'Simple voxel-wise difference method'; 
Simple_Diff.num     = [1 1];
% -------------------------------------------------------------------------
% Additional Inputs for Field Gradient Calculation Method
% -------------------------------------------------------------------------
Circshift_Diff         = cfg_entry;
Circshift_Diff.tag     = 'Circshift_Diff';
Circshift_Diff.name    = 'Circshift difference method';
Circshift_Diff.num     = [1 1];
% -------------------------------------------------------------------------
% Additional Inputs for Field Gradient Calculation Method
% -------------------------------------------------------------------------
Central_Diff         = cfg_entry;
Central_Diff.tag     = 'Central_Diff';
Central_Diff.name    = 'Central difference method'; 
Central_Diff.num     = [1 1];
% -------------------------------------------------------------------------
% Field Gradient Calculation Method
% -------------------------------------------------------------------------
FieldGradOpt        = cfg_choice;
FieldGradOpt.tag    = 'FieldGradOpt';
FieldGradOpt.name   = 'Field Gradient Calculation Option';
FieldGradOpt.values = {Simple_Diff Circshift_Diff Central_Diff};
FieldGradOpt.val    = {Circshift_Diff};
FieldGradOpt.help   = {['Field Gradient Calculation Method; Note methods differ' ...
                       'in the brain boundaries; The options are:' ...
                       '1. Simple voxel-wise difference – computes the gradient ' ...
                       'by taking the direct difference between neighbouring voxels.'...
                       '2. Circshift difference – computes the gradient ' ...
                       'by differenciating the image shifted one voxel to the right with the unshifted image.'...
                       '3. Central difference – computes the gradient by comparing the image shifted one voxel ' ...
                       'to the right with the image shifted one voxel to the left.']};
% -------------------------------------------------------------------------
% Saving Output
% -------------------------------------------------------------------------
Out_suf         = cfg_entry;
Out_suf.tag     = 'Out_suf';
Out_suf.name    = 'Output suffix';
Out_suf.val     = {'_Opt'};
Out_suf.help    = {'Enter an string suffix for the output folder where the results are saved'};
Out_suf.strtype = 's';
% -------------------------------------------------------------------------
% Other Settings
% -------------------------------------------------------------------------
other         = cfg_branch;
other.tag     = 'other';
other.name    = 'Other Settings';
other.val     = {rfs R2sOpt FieldGradOpt Out_suf};
other.help    = {'Other Settings Used for Optimization'};

% =========================================================================
% Preprocessing
% =========================================================================
fmpoptbs         = cfg_exbranch;
fmpoptbs.tag     = 'BOAST_Updated';
fmpoptbs.name    = 'BSopt Updated';
fmpoptbs.val     = {inputfiles fixedparameters simu other};
fmpoptbs.help    = {'This toolbox is currently only work in progress.'};
fmpoptbs.prog = @BOAST_Updated_apply;
fmpoptbs.vout = @vout_BOAST_Updated_apply;
%--------------------------------------------------------------------------
function opt = BOAST_Updated_apply(job)

opt.results = epi_opt_param_TB(job.inputfiles.fieldmaps, job.inputfiles.rois, ...
                               job.inputfiles.template, ...
                               job.fixedparameters.main_orientation, ...
                               job.fixedparameters.fov, ...
                               job.fixedparameters.base_res, ...
                               job.fixedparameters.pe_ov, ...
                               job.fixedparameters.slicethickness, ...
                               job.fixedparameters.echospacing, ...
                               job.fixedparameters.echotime, ...
                               job.fixedparameters.vox, ...
                               job.fixedparameters.AccF, job.fixedparameters.PF, ...
                               job.simu.tilt, job.simu.shimz, job.simu.TEOpt, ...
                               job.other.rfs, job.other.R2sOpt, ...
                               job.other.FieldGradOpt, job.other.Out_suf);

% =========================================================================
function dep = vout_BOAST_Updated_apply(~)
% do something
dep = cfg_dep;

