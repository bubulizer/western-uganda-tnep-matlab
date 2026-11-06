root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'matlab'));
outdir=fullfile(root,'outputs'); c0=load_study_case(root);
cases=[1.00 1.10 1.20]; case_names=["Case 1";"Case 2";"Case 3"];
algorithms=["Baseline";"MOPSO";"MODE";"MOPSO-DE"];
population=30; iterations=26; archive_size=90;
inertia=0.72; w1=1.55; w2=1.55; F=0.55; CR=0.80; de_fraction=0.30;
rows=cell(0,19); histories=struct(); archives=cell(numel(cases),3); evaluations=population*(iterations+1);
for s=1:numel(cases)
    c=c0; c.bus.Pd_MW=c0.bus.Pd_MW*cases(s); c.bus.Qd_MVAr=c0.bus.Qd_MVAr*cases(s);
    tic; b=ac_power_flow(c,c.branch); bt=toc;
    total_load=sum(c.bus.Pd_MW); total_qload=sum(c.bus.Qd_MVAr);
    rows(end+1,:)={case_names(s),cases(s),"Baseline",0,bt,b.converged,b.loss_MW,total_load+b.loss_MW, ...
        total_load,total_qload,b.min_voltage,b.max_voltage,b.max_loading_pct,0,b.max_mismatch_pu,b.iterations,0,0,0}; %#ok<AGROW>
    seed=41000+s;
    tic; [a1,h1]=mopso_de(c,population=population,iterations=iterations,archive_size=archive_size, ...
        seed=seed,inertia=inertia,c1=w1,c2=w2,de_fraction=0,de_F=F,de_CR=CR); t1=toc;
    tic; [a2,h2]=mode_de(c,population=population,iterations=iterations,archive_size=archive_size, ...
        seed=seed,F=F,CR=CR); t2=toc;
    tic; [a3,h3]=mopso_de(c,population=population,iterations=iterations,archive_size=archive_size, ...
        seed=seed,inertia=inertia,c1=w1,c2=w2,de_fraction=de_fraction,de_F=F,de_CR=CR); t3=toc;
    aa={a1,a2,a3}; hh={h1,h2,h3}; tt=[t1 t2 t3]; names=["MOPSO","MODE","MOPSO-DE"];
    allraw=zeros(0,3);
    for k=1:3
        feas=aa{k}.violation<1e-10; allraw=[allraw;aa{k}.raw(feas,:)]; %#ok<AGROW>
    end
    if isempty(allraw), allraw=vertcat(a1.objectives,a2.objectives,a3.objectives); end
    lo=min(allraw,[],1); hi=max(allraw,[],1); span=max(hi-lo,eps);
    for k=1:3
        [x,~]=select_compromise(aa{k}); e=evaluate_plan(c,x);
        quality=sqrt(sum(((e.raw_objectives-lo)./span).^2));
        rows(end+1,:)={case_names(s),cases(s),names(k),seed,tt(k),e.feasible,e.pf.loss_MW, ...
            total_load+e.pf.loss_MW,total_load,total_qload,e.pf.min_voltage,e.pf.max_voltage, ...
            e.pf.max_loading_pct,e.decoded.cost_MUSD,e.pf.max_mismatch_pu,e.pf.iterations,evaluations, ...
            quality,sum(aa{k}.violation<1e-10)}; %#ok<AGROW>
        archives{s,k}=aa{k}; histories.(sprintf('case%d_alg%d',s,k))=hh{k};
    end
end
comparison=cell2table(rows,'VariableNames',{'case_name','load_multiplier','algorithm','seed','runtime_s', ...
    'feasible','active_loss_MW','active_power_input_MW','delivered_load_MW','reactive_load_MVAr', ...
    'minimum_voltage_pu','maximum_voltage_pu','maximum_loading_pct','CAPEX_MUSD', ...
    'max_power_mismatch_pu','powerflow_iterations','objective_evaluations','normalized_ideal_distance', ...
    'feasible_archive_solutions'});
writetable(comparison,fullfile(outdir,'chapter4_algorithm_comparison.csv'));
parameters=table(["Population";"Iterations";"Archive size";"Inertia w";"Cognitive weight w1 (c1)"; ...
    "Social weight w2 (c2)";"r1";"r2";"DE scale F";"DE crossover CR";"Hybrid DE fraction"], ...
    ["30";"26";"90";"0.72";"1.55";"1.55";"U(0,1), resampled";"U(0,1), resampled"; ...
    "0.55";"0.80";"0.30"], ...
    'VariableNames',{'parameter','value'});
writetable(parameters,fullfile(outdir,'chapter4_algorithm_parameters.csv'));
save(fullfile(outdir,'chapter4_algorithm_comparison.mat'),'comparison','parameters','histories','archives');
disp(comparison); fprintf('Algorithm comparison completed.\n');
