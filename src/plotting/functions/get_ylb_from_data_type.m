function ylb = get_ylb_from_data_type(data_type, delta)
% GET_YLB_FROM_DATA_TYPE Return y-axis label string for a given data type.
%
%   ylb = get_ylb_from_data_type(data_type, delta)
%
%   Supports both base data types (e.g., 'fv_data') and delta variants
%   (e.g., 'fv_data_delta'). For delta variants, the function resolves
%   the base type automatically via resolve_delta_data_type.
%
% See also: resolve_delta_data_type

% Resolve delta data types (e.g., 'fv_data_delta' → 'fv_data' + delta=1)
[base_type, resolved_delta] = resolve_delta_data_type(data_type);
if resolved_delta > 0
    data_type = base_type;
    delta = resolved_delta;
end

switch data_type
    case "dist_data"
        if delta > 0
            ylb = "Distance moved towards centre (mm)";
            % ylb = 'Centripetal displacement (mm)';
        else
            ylb = 'Distance from centre (mm)';
        end

    case "dist_trav"
        ylb = 'Distance travelled (mm)';

    case "av_data"
        if delta > 0
            ylb = "\DeltaAngular velocity (deg s^-^1)";
        else
            ylb = "Angular velocity (deg s^-^1)";
        end

    case "heading_data"
        ylb = "Heading (deg)";

    case "vel_data"
        if delta > 0
            ylb = "\DeltaVelocity (mm s^-^1)";
        else
            ylb = "Velocity (mm s^-^1)";
        end

    case "fv_data"
        if delta > 0
            ylb = "\DeltaForward velocity (mm s^-^1)";
        else
            ylb = "Forward velocity (mm s^-^1)";
        end

    case "curv_data"
        if delta > 0
            ylb = "\DeltaTurning rate (deg mm^-^1)";
        else
            ylb = "Turning rate (deg mm^-^1)";
        end

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
