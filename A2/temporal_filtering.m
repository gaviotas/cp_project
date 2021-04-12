function [ filtered_frames ] = temporal_filtering( Hd, frames, alpha, level )
    [H, W, C, N] = size(frames);
    fftHd = freqz(Hd, N+1);
    % zero padding for FFT
    zero_padding_l = 2*N;
    temp_frames = zeros(H, W, C, zero_padding_l);

    fftHd_zp = zeros(zero_padding_l, 1);
    fftHd_zp(1:N+1) = fftHd;
    fftHd_zp(N+2:end) = fftHd(N:-1:2);

    temp = zeros(N, 1);
    fft_avg = zeros(zero_padding_l/2+1, 1);
    
    for c=2:C
        for w=1:W
            for h=1:H
                temp(:, 1) = frames(h,w,c,:);
                % FFT
                fft_temp = fft(temp, zero_padding_l, 1);
                fft_avg_temp = fft_temp(1:zero_padding_l/2+1);
                fft_avg_temp = fft_avg_temp/N;
                fft_avg_temp(2:end-1) = 2*fft_avg_temp(2:end-1);
                fft_avg = fft_avg + fft_avg_temp;
                % filtering process, inverse FFT, and amplification
                temp_frames(h,w,c,:) = alpha .* ...
                    real(ifft(fft_temp .* fftHd_zp, zero_padding_l, 1));
            end
        end
    end

    if level == 1

        figure;
        subplot(2, 1, 1);
        Fs = 30;
        
        fft_avg = fft_avg / (H * W * 2);
        freq = 0:Fs/zero_padding_l:Fs/2;
        plot(freq, abs(fft_avg));
        hold on
        title('frequency response');
        xlabel('Hz');
        ylabel('Amplitude');
        set(gca, 'XMinorTick', 'on');
        hold off

        subplot(2, 1, 2);
        plot(freq, abs(fftHd));
        hold on
        title('butterworth response');
        xlabel('Hz');
        ylabel('Amplitude');
        ylim([0 1.2]);
        set(gca, 'XMinorTick', 'on');
        hold off
    end

    filtered_frames = temp_frames(:,:,:,1:N);

end

