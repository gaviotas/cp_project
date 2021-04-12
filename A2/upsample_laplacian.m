function [ upsampled_laplacian ] = upsample_laplacian( frames, res_frames )
    [H, W, C, N] = size(res_frames);
    % upsampling and adding with residual frames
    upsampled_laplacian = imresize(frames, [H, W]) + res_frames;
end

