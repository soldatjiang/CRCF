function dist_vector = compute_dist_vector(new_hashcode, hash_samples, num_training_samples, dist_vector)
    if num_training_samples>0
        for k=1:num_training_samples
            dist_vector(k) = hamming_distance(new_hashcode, hash_samples(:,k));
        end
    end
end