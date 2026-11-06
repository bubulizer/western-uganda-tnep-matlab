function [x,index] = select_compromise(archive)
%SELECT_COMPROMISE Equal-weight normalized distance to the feasible utopia.
valid = find(archive.violation < 1e-10);
if isempty(valid), valid = (1:size(archive.position,1))'; end
R = archive.raw(valid,:);
lo=min(R,[],1); hi=max(R,[],1); span=max(hi-lo,eps);
score=sqrt(sum(((R-lo)./span).^2,2));
[~,k]=min(score); index=valid(k); x=archive.position(index,:);
end

