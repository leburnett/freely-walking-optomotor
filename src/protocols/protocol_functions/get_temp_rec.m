function [t_outside, t_ring] = get_temp_rec(d)

    cDAQ1Mod1_1 = read(d,seconds(1));
    
    t_outside = cDAQ1Mod1_1.outside_probe(1); 
    t_ring = cDAQ1Mod1_1.ring_probe(1); 

end 