function x_smooth = gaussian_conv(x)
% x = 1D array to be smoothed.
% window_size = how many points in the kernel. 
    n = numel(x);
    window_size = 15;
    sigma = 1;  % Standard deviation of Gaussian
    gauss_kernel = fspecial('gaussian', [1, window_size], sigma);
    
    x_smooth = x;
    x_smooth(floor(window_size/2)+1:n-floor(window_size/2)) = conv(x, gauss_kernel, 'valid');  % Apply Gaussian smoothing
end 