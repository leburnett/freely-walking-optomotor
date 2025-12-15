function ylb = get_ylb_from_data_type(data_type, delta)

switch data_type
    case "dist_data"
        if delta > 0
            ylb = 'Centripetal displacement (mm)';
        else
            ylb = 'Distance from centre (mm)';
        end

    case "dist_trav"
        ylb = 'Distance travelled (mm)';

    case "av_data"
        ylb = "Angular velocity (deg s^-^1)";

    case "heading_data"
        ylb = "Heading (deg)";

    case "vel_data"
        ylb = "Velocity (mm s^-^1)";

    case "fv_data"
        ylb = "Forward velocity (mm s^-^1)";

    case "curv_data"
        ylb = "Turning rate (deg mm^-^1)";

    case "IFD_data"
        ylb = "Distance to nearest fly (mm)";
    
    case "view_dist"
        ylb = "Viewing distance (mm)";

    case "dist_dt"
        ylb = "Centring rate (mm^-^s)";

    otherwise
        error("Unknown data_type: %s", data_type);
end

end 