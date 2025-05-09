function generate_condition_movie_from_avi_with_tracks()

cmap = hsv(15);
% cmap = muted_rainbow(15);
tail_length = 90;

fname = 'REC__cam_0_date_2025_01_07_time_14_05_34_v001_condition2_rep2_A.avi';
v = VideoReader(fname);

%% Open emty avi file. 
aviname = 'Example_centring_freely_walking_2025_01_07_14_05.avi';
fps = 30;

aviobj = VideoWriter(aviname);
set(aviobj,'FrameRate',fps);
set(aviobj,'Quality',100);
open(aviobj);
            
for f = 1:v.NumFrames
    
    im = v.readFrame;

    rng = f-tail_length:1:f;
    rng = rng(rng>0);
    n_flies = length(trx);

    imshow(im);
    hold on

    for fly = 1:n_flies

        x = trx(fly).x;
        y = trx(fly).y;
        col = cmap(fly, :);
      
        if length(x) ~= length(y)
            error('x and y must be the same length');
        end
    
        plot(x(rng), y(rng), '-', 'Color', col, 'LineWidth', 1); % Plot trajectory   
    end 
    hold off
    drawnow;
    
    frame = getframe(gcf);  % capture frame from axes
    writeVideo(aviobj, frame);
end

close(aviobj);
end 