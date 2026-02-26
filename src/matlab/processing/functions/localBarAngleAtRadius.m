function theta_deg = localBarAngleAtRadius(r_mm, R_arena, dphi_bar)
    xf = r_mm; yf = 0;
    phi0 = 0;
    phi1 = phi0 - dphi_bar/2;
    phi2 = phi0 + dphi_bar/2;

    p1 = [R_arena*cos(phi1); R_arena*sin(phi1)];
    p2 = [R_arena*cos(phi2); R_arena*sin(phi2)];
    pe = [xf; yf];

    v1 = p1 - pe;
    v2 = p2 - pe;

    denom = norm(v1)*norm(v2);
    if denom < 1e-12
        theta_deg = NaN;
        return;
    end

    cosang = dot(v1, v2)/denom;
    cosang = max(min(cosang, 1), -1);
    theta_deg = acos(cosang) * 180/pi;
end