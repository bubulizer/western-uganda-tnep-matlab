function out = nminus1_scan(c, branch)
%NMINUS1_SCAN Remove each in-service branch and run an AC contingency solve.
active=find(branch.status==1); n=numel(active);
out=table('Size',[n 9],'VariableTypes', ...
    {'double','double','double','logical','double','double','double','double','logical'}, ...
    'VariableNames',{'outage_branch_id','from_bus','to_bus','converged','loss_MW', ...
    'min_voltage_pu','max_voltage_pu','max_loading_pct','secure'});
for z=1:n
    k=active(z); b=branch; b.status(k)=0;
    pf=ac_power_flow(c,b);
    out.outage_branch_id(z)=branch.branch_id(k);
    out.from_bus(z)=branch.from_bus(k); out.to_bus(z)=branch.to_bus(k);
    out.converged(z)=pf.converged; out.loss_MW(z)=pf.loss_MW;
    out.min_voltage_pu(z)=pf.min_voltage; out.max_voltage_pu(z)=pf.max_voltage;
    out.max_loading_pct(z)=pf.max_loading_pct;
    out.secure(z)=pf.converged && pf.min_voltage>=min(c.bus.Vmin_pu)-1e-6 && ...
        pf.max_voltage<=max(c.bus.Vmax_pu)+1e-6 && pf.max_loading_pct<=100+1e-6;
end
end

