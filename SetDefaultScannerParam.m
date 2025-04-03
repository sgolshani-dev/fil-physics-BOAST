function scanner_param = SetDefaultScannerParam
% This is no longer needed!
% =========================================================================
% This function sets the scanner parameters. 
% These values can be modified as needed to suit specific requirements.
% =========================================================================
% name                            : Scanner name
% B0                              : Field strength
% R2s                             : R2* value (in s^-1) 
%                                 - An averaged value over the entire brain.
%                                   Although not directly a scanner parameter, 
%                                   it depends on the field strength!
% =========================================================================

% Updated 23/09/2024
% by Shokoufeh Golshani

scanner_param.name = 'Trio';
scanner_param.B0 = 3;
scanner_param.R2s = 1/45e-3; 	    % T2* at 3 T = 45 ms (Wansapura et al., JMRI 1999)

end
