function cmap_array = get_cmap_from_data2(data1, data2)
% Generate a colormap based on 2 types of data.
% data1 = Vf
% data2 = Va

    data1 = data1(:); % Ensure column vector
    data1 = fillmissing(data1, 'nearest');

    data2 = data2(:); % Ensure column vector
    data2 = fillmissing(data2, 'nearest');

    n_dp = numel(data1); % Must be the same number as data2.
    cmap_array = zeros(n_dp, 3);

    for i = 1:n_dp
        if data1(i) < 3 % not moving. 

            if data2(i)<75
                cmap_array(i, :) = [0 0 0]; % black 
            elseif data2(i)>= 75
                cmap_array(i, :) = [0 0 1]; % white. 
            end 

        elseif data1(i) >= 3 && data1(i)<11 % medium speed
            % Check for turning
            if data2(i)<100
                cmap_array(i, :) = [1 1 0]; % yellow. 
            elseif data2(i)>= 100
                cmap_array(i, :) = [1 0.65 0]; % orange. 
            end 
        elseif data1(i)>= 11 %moving fast
            if data2(i) < 100
                cmap_array(i, :) = [1 0 0]; % red. 
            elseif data2(i)>= 100
                cmap_array(i, :) = [1 0 1]; % magenta. 
            end 
        end 
    end 

end 