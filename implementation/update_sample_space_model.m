function [merged_sample, new_sample, merged_sample_id, new_sample_id, merge_sample_id1, merge_sample_id2, merge_w1, merge_w2, merged_hashcode, new_hashcode, distance_matrix, prior_weights] = ...
    update_sample_space_model(samples, new_train_sample, distance_matrix, hash_samples, prior_weights, num_training_samples,params)

% Updates the sample space model 
% There are 4 possible cases
% 1: Memory is not full. In this case the new train sample is placed in the
% next empty slot. 
%
% 2: Memory is full, one of the samples is outdated. In this case, the new
% train sample replaces the outdated sample.
%
% 3: Memory is full, the min distance of the new train sample to the existing samples
% is less than the min distance amongst any of the existing samples. The 
% new train sample is merged with the nearest existing sample
%
% 4: Memory is full, the min distance of the new train sample to the existing samples
% is more than the min distance amongst any of the existing samples. The
% closest existing samples are merged. New train sample is placed in the
% free slot

% Find the distance of the new sample with the existing samples
% Note: Since getting the 'exact' distance between the samples is not important,
% the distance computation is done by using only the half spectrum for
% efficiency. In practice the error incurred by this is negligible. Also
% since we wannt to merge samples that are similar, and finding the best
% match is not important, small error in the distance computation doesn't
% matter

new_hashcode = compute_hashcode(new_train_sample, params.norm_target_sz);

dist_vector = inf(params.nSamples, 1, 'single');
dist_vector = compute_dist_vector(new_hashcode, hash_samples, num_training_samples, dist_vector);

merged_sample = [];
new_sample = [];
merged_sample_id = -1;
new_sample_id = -1;
merge_sample_id1 = -1;
merge_sample_id2 = -1;
merge_w1 = 0;
merge_w2 = 0;
merged_hashcode = false(64, 1);
new_hashcode = false(64, 1);

