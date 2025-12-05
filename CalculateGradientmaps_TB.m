function [fm_dX, fm_dY, fm_dZ] = CalculateGradientmaps_TB(fieldmap_file, method) 

% =========================================================================
% This function calculates field map derivatives in the x,y,z directions 
% using the specified method
% Mehods differ in the boundaries
% -------------------------------------------------------------------------
% Input:
%        file_fmp              : Field map file (in Hz)
% Output:
%        fm_dX, fm_dY, fm_dZ   : Field Gradients in x,y,z directions in T/m 
% -------------------------------------------------------------------------
% Copyright (C)           2014-2018           Steffen Volz
% Wellcome Trust Centre for Neuroimaging, London
% and Max Planck Institute for Human Cognitive and Brain Sciences, Leipzig
% Updated and Refactored  2024 - 2025         Shokoufeh Golshani 
% =========================================================================
gyromagnetic_ratio = 42.58e6;         % Hz/T for proton

fieldmap_V = spm_vol(fieldmap_file);
fieldmap   = spm_read_vols(fieldmap_V);

rot_mat = fieldmap_V(1).mat(1:3,1:3)*10^-3;
voxel_size = [1 1 1].*1e-3;                  % in m

if diag(voxel_size)~=abs(rot_mat)
 error('CalculateGradientmaps: field map seems to be spatially transformed!');
end

if strcmp(method, 'Circshift_Diff')

    fm_dX = (fieldmap - circshift(fieldmap, [1, 0, 0]))./voxel_size(1)./gyromagnetic_ratio;  
    fm_dY = (fieldmap - circshift(fieldmap, [0, 1, 0]))./voxel_size(2)./gyromagnetic_ratio;  
    fm_dZ = (fieldmap - circshift(fieldmap, [0, 0, 1]))./voxel_size(3)./gyromagnetic_ratio; 

    % boundaries -- my method of making it more accurate!
    fm_dX(1, :, :)   = fieldmap(2, :, :) - fieldmap(end, :, :);
    fm_dY(:, 1, :)   = fieldmap(:, 2, :) - fieldmap(:, end, :);
    fm_dZ(:, :, 1)   = fieldmap(:, :, 2) - fieldmap(:, :, end);

% elseif strcmp(method, 'Central_Diff')
% 
%     fm_dX = (circshift(fieldmap, [-1, 0, 0]) - circshift(fieldmap, [1, 0, 0]))./voxel_size(1)./gyromagnetic_ratio;  
%     fm_dY = (circshift(fieldmap, [0, -1, 0]) - circshift(fieldmap, [0, 1, 0]))./voxel_size(2)./gyromagnetic_ratio; 
%     fm_dZ = (circshift(fieldmap, [0, 0, -1]) - circshift(fieldmap, [0, 0, 1]))./voxel_size(3)./gyromagnetic_ratio; 

elseif strcmp(method, 'Central_Diff')
    [sx, sy, sz] = size(fieldmap);
    
    fm_dX = zeros(sx, sy, sz);
    fm_dY = zeros(sx, sy, sz);
    fm_dZ = zeros(sx, sy, sz);
    
    for i = 2:sx-1
        fm_dX(i, :, :) = (fieldmap(i+1, :, :) - fieldmap(i-1, :, :))./2;
    end
    
    for j = 2:sy-1
        fm_dY(:, j, :) = (fieldmap(:, j+1, :) - fieldmap(:, j-1, :))./2;
    end
    
    for k = 2:sz-1
        fm_dZ(:, :, k) = (fieldmap(:, :, k+1) - fieldmap(:, :, k-1))./2;
    end
    
    % X boundaries
    fm_dX(1, :, :)   = fieldmap(2, :, :) - fieldmap(1, :, :);
    fm_dX(end, :, :) = fieldmap(end, :, :) - fieldmap(end-1, :, :);
    
    % Y boundaries
    fm_dY(:, 1, :)   = fieldmap(:, 2, :) - fieldmap(:, 1, :);
    fm_dY(:, end, :) = fieldmap(:, end, :) - fieldmap(:, end-1, :);
    
    % Z boundaries
    fm_dZ(:, :, 1)   = fieldmap(:, :, 2) - fieldmap(:, :, 1);
    fm_dZ(:, :, end) = fieldmap(:, :, end) - fieldmap(:, :, end-1);
       
    fm_dX = fm_dX./voxel_size(1)./gyromagnetic_ratio;
    fm_dY = fm_dY./voxel_size(2)./gyromagnetic_ratio;
    fm_dZ = fm_dZ./voxel_size(3)./gyromagnetic_ratio;

elseif strcmp(method, 'Simple_Diff')

    fm_dX = diff(fieldmap, 1, 1) ./ voxel_size(1);
    fm_dY = diff(fieldmap, 1, 2) ./ voxel_size(2);
    fm_dZ = diff(fieldmap, 1, 3) ./ voxel_size(3);
    
    % Pad to maintain original size
    fm_dX = padarray(fm_dX, [1 0 0], 'replicate', 'post') ./ gyromagnetic_ratio;
    fm_dY = padarray(fm_dY, [0 1 0], 'replicate', 'post') ./ gyromagnetic_ratio;
    fm_dZ = padarray(fm_dZ, [0 0 1], 'replicate', 'post') ./ gyromagnetic_ratio;
    
end

end
