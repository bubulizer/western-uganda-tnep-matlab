root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab'));
outdir = fullfile(root,'outputs');
S = load(fullfile(outdir,'study_results.mat'));
c = S.c; baseline = S.baseline; opt = S.opt; x = S.x;

%% Fixed-plan demand-growth sensitivity
multipliers = [0.80; 1.00; 1.10; 1.20; 1.30];
n = numel(multipliers);
base_loss = nan(n,1); base_min_v = nan(n,1); base_max_loading = nan(n,1);
base_converged = false(n,1);
opt_loss = nan(n,1); opt_min_v = nan(n,1); opt_max_loading = nan(n,1);
opt_converged = false(n,1);
for k = 1:n
    cs = c;
    cs.bus.Pd_MW = c.bus.Pd_MW * multipliers(k);
    cs.bus.Qd_MVAr = c.bus.Qd_MVAr * multipliers(k);
    pfb = ac_power_flow(cs,cs.branch);
    eo = evaluate_plan(cs,x);
    base_converged(k) = pfb.converged;
    opt_converged(k) = eo.pf.converged;
    if pfb.converged
        base_loss(k) = pfb.loss_MW;
        base_min_v(k) = pfb.min_voltage;
        base_max_loading(k) = pfb.max_loading_pct;
    end
    if eo.pf.converged
        opt_loss(k) = eo.pf.loss_MW;
        opt_min_v(k) = eo.pf.min_voltage;
        opt_max_loading(k) = eo.pf.max_loading_pct;
    end
end
loss_reduction_pct = 100*(base_loss-opt_loss)./base_loss;
load_sensitivity = table(multipliers,base_converged,base_loss,base_min_v,base_max_loading, ...
    opt_converged,opt_loss,opt_min_v,opt_max_loading,loss_reduction_pct, ...
    'VariableNames',{'load_multiplier','baseline_converged','baseline_loss_MW', ...
    'baseline_min_voltage_pu','baseline_max_loading_pct','optimized_converged', ...
    'optimized_loss_MW','optimized_min_voltage_pu','optimized_max_loading_pct', ...
    'loss_reduction_pct'});
writetable(load_sensitivity,fullfile(outdir,'chapter4_load_sensitivity.csv'));

f = figure('Visible','off','Color','w','Position',[100 100 1120 720]);
tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
nexttile; plot(100*multipliers,base_loss,'-o','LineWidth',1.8); hold on;
plot(100*multipliers,opt_loss,'-s','LineWidth',1.8); grid on;
xlabel('Demand level (% of field base case)'); ylabel('Active power loss (MW)');
legend('Existing network','Optimized network','Location','northwest');
nexttile; plot(100*multipliers,base_min_v,'-o','LineWidth',1.8); hold on;
plot(100*multipliers,opt_min_v,'-s','LineWidth',1.8); yline(0.95,'--r'); grid on;
xlabel('Demand level (% of field base case)'); ylabel('Minimum voltage (p.u.)');
legend('Existing network','Optimized network','0.95 p.u. limit','Location','southwest');
nexttile([1 2]); plot(100*multipliers,base_max_loading,'-o','LineWidth',1.8); hold on;
plot(100*multipliers,opt_max_loading,'-s','LineWidth',1.8); yline(100,'--r'); grid on;
xlabel('Demand level (% of field base case)'); ylabel('Maximum branch loading (%)');
legend('Existing network','Optimized network','Thermal limit','Location','northwest');
exportgraphics(f,fullfile(outdir,'chapter4_load_sensitivity.png'),'Resolution',220);
close(f);

%% Discount-rate and energy-price sensitivity
prices = [60 90 120 150];
rates = [0.06 0.08 0.10 0.12];
years = 25; load_factor = 0.65; om_fraction = 0.02;
loss_reduction = baseline.loss_MW-opt.pf.loss_MW;
capex = opt.decoded.cost_MUSD;
rows = zeros(numel(prices)*numel(rates),8); q = 0;
NPV = zeros(numel(rates),numel(prices)); BCR = NPV;
for i = 1:numel(rates)
    pvfactor = sum(1./(1+rates(i)).^(1:years));
    for j = 1:numel(prices)
        annual = loss_reduction*8760*load_factor*prices(j)/1e6;
        pvbenefit = annual*pvfactor;
        pvom = capex*om_fraction*pvfactor;
        npv = pvbenefit-capex-pvom;
        bcr = pvbenefit/(capex+pvom);
        q=q+1; rows(q,:)=[prices(j),rates(i),annual,pvbenefit,pvom,capex,npv,bcr];
        NPV(i,j)=npv; BCR(i,j)=bcr;
    end
