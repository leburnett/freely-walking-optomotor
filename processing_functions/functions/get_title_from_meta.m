function title_str = get_title_from_meta(cond_meta)

    trial_len = cond_meta.trial_len;
    % n_trials = cond_meta.n_trials;
    optomotor_pattern = cond_meta.optomotor_pattern;
    % disp(optomotor_pattern)
    optomotor_speed = cond_meta.optomotor_speed;
    flicker_pattern = cond_meta.flicker_pattern;
    flicker_speed = cond_meta.flicker_speed;

    switch optomotor_pattern

        case 4
            pattern_str = "15deg-gratings";

        case 6 
            pattern_str = "30deg-gratings";

        case 7
            pattern_str = "30deg-flicker";

        case 9 
            pattern_str = "60deg-gratings";

        case 10
            pattern_str = "flicker-60deg";

        case 13 
            pattern_str = "4ON-12OFF-bar";

        case 16 
            pattern_str = "12ON-4OFF-bar";

        case 17
            pattern_str = "2ON-14OFF-bar";

        case 19 
            pattern_str = "ON-curtains";

        case 20 
            pattern_str = "OFF-curtain";

        case 24
            pattern_str = "2OFF-14ON-bar";

        case 26
            pattern_str = "30deg-grating";
            optomotor_speed = optomotor_speed*2; % double as fast because pattern moves 2 pixels every frame not 1. 
       
        case 27
            pattern_str = "60deg-grating";
            optomotor_speed = optomotor_speed*2; % double as fast because pattern moves 2 pixels every frame not 1. 
       
        case 30 
            pattern_str = "bar-fixation-16px";
            optomotor_speed = "";

        case 31
            pattern_str = "reverse-phi-1px";

        case 32
            pattern_str = "reverse-phi-4px";
        
        case 33
            pattern_str = "reverse-phi-8px";
           
        case 34
            pattern_str = "FoE-30deg";

        case 35
            pattern_str = "FoE-15deg";

        case 36
            pattern_str = "FoE-60deg";

        case 37 
            pattern_str = "8px-OFF-bars";

        case 38
            pattern_str = "8px-ON-bars";

        case 39
            pattern_str = "8px-ON-bars-2bkg";

        case 40
            pattern_str = "8px-ON-bars-4bkg";

        case 41
            pattern_str = "8px-ON-bars-6bkg";

        case 42
            pattern_str = "8px-OFF-bars-2bkg";

        case 43
            pattern_str = "8px-OFF-bars-4bkg";

        case 44
            pattern_str = "8px-OFF-bars-6bkg";

        case 45
            pattern_str = "8px-ON-bars";

        case 46
            pattern_str = "8px-OFF-bars";

    end    

    switch flicker_pattern

        case 5
            flicker_str = "15deg-flicker";

        case 7
            flicker_str = "30deg-flicker";

        case 10
            flicker_str = "60deg-flicker";

        case 14
            flicker_str = "4ON12OFF-flicker";

        case 29 
            flicker_str = "greyscale";
    end 

    pattern_speed = string(optomotor_speed);
    flicker_speed = string(flicker_speed);
    len_str = string(trial_len);

    title_str = strcat(pattern_str, "-", pattern_speed, "fps-", flicker_str, "-", flicker_speed, "fps-", len_str, "s");

end 