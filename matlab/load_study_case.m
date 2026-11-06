function c = load_study_case(root)
%LOAD_STUDY_CASE Read the provenance-controlled Western Uganda case.
if nargin < 1
    root = fileparts(fileparts(mfilename('fullpath')));
end
c.root = root;
c.baseMVA = 100;
c.bus = readtable(fullfile(root,'data','buses.csv'),'TextType','string');
c.branch = readtable(fullfile(root,'data','branches.csv'),'TextType','string');
c.candidate = readtable(fullfile(root,'data','candidates.csv'),'TextType','string');
c.economics = readtable(fullfile(root,'data','economics.csv'),'TextType','string');
c.bus.type_code = ones(height(c.bus),1);
c.bus.type_code(c.bus.type == "PV") = 2;
c.bus.type_code(c.bus.type == "Slack") = 3;
c.switch_rows = find(c.branch.switchable == 1);
c.nCandidate = height(c.candidate);
c.nSwitch = numel(c.switch_rows);
c.pv_buses = find(c.bus.type_code == 2);
c.nVset = numel(c.pv_buses);
c.lb = [zeros(1,c.nCandidate+c.nSwitch), 0.98*ones(1,c.nVset)];
c.ub = [ones(1,c.nCandidate+c.nSwitch), 1.04*ones(1,c.nVset)];
c.binary_count = c.nCandidate + c.nSwitch;
end

