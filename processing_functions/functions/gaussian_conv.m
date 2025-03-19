function x_smooth = gaussian_conv(x)
% x = 1D array to be smoothed.
% window_size = how many points in the kernel. 

    window_size = 15;
    sigma = 1;  % Standard deviation of Gaussian
    gauss_kernel = fspecial('gaussian', [1, window_size], sigma);
    
    x_smooth = x;
    x_smooth((window_size/2)+1:n-(window_size/2)) = conv(x, gauss_kernel, 'valid');  % Apply Gaussian smoothing
end 