function [ im_out ] = toy_reconstruct( im_in )

    imwrite(im_in, 'results/toy_ori.png');

    [imh, imw, nn] = size(im_in);
    % map each pixel in the region S to a variable number
    Im2var = zeros(imh, imw);
    Im2var(1:imh*imw) = 1: imh*imw;

    M = 2 * imh * imw + 1;
    N = imh * imw;

    % sparse matrix A
    A = sparse([], [], [], M, N);
    % known vector b
    b = zeros(M, 1);

    % the objectivity of Equation (2) in A3.pdf
    e = 1;
    for y = 1:imh
        for x = 1:imw-1
            A(e, Im2var(y,x+1)) = 1;
            A(e, Im2var(y,x)) = -1;
            b(e) = im_in(y,x+1)-im_in(y,x);  
            e = e+1;
        end  
    end    

    % the objectivity of Equation (3) in A3.pdf
    for y = 1:imh-1
        for x = 1:imw
            A(e, Im2var(y+1,x)) = 1;
            A(e, Im2var(y,x)) = -1;
            b(e) = im_in(y+1,x)-im_in(y,x);  
            e = e+1;
        end  
    end
    
    % the objectivity of Equation (4) in A3.pdf
    A(e, Im2var(1,1)) = 1;
    b(e) = im_in(1,1);

    % the variable to be solved
    v = A\b;
    im_out = reshape(v, [imh, imw]);
    imwrite(im_out, 'results/toy_recon.png');

    
end

