
% Make a subset of the tracking data. 
% x and y from trx only over "frame_rng"


% Extract only the x and y fields into a new struct
tracking_data = rmfield(trx, setdiff(fieldnames(trx), {'x','y'}));

% Now loop through each element to keep only values 100:200
for i = 1:numel(tracking_data)
    % Make sure the vectors are long enough
    nX = numel(tracking_data(i).x);
    nY = numel(tracking_data(i).y);
    
    idx = frame_rng;
    idx = idx(idx <= min(nX,nY)); % avoid out-of-bounds
    
    tracking_data(i).x = tracking_data(i).x(idx);
    tracking_data(i).y = tracking_data(i).y(idx);
end

save('tracking_data_2025_04_18_15_58_c3_r1.mat', 'tracking_data');


% Check tracking 
% figure
% for j = 1
%     for k = 1:15
%         plot(tracking_data(k).x(j), tracking_data(k).y(j), 'k.', 'MarkerSize', 10); 
%         hold on
%     end 
% end 