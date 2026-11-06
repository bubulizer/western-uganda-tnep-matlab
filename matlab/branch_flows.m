function f = branch_flows(c, branch, V)
%BRANCH_FLOWS Complex power at both ends, loss and thermal loading.
n = height(branch);
Sf = complex(zeros(n,1)); St = Sf;
for k = 1:n
    if branch.status(k) == 0, continue; end
    i = branch.from_bus(k); j = branch.to_bus(k);
    y = 1/complex(branch.r_pu(k),branch.x_pu(k));
    ysh = 1i*branch.b_pu(k)/2;
    Iij = (V(i)-V(j))*y + V(i)*ysh;
    Iji = (V(j)-V(i))*y + V(j)*ysh;
    Sf(k) = V(i)*conj(Iij)*c.baseMVA;
    St(k) = V(j)*conj(Iji)*c.baseMVA;
end
f = table(branch.branch_id,branch.from_bus,branch.to_bus,real(Sf),imag(Sf), ...
    real(St),imag(St),real(Sf+St),max(abs(Sf),abs(St)), ...
    100*max(abs(Sf),abs(St))./branch.rate_MVA, ...
    'VariableNames',{'branch_id','from_bus','to_bus','P_from_MW','Q_from_MVAr', ...
    'P_to_MW','Q_to_MVAr','loss_MW','max_MVA','loading_pct'});
end

