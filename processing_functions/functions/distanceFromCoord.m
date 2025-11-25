function distMat = distanceFromCoord(x, y, coord)
% distanceFromCoord Compute distance of each fly from a given [x,y] coordinate.
%
%   distMat = distanceFromCoord(data2plot, coord)
%
%   INPUTS:
%       data2plot.x_data : [nFlies x nTimepoints] matrix of x positions
%       data2plot.y_data : [nFlies x nTimepoints] matrix of y positions
%       coord            : 1x2 vector [x0, y0] giving reference coordinate
%
%   OUTPUT:
%       distMat          : [nFlies x nTimepoints] matrix of distances of
%                          each fly from coord at each timepoint

    % Reference point
    x0 = coord(1);
    y0 = coord(2);

    % Compute Euclidean distance at each element
    distMat = sqrt((x - x0).^2 + (y - y0).^2);
end
