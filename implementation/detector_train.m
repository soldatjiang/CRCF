function g = detector_train(samplesf_large, yf_detector, num_training_samples, params, prior_weights)
    g_f = single(zeros(size(xf)));
    h_f = g_f;
    l_f = g_f;
    mu    = 1;
    betha = 10;
    mumax = 10000;
    i = 1;
    
    %det_sz = size(yf_detector);
    T = numel(yf_detector);
    if num_training_samples<params.nSamples
        samplesf_temp = samplesf_large(1:num_training_samples,:,:,:);
        S_xx = sum(bsxfun(@times, prior_weights(1:num_training_samples), sum(conj(samplesf_temp) .* samplesf_temp, 4)), 1);
    else
        S_xx = sum(bsxfun(@times, prior_weights, sum(conj(samplesf_large) .* samplesf_large, 4)), 1);
    end
    admm_iterations = 2;
    
    while (i <= admm_iterations)
        %   solve for G- please refer to the paper for more details
        B = S_xx + (T * mu);
        if num_training_samples<params.nSamples
            samplesf_temp = samplesf_large(1:num_training_samples,:,:,:);
            S_lx = sum(sum(bsxfun(@times, prior_weights(1:num_training_samples), conj(samplesf_temp)), 1) .* l_f, 3);
            S_hx = sum(sum(bsxfun(@times, prior_weights(1:num_training_samples), conj(samplesf_temp)), 1) .* h_f, 3);
        else
            S_lx = sum(sum(bsxfun(@times, prior_weights, conj(samplesf_large)), 1) .* l_f, 3);
            S_hx = sum(sum(bsxfun(@times, prior_weights, conj(samplesf_large)), 1) .* h_f, 3);
        end
        %S_lx = sum(conj(model_xf) .* l_f, 3);
        %S_hx = sum(conj(model_xf) .* h_f, 3);
        g_f = (((1/(T*mu)) * bsxfun(@times, yf, model_xf)) - ((1/mu) * l_f)  + h_f) - ...
            bsxfun(@rdivide,(((1/(T*mu)) * bsxfun(@times, model_xf, (S_xx .* yf))) ...
            - ((1/mu) * bsxfun(@times, model_xf, S_lx)) + (bsxfun(@times, model_xf, S_hx))), B);
        
        %   solve for H
        h = (T/((mu*T)+ params.admm_lambda))  *   ifft2((mu*g_f) + l_f);    
        [sx,sy,h] = get_subwindow_no_window(h, floor(use_sz/2) , small_filter_sz);
        t = single(zeros(use_sz(1), use_sz(2), size(h,3)));
        t(sx,sy,:) = h;

        h_f = fft2(t);
        
        %   update L
        l_f = l_f + (mu * (g_f - h_f));
        
        %   update mu- betha = 10.
        mu = min(betha * mu, mumax);
        i = i+1;
    end
end

