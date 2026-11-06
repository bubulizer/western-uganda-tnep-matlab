function modelPath = build_simulink_dashboard(root)
%BUILD_SIMULINK_DASHBOARD Create a runnable Simulink voltage-results viewer.
if nargin<1, root=fileparts(fileparts(mfilename('fullpath'))); end
S=load(fullfile(root,'outputs','study_results.mat'),'baseline','opt');
baseline_voltage=timeseries(S.baseline.Vm,(0:numel(S.baseline.Vm)-1)'); %#ok<NASGU>
optimized_voltage=timeseries(S.opt.pf.Vm,(0:numel(S.opt.pf.Vm)-1)'); %#ok<NASGU>
assignin('base','baseline_voltage',baseline_voltage);
assignin('base','optimized_voltage',optimized_voltage);
name='western_uganda_voltage_dashboard';
if bdIsLoaded(name), close_system(name,0); end
new_system(name); open_system(name);
set_param(name,'StopTime','10','Solver','FixedStepDiscrete','FixedStep','1');
add_block('simulink/Sources/From Workspace',[name '/Baseline voltage'], ...
    'VariableName','baseline_voltage','Position',[60 70 190 100]);
add_block('simulink/Sources/From Workspace',[name '/Optimized voltage'], ...
    'VariableName','optimized_voltage','Position',[60 150 190 180]);
add_block('simulink/Signal Routing/Mux',[name '/Compare'],'Inputs','2', ...
    'Position',[250 82 255 168]);
add_block('simulink/Sinks/Scope',[name '/Voltage Profile Scope'], ...
    'Position',[340 95 440 155]);
add_block('simulink/Sinks/To Workspace',[name '/Logged comparison'], ...
    'VariableName','voltage_profile_comparison','SaveFormat','Structure With Time', ...
    'Position',[340 190 475 220]);
add_line(name,'Baseline voltage/1','Compare/1');
add_line(name,'Optimized voltage/1','Compare/2');
add_line(name,'Compare/1','Voltage Profile Scope/1');
add_line(name,'Compare/1','Logged comparison/1','autorouting','on');
set_param([name '/Baseline voltage'],'AttributesFormatString','Research-case baseline');
set_param([name '/Optimized voltage'],'AttributesFormatString','MOPSO-DE compromise');
modelPath=fullfile(root,'matlab',[name '.slx']);
save_system(name,modelPath); sim(name); close_system(name,0);
fprintf('Created Simulink dashboard: %s\n',modelPath);
end