end
economic_sensitivity = array2table(rows,'VariableNames',{'energy_price_USD_MWh', ...
    'discount_rate','annual_loss_saving_MUSD','PV_loss_benefit_MUSD', ...
    'PV_OM_MUSD','CAPEX_MUSD','NPV_MUSD','benefit_cost_ratio'});
writetable(economic_sensitivity,fullfile(outdir,'chapter4_economic_sensitivity.csv'));
f = figure('Visible','off','Color','w','Position',[100 100 1050 420]);
tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
nexttile; imagesc(prices,100*rates,NPV); colorbar; axis xy;
xlabel('Energy price (USD/MWh)'); ylabel('Discount rate (%)'); title('Net present value (MUSD)');
for i=1:numel(rates), for j=1:numel(prices), text(prices(j),100*rates(i),sprintf('%.1f',NPV(i,j)), ...
    'HorizontalAlignment','center','Color','w','FontWeight','bold'); end, end
nexttile; imagesc(prices,100*rates,BCR); colorbar; axis xy;
xlabel('Energy price (USD/MWh)'); ylabel('Discount rate (%)'); title('Benefit-cost ratio');
for i=1:numel(rates), for j=1:numel(prices), text(prices(j),100*rates(i),sprintf('%.3f',BCR(i,j)), ...
    'HorizontalAlignment','center','Color','w','FontWeight','bold'); end, end
exportgraphics(f,fullfile(outdir,'chapter4_economic_sensitivity.png'),'Resolution',220);
close(f);

%% Independent-seed robustness of the hybrid optimizer
seeds = (24068:24072)'; nr = numel(seeds);
rob = nan(nr,9);
for k = 1:nr
    tic;
    [a,h] = mopso_de(c,population=30,iterations=26,archive_size=90,seed=seeds(k), ...
        inertia=0.72,c1=1.55,c2=1.55,de_fraction=0.30,de_F=0.55,de_CR=0.80);
    [xr,~] = select_compromise(a);
    er = evaluate_plan(c,xr);
    elapsed = toc;
    feasible_archive = sum(a.violation < 1e-10);
    rob(k,:) = [seeds(k),er.pf.loss_MW,er.pf.voltage_deviation,er.decoded.cost_MUSD, ...
        er.pf.min_voltage,er.pf.max_loading_pct,er.feasible,feasible_archive,elapsed];
    fprintf('Robustness seed %d complete: loss %.4f MW, capex %.2f MUSD\n', ...
        seeds(k),er.pf.loss_MW,er.decoded.cost_MUSD);
end
robustness = array2table(rob,'VariableNames',{'seed','loss_MW','voltage_deviation', ...
    'CAPEX_MUSD','minimum_voltage_pu','maximum_loading_pct','feasible', ...
    'feasible_archive_solutions','runtime_s'});
writetable(robustness,fullfile(outdir,'chapter4_robustness.csv'));
f = figure('Visible','off','Color','w','Position',[100 100 1080 420]);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');
nexttile; bar(categorical(string(seeds)),rob(:,2)); ylabel('Loss (MW)'); xlabel('Random seed'); grid on;
nexttile; bar(categorical(string(seeds)),rob(:,3)); ylabel('Voltage deviation'); xlabel('Random seed'); grid on;
nexttile; bar(categorical(string(seeds)),rob(:,4)); ylabel('CAPEX (MUSD)'); xlabel('Random seed'); grid on;
exportgraphics(f,fullfile(outdir,'chapter4_robustness.png'),'Resolution',220);
close(f);

save(fullfile(outdir,'chapter4_analysis.mat'),'load_sensitivity','economic_sensitivity','robustness');
fprintf('Chapter Four supplementary analysis completed.\n');
