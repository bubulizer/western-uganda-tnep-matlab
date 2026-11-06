function [archive, history] = mopso_de(c, opts)
%MOPSO_DE Hybrid multi-objective particle swarm/differential evolution.
arguments
    c struct
    opts.population (1,1) double = 28
    opts.iterations (1,1) double = 24
    opts.archive_size (1,1) double = 80
    opts.seed (1,1) double = 24068
    opts.inertia (1,1) double = 0.72
    opts.c1 (1,1) double = 1.55
    opts.c2 (1,1) double = 1.55
    opts.de_fraction (1,1) double = 0.30
    opts.de_F (1,1) double = 0.55
    opts.de_CR (1,1) double = 0.80
end
rng(opts.seed,'twister');
np = opts.population; nd = numel(c.lb);
pos = c.lb + rand(np,nd).*(c.ub-c.lb);
vel = zeros(np,nd);
[obj, raw, vio] = evaluate_population(c,pos);
pbest = pos; pbest_obj = obj;
archive = update_archive(empty_archive(nd),pos,obj,raw,vio,opts.archive_size);
history = table((0:opts.iterations)',zeros(opts.iterations+1,1), ...
    zeros(opts.iterations+1,1),zeros(opts.iterations+1,1), ...
    zeros(opts.iterations+1,1),zeros(opts.iterations+1,1), ...
    'VariableNames',{'iteration','best_loss_MW','best_voltage_deviation', ...
    'lowest_cost_MUSD','archive_size','feasible_archive'});
history(1,:) = history_row(0,archive);

for it = 1:opts.iterations
    for i = 1:np
        guide = select_guide(archive);
        vel(i,:) = opts.inertia*vel(i,:) + opts.c1*rand(1,nd).*(pbest(i,:)-pos(i,:)) + ...
            opts.c2*rand(1,nd).*(guide-pos(i,:));
        pos(i,:) = min(c.ub,max(c.lb,pos(i,:)+vel(i,:)));
    end
    nDE = max(0,round(opts.de_fraction*np));
    if nDE > 0
        for i = randperm(np,nDE)
            pool = setdiff(1:np,i);
            rr = pool(randperm(numel(pool),3));
            mutant = pos(rr(1),:) + opts.de_F*(pos(rr(2),:)-pos(rr(3),:));
            mutant = min(c.ub,max(c.lb,mutant));
            mask = rand(1,nd) < opts.de_CR;
            mask(randi(nd)) = true;
            pos(i,mask) = mutant(mask);
        end
    end
    [obj,raw,vio] = evaluate_population(c,pos);
    for i = 1:np
        if dominates(obj(i,:),pbest_obj(i,:)) || ...
                (~dominates(pbest_obj(i,:),obj(i,:)) && rand < 0.5)
            pbest(i,:) = pos(i,:); pbest_obj(i,:) = obj(i,:);
        end
    end
    archive = update_archive(archive,pos,obj,raw,vio,opts.archive_size);
    history(it+1,:) = history_row(it,archive);
end
end

function [obj,raw,vio] = evaluate_population(c,pos)
np = size(pos,1); obj = zeros(np,3); raw = obj; vio = zeros(np,1);
for i = 1:np
    e = evaluate_plan(c,pos(i,:));
    obj(i,:) = e.objectives; raw(i,:) = e.raw_objectives; vio(i) = e.violation;
end
end

function a = empty_archive(nd)
a.position = zeros(0,nd); a.objectives = zeros(0,3);
a.raw = zeros(0,3); a.violation = zeros(0,1);
end

function a = update_archive(a,pos,obj,raw,vio,maxn)
P = [a.position;pos]; O = [a.objectives;obj]; R = [a.raw;raw]; V = [a.violation;vio];
[~,u] = unique(round([P O],9),'rows','stable');
P=P(u,:); O=O(u,:); R=R(u,:); V=V(u);
keep = true(size(O,1),1);
for i=1:size(O,1)
    if ~keep(i), continue; end
    for j=1:size(O,1)
        if i~=j && dominates(O(j,:),O(i,:)), keep(i)=false; break; end
    end
end
P=P(keep,:); O=O(keep,:); R=R(keep,:); V=V(keep);
if size(O,1) > maxn
    cd = crowding(O); [~,ord] = sort(cd,'descend'); ord=ord(1:maxn);
    P=P(ord,:); O=O(ord,:); R=R(ord,:); V=V(ord);
end
a.position=P; a.objectives=O; a.raw=R; a.violation=V;
end

function d = crowding(O)
n=size(O,1); m=size(O,2); d=zeros(n,1);
if n<=2, d(:)=inf; return; end
for k=1:m
    [v,ix]=sort(O(:,k)); d(ix([1 end]))=inf;
    span=v(end)-v(1); if span==0, continue; end
    for i=2:n-1, d(ix(i))=d(ix(i))+(v(i+1)-v(i-1))/span; end
end
end

function g = select_guide(a)
d=crowding(a.objectives); finite=d(isfinite(d));
if isempty(finite), idx=randi(size(a.position,1));
else
    w=d; w(isinf(w))=max(finite)+1; w=max(w,1e-6); w=w/sum(w);
    idx=find(rand<=cumsum(w),1,'first');
end
g=a.position(idx,:);
end

function row = history_row(it,a)
feas=a.violation<1e-10;
if any(feas), r=a.raw(feas,:); else, r=a.objectives; end
row={it,min(r(:,1)),min(r(:,2)),min(r(:,3)),size(a.position,1),sum(feas)};
end
