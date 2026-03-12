function [htc_angle, htc_cos] = compute_heading_to_center(heading_wrap, x_data, y_data, cx, cy)
% COMPUTE_HEADING_TO_CENTER Angle between fly heading and direction to center.
%
%   [htc_angle, htc_cos] = COMPUTE_HEADING_TO_CENTER(heading_wrap, x_data, y_data, cx, cy)
%
%   Computes the angle between each fly's instantaneous heading direction
%   and the vector pointing from the fly to the arena center. This tests
%   whether flies actively orient toward the center during centring behavior.
%
%   INPUTS:
%     heading_wrap - [n_flies × n_frames] Wrapped heading angle (degrees).
%                    Uses the same convention as in combine_data_one_cohort.m:
%                    atan2(dy, dx) in image coordinates, converted to degrees.
%     x_data       - [n_flies × n_frames] X position in mm
%     y_data       - [n_flies × n_frames] Y position in mm
%     cx           - Arena center X coordinate (mm)
%     cy           - Arena center Y coordinate (mm)
%
%   OUTPUTS:
%     htc_angle - [n_flies × n_frames] Heading-to-center angle (degrees),
%                 wrapped to [-180, 180].
%                   0   = heading straight toward center
%                  ±180 = heading straight away from center
%                 +90   = center is to the left of heading
%                 -90   = center is to the right of heading
%     htc_cos   - [n_flies × n_frames] Alignment index = cos(htc_angle).
%                  +1 = heading toward center
%                  -1 = heading away from center
%                   0 = heading perpendicular to center direction
%
%   EXAMPLE:
%     PPM = 4.1691; CoA = [528, 520] / PPM;
%     [htc, htc_cos] = compute_heading_to_center(hw, x, y, CoA(1), CoA(2));
%     mean_alignment = nanmean(htc_cos(:, 300:1200), 2);  % during stimulus
%
%   NOTES:
%     Wrapping convention follows phototaxis_test_code.m (lines 74-86):
%       heading_rel_ref = mod(bearing_to_ref - heading + 180, 360) - 180
%
% See also: compute_radial_tangential, phototaxis_test_code

    % Direction from fly to arena center (degrees)
    angle_to_center = atan2d(cy - y_data, cx - x_data);

    % Heading-to-center angle: difference between center direction and heading
    % Wrapped to [-180, 180] using mod trick
    htc_angle = mod(angle_to_center - heading_wrap + 180, 360) - 180;

    % Alignment index: cosine of the heading-to-center angle
    % +1 = heading directly toward center, -1 = heading directly away
    htc_cos = cosd(htc_angle);

end
