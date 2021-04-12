%% Reset all variables
clc;
clear;

tic
%% Parameters
addpath('./src');
root = './data/face.mp4';
save_path = './output/face.avi';
gaussian_std = 1.0;
omega_l = 0.83;
omega_h = 1.0;
alpha = 5.0;
% omega_l = 2.33;
% omega_h = 2.67;
% alpha = 15.0;

%% 1. INITIALS AND COLOR TRANSFORMATION (5 PTS)
vr = VideoReader(root);
frames = read(vr);

% double-precision with range [0,1]
frames = double(frames) / 255;

% Convert each of the frames to the YIQ color space.
[H, W, C, N] = size(frames);

frames_YIQ = zeros(H, W, C, N);

for i=1:N
    frames_YIQ(:,:,:,i) = rgb2ntsc(frames(:,:,:,i));
end

imwrite(frames(:,:,:,1), './figure/frame_ori.png');
imwrite(frames_YIQ(:,:,:,1), './figure/frame_YIQ.png');

fprintf('STEP 1: INITIALS AND COLOR TRANSFORMATION DONE.\n');
toc


%% 2. LAPLACIAN PYRAMID (20 PTS)
% construct laplacian pyramid for each level
[gau_frames_1, res_frames_0] = construct_laplacian_pyramid(frames_YIQ, gaussian_std);
[gau_frames_2, res_frames_1] = construct_laplacian_pyramid(gau_frames_1, gaussian_std);
[gau_frames_3, res_frames_2] = construct_laplacian_pyramid(gau_frames_2, gaussian_std);
[gau_frames_4, res_frames_3] = construct_laplacian_pyramid(gau_frames_3, gaussian_std);

imwrite(res_frames_0(:,:,:,1) + 0.5, './figure/frame_residual_0.png');
imwrite(res_frames_1(:,:,:,1) + 0.5, './figure/frame_residual_1.png');
imwrite(res_frames_2(:,:,:,1) + 0.5, './figure/frame_residual_2.png');
imwrite(res_frames_3(:,:,:,1) + 0.5, './figure/frame_residual_3.png');
imwrite(gau_frames_4(:,:,:,1), './figure/frame_gaussian_4.png');

fprintf('STEP 2: LAPLACIAN PYRAMID DONE.\n');
toc

%% 3. TEMPORAL FILTERING (30 PTS) & 4. EXTRACTING THE FREQUENCY BAND OF INTEREST (30 PTS)

fps = vr.FrameRate;
Hd = butterworthBandpassFilter(fps, 256, omega_l, omega_h);

filtered_gau_frames_4 = temporal_filtering(Hd, gau_frames_4, alpha, 5);
filtered_res_frames_3 = temporal_filtering(Hd, res_frames_3, alpha, 4);
filtered_res_frames_2 = temporal_filtering(Hd, res_frames_2, alpha, 3);
filtered_res_frames_1 = temporal_filtering(Hd, res_frames_1, alpha, 2);
filtered_res_frames_0 = temporal_filtering(Hd, res_frames_0, alpha, 1);

clear('Hd');

fprintf('STEP 3&4: TEMPORAL FILTERING & EXTRACTING THE FREQUENCY BAND DONE.\n');
toc

%% 5. IMAGE RECONSTRUCTION (20 PTS, WHICH INCLUDES EVALUATION OF YOUR RESULTS)
% reconstruction process
re_frames_3 = upsample_laplacian(filtered_gau_frames_4, filtered_res_frames_3);
re_frames_2 = upsample_laplacian(re_frames_3, filtered_res_frames_2);
re_frames_1 = upsample_laplacian(re_frames_2, filtered_res_frames_1);
re_frames_0 = upsample_laplacian(re_frames_1, filtered_res_frames_0);

re_frames_0(:,:,2,:) = re_frames_0(:,:,2,:);
re_frames_0(:,:,3,:) = re_frames_0(:,:,3,:);

re_frames = re_frames_0 + frames_YIQ;

frames_RGB = zeros(H, W, C, N, 'uint8');

for i=1:N
    frame = ntsc2rgb(re_frames(:,:,:,i));
    frame = frame * 255.;
    frame(frame > 255.) = 255;
    frame(frame < 0. ) = 0;
    frame = uint8(frame);
    
    frames_RGB(:,:,:,i) = frame;
end

vw = VideoWriter(save_path);
open(vw);

for i=1:N
    writeVideo(vw, squeeze(frames_RGB(:, :, :, i)));
end

close(vw);

fprintf('STEP 5 DONE.\n');
toc