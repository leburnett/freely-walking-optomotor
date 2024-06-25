function Y = cent_diff(X, h)
% function Y = cent_diff(X, h)
% computes the numerical derivative of X by using the central difference
% formula. For the derivatives to be meaningful, need to use the step size
% h.

Y = zeros(size(X));

Y(2:end-1) = (X(3:end) - X(1:end-2))/(2*h);

% just repeat the first and end point, so that Y is length of X
Y(1) = Y(2);
Y(end) = Y(end-1);


