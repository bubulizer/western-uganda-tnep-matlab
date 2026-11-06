function e = evaluate_plan(c, x)
%EVALUATE_PLAN Multi-objective fitness plus quadratic constraint penalty.
ct = c;
ct.bus.Vset_pu(ct.pv_buses) = x(c.binary_count+(1:c.nVset));
[branch, decoded] = apply_plan(ct,x);
pf = ac_power_flow(ct,branch);
if ~pf.converged
    violation = 100;
else
    low = max(0,ct.bus.Vmin_pu-pf.Vm);
    high = max(0,pf.Vm-ct.bus.Vmax_pu);
    overload = max(0,pf.branch.loading_pct/100-1);
    violation = sum(low.^2+high.^2) + sum(overload.^2);
end
raw = [pf.loss_MW, pf.voltage_deviation, decoded.cost_MUSD];
penalty = [2e3, 2e3, 2e3] * violation;
e.objectives = raw + penalty;
e.raw_objectives = raw;
e.violation = violation;
e.feasible = pf.converged && violation < 1e-10;
e.pf = pf;
e.decoded = decoded;
e.branch = branch;
end

