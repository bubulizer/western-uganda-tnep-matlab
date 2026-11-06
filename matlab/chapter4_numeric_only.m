root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab'));
outdir = fullfile(root,'outputs');
S = load(fullfile(outdir,'study_results.mat'));
c = S.c; baseline = S.baseline; opt = S.opt;

prices = [60 90 120 150];
rates = [0.06 0.08 0.10 0.12];
years = 25; load_factor = 0.65; om_fraction = 0.02;
loss_reduction = baseline.loss_MW-opt.pf.loss_MW;
capex = opt.decoded.cost_MUSD;
rows = zeros(numel(prices)*numel(rates),8); q = 0;
for i = 1:numel(rates)
    pvfactor = sum(1./(1+rates(i)).^(1:years));
    for j = 1:numel(prices)
        annual = loss_reduction*8760*load_factor*prices(j)/1e6;
        pvbenefit = annual*pvfactor;
        pvom = capex*om_fraction*pvfactor;
        npv = pvbenefit-capex-pvom;
        bcr = pvbenefit/(capex+pvom);
        q=q+1; rows(q,:)=[prices(j),rates(i),annual,pvbenefit,pvom,capex,npv,bcr];
    end
end
economic_sensitivity = array2table(rows,'VariableNames',{'energy_price_USD_MWh', ...
    'discount_rate','annual_loss_saving_MUSD','PV_loss_benefit_MUSD', ...
    'PV_OM_MUSD','CAPEX_MUSD','NPV_MUSD','benefit_cost_ratio'});
writetable(economic_sensitivity,fullfile(outdir,'chapter4_economic_sensitivity.csv'));

seeds = (24068:24072)'; nr = numel(seeds);
rob = nan(nr,9);
for k = 1:nr
    tic;
    [a,~] = mopso_de(c,population=30,iterations=26,archive_size=90,seed=seeds(k), ...
        inertia=0.72,c1=1.55,c2=1.55,de_fraction=0.30,de_F=0.55,de_CR=0.80);
    [xr,~] = select_compromise(a);
    er = evaluate_plan(c,xr);
    elapsed = toc;
    rob(k,:) = [seeds(k),er.pf.loss_MW,er.pf.voltage_deviation,er.decoded.cost_MUSD, ...
        er.pf.min_voltage,er.pf.max_loading_pct,er.feasible,sum(a.violation < 1e-10),elapsed];
    fprintf('Robustness seed %d complete: loss %.4f MW, capex %.2f MUSD\n', ...
        seeds(k),er.pf.loss_MW,er.decoded.cost_MUSD);
end
robustness = array2table(rob,'VariableNames',{'seed','loss_MW','voltage_deviation', ...
    'CAPEX_MUSD','minimum_voltage_pu','maximum_loading_pct','feasible', ...
    'feasible_archive_solutions','runtime_s'});
writetable(robustness,fullfile(outdir,'chapter4_robustness.csv'));
save(fullfile(outdir,'chapter4_numeric_analysis.mat'),'economic_sensitivity','robustness');
fprintf('Chapter Four numerical analysis completed.\n');
