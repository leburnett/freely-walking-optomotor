function B = mapValues(A)
    % Initialize B with zeros of the same size as A
    B = zeros(size(A));

    % Apply value mapping according to the specified conditions
    B(A > 0.05) = 1;
    B(A > 0.01 & A <= 0.05) = 0.8;
    B(A > 0.001 & A <= 0.01) = 0.6;
    B(A > 0.0001 & A <= 0.001) = 0.4;
    B(A > 0.00001 & A <= 0.0001) = 0.2;
    B(A <= 0.00001) = 0;
end