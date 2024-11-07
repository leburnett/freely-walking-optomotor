function LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim, rep)

    if rep == 1

        acclim_off1.condition = 0;
        acclim_off1.dir = 0;
        
        Panel_com('all_off'); pause(t_pause)
        
        % % get frame and log it
        acclim_off1.start_t = vidobj.getTimeStamp().value;
        acclim_off1.start_f = vidobj.getFrameCount().value;
        
        disp('Acclim OFF')
        pause(t_acclim); 
        
        % get frame and log it 
        acclim_off1.stop_t = vidobj.getTimeStamp().value;
        acclim_off1.stop_f = vidobj.getFrameCount().value;
        
        LOG.acclim_off1 = acclim_off1;

    elseif rep == 2

        acclim_off2.condition = 0;
        acclim_off2.dir = 0;
        
        Panel_com('all_off'); pause(t_pause)
        
        % % get frame and log it
        acclim_off2.start_t = vidobj.getTimeStamp().value;
        acclim_off2.start_f = vidobj.getFrameCount().value;
        
        disp('Acclim OFF')
        pause(t_acclim); 
        
        % get frame and log it 
        acclim_off2.stop_t = vidobj.getTimeStamp().value;
        acclim_off2.stop_f = vidobj.getFrameCount().value;
        
        LOG.acclim_off2 = acclim_off2;
    
    end 

end 