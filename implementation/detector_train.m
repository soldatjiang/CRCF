function g = detector_train(samplesf_large, yf, num_training_samples, params, prior_weights)
    %det_sz = size(yf_detector);
    if num_training_samples<params.nSamples
        xf = samplesf_large(1:num_training_samples,:,:,:);
        alpha = prior_weights(1:num_training_samples);
        %S_xx = sum(bsxfun(@times, prior_weights(1:num_training_samples), sum(conj(samplesf_temp) .* samplesf_temp, 4)), 1);
    else
        %S_xx = sum(bsxfun(@times, prior_weights, sum(conj(samplesf_large) .* samplesf_large, 4)), 1);
        xf = samplesf_large;
        alpha = prior_weights;
    end
    
    g_f = single(zeros(size(xf,2), size(xf,3), size(xf,4)));
    h_f = g_f;
    l_f = g_f;
    %temp = single(zeros(1, size(h_f, 1), size(h_f, 2), size(h_f, 3)));
    mu    = 1;
    betha = 10;
    mumax = 10000;
    i = 1;
    T = numel(yf);
    
    xf_weighted = bsxfun(@times, alpha, xf);
    xf_sum = permute(sum(xf_weighted, 1),[2,3,4,1]);
    S_xx = sum(conj(xf) .* xf, 4);
    
    admm_iterations = 2;
    
    while (i <= admm_iterations)
        %   solve for G- please refer to the paper for more details
        if params.form2
            error('Not Implemented!');
        else
            %permute 升维，第一个维度为批量
            S_x_xsum = sum(conj(xf) .* repmat(permute(xf_sum, [4,1,2,3]), [size(xf,1),1,1,1]), 4);
            S_xl = sum(conj(xf) .* repmat(permute(l_f, [4,1,2,3]), [size(xf,1),1,1,1]), 4);
            S_xh = sum(conj(xf) .* repmat(permute(h_f, [4,1,2,3]), [size(xf,1),1,1,1]), 4);
            temp_xf_weighted = bsxfun(@rdivide, xf_weighted, S_xx+mu*T);
            g_f = (1/(mu*T))*bsxfun(@times, xf_sum, yf) - (1/(mu))*l_f + h_f...
            - (1/(mu*T))*permute(sum(bsxfun(@times, temp_xf_weighted, S_x_xsum.* repmat(permute(yf,[3,1,2]), [size(xf,1),1,1])), 1), [2,3,4,1])...
            + (1/(mu))*permute(sum(bsxfun(@times, temp_xf_weighted, S_xl), 1), [2,3,4,1])...
            - permute(sum(bsxfun(@times, temp_xf_weighted, S_xh), 1), [2,3,4,1]);
        
            %g_f = squeeze(g_f);
        end
        
        %   solve for H
        h = (T/((mu*T)+ params.admm_lambda))*ifft2((mu*g_f) + l_f);    
        [sx,sy,h] = get_subwindow_no_window(h, floor(params.det_sz/2) , params.small_filter_sz);
        t = single(zeros(params.det_sz(1), params.det_sz(2), size(h,3)));
        t(sx,sy,:) = h;

        h_f = fft2(t);
        
        %   update L
        l_f = l_f + (mu * (g_f - h_f));
        
        %   update mu- betha = 10.
        mu = min(betha * mu, mumax);
        i = i+1;
    end
    
    g = ifft2(g_f, 'symmetric');
end

