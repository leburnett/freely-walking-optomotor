function frame_out = overlay_stim_on_image(img1024, stim1750, valid_mask, varargin)
% OVERLAY_STIM_ON_IMAGE
% Centers a 1024x1024 uint8 image on a 1750x1750 canvas and overlays a
% stimulus (same 1750x1750 size) wherever valid_mask==1.
%
% frame_out = overlay_stim_on_image(img1024, stim1750, valid_mask)
% frame_out = overlay_stim_on_image(..., 'CanvasSize', [1750 1750], 'Alpha', 1.0)
%
% Inputs:
%   img1024    : 1024x1024 uint8 (grayscale); will be centered on canvas
%   stim1750   : 1750x1750 uint8 (grayscale) stimulus intensities
%   valid_mask : 1750x1750 logical (or numeric 0/1) mask where stimulus is valid
%
% Name-Value:
%   'CanvasSize' : [H W] of output canvas (default [1750 1750])
%   'Alpha'      : 0..1, blending factor for mask region (1 = replace)
%   'BG'         : background level for canvas (uint8, default 0)
%   'ColorizeStim': false/true; if true, colorize the stimulus (requires RGB out)
%
% Output:
%   frame_out : HxWx[1 or 3] uint8 frame suitable for VideoWriter
%
% Notes:
% - If you prefer RGB output, you can pass a 3-channel img1024 or set
%   'ColorizeStim', true (stimulus will be colorized, image stays gray).

% ---- Parse args
p = inputParser;
p.addParameter('CanvasSize', [1750 1750], @(x)isnumeric(x)&&numel(x)==2);
p.addParameter('Alpha', 1.0, @(x)isnumeric(x)&&isscalar(x)&&x>=0&&x<=1);
p.addParameter('BG', uint8(0), @(x)isnumeric(x)&&isscalar(x));
p.addParameter('ColorizeStim', false, @(x)islogical(x)||isnumeric(x));
p.parse(varargin{:});
H = p.Results.CanvasSize(1);
W = p.Results.CanvasSize(2);
alpha = p.Results.Alpha;
bg = uint8(p.Results.BG);
colorize = logical(p.Results.ColorizeStim);

% ---- Types & sizes
assert(isa(img1024,'uint8') && all(size(img1024,1:2)==[1024 1024]), ...
    'img1024 must be 1024x1024 uint8.');
valid_mask = logical(valid_mask);
assert(all(size(valid_mask,1:2)==[H W]), 'valid_mask must match CanvasSize.');

% ---- Prepare canvas
% Support grayscale or RGB input image (2D or 3D)
if ndims(img1024)==2
    % grayscale image; canvas grayscale
    canvas = repmat(bg, H, W, 1);
    % center image
    r0 = floor((H-1024)/2)+1;
    c0 = floor((W-1024)/2)+1;
    canvas(r0:r0+1023, c0:c0+1023) = img1024;
    base = canvas;  % uint8
    isRGB = false;
else
    % RGB image
    assert(size(img1024,3)==3, 'If 3D, img1024 must be RGB.');
    canvas = repmat(reshape(bg,1,1,1), H, W, 3);
    r0 = floor((H-1024)/2)+1;
    c0 = floor((W-1024)/2)+1;
    canvas(r0:r0+1023, c0:c0+1023, :) = img1024;
    base = canvas;  % uint8 RGB
    isRGB = true;
end

assert(all(size(stim1750,1:2)==[H W]), 'stim1750 must match CanvasSize.');
if isa(stim1750,'uint8')
    stim_u8 = stim1750;
else
    s = double(stim1750);
    s(~isfinite(s)) = 0;                % NaN/Inf → 0
    if max(s(:)) <= 1+eps && min(s(:)) >= 0
        % Interpreted as normalized [0,1]
        stim_u8 = uint8(round(255 * s));
    else
        % Interpreted as intensity [0,255] (clip just in case)
        s = min(max(s, 0), 255);
        stim_u8 = uint8(round(s));
    end
end

% ---- Build stimulus layer (grayscale or optional colorized)
if ~isRGB && ~colorize
    stim_layer = stim1750; % grayscale, single channel
else
    % Make RGB stimulus
    % Simple colorization: map intensity to [R,G,B] with a blue-ish tint
    % (customize if you like). Keep it fast & dependency-free.
    s = double(stim1750) / 255;  % 0..1
    R = uint8(255 * (0.1 * s));
    G = uint8(255 * (0.4 * s));
    B = uint8(255 * (1.0 * s));
    stim_layer = cat(3, R, G, B);
    % If base is grayscale, expand to RGB for blending
    if ~isRGB
        base = repmat(base, 1, 1, 3);
        isRGB = true;
    end
end

% ---- Apply mask (replace or alpha-blend)
% Convert to double for blending, then back to uint8
if alpha >= 1.0
    % Hard replace inside mask
    if isRGB && ndims(stim_layer)==3
        for ch = 1:3
            tmp = base(:,:,ch);
            sl = stim_layer(:,:,ch);
            tmp(valid_mask) = sl(valid_mask);
            base(:,:,ch) = tmp;
        end
    else
        tmp = base; % single channel
        tmp(valid_mask) = stim_layer(valid_mask);
        base = tmp;
    end
else
    % Alpha blend: base*(1-alpha) + stim*alpha, on mask only
    if isRGB && ndims(stim_layer)==3
        baseD = double(base);
        stimD = double(stim_layer);
        for ch = 1:3
            b = baseD(:,:,ch);
            s = stimD(:,:,ch);
            b(valid_mask) = (1-alpha)*b(valid_mask) + alpha*s(valid_mask);
            baseD(:,:,ch) = b;
        end
        base = uint8(round(baseD));
    else
        baseD = double(base);
        stimD = double(stim_layer);
        baseD(valid_mask) = (1-alpha)*baseD(valid_mask) + alpha*stimD(valid_mask);
        base = uint8(round(baseD));
    end
end

frame_out = base;  % uint8

end