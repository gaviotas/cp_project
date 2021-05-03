function [ im_blend ] = poissonBlend( im_s, mask_s, im_background )

    [imh, imw, nn] = size(im_s);
    Im2var = zeros(imh, imw);

    % the region S to be pasted
    [yy xx] = find(mask_s > 0);
    % the number of pixels in the region S (non-zero pixels in mask_s)
    nz = sum(sum(mask_s));

    % map each pixel in the region S to a variable number
    e = 1;
    for i = 1:nz
        Im2var(yy(i),xx(i)) = e;
        e = e+1;
    end
    
    % sparse matrix A
    A = sparse([], [], []);
    % known vector b
    b = zeros(nz, nn);

    e = 1;

    im_blend = im_background; 

    dx = [0, 0, -1, +1];
    dy = [-1, +1, 0, 0];

    % Laplacian filter
    for i = 1:nz
        y = yy(i);
        x = xx(i);
        A(e, Im2var(y,x)) = 4;
        for j = 1:4
            % the part of the first summation of Equation (1) in A3.pdf
            if mask_s(y+dy(j),x+dx(j)) == 1
                A(e, Im2var(y+dy(j),x+dx(j))) = -1;
                grad_s = reshape(im_s(y,x,:) - im_s(y+dy(j),x+dx(j),:), 1, nn);
                b(e,:) = b(e,:) + grad_s;
            % the part of the second summation of Equation (1) in A3.pdf
            else
                grad_s = reshape(im_s(y,x,:) - im_s(y+dy(j),x+dx(j),:), 1, nn);
                b(e,:) = b(e,:) + grad_s + reshape(im_background(y+dy(j),x+dx(j),:), 1, nn);
            end

        end
        e = e+1;
    end
    
    % the variable to be solved
    v = A\b;

    % reconstruct the blended image
    e = 1;
    for i=1:nz
        y = yy(i);
        x = xx(i);
        im_blend(y,x,:) = v(e,:);
        e = e + 1;
    end
    
    % save the results
    imwrite(im_s, 'results/poisson blending/im_s.png');
    imwrite(mask_s, 'results/poisson blending/mask_s.png');
    imwrite(im_background, 'results/poisson blending/im_background.png');    
    imwrite(im_blend, 'results/poisson blending/im_blend.png');
        
end