% Check if we have filled the memory
if num_training_samples == params.nSamples
    
    % Check if any sample weight is too low
    [min_sample_weight, min_sample_id] = min(prior_weights);
    
    if min_sample_weight < params.minimum_sample_weight
        % If any prior weight is less than the minimum allowed weight,
        % replace that sample with the new sample
        
        % Update distance matrix and the gram matrix
        %[distance_matrix, gram_matrix] = update_distance_matrix(distance_matrix, gram_matrix, gram_vector, new_train_sample_norm, min_sample_id, -1, 0, 1);
        distance_matrix(:, min_sample_id) = dist_vector;
        distance_matrix(min_sample_id, :) = dist_vector';
        distance_matrix(min_sample_id, min_sample_id) = inf;
        
        % Normalise the prior weights so that the new sample gets weight as
        % the learning rate
        prior_weights(min_sample_id) = 0;
        prior_weights = prior_weights*(1 - params.learning_rate)/sum(prior_weights);
        prior_weights(min_sample_id) = params.learning_rate;
        
        % Set the new sample and new sample position in the samplesf
        new_sample_id = min_sample_id;        
        new_sample = new_train_sample;        
    else
        % If no sample has low enough prior weight, then we either merge
        % the new sample with an existing sample, or merge two of the
        % existing samples and insert the new sample in the vacated
        % position
        
        % Find sample closest to the new sample
        [new_sample_min_dist, closest_sample_to_new_sample] = min(dist_vector);
        
        % Find the closest pair amongst existing samples
        [existing_samples_min_dist, closest_existing_sample_pair] = min(distance_matrix(:));
        [closest_existing_sample1,closest_existing_sample2] = ind2sub(size(distance_matrix),closest_existing_sample_pair);
        
        if closest_existing_sample1 == closest_existing_sample2
            error('Score matrix diagonal filled wrongly');
        end
        
        if new_sample_min_dist < existing_samples_min_dist
            % If the min distance of the new sample to the existing samples
            % is less than the min distance amongst any of the existing
            % samples, we merge the new sample with the nearest existing
            % sample
            
            % Renormalize prior weights
            prior_weights = prior_weights*(1 - params.learning_rate);
            
            % Set the position of the merged sample
            merged_sample_id = closest_sample_to_new_sample;
            
            % Extract the existing sample to merge
            existing_sample_to_merge = samples(merged_sample_id,:,:,:);
            merge_sample_id1 = merged_sample_id;
            merge_w1 = prior_weights(merged_sample_id);
            merge_w2 = params.learning_rate;
            
            % Merge the new_train_sample with existing sample
            merged_sample = merge_samples(existing_sample_to_merge, new_train_sample, prior_weights(merged_sample_id), params.learning_rate);
            
            % Update distance matrix
            hash_samples(:, merged_sample_id) = false(64, 1);
            merged_hashcode = compute_hashcode(merged_sample, params.norm_target_sz);
            dist_vector = inf(params.nSamples, 1, 'single');
            dist_vector = compute_dist_vector(new_hashcode, hash_samples, num_training_samples, dist_vector);
            distance_matrix(:, min_sample_id) = dist_vector;
            distance_matrix(min_sample_id, :) = dist_vector';
            distance_matrix(min_sample_id, min_sample_id) = inf;
            
            % Update the prior weight of the merged sample
            prior_weights(closest_sample_to_new_sample) = prior_weights(closest_sample_to_new_sample) + params.learning_rate;          
        else
            % If the min distance amongst any of the existing
            % samples is less than the min distance of the new sample to the existing samples, 
            % we merge the nearest existing samples and insert the new
            % sample in the vacated position
            
            % Renormalize prior weights
            prior_weights = prior_weights*(1 - params.learning_rate);
            
            % Ensure that the sample with higher prior weight is assigned
            % id1. This is only relevant if the sample_update_criteria is
            % 'replace'
            if prior_weights(closest_existing_sample2) > prior_weights(closest_existing_sample1)
                temp = closest_existing_sample1;
                closest_existing_sample1 = closest_existing_sample2;
                closest_existing_sample2 = temp;
            end
            
            % Extract the old sample
            sample_to_merge1 = samples(closest_existing_sample1,:,:,:);
            sample_to_merge2 = samples(closest_existing_sample2,:,:,:);
            merge_sample_id1 = closest_existing_sample1;
            merge_sample_id2 = closest_existing_sample2;
            merge_w1 = prior_weights(closest_existing_sample1);
            merge_w2 = prior_weights(closest_existing_sample2);
            
            % Merge the existing closest samples
            merged_sample = merge_samples(sample_to_merge1, sample_to_merge2, prior_weights(closest_existing_sample1), prior_weights(closest_existing_sample2));
                        
            % Update prior weights for the merged sample and the new sample
            prior_weights(closest_existing_sample1) = prior_weights(closest_existing_sample1) + prior_weights(closest_existing_sample2);
            prior_weights(closest_existing_sample2) = params.learning_rate;
            
            % Set the merged sample position and new sample position
            merged_sample_id = closest_existing_sample1;
            new_sample_id = closest_existing_sample2;
            
            new_sample = new_train_sample;  
            
            % Update distance matrix
            merged_hashcode = compute_hashcode(merged_sample, params.norm_target_sz);
            hash_samples(:, new_sample_id) = new_hashcode;
            hash_samples(:, merged_sample_id) = merged_hashcode;
            dist_vector = inf(params.nSamples, 1, 'single');
            dist_vector = compute_dist_vector(new_hashcode, hash_samples, num_training_samples, dist_vector);
            distance_matrix(:, new_sample_id) = dist_vector;
            distance_matrix(new_sample_id, :) = dist_vector';
            
            distance_matrix(new_sample_id, new_sample_id) = inf;
            dist_vector = inf(params.nSamples, 1, 'single');
            dist_vector = compute_dist_vector(merged_hashcode, hash_samples, num_training_samples, dist_vector);
            distance_matrix(:, merged_sample_id) = dist_vector;
            distance_matrix(merged_sample_id, :) = dist_vector';
            distance_matrix(merged_sample_id, merged_sample_id) = inf;
        end
    end
else
    % If the memory is not full, insert the new sample in the next empty
    % location
    
    sample_position = num_training_samples + 1;

    % Update the prior weight
    if sample_position == 1
        prior_weights(sample_position) = 1;
    else
        prior_weights = prior_weights*(1 - params.learning_rate);
        prior_weights(sample_position) = params.learning_rate;
    end
    
    new_sample_id = sample_position;    
    new_sample = new_train_sample;
    
    distance_matrix(:, new_sample_id) = dist_vector;
    distance_matrix(new_sample_id, :) = dist_vector';
    distance_matrix(new_sample_id, new_sample_id) = inf;
end

% Ensure that prior weights always sum to 1
if (abs(1 - sum(prior_weights)) > 1e-5)
    error('Weights not properly updated');
end
end