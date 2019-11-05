function merged_sample = merge_samples(sample1, sample2, w1, w2)
% Merge sample1 and sample2 using weights w1 and w2. The type of merging is
% decided by sample_merge_type. 
% The sample_merge_type can be
% 1) Merge: The output is the weighted sum of the input samples
% 2) Replace: The output is the first sample. ie w2 is assumed to be 0


% Normalise the weights so that they sum to one
alpha1 = w1/(w1+w2);
alpha2 = 1 - alpha1;

% Build the merged sample
sample1 = squeeze(sample1);
sample2 = squeeze(sample2);
merged_sample = squeeze(alpha1*sample1 + alpha2*sample2);
end
