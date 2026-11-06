function t = validate_ieee30()
%VALIDATE_IEEE30 Verify the in-house NR solver against the standard case.
c=case_ieee30_local(); pf=ac_power_flow(c,c.branch);
% Reference loss is the conventional MATPOWER case30 AC power-flow result.
reference_loss_MW=2.443; error_MW=abs(pf.loss_MW-reference_loss_MW);
t=table(pf.converged,pf.iterations,pf.max_mismatch_pu,pf.loss_MW, ...
    reference_loss_MW,error_MW,error_MW<0.08, ...
    'VariableNames',{'converged','iterations','max_mismatch_pu','calculated_loss_MW', ...
    'reference_loss_MW','absolute_error_MW','pass'});
end

