function [archive, history] = mode_de(c, opts)
%MODE_DE Standalone archive-based multi-objective differential evolution.
arguments
    c struct
    opts.population (1,1) double = 30
    opts.iterations (1,1) double = 26
    opts.archive_size (1,1) double = 90
    opts.seed (1,1) double = 24068
    opts.F (1,1) double = 0.55
    opts.CR (1,1) double = 0.80
end
rng(opts.seed,'twister');
np=opts.population; nd=numel(c.lb);
pos=c.lb+rand(np,nd).*(c.ub-c.lb);
[obj,raw,vio]=eval_pop(c,pos);
archive=update_archive_de(empty_archive_de(nd),pos,obj,raw,vio,opts.archive_size);
history=table((0:opts.iterations)',zeros(opts.iterations+1,1),zeros(opts.iterations+1,1), ...
    zeros(opts.iterations+1,1),zeros(opts.iterations+1,1),zeros(opts.iterations+1,1), ...
    'VariableNames',{'iteration','best_loss_MW','best_voltage_deviation', ...
    'lowest_cost_MUSD','archive_size','feasible_archive'});
history(1,:)=history_row_de(0,archive);
for it=1:opts.iterations
    trial=pos;
    for i=1:np
        pool=setdiff(1:np,i); rr=pool(randperm(numel(pool),3));
        mutant=pos(rr(1),:)+opts.F*(pos(rr(2),:)-pos(rr(3),:));
        mutant=min(c.ub,max(c.lb,mutant));
        mask=rand(1,nd)<opts.CR; mask(randi(nd))=true;
        trial(i,mask)=mutant(mask);
    end
    [tobj,traw,tvio]=eval_pop(c,trial);
    for i=1:np
        if dominates(tobj(i,:),obj(i,:)) || ...
                (~dominates(obj(i,:),tobj(i,:)) && rand<0.5)
            pos(i,:)=trial(i,:); obj(i,:)=tobj(i,:); raw(i,:)=traw(i,:); vio(i)=tvio(i);
        end
    end
    archive=update_archive_de(archive,pos,obj,raw,vio,opts.archive_size);
    history(it+1,:)=history_row_de(it,archive);
end
end

function [obj,raw,vio]=eval_pop(c,pos)
np=size(pos,1); obj=zeros(np,3); raw=obj; vio=zeros(np,1);
for i=1:np
    e=evaluate_plan(c,pos(i,:)); obj(i,:)=e.objectives; raw(i,:)=e.raw_objectives; vio(i)=e.violation;
end
end
function a=empty_archive_de(nd)
a.position=zeros(0,nd); a.objectives=zeros(0,3); a.raw=zeros(0,3); a.violation=zeros(0,1);
end
function a=update_archive_de(a,pos,obj,raw,vio,maxn)
P=[a.position;pos]; O=[a.objectives;obj]; R=[a.raw;raw]; V=[a.violation;vio];
[~,u]=unique(round([P O],9),'rows','stable'); P=P(u,:); O=O(u,:); R=R(u,:); V=V(u);
keep=true(size(O,1),1);
for i=1:size(O,1)
    if ~keep(i), continue; end
    for j=1:size(O,1)
        if i~=j && dominates(O(j,:),O(i,:)), keep(i)=false; break; end
    end
end
P=P(keep,:); O=O(keep,:); R=R(keep,:); V=V(keep);
if size(O,1)>maxn
    cd=crowding_de(O); [~,ord]=sort(cd,'descend'); ord=ord(1:maxn);
    P=P(ord,:); O=O(ord,:); R=R(ord,:); V=V(ord);
end
a.position=P; a.objectives=O; a.raw=R; a.violation=V;
end
function d=crowding_de(O)
n=size(O,1); d=zeros(n,1); if n<=2, d(:)=inf; return; end
for k=1:size(O,2)
    [v,ix]=sort(O(:,k)); d(ix([1 end]))=inf; span=v(end)-v(1); if span==0, continue; end
    for i=2:n-1, d(ix(i))=d(ix(i))+(v(i+1)-v(i-1))/span; end
end
end
function row=history_row_de(it,a)
feas=a.violation<1e-10; if any(feas), r=a.raw(feas,:); else, r=a.objectives; end
row={it,min(r(:,1)),min(r(:,2)),min(r(:,3)),size(a.position,1),sum(feas)};
end
