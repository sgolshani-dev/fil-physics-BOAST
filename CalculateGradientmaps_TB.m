
function [dX, dY, dZ] = CalculateGradientmaps_TB(fieldmap_file, method)
% -------------------------------------------------------------------------
% This function calculates field map derivatives in three directions using
% the specified method
% Mehods differ in the boundaries but almost consistent in the small
% spatial variations
%
% Written by Shokoufeh Golshani 2025
% -------------------------------------------------------------------------
gyromagnetic_ratio = 42.58e6;         % Hz/T for proton

fieldmap_V = spm_vol(fieldmap_file);
fieldmap   = spm_read_vols(fieldmap_V);

rot_mat = fieldmap_V(1).mat(1:3,1:3)*10^-3;
voxel_size = [1 1 1].*1e-3;          % in m

if diag(voxel_size)~=abs(rot_mat)
 error('CalculateGradientmaps: field map seems to be spatially transformed!');
end

if strcmp(method, 'Circshift_Diff')

    dX = (fieldmap - circshift(fieldmap, [1, 0, 0]))./voxel_size(1)./gyromagnetic_ratio;  
    dY = (fieldmap - circshift(fieldmap, [0, 1, 0]))./voxel_size(2)./gyromagnetic_ratio;  
    dZ = (fieldmap - circshift(fieldmap, [0, 0, 1]))./voxel_size(3)./gyromagnetic_ratio; 

    % boundaries -- my method of making it more accurate!
    dX(1, :, :)   = fieldmap(2, :, :) - fieldmap(end, :, :);
    dY(:, 1, :)   = fieldmap(:, 2, :) - fieldmap(:, end, :);
    dZ(:, :, 1)   = fieldmap(:, :, 2) - fieldmap(:, :, end);

elseif strcmp(method, 'Circshift2_Diff')

    dX = (circshift(fieldmap, [-1, 0, 0]) - circshift(fieldmap, [1, 0, 0]))./voxel_size(1)./gyromagnetic_ratio;  
    dY = (circshift(fieldmap, [0, -1, 0]) - circshift(fieldmap, [0, 1, 0]))./voxel_size(2)./gyromagnetic_ratio; 
    dZ = (circshift(fieldmap, [0, 0, -1]) - circshift(fieldmap, [0, 0, 1]))./voxel_size(3)./gyromagnetic_ratio; 

elseif strcmp(method, 'central')
    [sx, sy, sz] = size(fieldmap);
    
    dX = zeros(sx, sy, sz);
    dY = zeros(sx, sy, sz);
    dZ = zeros(sx, sy, sz);
    
    for i = 2:sx-1
        dX(i, :, :) = (fieldmap(i+1, :, :) - fieldmap(i-1, :, :))./2;
    end
    
    for j = 2:sy-1
        dY(:, j, :) = (fieldmap(:, j+1, :) - fieldmap(:, j-1, :))./2;
    end
    
    for k = 2:sz-1
        dZ(:, :, k) = (fieldmap(:, :, k+1) - fieldmap(:, :, k-1))./2;
    end
    
    % X boundaries
    dX(1, :, :)   = fieldmap(2, :, :) - fieldmap(1, :, :);
    dX(end, :, :) = fieldmap(end, :, :) - fieldmap(end-1, :, :);
    
    % Y boundaries
    dY(:, 1, :)   = fieldmap(:, 2, :) - fieldmap(:, 1, :);
    dY(:, end, :) = fieldmap(:, end, :) - fieldmap(:, end-1, :);
    
    % Z boundaries
    dZ(:, :, 1)   = fieldmap(:, :, 2) - fieldmap(:, :, 1);
    dZ(:, :, end) = fieldmap(:, :, end) - fieldmap(:, :, end-1);
       
    dX = dX./voxel_size(1)./gyromagnetic_ratio;
    dY = dY./voxel_size(2)./gyromagnetic_ratio;
    dZ = dZ./voxel_size(3)./gyromagnetic_ratio;

elseif strcmp(method, 'Simple_Diff')

    dX = diff(fieldmap, 1, 1) ./ voxel_size(1);
    dY = diff(fieldmap, 1, 2) ./ voxel_size(2);
    dZ = diff(fieldmap, 1, 3) ./ voxel_size(3);
    
    % Pad to maintain original size
    dX = padarray(dX, [1 0 0], 'replicate', 'post') ./ gyromagnetic_ratio;
    dY = padarray(dY, [0 1 0], 'replicate', 'post') ./ gyromagnetic_ratio;
    dZ = padarray(dZ, [0 0 1], 'replicate', 'post') ./ gyromagnetic_ratio;
    
end
