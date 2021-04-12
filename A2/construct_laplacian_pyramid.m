function [ gaussian_frames, residual_frames ] = construct_laplacian_pyramid(frames, gaussian_std)
    [H, W, C, N] = size(frames);
    gaussian_frames = zeros(floor((H+1)/2), floor((W+1)/2), C, N);
    residual_frames = zeros(H, W, C, N);

    for i=1:N
        ori_frame = frames(:,:,:,i);
        % gaussian
        gaussian_frame = imgaussfilt(ori_frame, gaussian_std);
        % downsampling
        downsampled_frame = imresize(gaussian_frame, 0.5);
        % upsampling
        upsampled_frame = imresize(downsampled_frame, [H, W]);
        % compute residual
        residual_frame = ori_frame - upsampled_frame;

        gaussian_frames(:,:,:,i) = downsampled_frame;
        residual_frames(:,:,:,i) = residual_frame;
    end
end

