root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab'));
c=load_study_case(root); pf=ac_power_flow(c,c.branch);
assert(pf.converged,'Western Uganda base case did not converge.');
assert(pf.max_mismatch_pu<1e-7,'Power-flow mismatch exceeds tolerance.');
v=validate_ieee30(); disp(v); assert(v.pass,'IEEE 30-bus validation failed.');
fprintf('All tests passed. Base-case loss %.4f MW, minimum V %.4f p.u.\n',pf.loss_MW,pf.min_voltage);

