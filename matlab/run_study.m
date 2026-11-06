root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab'));
outdir=fullfile(root,'outputs'); if ~exist(outdir,'dir'), mkdir(outdir); end
fprintf('Loading study data from %s\n',root);
c=load_study_case(root);
baseline=ac_power_flow(c,c.branch);
assert(baseline.converged,'Baseline power flow failed to converge.');
fprintf('Baseline: loss %.4f MW, min V %.4f p.u., max loading %.1f%%\n', ...
    baseline.loss_MW,baseline.min_voltage,baseline.max_loading_pct);

opts=struct('population',30,'iterations',26,'archive_size',90,'seed',24068, ...
    'inertia',0.72,'c1',1.55,'c2',1.55,'de_fraction',0.30,'de_F',0.55,'de_CR',0.80);
[archive,history]=mopso_de(c,population=opts.population,iterations=opts.iterations, ...
    archive_size=opts.archive_size,seed=opts.seed,inertia=opts.inertia,c1=opts.c1,c2=opts.c2, ...
    de_fraction=opts.de_fraction,de_F=opts.de_F,de_CR=opts.de_CR);
[x,compromise_index]=select_compromise(archive);
opt=evaluate_plan(c,x);
fprintf('Compromise: loss %.4f MW, V-dev %.4f, CAPEX %.2f MUSD, max loading %.1f%%\n', ...
    opt.pf.loss_MW,opt.pf.voltage_deviation,opt.decoded.cost_MUSD,opt.pf.max_loading_pct);
n1base=nminus1_scan(c,c.branch); n1opt=nminus1_scan(c,opt.branch);
cba=cost_benefit_analysis(c,baseline,opt);
validation=validate_ieee30(); writetable(validation,fullfile(outdir,'ieee30_validation.csv'));
write_results(c,baseline,opt,archive,history,n1base,n1opt,cba,outdir);
save(fullfile(outdir,'study_results.mat'),'c','baseline','archive','history','x', ...
    'compromise_index','opt','n1base','n1opt','cba','validation','opts');
diaryfile=fullfile(outdir,'run_manifest.txt');
fid=fopen(diaryfile,'w');
fprintf(fid,'Run date: %s\nMATLAB: %s\nRandom seed: %d\nPopulation: %d\nIterations: %d\n', ...
    string(datetime('now','TimeZone','Africa/Nairobi')),version,opts.seed,opts.population,opts.iterations);
fprintf(fid,'Baseline loss MW: %.9f\nOptimized loss MW: %.9f\nOptimized CAPEX MUSD: %.6f\n', ...
    baseline.loss_MW,opt.pf.loss_MW,opt.decoded.cost_MUSD);
fprintf(fid,'IEEE30 validation pass: %d\nData status: research-case; utility replacement required.\n',validation.pass);
fclose(fid);
disp(cba); disp(validation); fprintf('Finished. Outputs: %s\n',outdir);
