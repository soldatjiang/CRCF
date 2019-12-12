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
    
    model_xf = permute(sum(bsxfun(@times, alpha, xf), 1), [2,3,4,1]);
    S_xx = sum(conj(model_xf) .* model_xf, 3);
    
    admm_iterations = 4;

    while (i <= admm_iterations)
        %   solve for G- please refer to the paper for more details
        B = S_xx + (T * mu);
        S_lx = sum(conj(model_xf) .* l_f, 3);
        S_hx = sum(conj(model_xf) .* h_f, 3);
        g_f = (((1/(T*mu)) * bsxfun(@times, yf, model_xf)) - ((1/mu) * l_f)  + h_f) - ...
              bsxfun(@rdivide,(((1/(T*mu)) * bsxfun(@times, model_xf, (S_xx .* yf))) ...
              - ((1/mu) * bsxfun(@times, model_xf, S_lx)) + (bsxfun(@times, model_xf, S_hx))), B);
        
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

