%% Reset all variables
clc;
clear;

WHITE_BALANCING = 'gray';
BAYER_PATTERN = 'rggb';


%% 1. INITIALS (5 pts) : Load the image banana_slug.tiff and convert it into a double-precision array
img = imread('./data/banana_slug.tiff');

[h w] = size(img);
dtype = class(img);

img_info = sprintf('[INFO] height: %d / width: %d / dtype: %s', h, w, dtype);
disp(img_info);

img = double(img);

%% 2. LINEARIZATION (5 pts)
MAX_VAL = 15000;
MIN_VAL = 2047;

img = (img - MIN_VAL) / (MAX_VAL - MIN_VAL);
img(img<0) = 0;
img(img>1) = 1;

disp(sprintf('[INFO] MAX VAL: %d', max(reshape(img, [h*w,1]), [], 1)));
disp(sprintf('[INFO] MIN VAL: %d', min(reshape(img, [h*w,1]), [], 1)));

%% 3. IDENTIFYING THE CORRECT BAYER PATTERN (20 pts)
img1 = img(1:2:end, 1:2:end);
img2 = img(1:2:end, 2:2:end);
img3 = img(2:2:end, 1:2:end);
img4 = img(2:2:end, 2:2:end);

if strcmp(BAYER_PATTERN, 'grbg')
    img_rgb = cat(3, img2, img1, img3);
    imwrite(min(img_rgb * 5, 1), './results/step3_grbg.png');
elseif strcmp(BAYER_PATTERN, 'rggb')
    img_rgb = cat(3, img1, img2, img4);
    imwrite(min(img_rgb * 5, 1), './results/step3_rggb.png');
elseif strcmp(BAYER_PATTERN, 'bggr')
    img_rgb = cat(3, img4, img2, img1);
    imwrite(min(img_rgb * 5, 1), './results/step3_bggr.png');
elseif strcmp(BAYER_PATTERN, 'gbrg')
    img_rgb = cat(3, img3, img1, img2);
    imwrite(min(img_rgb * 5, 1), './results/step3_gbrg.png');
end
    
% figure,imshow(min(img_rgb * 5, 1));

%% 4. WHITE BALANCING (20 pts)
%% (1) white world  assumption
if strcmp(WHITE_BALANCING, 'white')
    mode = sprintf('[WHITE BALANCING] WHITE WORLD ASSUMPTION');
    [h w c] = size(img_rgb);
    channel_max = max(reshape(img_rgb, [h*w,3]), [], 1);
    img_rgb(:,:,1) = img_rgb(:,:,1) * (channel_max(2)/channel_max(1));
    img_rgb(:,:,3) = img_rgb(:,:,3) * (channel_max(2)/channel_max(3));
    imwrite(min(img_rgb * 5, 1), './results/step4_whiteworld.png');
    
%% (2) gray wolrd assumption
elseif strcmp(WHITE_BALANCING, 'gray')
    mode = sprintf('[WHITE BALANCING] GRAY WORLD ASSUMPTION');
    [h w c] = size(img_rgb);
    channel_mean = mean(reshape(img_rgb, [h*w,3]), 1);
    img_rgb(:,:,1) = img_rgb(:,:,1) * (channel_mean(2)/channel_mean(1));
    img_rgb(:,:,3) = img_rgb(:,:,3) * (channel_mean(2)/channel_mean(3));
    imwrite(min(img_rgb * 5, 1), './results/step4_grayworld.png');
%     figure; imshow(min(img_rgb, 1)),title('GrayWorld');
end
disp(mode)

%% 5. DEMOSAICING (25 pts) : Excute bilinear interpolation  (interp2)
img_dm = cat(3, interp2(img_rgb(:,:,1)), interp2(img_rgb(:,:,2)), interp2(img_rgb(:,:,3)));
imwrite(img_dm, './results/step5_demosaicing.png');

%% 6. BRIGHTNESS ADJUSTMENT AND GAMMA CORRECTION (20 pts)
%% (1) Brightness adjustment
img_gray = rgb2gray(img_dm);
[h w] = size(img_gray);
maximum_gray_val = max(reshape(img_gray, [h*w,1]));

% Best results at i == 4
% for i=0:8
%     brightening_per = i;
%     img_bright = img_dm * maximum_gray_val * (1 + brightening_per);
%     imwrite(img_bright, sprintf('./results/step6_1_brightness_x%d.png', i));
% end

img_bright = img_dm * maximum_gray_val * (1 + 4);

%% (2) Gamma correction
img_gamma_cor = zeros([h w 3]);
img_gamma_cor(img_bright < 0.0031308) = 12.92 * img_bright(img_bright < 0.0031308);
img_gamma_cor(img_bright >= 0.0031308) = (1 + 0.055) * img_bright(img_bright >= 0.0031308).^(1/2.4) - 0.055;
imwrite(img_gamma_cor, './results/step6_2_gamma.png');

%% 7. COMPRESSION (5 pts)
imwrite(img_gamma_cor, './results/step7_comp.png', 'png')

for i=5:15:95
    imwrite(img_gamma_cor, sprintf('./results/step7_comp_quality_%d.jpg', i), 'jpg', 'Quality', i)
end
