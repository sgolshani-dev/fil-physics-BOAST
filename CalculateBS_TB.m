function [relative_sBS, sII, sBS, fGP, fGS, shift_mask, TE, Q, Isl] = CalculateBS_TB(FG, epi_param_opt, epi_param_fix, scanner_param, ROI) 

% ========================================================================
% This function calculates BOLD sensitivity using field map gradients and 
% a defined set of parameters including the ROI-specific R2s value if
% provided.
%
% Copyright (C)          2014-2018      Steffen Volz
% Wellcome Trust Centre for Neuroimaging, London
% and Max Planck Institute for Human Cognitive and Brain Sciences, Leipzig
%
% Updated and refactored 2024           Shokoufeh Golshani
% ========================================================================

% Unpack Input Variables
% =========================================================================
gam = 42.58e6;                     % gyromagnetic ratio for protons in Hz/T

fov              = epi_param_fix.fov;
AcF              = epi_param_fix.AccF;
PF               = epi_param_fix.PF;
TC               = epi_param_fix.echotime;
TA               = epi_param_fix.TA;
TA_FS            = epi_param_fix.TA_FS;
vx_epi           = epi_param_fix.vx_epi;
delta_z          = epi_param_fix.slicethickness;
echo_spacing     = epi_param_fix.echo_spacing;
main_orientation = epi_param_fix.main_orientation;  

% Field gradients
fm_dX = FG.DX;
fm_dY = FG.DY;
fm_dZ = FG.DZ;
direction   = FG.direction;

% =========================================================================
% Compensation Gradient Moments
% =========================================================================
GPrep_RO = epi_param_opt.GP(1);
GPrep_PE = epi_param_opt.GP(2);
GPrep_SS = epi_param_opt.GP(3);

% =========================================================================
% Rotation matrix for converting filed map gradients from XYZ to RPS
% =========================================================================
Angle = epi_param_opt.tilt/180*pi;

% RO: RL, PE: PA, SL: SI;  Rotation about the RO axis (Positive towards foot)
if strcmp(main_orientation,'TRA') == 1
    Rrot = [1     0            0;
            0   cos(Angle)  sin(Angle);
            0  -sin(Angle)  cos(Angle)];

% Transformation from RAS+ (Nifti format) to LAI+ (Scanner Coordinte)
% this can be translated as a 180-degree rotation around the second axis
    Rtrans = [-1  0  0;
               0  1  0;
               0  0 -1]*direction;

% RO: IS, PE: PA, SL: RL;  Rotation about the RO axis (Positive towards right)    
elseif strcmp(main_orientation,'SAG') == 1
    Rrot = [1      0            0;
            0   cos(Angle)  -sin(Angle);
            0   sin(Angle)   cos(Angle)];

% Transformation from RAS+ (Nifti format) to SAL+ (Scanner Coordinte)
    Rtrans = [ 0  0  1;
               0  1  0;
              -1  0  0]*direction;

% RO: RL, PE: IS, SL: PA;  Rotation about the RO axis (Positive towards foot)   
elseif strcmp(main_orientation,'COR') == 1
    Rrot = [1      0           0;
            0   cos(Angle)  sin(Angle);
            0  -sin(Angle)  cos(Angle)];

% Transformation from RAS+ (Nifti format) to LSA+ (Scanner Coordinte)
    Rtrans = [-1  0  0;
               0  0  1;
               0  1  0]*direction;
end

Rtotal = Rrot*Rtrans;

fGR = fm_dX.*Rtotal(1,1) + fm_dY.*Rtotal(1,2) + fm_dZ.*Rtotal(1,3);
fGP = fm_dX.*Rtotal(2,1) + fm_dY.*Rtotal(2,2) + fm_dZ.*Rtotal(2,3);
fGS = fm_dX.*Rtotal(3,1) + fm_dY.*Rtotal(3,2) + fm_dZ.*Rtotal(3,3);

% =========================================================================
% Calculate the Q value which determines distortion and echo shift
% =========================================================================
if epi_param_opt.PE_dir == 1                  % A negative prephasing and positive blips          
    Q = 1 + (gam * echo_spacing * (fov/AcF) * fGP);
else                                          % A positive prephasing and negative blips 
    Q = 1 - (gam * echo_spacing * (fov/AcF) * fGP);
end

% =========================================================================
% Actual (local) Echo time
% =========================================================================
% if no shimming in the PE direction is used, this will be zero!
dTE_comp = gam * GPrep_PE * (fov/AcF) * echo_spacing;

TE = (TC + dTE_comp)./Q;
dTE = (TE - TC); 

% =========================================================================
% Sudden dropout when echo is shifted out of Acquisition window in the PE 
% and RO directions
% =========================================================================
shift_mask = ones(size(Q));

if PF ~= 1
    shift_mask((dTE) < -(TA - TA_FS/2/AcF)) = 0;
    shift_mask((dTE) > (TA_FS/2/AcF)) = 0;
else
    shift_mask(abs(dTE) > (TA/2)) = 0;
end

shift_mask = shift_mask.*(abs(fGR.*TE + GPrep_RO) < (1/2/gam/vx_epi(1)));

% =========================================================================
% Contribution of the through-plane field gradient --- Gaussian RF pulse
% =========================================================================
Isl = exp(-(((2*pi*gam)^2*delta_z^2/16/log(2)).*((GPrep_SS + fGS.*TE).^2)));
ROI_slct = ROI;
% =========================================================================
% Simulated Image Intensity and BOLD Sensitivity
% =========================================================================
if isfield(scanner_param, 'R2sOpt')
    n_R2s = scanner_param.nR2s;
    for n = 1:n_R2s
        relative_sBS(:,:,:,n) = (Isl./Q.^2).*exp(-(TC.*scanner_param.R2s(n)).*((1./Q)-1));
        sII(:,:,:,n) = (1./Q).*Isl.*exp(-(TC.*scanner_param.R2s(n)./Q));
        sBS(:,:,:,n) = (TC./Q) .* sII(:,:,:,n);

    end
else
    n_R2s = 1;
    relative_sBS = (Isl./Q.^2).*exp(-(TC.*scanner_param.R2s).*((1./Q)-1));
    sII = (1./Q).*Isl.*exp(-(TC.*scanner_param.R2s./Q));
    sBS = (TC./Q) .* sII;
end

% =========================================================================
% Correct maps for shifts of data out of acquisition window
% =========================================================================
relative_sBS = relative_sBS.*repmat(shift_mask, 1, 1, 1, n_R2s);
sII          = sII.*repmat(shift_mask, 1, 1, 1, n_R2s);
sBS          = sBS.*repmat(shift_mask, 1, 1, 1, n_R2s);

end

