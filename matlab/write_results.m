function write_results(c,baseline,opt,archive,history,n1base,n1opt,cba,outdir)
%WRITE_RESULTS Tables, charts and MP4 animation for thesis analysis.
if ~exist(outdir,'dir'), mkdir(outdir); end
busbase=table(c.bus.bus_id,c.bus.name,baseline.Vm,baseline.Va_deg,baseline.Pinj_MW,baseline.Qinj_MVAr, ...
    'VariableNames',{'bus_id','name','Vm_pu','angle_deg','P_injection_MW','Q_injection_MVAr'});
busopt=table(c.bus.bus_id,c.bus.name,opt.pf.Vm,opt.pf.Va_deg,opt.pf.Pinj_MW,opt.pf.Qinj_MVAr, ...
    'VariableNames',busbase.Properties.VariableNames);
writetable(busbase,fullfile(outdir,'baseline_bus_results.csv'));
writetable(busopt,fullfile(outdir,'optimized_bus_results.csv'));
writetable(baseline.branch,fullfile(outdir,'baseline_branch_results.csv'));
writetable(opt.pf.branch,fullfile(outdir,'optimized_branch_results.csv'));
writetable(n1base,fullfile(outdir,'baseline_nminus1.csv'));
writetable(n1opt,fullfile(outdir,'optimized_nminus1.csv'));
writetable(cba,fullfile(outdir,'cost_benefit_analysis.csv'));
writetable(history,fullfile(outdir,'optimization_history.csv'));
pareto=array2table([archive.raw archive.violation], ...
    'VariableNames',{'loss_MW','voltage_deviation','investment_MUSD','constraint_violation'});
writetable(pareto,fullfile(outdir,'pareto_front.csv'));
plan=table((1:c.nCandidate)',c.candidate.from_bus,c.candidate.to_bus, ...
    opt.decoded.build(:),c.candidate.cost_MUSD, ...
    'VariableNames',{'candidate_id','from_bus','to_bus','selected','cost_MUSD'});
writetable(plan,fullfile(outdir,'selected_plan.csv'));
summary=table([baseline.loss_MW;opt.pf.loss_MW], ...
    [baseline.voltage_deviation;opt.pf.voltage_deviation], ...
    [baseline.min_voltage;opt.pf.min_voltage], ...
    [baseline.max_loading_pct;opt.pf.max_loading_pct], ...
    [0;opt.decoded.cost_MUSD], ...
    'RowNames',{'Baseline','Optimized'},'VariableNames', ...
    {'loss_MW','voltage_deviation','minimum_voltage_pu','maximum_loading_pct','investment_MUSD'});
writetable(summary,fullfile(outdir,'techno_economic_summary.csv'),'WriteRowNames',true);

f=figure('Visible','off','Color','w');
plot(c.bus.bus_id,baseline.Vm,'o-','LineWidth',1.5); hold on;
plot(c.bus.bus_id,opt.pf.Vm,'s-','LineWidth',1.5); yline(0.95,'r--'); yline(1.05,'r--');
xlabel('Bus'); ylabel('Voltage (p.u.)'); grid on; legend('Baseline','Optimized','Location','best');
title('Voltage profile comparison'); exportgraphics(f,fullfile(outdir,'voltage_profiles.png'),'Resolution',180); close(f);

f=figure('Visible','off','Color','w');
bar([baseline.branch.loading_pct; nan(max(0,height(opt.pf.branch)-height(baseline.branch)),1)]); hold on;
plot(1:height(opt.pf.branch),opt.pf.branch.loading_pct,'ro-','LineWidth',1.2); yline(100,'k--');
xlabel('Branch row'); ylabel('Loading (%)'); grid on; legend('Baseline','Optimized');
title('Branch thermal loading'); exportgraphics(f,fullfile(outdir,'branch_loading.png'),'Resolution',180); close(f);

f=figure('Visible','off','Color','w');
scatter3(archive.raw(:,3),archive.raw(:,1),archive.raw(:,2),36,archive.violation,'filled');
xlabel('Investment (MUSD)'); ylabel('Loss (MW)'); zlabel('Voltage deviation'); grid on;
title('MOPSO-DE Pareto archive'); colorbar; exportgraphics(f,fullfile(outdir,'pareto_front.png'),'Resolution',180); close(f);

f=figure('Visible','off','Color','w');
tiledlayout(3,1); nexttile; plot(history.iteration,history.best_loss_MW,'LineWidth',1.4); ylabel('MW'); grid on;
nexttile; plot(history.iteration,history.best_voltage_deviation,'LineWidth',1.4); ylabel('Voltage dev.'); grid on;
nexttile; plot(history.iteration,history.feasible_archive,'LineWidth',1.4); ylabel('Feasible'); xlabel('Iteration'); grid on;
exportgraphics(f,fullfile(outdir,'convergence.png'),'Resolution',180); close(f);

try
    v=VideoWriter(fullfile(outdir,'mopso_de_convergence.mp4'),'MPEG-4'); v.FrameRate=4; open(v);
    f=figure('Visible','off','Color','w');
    for k=2:height(history)
        clf(f); tiledlayout(2,1);
        nexttile; plot(history.iteration(1:k),history.best_loss_MW(1:k),'b-o','LineWidth',1.3); grid on;
        ylabel('Best loss (MW)'); title(sprintf('MOPSO-DE iteration %d',history.iteration(k)));
        nexttile; plot(history.iteration(1:k),history.best_voltage_deviation(1:k),'m-o','LineWidth',1.3); grid on;
        xlabel('Iteration'); ylabel('Best voltage deviation'); drawnow;
        writeVideo(v,getframe(f));
    end
    close(v); close(f);
catch ME
    warning('Animation was not written: %s',ME.message);
end
end
