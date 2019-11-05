function dist = hamming_distance(hashcode1, hashcode2)
    dist = double(sum(hashcode1 ~= hashcode2))/double(numel(hashcode1));
end