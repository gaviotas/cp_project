clear; clc;

% main script for project 4

% parameters
img_num = 16;

DO_HDR_IMAGING = false;
DO_EVALUATION = false;
DO_PHOTOGRAPHIC_TONEMAPPING = true;
DO_TONEMAPPING_USING_BILATERAL_FILTERING = true;

W_SCHEME = 'tent';
IMAGE_TYPE = 'rendered';
MERGING_SCHEME = 'logarithmic';

hdr_path = sprintf('../results/HDR_%s_%s_%s.hdr', IMAGE_TYPE, W_SCHEME, MERGING_SCHEME);

Zmin = ceil(0.01 * 255);
Zmax = floor(0.95 * 255);
srow = 20;
scol = 40;
l = 200;

% log exposure stack
B = zeros(1, img_num);

for i = 1:img_num
    B(1, i) = log(power(2, i - 1) / 2048);
end

% weight scheme (uniform / tent)
w = weight_scheme(W_SCHEME, Zmin, Zmax);

if DO_HDR_IMAGING

    % LINEARIZE RENDERED IMAGES (25 POINTS)
    imgs = {};
    imgs_small = {};

    % read images
    for i = 1:img_num
        img_path = sprintf('../data/exposure_stack/exposure%d.jpg', i);
        img = imread(img_path);

        % to compute the g function practically, resizing the images
        img_small = imresize(img, [srow, scol], 'bilinear');

%         img_small(img_small < Zmin) = Zmin;
%         img_small(img_small > Zmax) = Zmax;

        imgs_small{i} = double(img_small);
    end

    pixel_num = size(imgs_small{1}, 1) * size(imgs_small{1}, 2);
    pixel_indices = zeros(1, pixel_num);

    for i = 1:pixel_num
        pixel_indices(1, i) = i;
    end

    % construct Z matrix for gsolve function
    Z = zeros(pixel_num, img_num, 3);

    for i = 1:img_num
        for c = 1:3
            Z(:, i, c) = imgs_small{i}(pixel_indices + (c - 1) * pixel_num);
        end
    end

    g = zeros(256, 3);
    lnE = zeros(srow * scol, 3);
    
    for c = 1:3
        [g(:, c), lnE(:, c)] = gsolve(Z(:,:,c), B, l, w);
    end

%     figure;
%     plot(Zmin:Zmax, exp(g(Zmin:Zmax, 1)), 'r');
%     hold on;
%     plot(Zmin:Zmax, exp(g(Zmin:Zmax, 2)), 'g');
%     hold on;
%     plot(Zmin:Zmax, exp(g(Zmin:Zmax, 3)), 'b');
%     hold off;
%     title('the function exp(g)');

    if strcmp(IMAGE_TYPE, 'raw')
        % read images
        for i = 1:img_num
            img_path = sprintf('../data/exposure_stack/exposure%d.tiff', i);
            img = imread(img_path);
            img = img(1:4000, 1:6000, :);
            img = imresize(img, 0.1);
            img = im2uint8(img);

            img(img < Zmin) = Zmin;
            img(img > Zmax) = Zmax;
            
            imgs{i} = double(img);
        end        
    elseif strcmp(IMAGE_TYPE, 'rendered')
        % read images
        for i = 1:img_num
            img_path = sprintf('../data/exposure_stack/exposure%d.jpg', i);
            img = imread(img_path);
            img = imresize(img, 0.1);
            imgs{i} = double(img);
        end
    end
    
    % MERGE EXPOSURE STACK INTO HDR IMAGE (15 POINTS)
    imgHDR = hdr_merging(imgs, g, B, w, IMAGE_TYPE, MERGING_SCHEME);

    % save the hdr image
    hdrwrite(imgHDR, hdr_path);
end

% get checker board patch position
% figure;
% img = imread('../data/exposure_stack/exposure16.jpg');
% img = imresize(img, 0.1);
% imshow(img);
% impixelinfo();  

% EVALUATION (10 POINTS)
if DO_EVALUATION
    tl = [375 62; 376 78; 376 93; 377 110; 377 125; 378 141;];
    br = [387 73; 388 89; 388 105; 388 122; 389 138; 390 153;];
    
    imgHDR = hdrread(hdr_path);
    img_XYZ = rgb2xyz(imgHDR, 'Colorspace', 'linear-rgb');
    
    L = img_XYZ(:,:,2);

    L_x = zeros(6, 1);
    L_y = zeros(6, 1);
    
    for i = 1:6       
        L_y(i) = log(mean(mean(L(tl(i,2):br(i,2), tl(i,1):br(i,1)))));
        L_x(i) = i;
    end
    
    % linear regression
    figure;
    mdl = fitlm(L_x, L_y);
    plot(mdl);
    title(sprintf('R-squared: %.3f', mdl.Rsquared.Ordinary));
    xlabel('');
    ylabel('');
    saveas(gcf, sprintf('../results/plot_evaluation/plot_%s_%s_%s.png', IMAGE_TYPE, W_SCHEME, MERGING_SCHEME))
end

% PHOTOGRAPHIC TONEMAPPING (20 POINTS)
if DO_PHOTOGRAPHIC_TONEMAPPING
    % parameters of phtographic tonemapping
    K_rgb = 0.7;
    B_rgb = 0.9;
    K_xyY = 0.15;
    B_xyY = 0.95;
    imgHDR = double(hdrread(hdr_path));

    imgTMP_rgb = photographic_tonemapping(imgHDR, K_rgb, B_rgb, 'rgb');
    imgTMP_xyY = photographic_tonemapping(imgHDR, K_xyY, B_xyY, 'xyY');

    imwrite(imgTMP_rgb, '../results/TM_PHOTO/rgb.png');    
    imwrite(imgTMP_xyY, '../results/TM_PHOTO/xyY.png');    
%     figure;
%     subplot(1, 2, 1);
%     imshow(imgTMP_rgb);
%     subplot(1, 2, 2);
%     imshow(imgTMP_xyY);
%     impixelinfo();
end

% TONEMAPPING USING BILATERAL FILTERING (30 POINTS)
if DO_TONEMAPPING_USING_BILATERAL_FILTERING
    % parameters of tonmapping useing bilateral filtering
    kernel_size = 5;
    S_rgb = 0.20;
    sigma_d = 2;
    sigma_r = 0.2;
    imgHDR = double(hdrread(hdr_path));

    imgTMP_rgb = tonemapping_using_bilateral_filtering(imgHDR, kernel_size, S_rgb, sigma_d, sigma_r, 'rgb');
    imgTMP_xyY = tonemapping_using_bilateral_filtering(imgHDR, kernel_size, S_rgb, sigma_d, sigma_r, 'xyY');

    imwrite(imgTMP_rgb, '../results/TM_BILATERAL/rgb.png');    
    imwrite(imgTMP_xyY, '../results/TM_BILATERAL/xyY.png');    

%     figure;
%     subplot(1, 2, 1);
%     imshow(imgTMP_rgb);
%     subplot(1, 2, 2);
%     imshow(imgTMP_xyY);
end