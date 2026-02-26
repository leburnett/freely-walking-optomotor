function x_smooth = gaussian_conv(x)
% GAUSSIAN_CONV Apply Gaussian convolution smoothing to 1D array
%
%   x_smooth = GAUSSIAN_CONV(x) smooths the input array using a Gaussian
%   kernel with default parameters.
%
% INPUT:
%   x - 1D array to be smoothed
%
% OUTPUT:
%   x_smooth - Smoothed 1D array (same size as input)
%
% PARAMETERS (hardcoded):
%   window_size - 15 points
%   sigma       - 1 (standard deviation of Gaussian)
%
% NOTES:
%   - Uses 'valid' convolution mode, so edges are preserved from original data
%   - Edge points within floor(window_size/2) of array ends are not smoothed
%
% EXAMPLE:
%   velocity = calculate_velocity(position);
%   velocity_smooth = gaussian_conv(velocity);
%
% See also: movmean, conv, fspecial 
    n = numel(x);
    window_size = 15;
    sigma = 1;  % Standard deviation of Gaussian
    gauss_kernel = fspecial('gaussian', [1, window_size], sigma);
    
    x_smooth = x;
    x_smooth(floor(window_size/2)+1:n-floor(window_size/2)) = conv(x, gauss_kernel, 'valid');  % Apply Gaussian smoothing
end 