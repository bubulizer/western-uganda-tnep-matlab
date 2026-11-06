function t = cost_benefit_analysis(c,baseline,opt)
%COST_BENEFIT_ANALYSIS Discounted loss-savings CBA; reliability unmonetized.
names=c.economics.parameter; vals=c.economics.value;
getv=@(n) vals(names==n);
years=getv("study_years"); rate=getv("discount_rate");
price=getv("energy_price"); lf=getv("annual_load_factor");
omf=getv("annual_om_fraction");
loss_reduction=max(0,baseline.loss_MW-opt.pf.loss_MW);
annual_MWh=loss_reduction*8760*lf;
annual_saving=annual_MWh*price/1e6;
pvfactor=sum(1./(1+rate).^(1:years));
pv_loss=annual_saving*pvfactor;
capex=opt.decoded.cost_MUSD;
pv_om=capex*omf*pvfactor;
npv=pv_loss-capex-pv_om;
bcr=pv_loss/max(capex+pv_om,eps);
t=table(loss_reduction,annual_MWh,annual_saving,pv_loss,capex,pv_om,npv,bcr, ...
    'VariableNames',{'loss_reduction_MW','annual_loss_saving_MWh','annual_saving_MUSD', ...
    'PV_loss_benefit_MUSD','CAPEX_MUSD','PV_OM_MUSD','NPV_MUSD','benefit_cost_ratio'});
end

