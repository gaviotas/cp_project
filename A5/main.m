% clear; clc;

% main script for project 5

STEP_1 = true;
STEP_2 = true;
STEP_3 = true;
STEP_4 = true;

if STEP_1
    % Initials (5 points)
    img = imread('data/chessboard_lightfield.png');

    lensletSize = 16;
    s = size(img, 1) / lensletSize;
    t = size(img, 2) / lensletSize;
    channel = 3;

    img_arr = zeros(lensletSize, lensletSize, s, t, channel);
end

if STEP_2
    % Rearranging the pixels in the light field image
    for i = 1:s
        for j = 1:t
            for u = 1:lensletSize
                for v = 1:lensletSize
                    for c = 1:channel
                        img_arr(u, v, i, j, c) = img((i-1)*lensletSize+u, (j-1)*lensletSize+v, c);
                    end
                end
            end
        end
    end
    
    img_mosaic = zeros(size(img));

    for u_ = 1:u
        for v_ = 1:v
            img_mosaic(s*(u_-1)+1:s*(u_-1)+s, t*(v_-1)+1:t*(v_-1)+t, :) = img_arr(u_, v_, :, :, :);
        end
    end
end

imwrite(uint8(img_mosaic), strcat('results/mosaic', '.png'));

% figure;
% imshow(uint8(squeeze(img_mosaic)));
% return

if STEP_3
    % Refocusing and focal-stack generation (40 points)    
    maxUV = (lensletSize - 1) / 2;
    u = (1:lensletSize) - 1 - maxUV;
    v = (1:lensletSize) - 1 - maxUV;
    focal_stack = zeros(7, s, t, c);
    d_cnt = 0;

    for range_d = 0:2:15
        d_cnt = d_cnt + 1;
        img_refocused = zeros(s, t, c);
        d = 0.1 * range_d;
        for idx_u = 1:lensletSize
            for idx_v = 1:lensletSize

                du = round(u(idx_u) * d) * -1;
                dv = round(v(idx_v) * d) * 1;
                img = squeeze(img_arr(idx_u, idx_v, :, :, :));
                img_shifted = circshift(img, du, 1);
                img_shifted = circshift(img_shifted, dv, 2);

                img_refocused = img_refocused + img_shifted / lensletSize^2;    
            end
        end
        focal_stack(d_cnt, :, :, :) = img_refocused;
%         imwrite(uint8(img_refocused), strcat('results/refocused_d_', num2str(d), '.png'));
    end
end

if STEP_4
    % All-focus image and depth from defocus (35 points)

    std_1 = 2;
    std_2 = 4;

    img_all_focus = zeros(s, t, channel);
    depth = zeros(s, t);
    w_sum = zeros(s, t);

    for d = 1:8
        img_rgb = squeeze(focal_stack(d, :, :, :));
        img_xyz = rgb2xyz(img_rgb);
        img_y = img_xyz(:, :, 2);
        img_low = imgaussfilt(img_y, std_1);
        img_high = img_y - img_low;
        w_sharpness = imgaussfilt(img_high.^2, std_2);

        for c = 1:channel
            img_all_focus(:, :, c) = img_all_focus(:, :, c) + img_rgb(:, :, c) .* w_sharpness;
        end

        depth = depth + w_sharpness*(d-1)*0.2;

        w_sum = w_sum + w_sharpness;

    end

    img_all_focus = img_all_focus ./ w_sum;
    depth = depth ./ w_sum;

    imwrite(uint8(img_all_focus), strcat('results/all_focus', '.png'));
    imwrite(depth, strcat('results/depth', '.png'));
%     figure;
%     subplot(1, 2, 1); imshow(uint8(img_all_focus));
%     subplot(1, 2, 2); imshow(depth);
end