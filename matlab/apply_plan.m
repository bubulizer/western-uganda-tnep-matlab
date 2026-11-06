function [branch, decoded] = apply_plan(c, x)
%APPLY_PLAN Decode expansion, line-opening and generator-voltage decisions.
build = x(1:c.nCandidate) >= 0.5;
open = x(c.nCandidate+(1:c.nSwitch)) >= 0.5;
vset = x(c.binary_count+(1:c.nVset));
branch = c.branch;
branch.status(c.switch_rows(open)) = 0;
for k = find(build(:))'
    row = c.candidate(k,:);
    newrow = table(1000+k,row.from_bus,row.to_bus,row.length_km,row.r_pu,row.x_pu, ...
        row.b_pu,row.rate_MVA,1,0,"candidate " + string(k), ...
        'VariableNames',branch.Properties.VariableNames);
    branch = [branch; newrow]; %#ok<AGROW>
end
decoded.build = build;
decoded.open = open;
decoded.vset = vset;
decoded.cost_MUSD = sum(c.candidate.cost_MUSD(build));
end

