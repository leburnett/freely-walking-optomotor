function [base_type, delta, d_fv] = resolve_delta_data_type(data_type)
% RESOLVE_DELTA_DATA_TYPE Map delta data_type strings to base type + flags.
%
%   [base_type, delta, d_fv] = resolve_delta_data_type(data_type)
%
%   Converts data_type strings like 'dist_data_delta', 'fv_data_delta', etc.
%   into the base field name and delta/d_fv flags used throughout the pipeline.
%
%   The delta flag controls within-fly baseline subtraction:
%     delta = 0 → no subtraction (raw values)
%     delta = 1 → subtract frame 300 (stimulus onset baseline)
%     delta = 2 → subtract frame 1200 (stimulus offset baseline)
%
% SUPPORTED TYPES:
%   'dist_data_delta'     → base='dist_data',  delta=1, d_fv=0
%   'dist_data_delta_end' → base='dist_data',  delta=2, d_fv=0
%   'dist_data_fv'        → base='dist_data',  delta=1, d_fv=1
%   'fv_data_delta'       → base='fv_data',    delta=1, d_fv=0
%   'av_data_delta'       → base='av_data',    delta=1, d_fv=0
%   'vel_data_delta'      → base='vel_data',   delta=1, d_fv=0
%   'curv_data_delta'     → base='curv_data',  delta=1, d_fv=0
%   All other types       → base=data_type,    delta=0, d_fv=0
%
% EXAMPLE:
%   [base, delta, d_fv] = resolve_delta_data_type("fv_data_delta");
%   % base = "fv_data", delta = 1, d_fv = 0
%   cond_data = combine_timeseries_across_exp_check(data, cond_n, base);
%   if delta == 1
%       cond_data = cond_data - cond_data(:, 300);
%   end
%
% See also: combine_timeseries_across_exp_check, get_ylb_from_data_type

    d_fv = 0;

    switch data_type
        case "dist_data_delta"
            base_type = "dist_data";
            delta = 1;
        case "dist_data_delta_end"
            base_type = "dist_data";
            delta = 2;
        case "dist_data_fv"
            base_type = "dist_data";
            delta = 1;
            d_fv = 1;
        case "fv_data_delta"
            base_type = "fv_data";
            delta = 1;
        case "av_data_delta"
            base_type = "av_data";
            delta = 1;
        case "vel_data_delta"
            base_type = "vel_data";
            delta = 1;
        case "curv_data_delta"
            base_type = "curv_data";
            delta = 1;
        otherwise
            base_type = data_type;
            delta = 0;
    end

end
