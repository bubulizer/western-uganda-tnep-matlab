function tf = dominates(a,b)
tf = all(a <= b) && any(a < b);
end

