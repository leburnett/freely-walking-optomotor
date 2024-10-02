function V = vel_estimate(D, samp_rate, method, t_window, cutoff)
% V = vel_estimate(D, samp_rate, method, t_window, cutoff)
% example usage - for low pass filtering
% V_lp = vel_estimate(D, 1/100, 'lpfilt', [], 10);
% here the data is D, sampled at 100 Hz, and cutoff frequency for the
% filter is 10 Hz (or rad/sec)?
% example usage - for line fit method
% V_lf = vel_estimate(D, 1/100, 'line_fit', 25, []);
% here the data is D, sampled at 100 Hz, and a window size is 25 samples.
% 
% This function estimates the velocity in a data set D by using several
% mehtods. This function is suited for wrapped up data like the pattern
% position data. The methods are - 
%   'lpfilt' which uses a low pass filter on the data and then uses a
%   central difference algorithms to estimate the derivative of the
%   smoothed data.
%
%   'line_fit' uses the window length parameter, t_window, in samples, to
%   specify a window size in which a line is fit to the data using least
%   sqaures, and the slope is reported. The last arg, for 'cutoff' can be
%   used to specify a window skip increment - but then velocity est. will
%   have fewer data points than the original data.
% 
%   'maximum_diff' just takes the max - min of the data in the time window,
%   this will only work for positive data
% 
%  Michael Reiser, Jan 2005

d = D; % D*2*pi./(max(D));   % unwrap the data
D_unw = unwrap(d); %.*max(D)/2/pi;

switch lower(method)
    case 'lpfilt'
        [b,a] = butter(4,2*cutoff*samp_rate);
        D_filt = filtfilt(b,a,D_unw);
        V = cent_diff(D_filt, samp_rate)';
        
    case 'line_fit'
        %pad start and finish with points to make output same length as input
        D_start = D_unw(1)*ones(t_window/2 ,1); D_end = D_unw(end)*ones(t_window/2 ,1);
        D_unw = [D_start' D_unw' D_end']';
        % make A matrix of time and ones vector for solving the line fit
        t = [0:t_window - 1]*samp_rate;
        A = [t; ones(size(t))]';
        cur_pos = 1;
        V = zeros(1,length(D));
        while cur_pos <= (length(D_unw) - t_window)
            cur_range = cur_pos:(cur_pos + t_window -1);
            B = A\D_unw(cur_range); % line fit, using least squares
            V(cur_pos) = B(1);  % grab the slope value
            cur_pos = cur_pos + 1;
        end
            
    case 'maximum_diff'
        %pad start and finish with points to make output same length as input
        D_start = D_unw(1)*ones(t_window/2 ,1); D_end = D_unw(end)*ones(t_window/2 ,1);
        D_unw = [D_start' D_unw' D_end']';
        cur_pos = 1;
        V = zeros(1,length(D));
        v_scale = samp_rate*t_window;
        % just take the maximum difference between the data
        while cur_pos <= (length(D_unw) - t_window)
            cur_range = cur_pos:(cur_pos + t_window -1);
            V(cur_pos) = max(D_unw(cur_range)) - min(D_unw(cur_range));
            cur_pos = cur_pos + 1;
        end
        V = V./v_scale; 
        
    otherwise
        error('wrong method type for velocity estimate');
end
